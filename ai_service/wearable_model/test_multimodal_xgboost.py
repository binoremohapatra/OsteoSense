import sys
import numpy as np
import joblib

from simulate_data import simulate_subject
from feature_extraction import extract_features

def test_multimodal_xgboost():
    print("=== MULTIMODAL AI TEST (XGBOOST API ONLY): 3 SCENARIOS ===")
    
    scenarios = [
        {"name": "LOW RISK (Healthy)", "label": 0, "pain": 1.0, "stiff": 0.0, "swell": 0.0, "inj": 0.0, "seed": 42},
        {"name": "MEDIUM RISK (Early OA)", "label": 1, "pain": 5.0, "stiff": 30.0, "swell": 0.0, "inj": 1.0, "seed": 99},
        {"name": "HIGH RISK (Severe OA)", "label": 1, "pain": 9.0, "stiff": 90.0, "swell": 1.0, "inj": 1.0, "seed": 150}
    ]
    
    xgb_model = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib")
    scaler = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\scaler.joblib")

    for sc in scenarios:
        print(f"\n==========================================")
        print(f"[{sc['name']}]")
        print(f"   Clinical Inputs: Pain={sc['pain']}, Stiffness={sc['stiff']}m, Swelling={sc['swell']}, Injury={sc['inj']}")
        
        # Simulate physical hardware data (Gyro, Piezo, EMG)
        data = simulate_subject(duration_s=6.0, label=sc['label'], seed=sc['seed'])
        
        if "HIGH" in sc['name']:
            # Simulate severe hardware signals
            data['gyro'] *= 1.8 
            data['emg'] *= 2.5
            data['piezo'] *= 2.0
            
        print(f"   Hardware Data Generated: Gyro ({len(data['gyro'])} samples), Piezo ({len(data['piezo'])} samples), EMG ({len(data['emg'])} samples)")
            
        # Inject our explicit clinical inputs
        data['pain_level'] = sc['pain']
        data['stiffness_duration'] = sc['stiff']
        data['swelling'] = sc['swell']
        data['past_injury'] = sc['inj']
        
        # Extract exactly 48 features
        feats_dict = extract_features(data)
        feature_vector = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
        
        # --- LEVEL 2: XGBOOST ---
        feat_scaled = scaler.transform(feature_vector)
        xgb_probs = xgb_model.predict_proba(feat_scaled)[0]
        xgb_pred = "OA-RISK" if xgb_probs[1] >= 0.5 else "HEALTHY"
        print(f"   ---> LEVEL 2 (Web API XGBoost):")
        print(f"        Result: {xgb_pred} (OA Probability: {xgb_probs[1]:.4f})")

if __name__ == "__main__":
    test_multimodal_xgboost()
