import os
import uuid
import io
import asyncio
import logging
import json
import re
import time
import hashlib
from typing import List, Dict, Optional, Any
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

import pdfplumber
import pytesseract
from PIL import Image
import docx
from chromadb.utils import embedding_functions
import chromadb
from langchain_ollama import OllamaLLM
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# --- НАСТРОЙКИ ---
class Config:
    CHUNK_SIZE = 600
    OVERLAP = 100
    RELEVANCE_THRESHOLD = 0.3
    LLM_MODEL = "qwen2.5:3b"  # Быстрая версия
    # ДЛЯ MAC: '/opt/homebrew/bin/tesseract'
    # ДЛЯ WINDOWS: r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    TESSERACT_PATH = '/opt/homebrew/bin/tesseract' 
    ALLOWED_EXTENSIONS = {'.pdf', '.docx', '.jpg', '.jpeg', '.png'}

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("LegalAI")

app = FastAPI(title="Legal AI Platform API", description="MVP для юридического анализа документов")

# Разрешаем фронтенду подключаться
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Проверка Tesseract
if os.path.exists(Config.TESSERACT_PATH):
    pytesseract.pytesseract.tesseract_cmd = Config.TESSERACT_PATH

# База данных и Эмбеддинги
embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="intfloat/multilingual-e5-small")
chroma_client = chromadb.PersistentClient(path="./db_storage")
collection = chroma_client.get_or_create_collection(name="legal_docs_v1", embedding_function=embedding_fn)

# Инициализация LLM
llm = OllamaLLM(
    model=Config.LLM_MODEL,
    temperature=0.1,
    num_ctx=3072,
    num_gpu=1,
    num_thread=8
)

# Кеш в памяти (для скорости конкурса)
response_cache = {}

# --- МОДЕЛИ ДАННЫХ ДЛЯ SWAGGER ---
class LegalResponse(BaseModel):
    summary: str
    risks: List[Any] = []
    deadlines: List[Any] = []
    sources: List[Source] = []
    processing_time: float
class ChatRequest(BaseModel):
    document_id: str = Field(..., example="uuid-от-вашего-файла")
    question: str = Field(..., example="Какие основные риски в этом договоре?")

class Source(BaseModel):
    page: int
    text_preview: str
    relevance: float

# --- ЛОГИКА ПАРСИНГА ---
def extract_text(content: bytes, ext: str) -> List[Dict]:
    pages = []
    try:
        if ext == '.pdf':
            with pdfplumber.open(io.BytesIO(content)) as pdf:
                for i, p in enumerate(pdf.pages[:10]): # Лимит 10 стр для скорости
                    txt = p.extract_text() or ""
                    if not txt.strip(): # Если пусто — это скан, включаем OCR
                        txt = pytesseract.image_to_string(p.to_image().original, lang='rus+kaz')
                    pages.append({"page": i+1, "text": txt})
        elif ext in {'.jpg', '.jpeg', '.png'}:
            txt = pytesseract.image_to_string(Image.open(io.BytesIO(content)), lang='rus+kaz')
            pages.append({"page": 1, "text": txt})
        elif ext == '.docx':
            doc = docx.Document(io.BytesIO(content))
            pages.append({"page": 1, "text": "\n".join([p.text for p in doc.paragraphs])})
    except Exception as e:
        logger.error(f"Error parsing {ext}: {e}")
    return pages

# --- ЭНДПОИНТЫ ---
@app.post("/upload", tags=["Upload"])
async def upload_document(file: UploadFile = File(...)):
    ext = Path(file.filename).suffix.lower()
    if ext not in Config.ALLOWED_EXTENSIONS:
        raise HTTPException(400, "Формат не поддерживается")
    
    content = await file.read()
    pages = extract_text(content, ext)
    
    if not pages:
        raise HTTPException(400, "Не удалось извлечь текст")

    doc_id = str(uuid.uuid4())
    chunks, ids, metas = [], [], []

    for p in pages:
        text = p['text']
        for i in range(0, len(text), Config.CHUNK_SIZE - Config.OVERLAP):
            chunk = text[i:i+Config.CHUNK_SIZE]
            if len(chunk.strip()) < 40: continue
            
            chunk_id = f"{doc_id}_p{p['page']}_{i}"
            chunks.append(chunk)
            ids.append(chunk_id)
            metas.append({"doc_id": doc_id, "page": p['page'], "text_preview": chunk[:150]})

    collection.add(documents=chunks, ids=ids, metadatas=metas)
    return {"document_id": doc_id, "filename": file.filename, "pages_count": len(pages)}
@app.post("/chat", response_model=LegalResponse, tags=["AI Chat"])
async def chat_with_document(req: ChatRequest):
    start_time = time.time()
    
    # --- ШАГ 1: ОПРЕДЕЛЯЕМ ЯЗЫК ВОПРОСА ---
    # Ищем специфичные казахские буквы
    kazakh_letters = set("әғқңөұүһіӘҒҚҢӨҰҮҺІ")
    is_kazakh = any(char in kazakh_letters for char in req.question)
    target_lang = "KAZAKH" if is_kazakh else "RUSSIAN"
    
    logger.info(f"Detected language: {target_lang}")

    # --- ШАГ 2: КЭШ ---
    cache_key = hashlib.md5(f"{req.document_id}:{req.question}".encode()).hexdigest()
    if cache_key in response_cache:
        cached_data = response_cache[cache_key]
        cached_data.processing_time = round(time.time() - start_time, 2)
        return cached_data

    # --- ШАГ 3: ПОИСК КОНТЕКСТА ---
    results = collection.query(
        query_texts=[req.question],
        where={"doc_id": req.document_id},
        n_results=3
    )

    if not results['documents'][0]:
        raise HTTPException(404, "Документ не найден")

    context_text = "\n".join(results['documents'][0])
    sources = [
        Source(
            page=results['metadatas'][0][i]['page'],
            text_preview=results['metadatas'][0][i]['text_preview'],
            relevance=round(1/(1+results['distances'][0][i]), 2)
        ) for i in range(len(results['documents'][0]))
    ]

    # --- ШАГ 4: ГИБКИЙ ПРОМПТ ---
    # Мы явно приказываем ИИ использовать нужный язык
    prompt = f"""You are a professional legal expert.
    TASK: Answer the question based on the context.
    
    STRICT RULE: You MUST answer ONLY in {target_lang} language. 
    If target language is KAZAKH, use legal Kazakh terms (e.g., 'Заң', 'Тарап', 'Мерзімі').
    
    Return ONLY JSON:
    {{
        "summary": "Full answer in {target_lang}",
        "risks": [{{ "desc": "description in {target_lang}", "level": "high/medium/low" }}],
        "deadlines": []
    }}

    CONTEXT:
    {context_text[:1500]}
    
    QUESTION: {req.question}
    
    JSON RESPONSE IN {target_lang}:"""

    try:
        raw_ai_response = await asyncio.wait_for(llm.ainvoke(prompt), timeout=120.0)
        
        data = {"summary": raw_ai_response, "risks": [], "deadlines": []}
        try:
            clean_json_match = re.search(r'\{.*\}', raw_ai_response, re.DOTALL)
            if clean_json_match:
                parsed = json.loads(clean_json_match.group())
                if isinstance(parsed, dict):
                    data.update(parsed)
        except:
            pass

        final_response = LegalResponse(
            summary=str(data.get("summary", "Ошибка")),
            risks=data.get("risks") if isinstance(data.get("risks"), list) else [],
            deadlines=data.get("deadlines") if isinstance(data.get("deadlines"), list) else [],
            sources=sources,
            processing_time=round(time.time() - start_time, 2)
        )
        
        response_cache[cache_key] = final_response
        return final_response

    except Exception as e:
        logger.error(f"AI Error: {e}")
        return LegalResponse(summary=f"Error: {e}", sources=sources, processing_time=0)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)