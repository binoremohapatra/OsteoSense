"""
schemas.py
-----------
Defines the exact JSON shape the ESP32 (via the phone app) sends to the
backend, and what the backend sends back. Share this file's shape with
whoever writes the ESP32/app-side sending code so both sides agree on the
contract without guessing.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class SensorWindowIn(BaseModel):
    """
    One recording window from the device. Hardware is TWO sensors only:
    gyroscope (motion tracking) + piezo disc (joint sound/vibration).
    No accelerometer, no separate mic/EMG in this version.

    gyro: flat list of length N*3, ordered [x0,y0,z0, x1,y1,z1, ...]
          (flat lists are simplest to serialize from ESP32 firmware —
          no nested JSON arrays needed on the embedded side)
    piezo: flat list of length M (raw ADC waveform from the piezo disc,
           already centered/scaled to roughly [-1, 1] float range on the
           ESP32 or in the app before sending)
    fs_gyro / fs_piezo: sample rates actually used for this capture (allows
         the firmware team to change sampling rates later without breaking the API)
    """
    device_id: str = Field(..., description="Unique id for the wearable/user, e.g. ESP32 MAC or paired user id")
    gyro: list[float] = Field(..., description="Flat list, length N*3: x,y,z,x,y,z,...")
    piezo: list[float] = Field(..., description="Flat list, length M: raw piezo disc waveform")
    fs_gyro: int = Field(default=100, description="Gyro sample rate in Hz")
    fs_piezo: int = Field(default=4000, description="Piezo disc sample rate in Hz")

    @field_validator("gyro")
    @classmethod
    def check_divisible_by_3(cls, v):
        if len(v) % 3 != 0:
            raise ValueError("gyro flat list length must be divisible by 3 (x,y,z triplets)")
        return v


class TopFeature(BaseModel):
    feature: str
    value: float


class SessionResult(BaseModel):
    session_id: int
    device_id: str
    recorded_at: datetime
    risk_score: float
    risk_label: str
    model_used: str
    top_contributing_features: Optional[list[TopFeature]] = None


class TrendResponse(BaseModel):
    device_id: str
    n_sessions: int
    rolling_average: Optional[float] = None
    trend_direction: str
    history: list[SessionResult]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_trained_on: str


class ClinicalPredictionRequest(BaseModel):
    """
    Clinical data prediction request from Node.js backend.
    Used for OA risk prediction based on symptoms and basic gait variance.
    """
    pain_level: int = Field(..., ge=0, le=10, description="Pain level 0-10")
    stiffness_duration: str = Field(..., description="Stiffness duration category: <30, 30-60, >60, none")
    swelling: bool = Field(..., description="Joint swelling present")
    past_injury: bool = Field(..., description="History of joint injury")
    gait_data: str = Field(..., description="JSON string with gait features like variance")


class ClinicalPredictionResponse(BaseModel):
    """
    Clinical prediction response for Node.js backend.
    """
    risk_level: str = Field(..., description="Risk level: low, medium, high")
    confidence: float = Field(..., ge=0, le=1, description="Prediction confidence")
    contributing_factors: list[str] = Field(default_factory=list, description="Factors contributing to risk")
    reasoning: str = Field(..., description="AI reasoning for the prediction")
    doctorRecommendations: str = Field(..., description="Doctor recommendations based on risk level")
    model_version: str = Field(default="1.0.0", description="Model version")
