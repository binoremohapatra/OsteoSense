import tensorflow as tf
import numpy as np

print("Generating TFLite Gait & Clinical Risk Model...")

# Input shape: 78 features
# Output shape: 3 classes (healthy, low_risk, high_risk)
inputs = tf.keras.Input(shape=(78,))

# A small neural network
x = tf.keras.layers.Dense(32, activation='relu')(inputs)
x = tf.keras.layers.Dense(16, activation='relu')(x)
outputs = tf.keras.layers.Dense(3, activation='softmax')(x)

model = tf.keras.Model(inputs=inputs, outputs=outputs)
model.compile(optimizer='adam', loss='categorical_crossentropy')

# Train on dummy data just to initialize weights properly
dummy_x = np.random.rand(10, 78)
dummy_y = np.random.rand(10, 3)
model.fit(dummy_x, dummy_y, epochs=1, verbose=0)

print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

import os
out_path = r"D:\OsteoSense\app\assets\models\oa_risk_model.tflite"
os.makedirs(os.path.dirname(out_path), exist_ok=True)

with open(out_path, 'wb') as f:
    f.write(tflite_model)

print(f"[SUCCESS] Gait model saved to {out_path}")
