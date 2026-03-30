"""
Voya Backend Proxy — uses Google Gemini API with API key.
Run: uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
import json
import base64
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBZXP2IpuGT_RDifjKTCO3FE2LOe1-ZLII")
genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel(
    "gemini-2.0-flash",
    system_instruction=(
        "You are Voya, a visual travel assistant that helps travelers understand "
        "unfamiliar text, signs, menus, products, and objects in any country or language. "
        "When given an image, analyze it and return a JSON object with these exact fields: "
        '"title": short English title, '
        '"zhName": the original text in its native language (if text is present, else empty string), '
        '"subtitle": one-line English description, '
        '"category": exactly one of: Food, Sign, Product, Document, Place, Other, '
        '"what": 1-2 sentence identification in English, '
        '"context": 2-3 sentences of cultural or practical background, '
        '"tips": practical advice for a traveler, '
        '"commonAllergens": comma-separated allergen list if food, else empty string. '
        "Return ONLY the raw JSON object. No markdown, no backticks."
    ),
)

app = FastAPI(title="Voya Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/analyze")
async def analyze(image: UploadFile = File(...)):
    """Receive an image from the iOS app, forward to Gemini."""
    image_bytes = await image.read()

    image_part = {
        "mime_type": image.content_type or "image/jpeg",
        "data": image_bytes,
    }

    try:
        response = model.generate_content(
            [image_part, "Analyze this image. Help me understand what I'm looking at as a traveler."],
            generation_config={"temperature": 0.4, "max_output_tokens": 1024},
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Gemini error: {str(e)}")

    text = response.text

    # Strip markdown fences if present
    cleaned = text.replace("```json", "").replace("```", "").strip()

    try:
        result = json.loads(cleaned)
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="Invalid JSON from Gemini")

    return result
