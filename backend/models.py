from sqlalchemy import Column, Integer, Float, Boolean, DateTime
from sqlalchemy.sql import func
from pydantic import BaseModel
from database import Base
import datetime

# SQLAlchemy Model
class PatientState(Base):
    __tablename__ = "patient_states"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    # Raw Vitals
    heart_rate = Column(Float)
    spo2 = Column(Float)
    temperature = Column(Float)
    systolic_bp = Column(Float)
    diastolic_bp = Column(Float)
    
    # Derived Metrics
    map_value = Column(Float)
    shock_index = Column(Float)
    pulse_pressure = Column(Float)
    rate_pressure_product = Column(Float)
    
    # Health and Anomaly Status
    health_score = Column(Float)
    is_anomaly = Column(Boolean, default=False)

# Pydantic Models for Input validation
class RawVitals(BaseModel):
    heart_rate: float
    spo2: float
    temperature: float
    systolic_bp: float
    diastolic_bp: float

# Pydantic Model for Output mapping
class EnrichedVitals(BaseModel):
    id: int
    timestamp: datetime.datetime
    heart_rate: float
    spo2: float
    temperature: float
    systolic_bp: float
    diastolic_bp: float
    map_value: float
    shock_index: float
    pulse_pressure: float
    rate_pressure_product: float
    health_score: float
    is_anomaly: bool

    class Config:
        from_attributes = True
        orm_mode = True # For pydantic v1 compatibility
