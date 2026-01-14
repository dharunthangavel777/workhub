import os
import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any
import logging

from ocr_engine import OCREngine
from extractor import ResumeExtractor

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Work Hub Resume Parser Service")

# Allow CORS for local development and Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global engines (lazy loaded)
ocr_engine = None
extractor = None

def get_engines():
    global ocr_engine, extractor
    if ocr_engine is None:
        logger.info("Lazy-loading OCR engine...")
        ocr_engine = OCREngine()
    if extractor is None:
        logger.info("Lazy-loading Extractor engine...")
        extractor = ResumeExtractor()
    return ocr_engine, extractor

@app.get("/")
async def health_check():
    return {"status": "healthy", "service": "resume-parser"}

import time

@app.post("/parse")
async def parse_resume(file: UploadFile = File(...)):
    """
    Parses a resume file (PDF or Image) and returns structured JSON data.
    """
    start_time = time.time()
    logger.info(f"Received file: {file.filename}")
    
    # Lazy load engines
    ocr_engine, extractor = get_engines()
    
    # Save the uploaded file temporarily
    temp_file_path = f"temp_{file.filename}"
    try:
        with open(temp_file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        save_time = time.time()
        logger.info(f"File saved in {save_time - start_time:.2f}s")
        
        # 1. OCR Step: Extract raw text from document
        raw_text = ocr_engine.extract_text(temp_file_path)
        ocr_time = time.time()
        logger.info(f"OCR completed in {ocr_time - save_time:.2f}s")
        
        # Limit text if it's excessively long
        if len(raw_text) > 50000:
            raw_text = raw_text[:50000]
            logger.warning("Truncated excessively long text from document.")
        
        # 2. Extraction Step: Structure the text into JSON
        structured_data = extractor.extract_from_text(raw_text)
        extract_time = time.time()
        logger.info(f"Extraction completed in {extract_time - ocr_time:.2f}s")
        
        total_time = extract_time - start_time
        logger.info(f"Total processing time: {total_time:.2f}s")
        
        return {
            "success": True,
            "filename": file.filename,
            "data": structured_data,
            "processing_time": f"{total_time:.2f}s"
        
        
    except Exception as e:
        logger.error(f"Error parsing resume: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Cleanup
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
