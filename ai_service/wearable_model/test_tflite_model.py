import numpy as np
import tensorflow as tf

def test_tflite():
    model_path = r"d:\OsteoSense\app\assets\models\oa_risk_model.tflite"
    print(f"Loading TFLite model from {model_path}...")
    
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\nInput details:")
    print(f"Shape: {input_details[0]['shape']}")
    print(f"Dtype: {input_details[0]['dtype']}")
    
    print("\nOutput details:")
    print(f"Shape: {output_details[0]['shape']}")
    print(f"Dtype: {output_details[0]['dtype']}")
    
    # Generate dummy 44 features
    dummy_input = np.random.rand(1, 44).astype(np.float32)
    
    interpreter.set_tensor(input_details[0]['index'], dummy_input)
    interpreter.invoke()
    
    output_data = interpreter.get_tensor(output_details[0]['index'])
    print("\nTest Prediction successful!")
    print(f"Raw Output Probabilities: {output_data[0]}")
    
    classes = ['low', 'medium', 'high']
    pred_idx = np.argmax(output_data[0])
    print(f"Predicted Risk Level: {classes[pred_idx]}")

if __name__ == "__main__":
    test_tflite()
