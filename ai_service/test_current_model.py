"""
test_current_model.py
-------------------
Test the current TFLite model to check output and confusion.
"""

import numpy as np
import tensorflow as tf
import json
import sys
sys.path.append("wearable_model")
from wearable_model.simulate_data import simulate_subject
from wearable_model.feature_extraction import extract_features

# Load TFLite model
print("Loading TFLite model...")
interpreter = tf.lite.Interpreter(model_path="../app/assets/models/oa_risk_model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input shape: {input_details[0]['shape']}")
print(f"Output shape: {output_details[0]['shape']}")
print()

# Test with different scenarios
print("=" * 80)
print("TESTING CURRENT MODEL OUTPUT")
print("=" * 80)
print()

scenarios = [
    {"name": "Healthy Patient", "label": 0, "seed": 1},
    {"name": "OA Risk Patient", "label": 1, "seed": 2},
    {"name": "Healthy with Some Symptoms", "label": 0, "seed": 3},
    {"name": "OA Risk with Mild Symptoms", "label": 1, "seed": 4},
    {"name": "Borderline Case", "label": 0, "seed": 5},
    {"name": "Severe OA", "label": 1, "seed": 6},
]

results = []

for scenario in scenarios:
    print(f"Scenario: {scenario['name']}")
    print(f"True Label: {'OA-Risk' if scenario['label'] == 1 else 'Healthy'}")
    
    # Simulate data
    record = simulate_subject(duration_s=6.0, label=scenario['label'], seed=scenario['seed'])
    
    # Extract features
    features = extract_features(record)
    print(f"Features extracted: {len(features)}")
    
    # Prepare input
    feature_values = list(features.values())
    feature_array = np.array(feature_values, dtype=np.float32).reshape(1, -1)
    
    # Run inference
    interpreter.set_tensor(input_details[0]['index'], feature_array)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    
    # Get prediction
    prediction = int(np.argmax(output))
    probability = float(output[1])
    
    # Determine output interpretation
    predicted_label = "OA-Risk" if prediction == 1 else "Healthy"
    confidence = probability if prediction == 1 else (1 - probability)
    
    is_correct = prediction == scenario['label']
    
    print(f"Model Prediction: {predicted_label}")
    print(f"Probability: {probability:.4f}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Status: {'CORRECT' if is_correct else 'INCORRECT'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "true_label": scenario['label'],
        "prediction": prediction,
        "probability": probability,
        "confidence": confidence,
        "correct": is_correct
    })

# Summary
print("=" * 80)
print("MODEL PERFORMANCE SUMMARY")
print("=" * 80)

correct_count = sum(1 for r in results if r['correct'])
total_count = len(results)

print(f"Total Tests: {total_count}")
print(f"Correct Predictions: {correct_count}")
print(f"Accuracy: {correct_count/total_count*100:.1f}%")
print()

print("DETAILED RESULTS:")
print(f"{'Scenario':<30} {'True':<10} {'Pred':<10} {'Prob':<10} {'Status':<10}")
print("-" * 80)

for r in results:
    true_str = "OA" if r['true_label'] == 1 else "HL"
    pred_str = "OA" if r['prediction'] == 1 else "HL"
    status = "OK" if r['correct'] else "ERR"
    print(f"{r['scenario']:<30} {true_str:<10} {pred_str:<10} {r['probability']:.4f}  {status:<10}")

# Check for confusion patterns
print()
print("=" * 80)
print("CONFUSION ANALYSIS")
print("=" * 80)

# False positives (Healthy predicted as OA)
false_positives = [r for r in results if r['true_label'] == 0 and r['prediction'] == 1]
# False negatives (OA predicted as Healthy)
false_negatives = [r for r in results if r['true_label'] == 1 and r['prediction'] == 0]

print(f"False Positives (Healthy -> OA): {len(false_positives)}")
if false_positives:
    for fp in false_positives:
        print(f"  - {fp['scenario']}: Confidence {fp['confidence']:.4f}")

print(f"False Negatives (OA -> Healthy): {len(false_negatives)}")
if false_negatives:
    for fn in false_negatives:
        print(f"  - {fn['scenario']}: Confidence {fn['confidence']:.4f}")

# Probability distribution
print()
print("PROBABILITY DISTRIBUTION:")
probs = [r['probability'] for r in results]
print(f"Mean: {np.mean(probs):.4f}")
print(f"Std: {np.std(probs):.4f}")
print(f"Min: {np.min(probs):.4f}")
print(f"Max: {np.max(probs):.4f}")

# Borderline cases (probabilities between 0.3 and 0.7)
borderline = [r for r in results if 0.3 < r['probability'] < 0.7]
print(f"Borderline Cases (0.3 < prob < 0.7): {len(borderline)}")
if borderline:
    for b in borderline:
        print(f"  - {b['scenario']}: {b['probability']:.4f}")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
