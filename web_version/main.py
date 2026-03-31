import os
import time
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Allow wildcard origins but credentials must be explicitly false for strict CORS specs
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, 
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize with fallback string to prevent local boot crashes
client = Groq(api_key=os.environ.get("GROQ_API_KEY", "missing_api_key"))

last_llm_update_time = 0.0
latest_ai_suggestion = "Gathering initial vitals. AI analysis will begin shortly..."
current_vitals = {"bpm": 0, "spo2": 0, "temp": 0.0, "pressure": 0}

class SensorData(BaseModel):
    bpm: float
    spo2: float
    temp: float
    pressure: float

@app.post("/update")
def update_vitals(data: SensorData):
    global current_vitals, last_llm_update_time, latest_ai_suggestion
    
    # --- Data Sanitization / Clamping ---
    if data.bpm == 0:
        data.pressure = 0
        data.spo2 = 0
        data.temp = 0.0
    else:
        data.bpm = max(55.0, min(data.bpm, 105.0))
        data.spo2 = max(93.0, min(data.spo2, 100.0))
        
    current_vitals = data.model_dump()
    current_time = time.time()
    
    # Decoupled Ingestion: Only hit Groq every 60 seconds
    if current_time - last_llm_update_time >= 60.0:
        try:
            prompt = f"Vitals: {current_vitals}. Give a very brief health assessment."
            chat_completion = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": "You are a brief, direct health assistant."},
                    {"role": "user", "content": prompt}
                ],
                model="llama-3.1-8b-instant",  # Updated from decommissioned 8192 model
                temperature=0.2,
            )
            latest_ai_suggestion = chat_completion.choices[0].message.content.strip()
            last_llm_update_time = current_time
        except Exception as e:
            print(f"AI Generation Error: {e}")
            
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
