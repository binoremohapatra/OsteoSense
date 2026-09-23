import os
import sys
import json
import numpy as np
import tensorflow as tf
from backend.app.inference_service import inference_service
from wearable_model.simulate_data import simulate_subject
from wearable_model.feature_extraction import extract_features

def test_models():
    # Load TFLite model
    tflite_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("# Multimodal Model Testing Report\n")
    print("Testing both the **Web Backend (Rule-Based)** and the **TFLite Wearable Model (Neural Network)** using 10 diverse simulated patient profiles.\n")
    
    print("## Patient Profiles & Results\n")
    print("| Patient | Age | BMI | MRI KL Grade | Symptoms | TFLite Prediction | Web Backend Score | TFLite Conf. |")
    print("|---------|-----|-----|--------------|----------|-------------------|-------------------|--------------|")
    
    rng = np.random.default_rng(42)
    
    for i in range(1, 11):
        # Generate random ground truth (5 healthy, 5 OA)
        gt_label = 0 if i <= 5 else 1
        
        record = simulate_subject(duration_s=6.0, label=gt_label, seed=i*100)
        
        # 1. TFLite Prediction
        feats_dict = extract_features(record)
        input_data = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        tflite_out = interpreter.get_tensor(output_details[0]['index'])[0]
        
        pred_class = np.argmax(tflite_out)
        conf = float(np.max(tflite_out))
        tflite_pred_str = ["Low Risk", "Medium Risk", "High Risk"][pred_class]
        
        # 2. Web Backend Prediction (simulating the logic from main.py /predict)
        score = 0
        pain_level = record.get("pain_level", 0)
        score += (pain_level / 10) * 0.3
        
        stiffness = record.get("stiffness_duration", 0)
        if stiffness > 60: score += 0.25
        elif stiffness > 30: score += 0.15
        elif stiffness > 15: score += 0.05
        
        if record.get("swelling", 0) == 1.0: score += 0.10
        if record.get("past_injury", 0) == 1.0: score += 0.15
        
        kl = record.get("mri_kl_grade", 0)
        if kl == 4: score += 0.50
        elif kl == 3: score += 0.35
        elif kl == 2: score += 0.20
        elif kl == 1: score += 0.05
        
        # Convert score to string
        backend_score_str = f"{score*100:.1f}%"
        
        age = int(record.get('age', 0))
        bmi = float(feats_dict.get('bmi', 24.0))
        kl_grade = int(record.get('mri_kl_grade', 0))
        symptoms = []
        if record.get('sym_locking'): symptoms.append("Locking")
        if record.get('sym_clicking'): symptoms.append("Clicking")
        if pain_level > 5: symptoms.append("High Pain")
        
        sym_str = ", ".join(symptoms) if symptoms else "None"
        
        print(f"| {i} | {age} | {bmi:.1f} | Grade {kl_grade} | {sym_str} | **{tflite_pred_str}** | {backend_score_str} | {conf*100:.1f}% |")

if __name__ == "__main__":
    test_models()
