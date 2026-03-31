import os
import time
import math
import json
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from groq import Groq

load_dotenv()
# Initialize with a fallback string so local Uvicorn doesn't crash if .env is missing
api_key = os.environ.get("GROQ_API_KEY", "missing_key")
client = Groq(api_key=api_key)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, # Must be False when origin is "*" to prevent strict CORS rejection 
    allow_methods=["*"],
    allow_headers=["*"],
)

class SensorData(BaseModel):
    bpm: float
    temp: float
    pressure: float
    spo2: float

# --- Helper Functions for Derived Metrics ---

def calculate_altitude(pressure_hpa: float) -> float:
    """
    Calculate estimated altitude in meters using the standard barometric formula.
    Assumes standard sea level pressure of 1013.25 hPa.
    Formula: 44330 * (1 - (p / p0)^(1 / 5.255))
    """
    p0 = 1013.25
    if pressure_hpa <= 0:
        return 0.0
    return 44330.0 * (1.0 - math.pow(pressure_hpa / p0, 1.0 / 5.255))

def get_environmental_heat_risk(ambient_temp_c: float) -> str:
    """
    Determine environmental heat risk based on ambient temperature.
    High if > 35.0 C, Moderate if > 30.0 C, otherwise Low.
    """
    if ambient_temp_c > 35.0:
        return "High"
    elif ambient_temp_c > 30.0:
        return "Moderate"
    else:
        return "Low"

def get_cardiac_workload_index(bpm: float, spo2: float) -> float:
    """
    Calculate a simulated cardiac workload index (0-100).
    Base workload increases significantly if BPM > 100 or SpO2 < 95.
    """
    workload = 30.0 # Base index
    if bpm > 100.0:
        workload += (bpm - 100.0) * 0.8
    if spo2 < 95.0:
        workload += (95.0 - spo2) * 2.5
    return min(100.0, max(0.0, workload))

def estimate_body_temp(bpm: float, ambient_temp_c: float) -> float:
    """
    Heuristic estimation of body temperature starting at 37.0 C.
    Increases slightly for elevated BPM and high ambient heat. Max cap at 40.0 C.
    """
    body_temp = 37.0
    if ambient_temp_c > 35.0:
        body_temp += (ambient_temp_c - 35.0) * 0.1
    if bpm > 100.0:
        body_temp += (bpm - 100.0) * 0.02
    return min(40.0, body_temp)

def compute_overall_wellness_score(bpm: float, spo2: float, ambient_temp_c: float) -> float:
    """
    Compute an overall wellness score (0-100) based on deviations from normal.
    Normal: BPM (60-100), SpO2 (95-100%), Ambient limits.
    """
    score = 100.0
    
    # Penalize abnormal BPM
    if bpm < 60.0:
        score -= (60.0 - bpm) * 1.5
    elif bpm > 100.0:
        score -= (bpm - 100.0) * 1.0
        
    # Penalize low SpO2
    if spo2 < 95.0:
        score -= (95.0 - spo2) * 4.0
        
    # Penalize ambient extremes
    if ambient_temp_c > 35.0:
        score -= (ambient_temp_c - 35.0) * 2.5
    elif ambient_temp_c < 18.0:
        score -= (18.0 - ambient_temp_c) * 1.0
        
    return float(round(min(100.0, max(0.0, score)), 2))

# --- AI Action Plan Helper ---

_last_ai_time = 0.0
_cached_wellness_plan = {
    "immediate_actions": ["Waiting for sufficient data to generate wellness plan..."],
    "hydration_and_environment": "Maintain comfortable environment.",
    "monitoring_advice": "Monitor vitals.",
    "disclaimer": "These are general wellness guidelines, not medical advice."
}

def generate_ai_wellness_plan(measured: dict, calculated: dict) -> dict:
    global _last_ai_time, _cached_wellness_plan
    
    current_time = time.time()
    # Throttle AI calls to once every 60 seconds to avoid API quota limits
    if current_time - _last_ai_time < 60.0:
        return _cached_wellness_plan
        
    # Lock the cache timer immediately so failures don't cause spam retries
    _last_ai_time = current_time
    """
    Generates an elaborate AI action plan consisting of general wellness guidelines
    (non-medical). Uses Groq llama3-8b-8192.
    """
    fallback_plan = {
        "immediate_actions": [
            "Rest in a comfortable position.",
            "Please consult a medical professional if you feel unwell."
        ],
        "hydration_and_environment": "Drink water and ensure your environment is at a comfortable temperature.",
        "monitoring_advice": "Monitor vitals continuously for any drastic changes.",
        "disclaimer": "These are general wellness guidelines, not medical advice. Consult a healthcare provider for medical concerns."
    }
    
    try:
        user_prompt = f"""
Generate a structured, non-medical wellness plan based on the following real-time vitals:

Measured Data:
- Heart Rate (BPM): {measured['bpm']}
- Ambient Temperature: {measured['temp']}°C
- Pressure: {measured['pressure']} hPa
- SpO2: {measured['spo2']}%

Derived Data:
- Heat Risk: {calculated['environmental_heat_risk']}
- Cardiac Workload Index (0-100): {calculated['cardiac_workload_index']:.1f}
- Estimated Body Temp: {calculated['simulated_body_temp_c']:.1f}°C
- Overall Wellness Score: {calculated['overall_wellness_score']:.1f}/100

INSTRUCTIONS:
Provide a brief, actionable non-medical first aid/wellness plan for a family member taking care of the individual at home. Explicitly highlight that these are general guidelines, not medical advice. Keep all explanations extremely short and concise (max 1 sentence per point/section). Do not output markdown code blocks. Output ONLY a valid JSON object matching exactly this structure:
{{
  "immediate_actions": [
    "1-2 short bullet points focusing on immediate physical comfort (e.g., 'Move to shade', 'Loosen clothing'). Max 10 words each."
  ],
  "hydration_and_environment": "One short sentence on water intake and airflow/temperature adjustment.",
  "monitoring_advice": "One short sentence on what to watch for over the next 15-30 minutes.",
  "disclaimer": "Short disclaimer stating this is general wellness guidance, not medical advice."
}}
"""
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a brief, direct health assistant. You must output only raw, valid JSON matching the requested structure."
                },
                {
                    "role": "user",
                    "content": user_prompt
                }
            ],
            model="llama-3.1-8b-instant",
            temperature=0.2,
        )

        raw_text = chat_completion.choices[0].message.content.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:]
        if raw_text.startswith("```"):
            raw_text = raw_text[3:]
        if raw_text.endswith("```"):
            raw_text = raw_text[:-3]
            
        parsed_json = json.loads(raw_text.strip())
        _cached_wellness_plan = parsed_json
        return parsed_json
    except Exception as e:
        print(f"AI Generation Error: {e}")
        return fallback_plan

# --- FastAPI Endpoints ---

latest_sensor_state = {
    "status": "Waiting for ESP32 sensor data...",
    "data": None,
    "detailed_wellness_plan": None
}

@app.get("/")
@app.head("/")
def read_root():
    return {"message": "VitalBridge AI Backend is LIVE"}

@app.options("/update")
def options_update():
    return {"message": "OK"}

@app.post("/update")
def update_vitals(data: SensorData):
    global latest_sensor_state
    measured = data.model_dump()
    
    # Process derived metrics
    calculated = {
        "estimated_altitude_meters": round(calculate_altitude(data.pressure), 2),
        "environmental_heat_risk": get_environmental_heat_risk(data.temp),
        "cardiac_workload_index": round(get_cardiac_workload_index(data.bpm, data.spo2), 2),
        "simulated_body_temp_c": round(estimate_body_temp(data.bpm, data.temp), 2),
        "overall_wellness_score": compute_overall_wellness_score(data.bpm, data.spo2, data.temp)
    }
    
    # Generate the AI response plan
    detailed_wellness_plan = generate_ai_wellness_plan(measured, calculated)
    
    # Construct strictly structured output response
    response_payload = {
        "status": "Success",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "data": {
            "measured": measured,
            "calculated": calculated
        },
        "detailed_wellness_plan": detailed_wellness_plan
    }
    
    latest_sensor_state = response_payload
    return response_payload

@app.get("/vitals")
def get_vitals():
    return latest_sensor_state

@app.options("/vitals")
def options_vitals():
    return {"message": "OK"}
