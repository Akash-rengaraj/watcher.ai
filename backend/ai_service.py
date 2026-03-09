import json
import httpx
from models import EnrichedVitals

OLLAMA_URL = "http://localhost:11434/api/generate"
# Assuming 'llama3' is pulled. Set to whichever model is available locally.
OLLAMA_MODEL = "llama3"

async def generate_triage_assessment(vitals: EnrichedVitals) -> dict:
    """Send vitals to local Ollama and get a strict JSON triage response."""
    
    prompt = f"""
    You are an AI Clinical Triage Assistant for a post-operative health monitoring system.
    Analyze the following patient state and provide a rapid assessment in STRICT JSON FORMAT.
    DO NOT output any markdown blocks, conversational text, or explanations. ONLY raw JSON.
    
    Raw Vitals:
    - Heart Rate: {vitals.heart_rate} bpm
    - SpO2: {vitals.spo2}%
    - Temperature: {vitals.temperature}°C
    - Blood Pressure: {vitals.systolic_bp}/{vitals.diastolic_bp} mmHg
    
    Derived Metrics:
    - MAP (Mean Arterial Pressure): {vitals.map_value} mmHg
    - Shock Index: {vitals.shock_index}
    - Pulse Pressure: {vitals.pulse_pressure} mmHg
    - Rate Pressure Product: {vitals.rate_pressure_product}
    
    Overall Health Score: {vitals.health_score}/100
    
    Output Format required:
    {{
      "summary": "<1-sentence clinical summary of the failure>",
      "prediction": "<predicted complication based on vitals>",
      "first_aid": [
        "<immediate, non-medical physical step 1>",
        "<immediate, non-medical physical step 2>",
        "<immediate, non-medical physical step 3>"
      ]
    }}
    """
    
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "format": "json",
        "stream": False,
        "options": {
            "temperature": 0.1 # Low temperature for consistent, strict JSON clinical output
        }
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(OLLAMA_URL, json=payload, timeout=30.0)
            response.raise_for_status()
            
            data = response.json()
            response_text = data.get("response", "{}")
            
            return json.loads(response_text)
            
    except Exception as e:
        print(f"Error calling AI Service: {e}")
        # Return fallback emergency response if AI is unreachable
        return {
            "summary": "AI Assessment failed due to connection error.",
            "prediction": "Unknown - Manual assessment required immediately",
            "first_aid": [
                "Alert medical staff immediately.",
                "Check patient responsiveness.",
                "Prepare crash cart if necessary."
            ]
        }
