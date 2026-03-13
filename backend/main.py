import os
import uuid
import io
import asyncio
import pdfplumber
import faiss
import numpy as np
import pytesseract
from pathlib import Path
from datetime import datetime, timezone
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from docx import Document
from langchain_ollama import OllamaLLM
from sentence_transformers import SentenceTransformer

# === Настройки ===
CHUNK_SIZE = 1500  # Чуть больше для юр. контекста
OVERLAP = 300
embedder = SentenceTransformer('all-MiniLM-L6-v2')
model = OllamaLLM(model="qwen2.5") # Используем Qwen через Ollama
DOCUMENTS = {}

# === Утилиты ===
def chunk_text(text: str) -> list:
    return [text[i:i + CHUNK_SIZE] for i in range(0, len(text), CHUNK_SIZE - OVERLAP)]

def create_embeddings(chunks: list):
    embeddings = embedder.encode(chunks)
    index = faiss.IndexFlatL2(embeddings.shape[1])
    index.add(np.array(embeddings).astype('float32'))
    return index

# === FastAPI ===
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# === Функции извлечения ===
def extract_text(content: bytes, ext: str) -> str:
    if ext == ".pdf":
        with pdfplumber.open(io.BytesIO(content)) as pdf:
            return "\n".join([page.extract_text() for page in pdf.pages if page.extract_text()])
    elif ext in [".docx", ".doc"]:
        doc = Document(io.BytesIO(content))
        return "\n".join([p.text for p in doc.paragraphs])
    elif ext in [".jpg", ".jpeg", ".png"]:
        image = Image.open(io.BytesIO(content))
        return pytesseract.image_to_string(image, lang='rus+kaz')
    return ""

# === API Endpoints ===

@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    try:
        content = await file.read()
        ext = Path(file.filename).suffix.lower()
        text = extract_text(content, ext)
            
        if not text or len(text.strip()) < 50:
            raise HTTPException(status_code=400, detail="Не удалось распознать текст.")
        
        doc_id = str(uuid.uuid4())
        chunks = chunk_text(text)
        index = create_embeddings(chunks)
        
        DOCUMENTS[doc_id] = {
            "text": text, "chunks": chunks, "index": index, 
            "filename": file.filename, "upload_date": datetime.now(timezone.utc).isoformat()
        }
        return {"id": doc_id, "filename": file.filename, "status": "ready"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
async def chat_with_document(document_id: str, question: str, language: str = "ru"):
    doc = DOCUMENTS.get(document_id)
    if not doc: raise HTTPException(status_code=404, detail="Документ не найден")
    
    # Поиск контекста
    query_vector = embedder.encode([question]).astype('float32')
    D, I = doc["index"].search(query_vector, k=4) # Берем больше контекста
    context = "\n".join([doc["chunks"][i] for i in I[0] if i != -1])
 
    prompt = f"""
    Ты — профессиональный ИИ-юрист. Твоя задача: проанализировать договор и ответить на вопрос.
    ПРАВИЛА:
    1. Ответ должен быть на языке: {language}.
    2. Если в тексте есть скрытые риски, странные условия (red flags) или важные дедлайны — выдели их жирным.
    3. Структура: Краткий ответ, затем пояснение рисков/обязательств.
    Контекст документа: {context}
    Вопрос пользователя: {question}
    """
    
    answer = await asyncio.to_thread(lambda: model.invoke(prompt))
    return {"answer": answer, "timestamp": datetime.now(timezone.utc).isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
    