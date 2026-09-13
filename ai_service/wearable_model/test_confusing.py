import sys
import numpy as np
import joblib
import tensorflow as tf

from simulate_data import simulate_subject
from feature_extraction import extract_features

def test_multimodal_confusing():
    print("=== MULTIMODAL AI STRESS TEST: CONFUSING SCENARIOS ===")
    
    scenarios = [
        {
            "name": "PHANTOM PAIN (Sensors=HEALTHY, Clinical=SEVERE)", 
            "label": 0, # Healthy physical sensors
            "pain": 10.0, "stiff": 120.0, "swell": 1.0, "inj": 1.0, 
            "seed": 42
        },
        {
            "name": "SILENT DEGENERATION (Sensors=SEVERE OA, Clinical=HEALTHY)", 
            "label": 1, # OA-risk physical sensors
            "pain": 0.0, "stiff": 0.0, "swell": 0.0, "inj": 0.0, 
            "seed": 99
        }
    ]
    
    tflite_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    xgb_model = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib")
    scaler = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\scaler.joblib")

    classes_tflite = ['low', 'medium', 'high']

    for sc in scenarios:
        print(f"\n==========================================")
        print(f"[{sc['name']}]")
        print(f"   Clinical Inputs: Pain={sc['pain']}, Stiffness={sc['stiff']}m, Swelling={sc['swell']}, Injury={sc['inj']}")
        
        # Simulate physical data
        data = simulate_subject(duration_s=6.0, label=sc['label'], seed=sc['seed'])
        
        if "SILENT DEGENERATION" in sc['name']:
            # Make sensors extremely bad
            data['gyro'] *= 2.0 
            data['emg'] *= 3.0
            data['piezo'] *= 2.5
            
        print(f"   Physical Ground Truth: {'HEALTHY' if sc['label']==0 else 'SEVERE OA (Amplified)'}")
            
        # Inject our explicit clinical inputs
        data['pain_level'] = sc['pain']
        data['stiffness_duration'] = sc['stiff']
        data['swelling'] = sc['swell']
        data['past_injury'] = sc['inj']
        
        # Extract exactly 48 features
        feats_dict = extract_features(data)
        feature_vector = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
        
        # --- LEVEL 1: TFLITE ---
        interpreter.set_tensor(input_details[0]['index'], feature_vector)
        interpreter.invoke()
        tflite_probs = interpreter.get_tensor(output_details[0]['index'])[0]
        tflite_pred = classes_tflite[np.argmax(tflite_probs)]
        print(f"\n   ---> LEVEL 1 (TFLite Local App):")
        print(f"        Result: {tflite_pred.upper()} (Probabilities: [Low: {tflite_probs[0]:.2f}, Med: {tflite_probs[1]:.2f}, High: {tflite_probs[2]:.2f}])")
        
        # --- LEVEL 2: XGBOOST ---
        feat_scaled = scaler.transform(feature_vector)
        xgb_probs = xgb_model.predict_proba(feat_scaled)[0]
        xgb_pred = "OA-RISK" if xgb_probs[1] >= 0.5 else "HEALTHY"
        print(f"   ---> LEVEL 2 (Web API XGBoost):")
        print(f"        Result: {xgb_pred} (OA Probability: {xgb_probs[1]:.4f})")

if __name__ == "__main__":
    test_multimodal_confusing()
