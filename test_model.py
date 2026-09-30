import tensorflow as tf
import numpy as np
from PIL import Image
import os
import glob

model_path = r"D:\OsteoSense\app\assets\models\oa_image_model.tflite"
images_dir = r"D:\OsteoSense\test_scans\xray"

print("Loading TFLite model...")
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

image_files = glob.glob(os.path.join(images_dir, "*.jpg"))
print(f"Found {len(image_files)} test images.\n")

print(f"{'IMAGE NAME':<18} | {'PREDICTED GRADE'} | {'CONFIDENCE'} | {'DETAILS'}")
print("-" * 75)

for image_path in image_files:
    filename = os.path.basename(image_path)
    try:
        # Load image and resize to 224x224
        img = Image.open(image_path).resize((224, 224))
        img_array = np.array(img, dtype=np.float32)

        # Ensure 3 channels (RGB)
        if len(img_array.shape) == 2:
            img_array = np.stack((img_array,)*3, axis=-1)

        # Preprocess [-1, 1] as per MobileNetV2
        img_array = (img_array / 127.5) - 1.0

        # Add batch dimension
        input_data = np.expand_dims(img_array, axis=0)

        # Run inference
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()

        output_data = interpreter.get_tensor(output_details[0]['index'])[0]

        # Get the highest probability class
        predicted_class = np.argmax(output_data)
        confidence = output_data[predicted_class]
        
        # Get second best
        sorted_indices = np.argsort(output_data)[::-1]
        second_best = sorted_indices[1]
        second_conf = output_data[second_best]

        print(f"{filename:<18} | KL Grade {predicted_class}    | {confidence * 100:>5.1f}%     | 2nd choice: Grade {second_best} ({second_conf * 100:.1f}%)")
    except Exception as e:
        print(f"{filename:<18} | ERROR: {str(e)}")

print("-" * 75)
print("Testing complete.")
