import os
import uuid
import io
import asyncio
import logging
import json
import hashlib
import time
import re  
from typing import List, Optional
from pathlib import Path
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

import pytesseract
import pdfplumber
from PIL import Image
from docx import Document
import chromadb
import numpy as np
from sentence_transformers import SentenceTransformer
from langchain_ollama import OllamaLLM
from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# --- Конфигурация ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

CHUNK_SIZE = 2000
OVERLAP = 400
MAX_FILE_SIZE = 50 * 1024 * 1024
RELEVANCE_THRESHOLD = 0.3
LLM_TIMEOUT = 90

# Инициализация
app = FastAPI(title="Legal AI Assistant")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

llm_executor = ThreadPoolExecutor(max_workers=3)
model = OllamaLLM(model="qwen2.5", temperature=0.1)
client = chromadb.PersistentClient(path="./db_storage")
collection = client.get_or_create_collection(name="law_docs")

pytesseract.pytesseract.tesseract_cmd = os.getenv('TESSERACT_PATH', '/opt/homebrew/bin/tesseract')

# --- Pydantic модели ---
class ChatRequest(BaseModel):
    document_id: str
    question: str
    language: str = "ru"

class ChatResponse(BaseModel):
    answer: dict
    cached: bool = False

# --- Кэш ---
class ResponseCache:
    def __init__(self, maxsize=100):
        self.cache = {}
        self.maxsize = maxsize
    
    def _key(self, doc_id: str, q: str) -> str:
        return hashlib.md5(f"{doc_id}:{q.lower().strip()}".encode()).hexdigest()
    
    def get(self, doc_id: str, q: str):
        return self.cache.get(self._key(doc_id, q))
    
    def set(self, doc_id: str, q: str, ans: dict):
        if len(self.cache) >= self.maxsize:
            self.cache.pop(next(iter(self.cache)))
        self.cache[self._key(doc_id, q)] = ans

cache = ResponseCache()

# --- Rate Limiter ---
class RateLimiter:
    def __init__(self, requests_per_minute: int = 10):
        self.rate = requests_per_minute
        self.requests = {}
    
    def is_allowed(self, ip: str) -> bool:
        now = time.time()
        minute_ago = now - 60
        
        if ip in self.requests:
            self.requests[ip] = [ts for ts in self.requests[ip] if ts > minute_ago]
            if len(self.requests[ip]) >= self.rate:
                return False
        else:
            self.requests[ip] = []
        
        self.requests[ip].append(now)
        return True

rate_limiter = RateLimiter()

# --- Утилиты ---
def parse_llm_response(response: str) -> dict:
    """Парсит ответ LLM в JSON"""
    try:
        # Очищаем от markdown
        clean = re.sub(r'```json|```', '', response).strip()
        return json.loads(clean)
    except json.JSONDecodeError:
        logger.error(f"Failed to parse LLM response: {response[:200]}")
        return {
            "summary": response[:500],
            "risks": ["Ошибка парсинга JSON"],
            "legal_basis": [],
            "obligations": [],
            "deadlines": [],
            "disclaimer": "Ответ не в требуемом формате JSON"
        }

def extract_text(content: bytes, ext: str) -> str:
    """Извлекает текст из файла"""
    try:
        if ext == ".pdf":
            with pdfplumber.open(io.BytesIO(content)) as pdf:
                return "\n".join([p.extract_text() for p in pdf.pages if p.extract_text()])
        elif ext in [".docx", ".doc"]:
            return "\n".join([p.text for p in Document(io.BytesIO(content)).paragraphs])
        elif ext in [".jpg", ".jpeg", ".png"]:
            return pytesseract.image_to_string(Image.open(io.BytesIO(content)), lang='rus+kaz')
    except Exception as e:
        logger.error(f"Extraction error: {e}")
        raise HTTPException(status_code=400, detail="Ошибка обработки файла")
    return ""

# --- Эндпоинты ---
@app.get("/health")
async def health_check():
    """Проверка здоровья сервиса"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "documents_count": collection.count()
    }

@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    """Загрузка документа"""
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large")
    
    text = extract_text(content, Path(file.filename).suffix.lower())
    if not text or len(text.strip()) < 50:
        raise HTTPException(status_code=400, detail="Текст не распознан")
    
    doc_id = str(uuid.uuid4())
    chunks = [text[i:i + CHUNK_SIZE] for i in range(0, len(text), CHUNK_SIZE - OVERLAP)]
    
    # Добавляем с метаданными
    collection.add(
        documents=chunks,
        ids=[f"{doc_id}_{i}" for i in range(len(chunks))],
        metadatas=[{
            "doc_id": doc_id,
            "chunk_index": i,
            "total_chunks": len(chunks),
            "filename": file.filename,
            "upload_time": datetime.now().isoformat()
        } for i in range(len(chunks))]
    )
    
    logger.info(f"Document {doc_id} uploaded with {len(chunks)} chunks")
    return {"id": doc_id, "status": "ready", "chunks": len(chunks)}

@app.post("/chat", response_model=ChatResponse)
async def chat_with_document(request: Request, chat_request: ChatRequest):
    """Чат с документом"""
    # Rate limiting
    if not rate_limiter.is_allowed(request.client.host):
        raise HTTPException(status_code=429, detail="Too many requests")
    
    # Проверка кэша
    cached = cache.get(chat_request.document_id, chat_request.question)
    if cached:
        logger.info(f"Cache hit for: {chat_request.question[:50]}")
        return {"answer": cached, "cached": True}
    
    # Проверка документа
    doc_check = collection.get(where={"doc_id": chat_request.document_id}, limit=1)
    if not doc_check['ids']:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Поиск релевантных чанков
    results = collection.query(
        query_texts=[chat_request.question],
        where={"doc_id": chat_request.document_id},
        n_results=5,
        include=["documents", "distances"]
    )
    
    docs = results['documents'][0]
    dists = results['distances'][0]
    
    # Фильтрация по релевантности
    similarities = [1 / (1 + dist) for dist in dists]
    relevant = [doc for doc, sim in zip(docs, similarities) if sim > RELEVANCE_THRESHOLD]
    
    if not relevant:
        return {
            "answer": {
                "summary": "В документе не найдено релевантной информации",
                "risks": [],
                "legal_basis": [],
                "obligations": [],
                "deadlines": [],
                "disclaimer": "Проверьте вопрос или загрузите другой документ"
            },
            "cached": False
        }
    
    # Запрос к LLM
    context = "\n".join(relevant)
    prompt = f"""You are a professional Legal AI Assistant. 
Analyze the provided document context and answer the user's question accurately. 
If the answer is not in the context, return "мәлімет жоқ" or "информация отсутствует".

Rules:
1. Respond strictly in JSON format.
2. If language is Kazakh, use formal, professional legal terminology.
3. Base answers ONLY on the context.

Context:
{context}

Question: {chat_request.question}

Output Format (JSON):
{{
    "summary": "...",
    "risks": ["..."],
    "legal_basis": ["..."],
    "obligations": ["..."],
    "deadlines": ["..."],
    "disclaimer": "..."
}}
"""
    
    try:
        loop = asyncio.get_event_loop()
        answer = await asyncio.wait_for(
            loop.run_in_executor(llm_executor, model.invoke, prompt),
            timeout=LLM_TIMEOUT
        )
        
        parsed = parse_llm_response(answer)
        cache.set(chat_request.document_id, chat_request.question, parsed)
        
        return {"answer": parsed, "cached": False}
        
    except asyncio.TimeoutError:
        logger.error(f"LLM timeout for doc {chat_request.document_id}")
        raise HTTPException(status_code=504, detail="LLM timeout")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)