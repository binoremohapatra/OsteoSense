import tensorflow as tf
import os
import sys
import numpy as np
import pandas as pd
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "backend", "app"))
from backend.app.main import app
from wearable_model.simulate_data import simulate_subject
from wearable_model.feature_extraction import extract_features
from backend.app.test_api import record_to_payload

def run_batch_test(num_subjects=20):
    client = TestClient(app)
    client.__enter__()
    
    # Load TFLite Model
    tflite_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    results = []
    print(f"Running Batch Test on {num_subjects} Simulated Patients...\n")
    
    for i in range(1, num_subjects + 1):
        # Even IDs = Healthy (0), Odd IDs = OA Risk (1)
        gt_label = 0 if i % 2 == 0 else 1
        record = simulate_subject(label=gt_label, seed=i*100)
        
        # 1. Test Web Backend (via API)
        payload = record_to_payload(record, f"patient-{i}")
        
        res = client.post("/sessions", json=payload)
        backend_score = res.json().get('risk_score', -1)
        backend_label = res.json().get('risk_label', 'ERROR')
        
        # 2. Test TFLite Model
        feats_dict = extract_features(record)
        input_data = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        tflite_out = interpreter.get_tensor(output_details[0]['index'])[0]
        tflite_pred_class = np.argmax(tflite_out)
        tflite_label = ["Low Risk", "Medium Risk", "High Risk"][tflite_pred_class]
        
        # Record results
        results.append({
            "Patient": i,
            "True Status": "Healthy" if gt_label == 0 else "OA-Risk",
            "MRI": record.get('mri_kl_grade', 0),
            "Pain": payload['painLevel'],
            "Swelling": payload['swelling'],
            "Injury": payload['pastInjury'],
            "Mech. Symp": any([payload['sym_locking'], payload['sym_clicking'], payload['sym_grinding']]),
            "Func. Diff": round(np.mean([payload['func_standing'], payload['func_walking'], payload['func_stairs'], payload['func_chores']]), 2),
            "Gait (Gyro RMS)": round(feats_dict.get('gyro_rms_flex', 0), 2),
            "Device (Piezo Pwr)": round(feats_dict.get('piezo_total_power', 0), 2),
            "API Label": backend_label,
            "API Score": round(backend_score, 3),
            "TFLite": tflite_label
        })

    df = pd.DataFrame(results)
    print(df.to_string(index=False))
    
    # Calculate Accuracy
    backend_correct = sum((row["True Status"] == "Healthy" and row["API Label"] == "healthy") or 
                          (row["True Status"] == "OA-Risk" and row["API Label"] == "OA-risk") for row in results)
    
    tflite_correct = sum((row["True Status"] == "Healthy" and row["TFLite"] == "Low Risk") or 
                         (row["True Status"] == "OA-Risk" and row["TFLite"] == "Medium Risk") for row in results)
                         
    print(f"\n--- Summary ---")
    print(f"Web API Accuracy: {backend_correct}/{num_subjects} ({backend_correct/num_subjects*100:.1f}%)")
    print(f"TFLite Accuracy:  {tflite_correct}/{num_subjects} ({tflite_correct/num_subjects*100:.1f}%)")

if __name__ == "__main__":
    run_batch_test(20)
