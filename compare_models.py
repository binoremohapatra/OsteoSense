import json
import joblib
import numpy as np
import tensorflow as tf
from pathlib import Path

# Paths
WEB_MODEL_PATH = r"D:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib"
SCALER_PATH = r"D:\OsteoSense\ai_service\wearable_model\models\scaler.joblib"
LOCAL_MODEL_PATH = r"D:\OsteoSense\app\assets\models\oa_risk_model.tflite"

print("========================================")
print(" COMPARISON: WEB MODEL vs LOCAL TFLITE ")
print("========================================\n")

# 1. Generate realistic fake patient data (62 features)
# Assuming 78 features as per the scaler
test_features = np.random.rand(1, 78).astype(np.float32)

# ==========================================
# TEST WEB MODEL (Scikit-Learn Joblib)
# ==========================================
print("[1] Running Web Backend Model (oa_risk_model.joblib)...")
try:
    web_model = joblib.load(WEB_MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    
    # Scale features
    x_scaled = scaler.transform(test_features)
    
    # Predict
    web_proba = web_model.predict_proba(x_scaled)[0]
    web_pred = np.argmax(web_proba)
    print(f" -> Web Model Prediction: Class {web_pred} (Probabilities: {web_proba})")
    
    if hasattr(web_model, 'classes_'):
        print(f" -> Web Classes: {web_model.classes_}")
except Exception as e:
    print(f" -> Failed to run Web Model: {e}")

print("\n")

# ==========================================
# TEST LOCAL MODEL (TFLite)
# ==========================================
print("[2] Running Local Device Model (oa_risk_model.tflite)...")
try:
    interpreter = tf.lite.Interpreter(model_path=LOCAL_MODEL_PATH)
    interpreter.allocate_tensors()
    
    input_idx = interpreter.get_input_details()[0]['index']
    output_idx = interpreter.get_output_details()[0]['index']
    
    # Set features (Note: Local model currently doesn't have the scaler baked in, 
    # but we feed the raw features for comparison)
    interpreter.set_tensor(input_idx, test_features[:, :62])
    interpreter.invoke()
    
    local_proba = interpreter.get_tensor(output_idx)[0]
    local_pred = np.argmax(local_proba)
    print(f" -> Local Model Prediction: Class {local_pred} (Probabilities: {local_proba})")
except Exception as e:
    print(f" -> Failed to run Local Model: {e}")

print("\n========================================")
print(" ANALYSIS SUMMARY ")
print("========================================")
