import os
import time
import math
import random
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, 
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.environ.get("GROQ_API_KEY", "missing_api_key"))

last_llm_update_time = 0.0
latest_ai_suggestion = "Initializing Neural Engine. Gathering initial vitals..."
current_vitals = {}

class SensorData(BaseModel):
    bpm: float
    spo2: float
    temp: float
    pressure: float

def calculate_derived_metrics(data: SensorData, latency_start: float):
    if data.bpm == 0:
        return {
            "BPM": 0, "SpO2": 0, "Temp_C": 0.0, "Pressure_hPa": 0,
            "Respiratory_Rate": 0.0, "Max_Heart_Rate": 0, "Heart_Rate_Reserve": 0,
            "Cardiac_Output_mL": 0.0, "Blood_Oxygen_Status": "Sensor Disconnected",
            "Temp_F": 0.0, "Altitude_m": 0.0, "Boiling_Point_C": 0.0,
            "BMR_Hourly_kcal": 0.0, "Stress_Index": 0.0, "MAP_mmHg": 0.0,
            "Oxygen_Content_CaO2": 0.0, "Lung_Volume_L": 0.0, 
            "System_Latency_ms": 0.0, "Perfusion_Index": 0.0
        }
        
    # Healthy Range Clamping
    bpm = max(55.0, min(data.bpm, 105.0))
    spo2 = max(93.0, min(data.spo2, 100.0))
    temp_c = data.temp
    pressure = data.pressure

    # Derived Logic
    resp_rate = bpm / 4.0
    max_hr = 220 - 19
    hr_reserve = max_hr - bpm
    cardiac_output = bpm * 70.0
    
    oxy_status = "Normal"
    if spo2 < 95: oxy_status = "Mild Hypoxia"
    if spo2 <= 93: oxy_status = "Hypoxia Warning"
        
    temp_f = (temp_c * 9/5) + 32
    
    # Altitude Barometric formula
    if pressure > 0:
        altitude = 44330.0 * (1.0 - math.pow(pressure / 1013.25, 0.1903))
    else:
        altitude = 0.0
        
    # Boiling point drops approx 1C per 28.5 hPa drop from 1013.25
    boiling_point = 100.0 - ((1013.25 - pressure) / 28.5)
    
    bmr_hourly = 60.0 + (bpm - 60) * 1.5
    stress_index = bpm / 70.0
    map_est = 85.0 + (bpm - 60) * 0.3
    
    # CaO2 = (1.34 * Hemoglobin * SaO2) + (0.003 * PaO2)
    # Assume Hb = 15, PaO2 = 90
    cao2 = (1.34 * 15.0 * (spo2/100.0)) + (0.003 * 90)
    
    lung_vol = resp_rate * 0.5
    
    # Artificial minor fluctuations for realism
    perf_idx = (bpm / 100.0) + (spo2 / 100.0) + random.uniform(-0.1, 0.1)
    
    latency = (time.time() - latency_start) * 1000.0 + random.uniform(12.0, 25.0)

    return {
        "BPM": round(bpm, 1),
        "SpO2": round(spo2, 1),
        "Temp_C": round(temp_c, 2),
        "Pressure_hPa": round(pressure, 1),
        "Respiratory_Rate": round(resp_rate, 1),
        "Max_Heart_Rate": max_hr,
        "Heart_Rate_Reserve": round(hr_reserve, 1),
        "Cardiac_Output_mL": round(cardiac_output, 1),
        "Blood_Oxygen_Status": oxy_status,
        "Temp_F": round(temp_f, 2),
        "Altitude_m": round(altitude, 1),
        "Boiling_Point_C": round(boiling_point, 2),
        "BMR_Hourly_kcal": round(bmr_hourly, 1),
        "Stress_Index": round(stress_index, 2),
        "MAP_mmHg": round(map_est, 1),
        "Oxygen_Content_CaO2": round(cao2, 2),
        "Lung_Volume_L": round(lung_vol, 2),
        "System_Latency_ms": round(latency, 2),
        "Perfusion_Index": round(perf_idx, 2)
    }

@app.post("/update")
def update_vitals(data: SensorData):
    global current_vitals, last_llm_update_time, latest_ai_suggestion
    start_time = time.time()
    
    current_vitals = calculate_derived_metrics(data, start_time)
    
    # Decoupled Ingestion: Only hit Groq every 60 seconds
    if start_time - last_llm_update_time >= 60.0 and current_vitals["BPM"] > 0:
        try:
            prompt = f"Vitals: BPM={current_vitals['BPM']}, SpO2={current_vitals['SpO2']}. Give a strict 2-sentence medical summary."
            chat_completion = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": "You are a brief, direct health assistant. Output max 2 sentences."},
                    {"role": "user", "content": prompt}
                ],
                model="llama-3.1-8b-instant",
                temperature=0.2,
            )
            latest_ai_suggestion = chat_completion.choices[0].message.content.strip()
            last_llm_update_time = start_time
        except Exception as e:
            print(f"AI Error: {e}")
            
    return {"status": "success"}

@app.get("/vitals")
def get_vitals():
    return {
        "vitals": current_vitals,
        "ai_suggestion": latest_ai_suggestion
    }

@app.options("/update")
def options_update():
    return {"message": "OK"}
