import os
import sys
import numpy as np
import tensorflow as tf
import joblib

try:
    from simulate_data import simulate_subject  # type: ignore
    from feature_extraction import extract_features  # type: ignore
except ImportError:
    from ai_service.wearable_model.simulate_data import simulate_subject  # type: ignore
    from ai_service.wearable_model.feature_extraction import extract_features  # type: ignore

def deep_test():
    print("=== DEEP TEST: HEAVY vs LITE MODEL ===")
    
    # 1. Generate Fake Raw Sensor Data
    print("\n1. Generating fake raw sensor data (Healthy profile)...")
    raw_data = simulate_subject(duration_s=6.0, label=0, seed=42)
    
    # 2. Extract 44 Features
    print("2. Extracting 44 advanced DSP features...")
    feats_dict = extract_features(raw_data)
    feature_vector = np.array([[v for k, v in feats_dict.items()]], dtype=np.float32)
    print(f"   Feature vector shape: {feature_vector.shape}")
    
    # 3. Test HEAVY Model (Scikit-Learn Joblib)
    heavy_model_path = r"d:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib"
    scaler_path = r"d:\OsteoSense\ai_service\wearable_model\models\scaler.joblib"
    
    print("\n3. Testing HEAVY Model (Scikit-Learn/XGBoost)...")
    heavy_model = joblib.load(heavy_model_path)
    scaler = joblib.load(scaler_path)
    
    # Scale features for heavy model
    heavy_input = scaler.transform(feature_vector)
    heavy_probs = heavy_model.predict_proba(heavy_input)[0]
    heavy_pred = np.argmax(heavy_probs)
    
    classes = ['low', 'medium', 'high']
    # The heavy model was binary (healthy vs OA-risk) in train_model.py!
    # Wait, let's check train_model.py outputs. 
    # train_model.py output binary probabilities: healthy (0) or OA-risk (1).
    if len(heavy_probs) == 2:
        h_classes = ['low/healthy', 'high/OA-risk']
        print(f"   Heavy Probabilities: {heavy_probs}")
        print(f"   Heavy Prediction:    {h_classes[heavy_pred]}")
    else:
        print(f"   Heavy Probabilities: {heavy_probs}")
        print(f"   Heavy Prediction:    {classes[heavy_pred] if heavy_pred < 3 else heavy_pred}")

    # 4. Test LITE Model (TFLite Keras)
    lite_model_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    print("\n4. Testing LITE Model (TFLite Neural Network)...")
    
    interpreter = tf.lite.Interpreter(model_path=lite_model_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # TFLite takes the unscaled feature vector directly (since our train_full_tflite_model didn't use scaler)
    # OR did it? train_full_tflite_model.py didn't use a StandardScaler! 
    interpreter.set_tensor(input_details[0]['index'], feature_vector)
    interpreter.invoke()
    
    lite_probs = interpreter.get_tensor(output_details[0]['index'])[0]
    lite_pred = np.argmax(lite_probs)
    
    print(f"   Lite Probabilities: {lite_probs}")
    print(f"   Lite Prediction:    {classes[lite_pred]}")
    
    print("\n=== TEST COMPLETE ===")

if __name__ == "__main__":
    deep_test()
