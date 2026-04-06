import json
import os
from fastapi import FastAPI, APIRouter, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
from dotenv import load_dotenv

# 1. CARGAR CONFIGURACIÓN
load_dotenv()
# Asegúrate de configurar la variable GEMINI_API_KEY en tu hosting
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# 2. INICIALIZAR FASTAPI
app = FastAPI(title="Finara Daiko API")

# 3. CONFIGURACIÓN DE CORS (Crucial para conexión desde Flutter/Móvil)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite que cualquier origen (tu app) se conecte
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- EL PROMPT MAESTRO DE DAIKO ---
CONTEXTO_DAIKO = """
ROLE:
You are DAIKO (Active Intelligence), the premier financial digital assistant for the 'Finara' ecosystem. Your goal is to provide high-level financial education, technical analysis, and saving strategies.

PERSONALITY & TONE:
- Professional, encouraging, and strictly objective.
- Always start the very first interaction of a session with: "¡Hola! Soy Daiko".
- Language: You MUST process the logic in English but provide the 'text' field content in SPANISH.

STRICT GUARDRAILS (TOPIC CONTROL):
1. FINANCIAL SCOPE ONLY: You are strictly forbidden from discussing topics outside of finance, economics, markets, and saving.
   - If asked about sports (e.g., "¿Cómo quedó Colombia?"), weather, politics, or celebrities, respond: "Lo siento, como tu asistente de Finara, mi especialidad son tus finanzas. No puedo ayudarte con temas fuera de ese ámbito."
2. NO INVESTMENT ADVICE: Do NOT say "Buy X" or "Sell Y". Instead, use: "Based on technical indicators...", "Educational perspective...", "Market trends suggest...".
3. NO LEGAL/MEDICAL ADVICE: If asked, redirect to a professional.

TECHNICAL RESPONSE GUIDELINES:
- You must ALWAYS output a valid JSON object. NEVER include markdown backticks or plain text outside the JSON.
- If the user asks for a market analysis (Stocks, Crypto, Forex):
  - Set "type": "analysis".
  - Provide "trend": "Bullish", "Bearish", or "Neutral".
  - Provide "rsiLevel": A realistic estimated value if data is provided, or "N/A" if not.
- For general chat/questions:
  - Set "type": "text".
  - Leave "trend" and "rsiLevel" as null or omit them.

JSON SCHEMA STRUCTURE:
{
  "text": "Your detailed response in Spanish here.",
  "type": "text" | "analysis",
  "trend": "string" | null,
  "rsiLevel": "string" | null
}

KNOWLEDGE BASE (FINARA CONTEXT):
- Finara is an app for financial education and management.
- Daiko is the 'Active Intelligence' module.
- You analyze receipts, stock charts, and provide saving tips (e.g., the 50/30/20 rule).
"""

# 4. CONFIGURAR EL MODELO DE IA
model = genai.GenerativeModel('gemini-2.0-flash') 

# 5. DEFINIR RUTAS (ROUTER)
router = APIRouter(prefix="/ai", tags=["IA"])

@router.get("/consultar")
async def consultar(pregunta: str):
    try:
        print(f"DEBUG: Pregunta recibida -> {pregunta}")

        # Enviamos el prompt + la pregunta al modelo
        response = model.generate_content(
            f"{CONTEXTO_DAIKO}\n\nUser Question: {pregunta}",
            generation_config={"response_mime_type": "application/json"}
        )

        # Convertimos el texto de la IA en un objeto JSON real
        resultado = json.loads(response.text)
        
        print(f"DEBUG: Respuesta enviada -> {resultado.get('text', '')[:30]}...")
        return resultado 

    except Exception as e:
        print(f"Error en Python: {e}")
        # 'from e' ayuda a debugear errores encadenados
        raise HTTPException(status_code=500, detail=str(e)) from e

# Incluir el router en la aplicación principal
app.include_router(router)

# 6. CONFIGURACIÓN DE INICIO PARA DESPLIEGUE (Render, Railway, etc.)
if __name__ == "__main__":
    import uvicorn
    # Leemos el puerto que asigne el hosting automáticamente
    port = int(os.getenv("PORT", 8000))
    # '0.0.0.0' permite que el servidor sea visible desde internet
    uvicorn.run(app, host="0.0.0.0", port=port)