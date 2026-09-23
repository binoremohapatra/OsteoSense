import os
import sys
sys.path.append(os.path.dirname(__file__))
import numpy as np
import tensorflow as tf
try:
    from simulate_data import build_dataset # type: ignore
    from feature_extraction import extract_features # type: ignore
except ImportError:
    from ai_service.wearable_model.simulate_data import build_dataset # type: ignore
    from ai_service.wearable_model.feature_extraction import extract_features # type: ignore

def train_and_export():
    print("Building dataset for FULL 62 features...")
    records = build_dataset(n_per_class=1000, duration_s=6.0, seed=42)
    
    X = []
    y = []
    
    for rec in records:
        feats_dict = extract_features(rec)
        feats_array = [v for k, v in feats_dict.items()]
        X.append(feats_array)
        y.append(rec["label"])
        
    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int32)
    
    print(f"Dataset shape: X={X.shape}, y={y.shape}")
    if X.shape[1] != 62:
        print(f"WARNING: Expected 62 features, got {X.shape[1]}")
    
    # Deep Neural Network Architecture to match XGBoost capacity
    model = tf.keras.Sequential([
        tf.keras.Input(shape=(62,)),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.Dense(3, activation='softmax')
    ])
    
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    
    print("Training FULL model...")
    model.fit(X, y, epochs=50, batch_size=16, verbose=1)
    
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    out_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(tflite_model)
        
    print(f"TFLite FULL model saved to {out_path}")

if __name__ == "__main__":
    train_and_export()
