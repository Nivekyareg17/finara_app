import json
from fastapi import APIRouter, HTTPException
import google.generativeai as genai
import os
from dotenv import load_dotenv

# 1. ESTO TE FALTA: Cargar configuración
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

# 2. ESTO TE FALTA: Definir el modelo
model = genai.GenerativeModel('gemini-2.5-flash')

# 3. ESTO TE FALTA: Definir el router
router = APIRouter(prefix="/ai", tags=["IA Financiera"])

@router.get("/consultar")
async def consultar_ia(pregunta: str):
    try:
        contexto_daiko = (
            "Eres Daiko, IA de la app Finara. Analiza el siguiente mensaje. "
            "Si es una consulta financiera, responde en formato JSON con estos campos: "
            "{ 'text': 'tu respuesta', "
            "Si es charla normal, usa type: 'text'."
        )
        
        response = model.generate_content(
            f"{contexto_daiko}\n\nMensaje del usuario: {pregunta}",
            generation_config={"response_mime_type": "application/json"}
        )

        resultado = json.loads(response.text)
        return resultado 
    except Exception as e:
        # Agregamos el 'from e' que te pedía el otro error
        raise HTTPException(status_code=500, detail=str(e)) from e