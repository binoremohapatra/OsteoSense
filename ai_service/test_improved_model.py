"""
test_improved_model.py
--------------------
Test the improved model with uncertainty estimation.
"""

import numpy as np
import joblib
import json
from scipy.special import softmax
from improved_simulate_data import ImprovedDataGenerator
from improved_feature_extraction import ImprovedFeatureExtractor

class TemperatureScaler:
    """Temperature scaling for probability calibration."""
    
    def __init__(self):
        self.temperature = 1.0
    
    def calibrate(self, probs):
        """Calibrate probabilities using temperature."""
        logits = np.log(probs + 1e-10)
        scaled_logits = logits / self.temperature
        return softmax(scaled_logits, axis=1)

# Load improved model
print("Loading improved 2-class model...")
model = joblib.load('models/improved_2class_model.joblib')
scaler = joblib.load('models/improved_2class_scaler.joblib')

# Load temperature value from metadata
with open('models/improved_2class_metadata.json', 'r') as f:
    metadata = json.load(f)
    temperature = metadata['temperature']

# Create temperature scaler
temp_scaler = TemperatureScaler()
temp_scaler.temperature = temperature

with open('models/improved_2class_feature_columns.json', 'r') as f:
    feature_names = json.load(f)

print(f"Model loaded with {len(feature_names)} features")
print(f"Temperature: {temp_scaler.temperature:.4f}")
print()

# Test with different scenarios
print("=" * 80)
print("TESTING IMPROVED MODEL WITH UNCERTAINTY")
print("=" * 80)
print()

scenarios = [
    {"name": "Healthy Patient", "label": 0, "seed": 1},
    {"name": "Low Risk Patient", "label": 1, "seed": 1000},
    {"name": "High Risk Patient", "label": 1, "seed": 2000},
    {"name": "Borderline Healthy", "label": 0, "seed": 5},
    {"name": "Borderline OA-Risk", "label": 1, "seed": 1500},
]

results = []

for scenario in scenarios:
    print(f"Scenario: {scenario['name']}")
    print(f"True Label: {'OA-Risk' if scenario['label'] == 1 else 'Healthy'}")
    
    # Generate data
    generator = ImprovedDataGenerator(noise_level=0.15, uncertainty_level=0.2)
    record = generator.generate_subject(scenario['label'], seed=scenario['seed'])
    
    # Extract features
    extractor = ImprovedFeatureExtractor()
    features = extractor.extract_all_features(record)
    
    # Prepare input
    feature_values = [features.get(col, 0.0) for col in feature_names]
    feature_array = np.array(feature_values).reshape(1, -1)
    
    # Scale
    feature_scaled = scaler.transform(feature_array)
    
    # Predict
    probs = model.predict_proba(feature_scaled)
    probs_calibrated = temp_scaler.calibrate(probs)
    prediction = int(np.argmax(probs_calibrated))
    
    # Calculate uncertainty (using probability distance from 0.5)
    confidence = max(probs_calibrated[0])
    uncertainty = 1.0 - confidence
    
    predicted_label = "OA-Risk" if prediction == 1 else "Healthy"
    is_correct = prediction == scenario['label']
    
    print(f"Model Prediction: {predicted_label}")
    print(f"Raw Probabilities: {probs[0]}")
    print(f"Calibrated Probabilities: {probs_calibrated[0]}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Uncertainty: {uncertainty:.4f}")
    print(f"Status: {'CORRECT' if is_correct else 'INCORRECT'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "true_label": scenario['label'],
        "prediction": prediction,
        "raw_probs": probs[0],
        "calibrated_probs": probs_calibrated[0],
        "confidence": confidence,
        "uncertainty": uncertainty,
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
print(f"{'Scenario':<25} {'True':<10} {'Pred':<10} {'Conf':<10} {'Uncert':<10} {'Status':<10}")
print("-" * 80)

for r in results:
    true_str = "OA" if r['true_label'] == 1 else "HL"
    pred_str = "OA" if r['prediction'] == 1 else "HL"
    status = "OK" if r['correct'] else "ERR"
    print(f"{r['scenario']:<25} {true_str:<10} {pred_str:<10} {r['confidence']:.4f}  {r['uncertainty']:.4f}  {status:<10}")

# Probability analysis
print()
print("PROBABILITY ANALYSIS:")
calibrated_probs = [r['calibrated_probs'][1] for r in results]
print(f"Mean: {np.mean(calibrated_probs):.4f}")
print(f"Std: {np.std(calibrated_probs):.4f}")
print(f"Min: {np.min(calibrated_probs):.4f}")
print(f"Max: {np.max(calibrated_probs):.4f}")

# Check for borderline cases
borderline = [r for r in results if 0.3 < r['calibrated_probs'][1] < 0.7]
print(f"Borderline Cases (0.3 < prob < 0.7): {len(borderline)}")
if borderline:
    for b in borderline:
        print(f"  - {b['scenario']}: {b['calibrated_probs'][1]:.4f}")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
