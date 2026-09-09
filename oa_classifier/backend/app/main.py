"""
main.py
--------
FastAPI backend for the OA risk wearable app.

Endpoints:
    POST /devices/register        register a new device/user
    POST /sessions                 submit one sensor window -> get risk score back
    GET  /sessions/{device_id}     full session history for a device
    GET  /trend/{device_id}        rolling average + trend direction
    GET  /health                   service health check

Run locally:
    uvicorn main:app --reload --port 8000
    (from inside the backend/app directory, or adjust the module path)

The ESP32 itself will likely talk to the paired phone app over BLE, and the
PHONE APP is what calls this HTTP API (phones have WiFi/data, ESP32 usually
doesn't need to hit the internet directly). This backend doesn't care which
layer calls it as long as the JSON contract in schemas.py is followed.
"""

import numpy as np
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import init_db, get_db, Device, SensorSession
from schemas import SensorWindowIn, SessionResult, TrendResponse, HealthResponse, TopFeature
from inference_service import inference_service

app = FastAPI(
    title="OA Risk Wearable API",
    description="Receives gait+acoustic sensor windows, returns osteoarthritis risk scores and trends.",
    version="0.1.0",
)

# Wide-open CORS for hackathon demo purposes — tighten this before any real deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    init_db()


def get_or_create_device(db: Session, device_id: str) -> Device:
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if device is None:
        device = Device(device_id=device_id)
        db.add(device)
        db.commit()
        db.refresh(device)
    return device


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(
        status="ok",
        model_loaded=inference_service.model is not None,
        model_trained_on=inference_service.trained_on_note,
    )


@app.post("/sessions", response_model=SessionResult)
def submit_session(payload: SensorWindowIn, db: Session = Depends(get_db)):
    """
    Main ingestion endpoint. The app/ESP32 sends one recording window here;
    we extract features, run the model, store the result, and return the
    risk score immediately so the app can show it right away.
    """
    device = get_or_create_device(db, payload.device_id)

    try:
        proba, label, feats, top_features = inference_service.score_window(
            payload.gyro, payload.piezo, payload.fs_gyro, payload.fs_piezo
        )
    except Exception as e:
        # Common causes: window too short for reliable feature extraction,
        # malformed/garbage sensor data from a flaky BLE transfer, etc.
        raise HTTPException(status_code=422, detail=f"Could not score sensor window: {e}")

    # numpy float32 isn't JSON-serializable directly -> cast everything to plain floats
    clean_feats = {k: float(v) for k, v in feats.items()}

    session = SensorSession(
        device_fk=device.id,
        risk_score=proba,
        risk_label=label,
        model_used=inference_service.model_name,
        features=clean_feats,
        top_features=top_features,
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    return SessionResult(
        session_id=session.id,
        device_id=device.device_id,
        recorded_at=session.recorded_at,
        risk_score=session.risk_score,
        risk_label=session.risk_label,
        model_used=session.model_used,
        top_contributing_features=[TopFeature(**f) for f in (top_features or [])],
    )


@app.get("/sessions/{device_id}", response_model=list[SessionResult])
def get_sessions(device_id: str, limit: int = 50, db: Session = Depends(get_db)):
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if device is None:
        raise HTTPException(status_code=404, detail="Unknown device_id")

    sessions = (
        db.query(SensorSession)
        .filter(SensorSession.device_fk == device.id)
        .order_by(SensorSession.recorded_at.desc())
        .limit(limit)
        .all()
    )

    return [
        SessionResult(
            session_id=s.id,
            device_id=device.device_id,
            recorded_at=s.recorded_at,
            risk_score=s.risk_score,
            risk_label=s.risk_label,
            model_used=s.model_used,
            top_contributing_features=[TopFeature(**f) for f in (s.top_features or [])],
        )
        for s in sessions
    ]


@app.get("/trend/{device_id}", response_model=TrendResponse)
def get_trend(device_id: str, window: int = 5, db: Session = Depends(get_db)):
    """
    Rolling average + trend direction over the most recent sessions.
    This is the key clinical framing: a single reading is noisy, but a
    persistent upward trend in risk_score over days/weeks is the actual signal.
    """
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if device is None:
        raise HTTPException(status_code=404, detail="Unknown device_id")

    sessions = (
        db.query(SensorSession)
        .filter(SensorSession.device_fk == device.id)
        .order_by(SensorSession.recorded_at.asc())
        .all()
    )

    if not sessions:
        return TrendResponse(
            device_id=device_id, n_sessions=0, rolling_average=None,
            trend_direction="no_data", history=[]
        )

    scores = [s.risk_score for s in sessions]
    recent = scores[-window:]
    rolling_avg = float(np.mean(recent))

    if len(recent) >= 3:
        x = np.arange(len(recent))
        slope = np.polyfit(x, recent, 1)[0]
        direction = "worsening" if slope > 0.01 else ("improving" if slope < -0.01 else "stable")
    else:
        direction = "insufficient_data"

    history = [
        SessionResult(
            session_id=s.id,
            device_id=device_id,
            recorded_at=s.recorded_at,
            risk_score=s.risk_score,
            risk_label=s.risk_label,
            model_used=s.model_used,
            top_contributing_features=[TopFeature(**f) for f in (s.top_features or [])],
        )
        for s in sessions
    ]

    return TrendResponse(
        device_id=device_id,
        n_sessions=len(sessions),
        rolling_average=rolling_avg,
        trend_direction=direction,
        history=history,
    )
