from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from contextlib import asynccontextmanager
import json

from database import engine, Base, get_db
from models import PatientState, RawVitals, EnrichedVitals
from clinical_engine import calculate_derived_metrics, calculate_health_score, evaluate_anomaly
from ai_service import generate_triage_assessment

# DB Initialization on startup
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Setup SQLite tables
    Base.metadata.create_all(bind=engine)
    yield
    # Keep teardown empty for now

app = FastAPI(title="Watcher.AI Backend", lifespan=lifespan)

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

# Background task for AI Triage Assessment
async def process_anomaly(vitals: EnrichedVitals):
    assessment = await generate_triage_assessment(vitals)
    
    payload = {
        "event": "ANOMALY_DETECTED",
        "vitals_id": vitals.id,
        "ai_assessment": assessment
    }
    
    # Broadcast assessment to all connected clients immediately
    await manager.broadcast(json.dumps(payload))

# WebSocket Route
@app.websocket("/api/alerts")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Maintain connection, server mostly acts as broadcaster
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Ingestion Endpoint
@app.post("/api/vitals", response_model=EnrichedVitals)
async def ingest_vitals(vitals_in: RawVitals, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    # 1. Run the Math Engine
    derived = calculate_derived_metrics(vitals_in)
    health_score = calculate_health_score(vitals_in, derived)
    is_anomaly = evaluate_anomaly(vitals_in, derived, health_score)
    
    # 2. Save enriched state to SQLite
    new_state = PatientState(
        heart_rate=vitals_in.heart_rate,
        spo2=vitals_in.spo2,
        temperature=vitals_in.temperature,
        systolic_bp=vitals_in.systolic_bp,
        diastolic_bp=vitals_in.diastolic_bp,
        map_value=derived["map_value"],
        shock_index=derived["shock_index"],
        pulse_pressure=derived["pulse_pressure"],
        rate_pressure_product=derived["rate_pressure_product"],
        health_score=health_score,
        is_anomaly=is_anomaly
    )
    
    db.add(new_state)
    db.commit()
    db.refresh(new_state)
    
    # Instantiate Pydantic model explicitly to decouple from SQLAlchemy session for async background processing
    enriched_vitals = EnrichedVitals(
        id=new_state.id,
        timestamp=new_state.timestamp,
        heart_rate=new_state.heart_rate,
        spo2=new_state.spo2,
        temperature=new_state.temperature,
        systolic_bp=new_state.systolic_bp,
        diastolic_bp=new_state.diastolic_bp,
        map_value=new_state.map_value,
        shock_index=new_state.shock_index,
        pulse_pressure=new_state.pulse_pressure,
        rate_pressure_product=new_state.rate_pressure_product,
        health_score=new_state.health_score,
        is_anomaly=new_state.is_anomaly
    )
    
    # 3. AI Trigger if an anomaly is detected or health drops low
    if is_anomaly or health_score < 75.0:
        background_tasks.add_task(process_anomaly, enriched_vitals)

    return enriched_vitals

# History Endpoint
@app.get("/api/vitals/history", response_model=List[EnrichedVitals])
def get_vitals_history(db: Session = Depends(get_db)):
    # Return last 100 records for mobile app trend graphs, sorted chronologically.
    # We fetch descending by timestamp to get the most recent, then reverse the list.
    records = db.query(PatientState).order_by(PatientState.timestamp.desc()).limit(100).all()
    records.reverse()
    return records
