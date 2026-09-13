import os
import sys
sys.path.append(os.path.dirname(__file__))
import json
import numpy as np
import tensorflow as tf
from simulate_data import build_dataset  # type: ignore

def extract_lite_features(rec):
    # 1. normalizedPain
    pain = rec.get("pain_level", 0) / 10.0
    
    # 2. normalizedStiffness
    stiff = rec.get("stiffness_duration", "0")
    import re
    m = re.search(r'\d+', str(stiff))
    stiff_mins = int(m.group(0)) if m else 0
    stiff_norm = min(stiff_mins / 60.0, 1.0)
    
    # 3. swelling
    swelling = 1.0 if rec.get("swelling", False) else 0.0
    
    # 4. hasPastInjury
    past_inj = rec.get("past_injury", "")
    has_inj = 1.0 if (past_inj and len(str(past_inj)) > 0) else 0.0
    
    gyro = np.array(rec["gyro"])
    piezo = np.array(rec["piezo"])
    emg = np.array(rec["emg"])
    
    # Simulate accel as just gyro * 0.1 for synthetic training
    accel = gyro * 0.1 
    
    accel_mean_x = float(np.mean(accel))
    accel_mean_y = float(np.mean(accel))
    accel_mean_z = float(np.mean(accel))
    accel_std_x = float(np.std(accel))
    accel_std_y = float(np.std(accel))
    accel_std_z = float(np.std(accel))
    accel_rms = float(np.sqrt(np.mean(accel**2)))
    
    gyro_mean_x = float(np.mean(gyro))
    gyro_mean_y = float(np.mean(gyro))
    gyro_mean_z = float(np.mean(gyro))
    
    piezo_rms = float(np.sqrt(np.mean(piezo**2)))
    piezo_max = float(np.max(piezo))
    
    emg_rms = float(np.sqrt(np.mean(emg**2)))
    emg_max = float(np.max(emg))
    
    features = [
        pain, stiff_norm, swelling, has_inj,
        accel_mean_x, accel_mean_y, accel_mean_z,
        accel_std_x, accel_std_y, accel_std_z,
        accel_rms, gyro_mean_x, gyro_mean_y, gyro_mean_z,
        piezo_rms, piezo_max, 0.0,
        emg_rms, emg_max, 0.0
    ]
    return features

def train_and_export():
    print("Simulating dataset...")
    records = build_dataset(n_per_class=200, duration_s=6.0, seed=42)
    
    X = []
    y = []
    for rec in records:
        X.append(extract_lite_features(rec))
        # 0 = low, 1 = medium, 2 = high
        # map 'healthy' -> 0 (low), 'OA-risk' -> 2 (high)
        y.append(2 if rec["label"] == "OA-risk" else 0)
        
    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int32)
    
    print(f"Dataset shape: X={X.shape}, y={y.shape}")
    
    model = tf.keras.Sequential([
        tf.keras.Input(shape=(20,)),
        tf.keras.layers.Dense(8, activation='relu'),
        tf.keras.layers.Dense(3, activation='softmax')
    ])
    
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    
    print("Training model...")
    model.fit(X, y, epochs=50, batch_size=16, verbose=1)
    
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    out_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(tflite_model)
        
    print(f"TFLite model saved to {out_path}")

if __name__ == "__main__":
    train_and_export()
