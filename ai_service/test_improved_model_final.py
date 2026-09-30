"""
test_improved_model_final.py
---------------------------
Test the improved model with raw probabilities (no temperature scaling).
"""

import numpy as np
import joblib
import json
from improved_simulate_data import ImprovedDataGenerator
from improved_feature_extraction import ImprovedFeatureExtractor

# Load improved model
print("Loading improved 2-class model...")
model = joblib.load('models/improved_2class_model.joblib')
scaler = joblib.load('models/improved_2class_scaler.joblib')

with open('models/improved_2class_feature_columns.json', 'r') as f:
    feature_names = json.load(f)

print(f"Model loaded with {len(feature_names)} features")
print()

# Test with different scenarios
print("=" * 80)
print("TESTING IMPROVED MODEL WITH RAW PROBABILITIES")
print("=" * 80)
print()

scenarios = [
    {"name": "Healthy Patient", "label": 0, "seed": 1},
    {"name": "Low Risk Patient", "label": 1, "seed": 1000},
    {"name": "High Risk Patient", "label": 1, "seed": 2000},
    {"name": "Borderline Healthy", "label": 0, "seed": 5},
    {"name": "Borderline OA-Risk", "label": 1, "seed": 1500},
    {"name": "Very Healthy", "label": 0, "seed": 10},
    {"name": "Severe OA", "label": 1, "seed": 2500},
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
    
    # Predict (RAW PROBABILITIES - NO TEMPERATURE SCALING)
    probs = model.predict_proba(feature_scaled)
    prediction = int(np.argmax(probs))
    
    # Calculate confidence and uncertainty
    confidence = max(probs[0])
    uncertainty = 1.0 - confidence
    
    predicted_label = "OA-Risk" if prediction == 1 else "Healthy"
    is_correct = prediction == scenario['label']
    
    print(f"Model Prediction: {predicted_label}")
    print(f"Probabilities: {probs[0]}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Uncertainty: {uncertainty:.4f}")
    print(f"Status: {'CORRECT' if is_correct else 'INCORRECT'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "true_label": scenario['label'],
        "prediction": prediction,
        "probs": probs[0],
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
oa_risk_probs = [r['probs'][1] for r in results]
print(f"Mean: {np.mean(oa_risk_probs):.4f}")
print(f"Std: {np.std(oa_risk_probs):.4f}")
print(f"Min: {np.min(oa_risk_probs):.4f}")
print(f"Max: {np.max(oa_risk_probs):.4f}")

# Check for borderline cases
borderline = [r for r in results if 0.3 < r['probs'][1] < 0.7]
print(f"Borderline Cases (0.3 < prob < 0.7): {len(borderline)}")
if borderline:
    for b in borderline:
        print(f"  - {b['scenario']}: {b['probs'][1]:.4f}")

# Check for meaningful uncertainty
meaningful_uncertainty = [r for r in results if 0.1 < r['uncertainty'] < 0.9]
print(f"Meaningful Uncertainty (0.1 < uncert < 0.9): {len(meaningful_uncertainty)}")
if meaningful_uncertainty:
    for m in meaningful_uncertainty:
        print(f"  - {m['scenario']}: {m['uncertainty']:.4f}")

print()
print("=" * 80)
print("FINAL VERDICT")
print("=" * 80)

if len(borderline) > 0 or len(meaningful_uncertainty) > 0:
    print("Model shows reasonable uncertainty - PROBABILITY CALIBRATION WORKING")
else:
    print("Model still too confident - NEEDS MORE REAL DATA")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
