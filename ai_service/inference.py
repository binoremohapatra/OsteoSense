"""
inference.py
-------------
Shows how the companion app (or a backend service it calls) would use the
trained model to score a NEW sensor recording coming off the ESP32
(gyro + piezo disc only).
"""

import json
import joblib
import numpy as np

from feature_extraction import extract_features

MODEL_DIR = "models"


class OARiskPredictor:
    def __init__(self, model_dir=MODEL_DIR):
        self.model = joblib.load(f"{model_dir}/oa_risk_model.joblib")
        self.scaler = joblib.load(f"{model_dir}/scaler.joblib")
        with open(f"{model_dir}/feature_columns.json") as f:
            self.feature_cols = json.load(f)
        with open(f"{model_dir}/model_metadata.json") as f:
            self.metadata = json.load(f)

    def predict(self, record):
        """
        record: dict with 'gyro' (N,3), 'piezo' (M,), 'fs_gyro', 'fs_piezo'
                — i.e. one windowed capture from the ESP32.
        Returns: dict with risk_score (0-1), risk_label, and top contributing features.
        """
        feats = extract_features(record)
        x = np.array([[feats[c] for c in self.feature_cols]])
        x_scaled = self.scaler.transform(x)

        proba = self.model.predict_proba(x_scaled)[0, 1]
        label = "OA-risk" if proba >= 0.5 else "healthy"

        result = {
            "risk_score": float(proba),
            "risk_label": label,
            "model_used": self.metadata["best_model"],
            "trained_on": "SYNTHETIC data - not clinically validated",
        }

        if hasattr(self.model, "feature_importances_"):
            importances = self.model.feature_importances_
            top_idx = np.argsort(importances)[::-1][:5]
            result["top_contributing_features"] = [
                {"feature": self.feature_cols[i], "value": float(feats[self.feature_cols[i]])}
                for i in top_idx
            ]

        return result


def trend_score(history_scores, window=5):
    """
    Single readings are noisy. Track risk_score over multiple sessions
    (days/weeks) and flag a persistent upward trend, not a single high reading.

    history_scores: list of past risk_score floats, oldest -> newest
    Returns: dict with rolling_average and trend_direction
    """
    if len(history_scores) < 2:
        return {"rolling_average": history_scores[-1] if history_scores else None, "trend_direction": "insufficient_data"}

    recent = history_scores[-window:]
    rolling_avg = float(np.mean(recent))

    if len(recent) >= 3:
        x = np.arange(len(recent))
        slope = np.polyfit(x, recent, 1)[0]
        direction = "worsening" if slope > 0.01 else ("improving" if slope < -0.01 else "stable")
    else:
        direction = "insufficient_data"

    return {"rolling_average": rolling_avg, "trend_direction": direction}


if __name__ == "__main__":
    from simulate_data import simulate_subject

    predictor = OARiskPredictor()

    print("Testing on a fresh simulated healthy subject:")
    healthy_rec = simulate_subject(label=0, seed=999)
    print(json.dumps(predictor.predict(healthy_rec), indent=2))

    print("\nTesting on a fresh simulated OA-risk subject:")
    oa_rec = simulate_subject(label=1, seed=1000)
    print(json.dumps(predictor.predict(oa_rec), indent=2))

    print("\nTesting trend tracking across mock sessions:")
    mock_history = [0.2, 0.25, 0.3, 0.42, 0.55, 0.6]
    print(json.dumps(trend_score(mock_history), indent=2))
