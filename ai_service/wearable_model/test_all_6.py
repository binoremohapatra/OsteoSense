import sys
import numpy as np
import joblib
import tensorflow as tf

from simulate_data import simulate_subject
from feature_extraction import extract_features

def test_all_6_scenarios():
    print("=== THE ULTIMATE MULTIMODAL AI TEST: 6 SCENARIOS ===")
    
    scenarios = [
        # Normal Scenarios
        {"name": "1. LOW RISK (Normal)", "label": 0, "pain": 1.0, "stiff": 0.0, "swell": 0.0, "inj": 0.0, "seed": 42},
        {"name": "2. MEDIUM RISK (Early OA)", "label": 1, "pain": 5.0, "stiff": 30.0, "swell": 0.0, "inj": 1.0, "seed": 99},
        {"name": "3. HIGH RISK (Severe OA)", "label": 1, "pain": 9.0, "stiff": 90.0, "swell": 1.0, "inj": 1.0, "seed": 150},
        
        # Confusing Scenarios
        {"name": "4. CONFUSING A: PHANTOM PAIN (Sensors=Healthy, Clinical=Severe)", "label": 0, "pain": 10.0, "stiff": 120.0, "swell": 1.0, "inj": 1.0, "seed": 42},
        {"name": "5. CONFUSING B: SILENT DEGENERATION (Sensors=Severe OA, Clinical=Healthy)", "label": 1, "pain": 0.0, "stiff": 0.0, "swell": 0.0, "inj": 0.0, "seed": 150},
        {"name": "6. CONFUSING C: ANXIOUS PATIENT (Sensors=Medium, Clinical=Severe)", "label": 1, "pain": 9.0, "stiff": 90.0, "swell": 1.0, "inj": 1.0, "seed": 99}
    ]
    
    print("Loading TFLite Model (Local Phone Fallback)...")
    tflite_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("Loading XGBoost Model (Web API)...")
    xgb_model = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib")
    scaler = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\scaler.joblib")

    classes_tflite = ['low', 'medium', 'high']

    for sc in scenarios:
        print(f"\n========================================================")
        print(f"[{sc['name']}]")
        print(f"   Clinical Inputs: Pain={sc['pain']}/10, Stiffness={sc['stiff']}m, Swelling={sc['swell']}, Injury={sc['inj']}")
        
        # Simulate physical data
        data = simulate_subject(duration_s=6.0, label=sc['label'], seed=sc['seed'])
        
        # Modify hardware data based on the scenario
        if "HIGH" in sc['name'] or "SILENT DEGENERATION" in sc['name']:
            data['gyro'] *= 1.8 
            data['emg'] *= 2.5
            data['piezo'] *= 2.0
            print("   Hardware: SEVERE (Amplified Crepitus and Muscle Guarding)")
        elif "LOW" in sc['name'] or "PHANTOM PAIN" in sc['name']:
            print("   Hardware: HEALTHY (Smooth gait, no bad sounds)")
        elif "MEDIUM" in sc['name'] or "ANXIOUS PATIENT" in sc['name']:
            print("   Hardware: MEDIUM (Slight Early-OA variations detected)")
            
        # Inject explicit clinical inputs
        data['pain_level'] = sc['pain']
        data['stiffness_duration'] = sc['stiff']
        data['swelling'] = sc['swell']
        data['past_injury'] = sc['inj']
        
        # Extract features
        feats_dict = extract_features(data)
        feature_vector = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
        
        # --- LEVEL 1: TFLITE ---
        interpreter.set_tensor(input_details[0]['index'], feature_vector)
        interpreter.invoke()
        tflite_probs = interpreter.get_tensor(output_details[0]['index'])[0]
        tflite_pred = classes_tflite[np.argmax(tflite_probs)]
        
        print(f"\n   ---> LEVEL 1 (TFLite Local Phone):")
        print(f"        Result: {tflite_pred.upper()} (Probs: [Low: {tflite_probs[0]*100:.1f}%, Med: {tflite_probs[1]*100:.1f}%, High: {tflite_probs[2]*100:.1f}%])")
        
        # --- LEVEL 2: XGBOOST ---
        feat_scaled = scaler.transform(feature_vector)
        xgb_probs = xgb_model.predict_proba(feat_scaled)[0]
        xgb_pred = "OA-RISK (HIGH/MED)" if xgb_probs[1] >= 0.5 else "HEALTHY (LOW)"
        
        print(f"   ---> LEVEL 2 (Web API XGBoost):")
        print(f"        Result: {xgb_pred} (Risk Probability: {xgb_probs[1]*100:.2f}%)")

if __name__ == "__main__":
    test_all_6_scenarios()
