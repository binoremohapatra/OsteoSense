import os
import sys
import numpy as np
import tensorflow as tf

sys.path.append(r"d:\OsteoSense")

from ai_service.wearable_model.simulate_data import simulate_subject  # type: ignore
from ai_service.wearable_model.feature_extraction import extract_features  # type: ignore
from ai_service.backend.app.inference_service import InferenceService  # type: ignore

def simulate_dart_rule_based_fallback(gyro, piezo, emg):
    """
    Python clone of the _predictWithRules fallback logic from tflite_service.dart
    to demonstrate what Level 3 outputs.
    """
    # Assuming some default clinical inputs for testing
    pain_level = 5
    stiffness_minutes = 30
    swelling = False
    
    risk_score = 0
    factors = []
    
    # Pain
    risk_score += pain_level * 0.3
    if pain_level >= 7: factors.append("High pain")
    elif pain_level >= 4: factors.append("Moderate pain")
        
    # Stiffness
    if stiffness_minutes > 30: 
        risk_score += 2.0; factors.append("Prolonged stiffness")
    elif stiffness_minutes > 15: 
        risk_score += 1.0; factors.append("Morning stiffness")
        
    # Gait variance (approximated from raw gyro)
    variance = np.var(gyro)
    if variance > 0.5:
        risk_score += 1.5; factors.append("Abnormal gait pattern")
    elif variance > 0.3:
        risk_score += 1.0; factors.append("Abnormal gait pattern")
    else:
        risk_score += 0.5
        
    # Piezo
    piezo_rms = np.sqrt(np.mean(piezo**2))
    if piezo_rms > 0.5:
        risk_score += 1.5; factors.append("Elevated joint crepitus")
        
    # EMG
    emg_rms = np.sqrt(np.mean(emg**2))
    if emg_rms > 0.4:
        risk_score += 1.0; factors.append("Abnormal muscle guarding")
        
    if risk_score >= 5.0:
        return "high", 0.85, factors
    elif risk_score >= 3.0:
        return "medium", 0.75, factors
    else:
        return "low", 0.70, factors


def test_3_level_architecture():
    print("=== 3-LEVEL ARCHITECTURE SIMULATION: 3 SCENARIOS ===")
    
    scenarios = [
        {"name": "LOW RISK (Healthy)", "label": 0, "seed": 42},
        {"name": "MEDIUM RISK (Early OA)", "label": 1, "seed": 99},
        {"name": "HIGH RISK (Severe OA)", "label": 1, "seed": 150} # We'll artificially boost severity below
    ]
    
    for sc in scenarios:
        print(f"\n==========================================")
        print(f"[{sc['name']}] Generating Data...")
        
        data = simulate_subject(duration_s=6.0, label=sc['label'], seed=sc['seed'])
        
        if sc['name'] == "HIGH RISK (Severe OA)":
            # Artificially boost the severity for "High Risk" scenario
            data['gyro'] *= 1.8 
            data['emg'] *= 2.5
            data['piezo'] *= 2.0
            data['pain_level'] = 9.0
            data['stiffness_duration'] = 90.0
            data['swelling'] = 1.0
            data['past_injury'] = 1.0
            
        feats_dict = extract_features(data)
        feature_vector = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)

        # ==========================================
        # LEVEL 2: WEB API (HEAVY ML)
        # ==========================================
        print("\n---> LEVEL 2: WEB API / DEPLOYED SERVER (Heavy ML)")
        web_service = InferenceService()
        try:
            prob, label, _, _ = web_service.score_window(
                data['gyro'], data['piezo'], data['emg'],
                data['fs_gyro'], data['fs_piezo'], data['fs_emg'],
                data['pain_level'], data['stiffness_duration'],
                data['swelling'], data['past_injury']
            )
            print(f"   Result:      {label.upper()}")
            print(f"   Probability: {prob:.4f}")
        except Exception as e:
            print(f"   Error: {e}")

        # ==========================================
        # LEVEL 1: LOCAL APP (TFLITE ML)
        # ==========================================
        print("\n---> LEVEL 1: LOCAL APP (TFLite Deep NN)")
        tflite_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        interpreter.set_tensor(interpreter.get_input_details()[0]['index'], feature_vector)
        interpreter.invoke()
        tflite_probs = interpreter.get_tensor(interpreter.get_output_details()[0]['index'])[0]
        
        classes = ['low', 'medium', 'high']
        tflite_pred = classes[np.argmax(tflite_probs)]
        
        # Format probabilities nicely
        prob_str = f"[Low: {tflite_probs[0]:.2f}, Med: {tflite_probs[1]:.2f}, High: {tflite_probs[2]:.2f}]"
        print(f"   Result:      {tflite_pred.upper()}")
        print(f"   Probabilities: {prob_str}")

        # ==========================================
        # LEVEL 3: LOCAL APP (RULE-BASED FALLBACK)
        # ==========================================
        print("\n---> LEVEL 3: LOCAL APP FALLBACK (Rule-Based)")
        rule_label, rule_conf, rule_factors = simulate_dart_rule_based_fallback(data['gyro'], data['piezo'], data['emg'])
        print(f"   Result:      {rule_label.upper()}")
        print(f"   Confidence:  {rule_conf:.2f}")
        print(f"   Factors:     {rule_factors}")
    
    print("\n==========================================")
    print("=== ALL SCENARIOS COMPLETE ===")

if __name__ == "__main__":
    test_3_level_architecture()
