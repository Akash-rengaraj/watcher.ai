from models import RawVitals

def calculate_derived_metrics(vitals: RawVitals) -> dict:
    """Calculate MAP, Shock Index, PP, and RPP from raw vitals."""
    map_value = vitals.diastolic_bp + ((vitals.systolic_bp - vitals.diastolic_bp) / 3.0)
    shock_index = vitals.heart_rate / vitals.systolic_bp if vitals.systolic_bp > 0 else 0.0
    pulse_pressure = vitals.systolic_bp - vitals.diastolic_bp
    rate_pressure_product = vitals.heart_rate * vitals.systolic_bp
    
    return {
        "map_value": round(map_value, 2),
        "shock_index": round(shock_index, 2),
        "pulse_pressure": round(pulse_pressure, 2),
        "rate_pressure_product": round(rate_pressure_product, 2)
    }

def calculate_health_score(vitals: RawVitals, derived: dict) -> float:
    """Calculate overall health score based on clinical danger zones."""
    score = 100.0
    
    # SpO2 deductions
    if vitals.spo2 < 90:
        score -= 30
    elif vitals.spo2 < 94:
        score -= 15
    elif vitals.spo2 < 98:
        score -= 5
        
    # Heart Rate deductions
    if vitals.heart_rate > 130:
        score -= 20
    elif vitals.heart_rate > 110:
        score -= 10
    elif vitals.heart_rate < 50:
        score -= 15
        
    # MAP deductions
    map_val = derived["map_value"]
    if map_val < 65:
        score -= 20
    elif map_val > 120:
        score -= 15
        
    # Temperature deductions
    if vitals.temperature > 39.0:
        score -= 15
    elif vitals.temperature > 38.0:
        score -= 5
    elif vitals.temperature < 35.0:
        score -= 15
        
    return max(0.0, score)

def evaluate_anomaly(vitals: RawVitals, derived: dict, health_score: float) -> bool:
    """Detect critical anomalies using correlative thresholding."""
    # Example 1: High temp AND low BP (possible sepsis/shock)
    if vitals.temperature > 38.0 and derived["map_value"] < 65:
        return True
    
    # Example 2: Low SpO2 AND High HR (possible respiratory failure / PE)
    if vitals.spo2 < 92 and vitals.heart_rate > 120:
        return True
        
    # Example 3: Very high shock index
    if derived["shock_index"] >= 1.0:
        return True
        
    # Example 4: Generalized low health score
    if health_score < 75:
        return True
        
    return False
