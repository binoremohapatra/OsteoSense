"""
inference_service.py
---------------------
Thin wrapper around the trained model (same one from train_model.py) for
use inside the API. Converts the flat JSON lists the ESP32/app sends back
into the (N,3) / (M,) array shapes feature_extraction.py expects.
"""

import json
import joblib
import numpy as np
from pathlib import Path

from .feature_extraction import extract_features

MODEL_DIR = Path(__file__).parent.parent.parent / "wearable_model" / "models"


class InferenceService:
    def __init__(self, model_dir: Path = MODEL_DIR):
        self.model = joblib.load(model_dir / "oa_risk_model.joblib")
        self.scaler = joblib.load(model_dir / "scaler.joblib")
        with open(model_dir / "feature_columns.json") as f:
            self.feature_cols = json.load(f)
        with open(model_dir / "model_metadata.json") as f:
            self.metadata = json.load(f)

    def score_window(self, gyro_flat, piezo_flat, emg_flat, fs_gyro, fs_piezo, fs_emg,
                     pain_level=0, stiffness_duration=0, swelling=0, past_injury=0, **kwargs):
        """
        gyro_flat: flat list, length N*3
        piezo_flat: flat list, length M
        emg_flat: flat list, length K
        Returns: (risk_score: float, risk_label: str, feats: dict, top_features: list[dict])
        """
        gyro = np.array(gyro_flat, dtype=np.float32).reshape(-1, 3)
        piezo = np.array(piezo_flat, dtype=np.float32)
        emg = np.array(emg_flat, dtype=np.float32)

        record = {
            "gyro": gyro, 
            "piezo": piezo, 
            "emg": emg, 
            "fs_gyro": fs_gyro, 
            "fs_piezo": fs_piezo, 
            "fs_emg": fs_emg,
            "pain_level": pain_level,
            "stiffness_duration": 0.0 if str(stiffness_duration).lower() == "none" else (float(str(stiffness_duration).replace('>','').replace('<','').split('-')[0]) if type(stiffness_duration) == str else stiffness_duration),
            "swelling": float(swelling),
            "past_injury": float(past_injury)
        }
        # Add any extra multimodal factors (like mri_kl_grade, sym_locking, etc.)
        for k, v in kwargs.items():
            record[k] = v

        feats = extract_features(record)

        x = np.array([[feats.get(c, 0.0) for c in self.feature_cols]])
        x_scaled = self.scaler.transform(x)
        proba = float(self.model.predict_proba(x_scaled)[0, 1])
        label = "OA-risk" if proba >= 0.5 else "healthy"

        top_features = None
        if hasattr(self.model, "feature_importances_"):
            importances = self.model.feature_importances_
            top_idx = np.argsort(importances)[::-1][:5]
            top_features = [
                {"feature": self.feature_cols[i], "value": float(feats.get(self.feature_cols[i], 0.0))}
                for i in top_idx
            ]

        return proba, label, feats, top_features

    @property
    def model_name(self):
        return self.metadata.get("best_model", "unknown")

    @property
    def trained_on_note(self):
        return self.metadata.get("note", "")


# Singleton instance loaded once at API startup
inference_service = InferenceService()
