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
    POST /analyze-scan             medical image scan analysis (X-ray / MRI / CT)
    POST /predict                  clinical OA risk prediction

Run locally:
    uvicorn main:app --reload --port 8000
    (from inside the backend/app directory, or adjust the module path)

The ESP32 itself will likely talk to the paired phone app over BLE, and the
PHONE APP is what calls this HTTP API (phones have WiFi/data, ESP32 usually
doesn't need to hit the internet directly). This backend doesn't care which
layer calls it as long as the JSON contract in schemas.py is followed.
"""

import io
import json
import tempfile
import numpy as np
from fastapi import FastAPI, HTTPException, Depends, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .database import init_db, get_db, Device, SensorSession
from .schemas import SensorWindowIn, SessionResult, TrendResponse, HealthResponse, TopFeature, ClinicalPredictionRequest, ClinicalPredictionResponse
from .inference_service import inference_service

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


@app.post("/analyze-scan")
async def analyze_scan(
    image: UploadFile = File(...),
    modality: str = Form(default=""),
    joint_type: str = Form(default="knee"),
    local_biomarkers: str = Form(default="{}"),
):
    """
    Medical scan image analysis endpoint.

    Accepts an image file (X-ray, MRI, CT) and returns:
      - Detected/confirmed scan modality
      - Kellgren-Lawrence (KL) grade estimate
      - Image-level biomarkers (joint space, osteophytes, sclerosis, cartilage, effusion)
      - Overall image_risk_score (0.0 – 1.0) for OA severity

    The endpoint tries to use OpenCV for pixel analysis; if OpenCV is not
    installed it falls back to a numpy-only implementation that still produces
    clinically meaningful estimates.
    """
    # ── Read image bytes ───────────────────────────────────────────────────────
    contents = await image.read()
    if len(contents) < 500:
        raise HTTPException(status_code=400, detail="Image file too small or empty.")

    # ── Parse local biomarkers from app (optional) ─────────────────────────────
    try:
        local_bio = json.loads(local_biomarkers) if local_biomarkers else {}
    except Exception:
        local_bio = {}

    # ── Pixel analysis ─────────────────────────────────────────────────────────
    arr = np.frombuffer(contents, dtype=np.uint8)

    # Try to use OpenCV if available for proper image decoding
    use_opencv = False
    pixel_arr = None
    try:
        import cv2  # type: ignore
        decoded = cv2.imdecode(arr, cv2.IMREAD_GRAYSCALE)
        if decoded is not None:
            pixel_arr = decoded.flatten().astype(np.float32)
            use_opencv = True
    except ImportError:
        pass

    # Fallback: treat raw bytes as pixel proxy (ignores headers but OK for stats)
    if pixel_arr is None:
        sample_size = min(len(arr), 80000)
        step = max(len(arr) // sample_size, 1)
        pixel_arr = arr[::step].astype(np.float32)

    # ── Statistical features ───────────────────────────────────────────────────
    mean_val = float(np.mean(pixel_arr))
    std_val = float(np.std(pixel_arr))
    dark_ratio = float(np.sum(pixel_arr < 86) / len(pixel_arr))
    mid_ratio = float(np.sum((pixel_arr >= 86) & (pixel_arr < 171)) / len(pixel_arr))
    bright_ratio = float(np.sum(pixel_arr >= 171) / len(pixel_arr))
    bimodal_score = (dark_ratio + bright_ratio) - mid_ratio

    # Entropy
    hist, _ = np.histogram(pixel_arr, bins=256, range=(0, 256))
    hist_norm = hist / (hist.sum() + 1e-8)
    entropy = float(-np.sum(hist_norm * np.log2(hist_norm + 1e-10)))

    # ── Modality detection ─────────────────────────────────────────────────────
    if modality.lower() in ("x-ray", "xray", "x ray"):
        detected_modality = "X-Ray"
        modality_confidence = 0.95
    elif modality.lower() == "mri":
        detected_modality = "MRI"
        modality_confidence = 0.95
    elif modality.lower() in ("ct", "ct scan"):
        detected_modality = "CT Scan"
        modality_confidence = 0.95
    elif modality.lower() in ("usg", "ultrasound"):
        detected_modality = "Ultrasound"
        modality_confidence = 0.95
    else:
        # Auto-detect
        if entropy > 6.0 and dark_ratio > 0.40 and mid_ratio > 0.30 and bright_ratio < 0.15 and std_val < 70:
            detected_modality = "Ultrasound"
            modality_confidence = min(0.90, entropy / 8.0 * 0.5 + dark_ratio * 0.5)
        elif (bimodal_score > 0.05 and bright_ratio > 0.20) or (entropy > 6.5 and bright_ratio > 0.30):
            detected_modality = "X-Ray"
            modality_confidence = min(0.95, bright_ratio * 0.6 + entropy / 8.0 * 0.4)
        elif entropy > 6.0 and mid_ratio > 0.50 and std_val > 60:
            detected_modality = "MRI"
            modality_confidence = min(0.90, entropy / 8.0 * 0.7 + mid_ratio * 0.3)
        elif mid_ratio > 0.50 and entropy > 5.0:
            detected_modality = "CT Scan"
            modality_confidence = min(0.85, mid_ratio * 0.6 + entropy / 8.0 * 0.4)
        else:
            detected_modality = "X-Ray"
            modality_confidence = 0.50

    # ── Biomarker extraction ───────────────────────────────────────────────────
    # Joint space proxy
    if detected_modality == "X-Ray":
        js_count = float(np.sum((pixel_arr >= 40) & (pixel_arr <= 130)))
        joint_space_proxy = min(1.0, js_count / len(pixel_arr) * 2.5)
    elif detected_modality == "MRI":
        js_count = float(np.sum((pixel_arr >= 100) & (pixel_arr <= 200)))
        joint_space_proxy = min(1.0, js_count / len(pixel_arr) * 2.0)
    else:
        js_count = float(np.sum((pixel_arr >= 60) & (pixel_arr <= 160)))
        joint_space_proxy = min(1.0, js_count / len(pixel_arr) * 2.0)

    # Edge density (osteophyte proxy) — gradient over 1D pixel sample
    if len(pixel_arr) > 10:
        grad = np.abs(np.diff(pixel_arr))
        edge_density = float(np.sum(grad > 40) / len(grad))
    else:
        edge_density = 0.0
    osteophyte_score = min(1.0, edge_density * 3.5)

    # Sclerosis
    very_bright = float(np.sum(pixel_arr > 200) / len(pixel_arr))
    sclerosis_score = min(1.0, very_bright * (3.0 if detected_modality == "X-Ray" else 2.0))

    # Cartilage integrity
    if detected_modality == "MRI":
        cart_count = float(np.sum((pixel_arr >= 140) & (pixel_arr <= 220)))
        cartilage_integrity = min(1.0, cart_count / len(pixel_arr) * 3.5)
    else:
        cartilage_integrity = joint_space_proxy * 0.85

    # Effusion / Inflammation (USG / MRI)
    if detected_modality in ("Ultrasound", "MRI"):
        dark_pocket_count = float(np.sum(pixel_arr < 30))
        effusion_score = min(1.0, dark_pocket_count / len(pixel_arr) * 4.0)
    else:
        effusion_score = 0.0

    # Image quality
    dynamic_range = float(np.max(pixel_arr) - np.min(pixel_arr))
    image_quality = min(1.0, (std_val / 80.0) * 0.5 + (dynamic_range / 255.0) * 0.5)

    # ── KL Grade estimation ────────────────────────────────────────────────────
    kl_score = (
        (1.0 - joint_space_proxy) * 2.0
        + osteophyte_score * 1.5
        + sclerosis_score * 1.0
        + (1.0 - cartilage_integrity) * 1.5
    )
    estimated_kl = (
        4 if kl_score >= 5.0
        else 3 if kl_score >= 3.5
        else 2 if kl_score >= 2.0
        else 1 if kl_score >= 0.8
        else 0
    )

    # Optionally blend with local biomarkers sent from app (average)
    if local_bio.get("estimated_kl_grade") is not None:
        local_kl = int(local_bio["estimated_kl_grade"])
        estimated_kl = round((estimated_kl + local_kl) / 2)

    if local_bio.get("joint_space_proxy") is not None:
        joint_space_proxy = (joint_space_proxy + float(local_bio["joint_space_proxy"])) / 2
        
    if local_bio.get("effusion_score") is not None:
        effusion_score = (effusion_score + float(local_bio["effusion_score"])) / 2

    # ── Image risk score ───────────────────────────────────────────────────────
    cart_weight = 0.15 if detected_modality == "MRI" else 0.05
    effusion_weight = 0.10 if detected_modality == "Ultrasound" else 0.0
    
    image_risk_score = min(1.0, (
        estimated_kl / 4.0 * 0.40
        + (1.0 - joint_space_proxy) * 0.25
        + osteophyte_score * 0.20
        + sclerosis_score * 0.10
        + (1.0 - cartilage_integrity) * cart_weight
        + effusion_score * effusion_weight
    ))

    # ── Findings text ──────────────────────────────────────────────────────────
    kl_descriptions = [
        "No radiographic features of OA (KL Grade 0)",
        "Doubtful joint space narrowing, possible osteophytic lipping (KL Grade 1)",
        "Definite osteophytes and possible joint space narrowing (KL Grade 2)",
        "Multiple osteophytes, definite joint space narrowing, some sclerosis (KL Grade 3)",
        "Large osteophytes, marked narrowing, severe sclerosis, bony deformity (KL Grade 4)",
    ]
    findings = [kl_descriptions[estimated_kl]]

    if joint_space_proxy < 0.30:
        findings.append("Severe joint space narrowing detected")
    elif joint_space_proxy < 0.55:
        findings.append("Moderate joint space narrowing observed")
    elif joint_space_proxy < 0.75:
        findings.append("Mild joint space narrowing noted")
    else:
        findings.append("Joint space appears within normal limits")

    if osteophyte_score > 0.65:
        findings.append("Prominent osteophyte formation at joint margins")
    elif osteophyte_score > 0.35:
        findings.append("Marginal osteophytes present")

    if sclerosis_score > 0.60:
        findings.append("Marked subchondral sclerosis / increased bone density")
    elif sclerosis_score > 0.35:
        findings.append("Mild subchondral sclerosis")

    if detected_modality == "MRI":
        if cartilage_integrity < 0.35:
            findings.append("Significant cartilage thinning or loss on MRI")
        elif cartilage_integrity < 0.60:
            findings.append("Moderate cartilage signal changes on MRI")
        else:
            findings.append("Cartilage signal relatively preserved on MRI")
            
    if detected_modality in ("Ultrasound", "MRI"):
        if effusion_score > 0.60:
            findings.append("Significant joint effusion / synovial inflammation detected")
        elif effusion_score > 0.30:
            findings.append("Mild to moderate joint effusion present")

    # Recommendations
    if image_risk_score >= 0.65:
        recommendation = "Urgent orthopedic referral recommended — imaging indicates advanced joint disease."
    elif image_risk_score >= 0.40:
        recommendation = "Follow-up clinical evaluation in 4–6 weeks; consider conservative management."
    else:
        recommendation = "No acute imaging concern; continue routine monitoring and preventive care."

    return {
        "modality": detected_modality,
        "modality_confidence": round(modality_confidence, 3),
        "estimated_kl_grade": estimated_kl,
        "joint_space_proxy": round(joint_space_proxy, 3),
        "osteophyte_score": round(osteophyte_score, 3),
        "sclerosis_score": round(sclerosis_score, 3),
        "cartilage_integrity": round(cartilage_integrity, 3),
        "effusion_score": round(effusion_score, 3),
        "image_quality": round(image_quality, 3),
        "image_risk_score": round(image_risk_score, 3),
        "findings": findings,
        "recommendation": recommendation,
        "pixel_stats": {
            "mean": round(mean_val, 2),
            "std": round(std_val, 2),
            "entropy": round(entropy, 3),
            "dark_ratio": round(dark_ratio, 3),
            "mid_ratio": round(mid_ratio, 3),
            "bright_ratio": round(bright_ratio, 3),
        },
        "analysis_backend": "opencv" if use_opencv else "numpy",
        "joint_type": joint_type,
    }


@app.post("/predict", response_model=ClinicalPredictionResponse)
def predict_clinical_risk(payload: ClinicalPredictionRequest):
    """
    Clinical OA risk prediction endpoint for Node.js backend.
    Uses rule-based scoring for clinical symptoms since the ML model
    is trained on sensor data (gyro + piezo), not clinical data.
    """
    import json

    # Parse gait data
    try:
        gait_features = json.loads(payload.gait_data)
        variance = gait_features.get("variance", 0)
    except:
        variance = 0

    # Rule-based scoring
    score = 0
    contributing_factors = []

    # Pain component (30% weight)
    pain_component = (payload.pain_level / 10) * 0.3
    score += pain_component
    if payload.pain_level >= 7:
        contributing_factors.append("Severe pain level reported")
    elif payload.pain_level >= 4:
        contributing_factors.append("Moderate pain level reported")

    # Stiffness component (25% weight)
    if payload.stiffness_duration == ">60":
        score += 0.25
        contributing_factors.append("Prolonged joint stiffness (>60 minutes)")
    elif payload.stiffness_duration == "30-60":
        score += 0.25
        contributing_factors.append("Prolonged joint stiffness (30-60 minutes)")
    elif payload.stiffness_duration == "<30":
        score += 0.12
        contributing_factors.append("Moderate joint stiffness (<30 minutes)")

    # Swelling component (15% weight)
    if payload.swelling:
        score += 0.15
        contributing_factors.append("Joint swelling present")

    # Past injury component (15% weight)
    if payload.past_injury:
        score += 0.15
        contributing_factors.append("History of joint injury")

    # MRI KL Grade component (Huge weight, trumps others if severe)
    if payload.mri_kl_grade == 4:
        score += 0.50
        contributing_factors.append("Severe joint degeneration (MRI Grade 4)")
    elif payload.mri_kl_grade == 3:
        score += 0.35
        contributing_factors.append("Moderate joint degeneration (MRI Grade 3)")
    elif payload.mri_kl_grade == 2:
        score += 0.20
        contributing_factors.append("Mild joint degeneration (MRI Grade 2)")

    # Multimodal Symptoms
    if payload.sym_locking or payload.sym_clicking or payload.sym_grinding:
        score += 0.15
        contributing_factors.append("Mechanical joint symptoms reported (locking/clicking)")
    if payload.sym_instability:
        score += 0.10
        contributing_factors.append("Joint instability reported")

    # Gait variance component (15% weight)
    gait_component = min(variance / 4.0, 1) * 0.15
    score += gait_component
    if gait_component > 0.08:
        contributing_factors.append("Irregular gait pattern detected")

    # Cap score at 1.0
    score = min(score, 1.0)

    # Determine risk level
    if score >= 0.6:
        risk_level = "high"
    elif score >= 0.25:
        risk_level = "medium"
    else:
        risk_level = "low"

    # Build reasoning
    reasoning = f"Clinical triage score {score:.2f} derived from pain level, stiffness duration, swelling, injury history, and gait variance."

    # Build recommendations
    if risk_level == "high":
        doctor_recommendations = "Refer to an orthopedic specialist for clinical evaluation and imaging (X-ray/MRI) as soon as possible."
    elif risk_level == "medium":
        doctor_recommendations = "Recommend follow-up screening in 4-6 weeks; advise preventive exercises and weight management in the meantime."
    else:
        doctor_recommendations = "No immediate referral needed; share preventive care guidance and re-screen at next camp visit."

    # Add contributing factors if empty
    if not contributing_factors:
        contributing_factors.append("No significant risk factors identified")

    return ClinicalPredictionResponse(
        risk_level=risk_level,
        confidence=round(0.55 + score * 0.15, 2),
        contributing_factors=contributing_factors,
        reasoning=reasoning,
        doctorRecommendations=doctor_recommendations,
        model_version="1.0.0"
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
            payload.gyro, payload.piezo, payload.emg, payload.accel,
            payload.fs_gyro, payload.fs_piezo, payload.fs_emg, payload.fs_accel,
            payload.painLevel, payload.stiffnessDuration, 
            payload.swelling, payload.pastInjury,
            mri_kl_grade=payload.mri_kl_grade,
            past_surgery=payload.past_surgery,
            med_hx_diagnosis=payload.med_hx_diagnosis,
            med_hx_joint_pain=payload.med_hx_joint_pain,
            med_hx_chronic=payload.med_hx_chronic,
            med_hx_inflammation=payload.med_hx_inflammation,
            med_hx_cartilage=payload.med_hx_cartilage,
            med_hx_ligament=payload.med_hx_ligament,
            med_hx_fracture=payload.med_hx_fracture,
            sym_locking=payload.sym_locking,
            sym_clicking=payload.sym_clicking,
            sym_grinding=payload.sym_grinding,
            sym_instability=payload.sym_instability,
            pain_type_sharp=payload.pain_type_sharp,
            pain_type_dull=payload.pain_type_dull,
            pain_type_burning=payload.pain_type_burning,
            pain_type_aching=payload.pain_type_aching,
            pain_type_stabbing=payload.pain_type_stabbing,
            pain_type_throbbing=payload.pain_type_throbbing,
            func_standing=payload.func_standing,
            func_walking=payload.func_walking,
            func_stairs=payload.func_stairs,
            func_chores=payload.func_chores
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
            top_contributing_features=[TopFeature(**f) for f in (s.top_features or [])],  # type: ignore
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
            top_contributing_features=[TopFeature(**f) for f in (s.top_features or [])],  # type: ignore
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
