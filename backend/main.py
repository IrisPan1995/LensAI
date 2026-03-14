"""
LensAI Backend Proxy — keeps Gemini API key on the server side.
Run: uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
import httpx
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import base64

load_dotenv()

app = FastAPI(title="LensAI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.0-flash"
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"

SYSTEM_INSTRUCTION = (
    "You are LensAI, a cultural visual guide for foreigners visiting China. "
    "When given an image of Chinese text, menus, signs, medicine, forms, or any Chinese content, "
    "analyze it and return a JSON object with these exact fields: "
    '"title": short English title, '
    '"zhName": the original Chinese text, '
    '"subtitle": one-line English description, '
    '"category": exactly one of: Food, Sign, Product, Document, Place, Other, '
    '"what": 1-2 sentence identification, '
    '"context": 2-3 sentences of cultural background, '
    '"tips": practical advice for a foreigner, '
    '"commonAllergens": comma-separated allergen list if food, else empty string. '
    "Return ONLY the raw JSON object. No markdown, no backticks."
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/analyze")
async def analyze(image: UploadFile = File(...)):
    """Receive an image from the iOS app, forward to Gemini, return the result."""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")

    image_bytes = await image.read()
    b64 = base64.b64encode(image_bytes).decode("utf-8")

    payload = {
        "system_instruction": {"parts": [{"text": SYSTEM_INSTRUCTION}]},
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": image.content_type or "image/jpeg",
                            "data": b64,
                        }
                    },
                    {
                        "text": "Analyze this image. Help me understand it as a foreigner in China."
                    },
                ]
            }
        ],
        "generationConfig": {"temperature": 0.4, "maxOutputTokens": 1024},
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            GEMINI_URL,
            params={"key": GEMINI_API_KEY},
            json=payload,
        )

    if resp.status_code != 200:
        raise HTTPException(status_code=resp.status_code, detail=resp.text)

    gemini_data = resp.json()

    try:
        text = gemini_data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError):
        raise HTTPException(status_code=502, detail="No text in Gemini response")

    # Strip markdown fences if present
    cleaned = text.replace("```json", "").replace("```", "").strip()

    import json
    try:
        result = json.loads(cleaned)
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="Invalid JSON from Gemini")

    return result
