import numpy as np
import joblib
import tensorflow as tf

print("Starting fast test...")

# Dummy 48 features (e.g. 44 sensors + 4 clinicals)
feats = np.zeros((1, 48), dtype=np.float32)

print("\n--- LEVEL 1: TFLITE (Local Phone) ---")
try:
    interpreter = tf.lite.Interpreter(model_path=r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite")
    interpreter.allocate_tensors()
    interpreter.set_tensor(interpreter.get_input_details()[0]['index'], feats)
    interpreter.invoke()
    tflite_probs = interpreter.get_tensor(interpreter.get_output_details()[0]['index'])[0]
    print(f"TFLite Probs: {tflite_probs}")
except Exception as e:
    print(f"TFLite Error: {e}")

print("\n--- LEVEL 2: XGBOOST (Web API) ---")
try:
    model = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib")
    scaler = joblib.load(r"d:\OsteoSense\ai_service\wearable_model\models\scaler.joblib")
    feats_scaled = scaler.transform(feats)
    heavy_probs = model.predict_proba(feats_scaled)[0]
    print(f"XGBoost Probs: {heavy_probs}")
except Exception as e:
    print(f"XGBoost Error: {e}")
    
print("\nDone.")
