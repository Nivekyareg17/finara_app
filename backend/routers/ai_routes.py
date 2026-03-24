import os
from fastapi import APIRouter
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

model = genai.GenerativeModel('gemini-2.5-flash')

# El prefix es /ai
router = APIRouter(prefix="/ai", tags=["IA"])

@router.get("/consultar")
async def consultar(pregunta: str):
    try:
        print(f"DEBUG: Pregunta recibida -> {pregunta}")
        response = model.generate_content(pregunta)
        
        # IMPORTANTE: La clave debe ser "text"
        if response.text:
            print(f"DEBUG: Respuesta enviada -> {response.text[:20]}...")
            return {"text": response.text}
        else:
            return {"text": "La IA no generó texto."}
            
    except Exception as e:
        print(f"Error en Python: {e}")
        return {"text": f"Error: {str(e)}"}