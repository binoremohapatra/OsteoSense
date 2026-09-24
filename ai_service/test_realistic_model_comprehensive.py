"""
test_realistic_model_comprehensive.py
-----------------------------------
Comprehensive test of the realistic model on various cases.
"""

import numpy as np
import json
import joblib
from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

# Load realistic model
print("Loading Realistic Ensemble Model...")

class RegularizedEnsembleModel:
    def __init__(self):
        self.models = []
        self.scalers = []
    
    def predict_proba(self, X):
        all_probs = []
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        return np.mean(all_probs, axis=0)
    
    def predict(self, X):
        probs = self.predict_proba(X)
        return np.argmax(probs, axis=1)
    
    def predict_with_uncertainty(self, X):
        all_probs = []
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        all_probs = np.array(all_probs)
        avg_probs = np.mean(all_probs, axis=0)
        uncertainty = np.std(all_probs, axis=0)
        overall_uncertainty = np.mean(uncertainty, axis=1)
        return avg_probs, overall_uncertainty

ensemble = RegularizedEnsembleModel()
ensemble_data = joblib.load('models/realistic_ensemble_model.joblib')
ensemble.models = ensemble_data.models
ensemble.scalers = ensemble_data.scalers
scaler = joblib.load('models/realistic_scaler.joblib')

with open('models/realistic_feature_columns.json', 'r') as f:
    feature_names = json.load(f)

with open('models/realistic_metadata.json', 'r') as f:
    metadata = json.load(f)

print(f"Realistic Model loaded with {len(feature_names)} features")
print(f"Model accuracy: {metadata['test_accuracy']*100:.1f}%")
print(f"Model type: {metadata['model_type']}")
print()

print("=" * 80)
print("COMPREHENSIVE MODEL TESTING")
print("=" * 80)
print()

# Generate comprehensive test scenarios
generator = AdvancedDataGenerator(noise_level=0.20, uncertainty_level=0.25, augmentation_level=0.15)

test_scenarios = [
    # Clear healthy cases
    {"name": "Very Healthy Patient", "label": 0, "seed": 1, "description": "No symptoms, normal gait, healthy MRI"},
    {"name": "Healthy Young Adult", "label": 0, "seed": 2, "description": "Young, no pain, normal activity"},
    {"name": "Healthy Athlete", "label": 0, "seed": 3, "description": "Athlete with healthy joints"},
    
    # Clear OA-Risk cases
    {"name": "Severe OA Patient", "label": 1, "seed": 1000, "description": "High pain, severe MRI changes"},
    {"name": "Advanced OA", "label": 1, "seed": 1001, "description": "KL Grade 4, significant symptoms"},
    {"name": "Chronic OA", "label": 1, "seed": 1002, "description": "Long-term OA with complications"},
    
    # Borderline cases
    {"name": "Borderline Case 1", "label": 0, "seed": 500, "description": "Mild symptoms but normal MRI"},
    {"name": "Borderline Case 2", "label": 1, "seed": 1500, "description": "Moderate MRI but minimal symptoms"},
    {"name": "Borderline Case 3", "label": 0, "seed": 501, "description": "Low pain with some swelling"},
    
    # Contradictory cases
    {"name": "Contradictory 1", "label": 1, "seed": 2000, "description": "No symptoms but severe MRI (KL Grade 3)"},
    {"name": "Contradictory 2", "label": 0, "seed": 2001, "description": "High pain but normal MRI"},
    
    # Asymptomatic cases
    {"name": "Asymptomatic OA", "label": 1, "seed": 3000, "description": "No symptoms but KL Grade 2 MRI"},
    {"name": "Symptomatic Healthy", "label": 0, "seed": 3001, "description": "Symptoms but normal MRI and gait"},
    
    # Mixed cases
    {"name": "Mixed Symptoms 1", "label": 1, "seed": 4000, "description": "Pain and swelling, moderate MRI"},
    {"name": "Mixed Symptoms 2", "label": 0, "seed": 4001, "description": "Mild pain and stiffness, normal MRI"},
    
    # Recovered cases
    {"name": "Recovered Patient", "label": 0, "seed": 5000, "description": "Past injury but now normal"},
    {"name": "Post-Surgery Recovery", "label": 0, "seed": 5001, "description": "After successful surgery"},
    
    # Elderly cases
    {"name": "Elderly Healthy", "label": 0, "seed": 6000, "description": "Healthy elderly patient"},
    {"name": "Elderly OA-Risk", "label": 1, "seed": 6001, "description": "Age-related OA changes"},
]

results = []

for scenario in test_scenarios:
    print(f"Testing: {scenario['name']}")
    print(f"Description: {scenario['description']}")
    print(f"True Label: {'OA-Risk' if scenario['label'] == 1 else 'Healthy'}")
    
    # Generate data
    record = generator.generate_subject(scenario['label'], seed=scenario['seed'])
    
    # Extract features
    extractor = AdvancedFeatureExtractor()
    features = extractor.extract_all_features(record)
    feature_values = [features.get(col, 0.0) for col in feature_names]
    feature_array = np.array(feature_values).reshape(1, -1)
    
    # Predict
    probs, uncertainty = ensemble.predict_with_uncertainty(feature_array)
    prediction = int(np.argmax(probs))
    confidence = max(probs[0])
    
    predicted_label = "OA-Risk" if prediction == 1 else "Healthy"
    is_correct = prediction == scenario['label']
    
    # Determine case type
    case_type = "Unknown"
    if "Borderline" in scenario['name']:
        case_type = "Borderline"
    elif "Contradictory" in scenario['name']:
        case_type = "Contradictory"
    elif "Asymptomatic" in scenario['name']:
        case_type = "Asymptomatic"
    elif "Mixed" in scenario['name']:
        case_type = "Mixed"
    elif "Recovered" in scenario['name']:
        case_type = "Recovered"
    elif "Elderly" in scenario['name']:
        case_type = "Elderly"
    elif "Severe" in scenario['name'] or "Advanced" in scenario['name'] or "Chronic" in scenario['name']:
        case_type = "Severe"
    elif "Very Healthy" in scenario['name'] or "Young" in scenario['name'] or "Athlete" in scenario['name']:
        case_type = "Healthy"
    
    print(f"Model Prediction: {predicted_label}")
    print(f"Probabilities: Healthy={probs[0][0]:.4f}, OA-Risk={probs[0][1]:.4f}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Uncertainty: {uncertainty[0]:.4f}")
    print(f"Case Type: {case_type}")
    print(f"Status: {'CORRECT' if is_correct else 'INCORRECT'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "description": scenario['description'],
        "true_label": scenario['label'],
        "prediction": prediction,
        "predicted_label": predicted_label,
        "probs": probs[0],
        "confidence": confidence,
        "uncertainty": uncertainty[0],
        "correct": is_correct,
        "case_type": case_type
    })

# Summary Analysis
print("=" * 80)
print("COMPREHENSIVE TEST RESULTS")
print("=" * 80)
print()

# Overall accuracy
correct_count = sum(1 for r in results if r['correct'])
total_count = len(results)
overall_accuracy = correct_count / total_count if total_count > 0 else 0

print(f"Overall Accuracy: {correct_count}/{total_count} ({overall_accuracy*100:.1f}%)")
print()

# Breakdown by case type
print("ACCURACY BY CASE TYPE:")
case_types = {}
for r in results:
    ct = r['case_type']
    if ct not in case_types:
        case_types[ct] = {'total': 0, 'correct': 0}
    case_types[ct]['total'] += 1
    if r['correct']:
        case_types[ct]['correct'] += 1

for ct, stats in case_types.items():
    acc = stats['correct'] / stats['total'] if stats['total'] > 0 else 0
    print(f"  {ct}: {stats['correct']}/{stats['total']} ({acc*100:.1f}%)")

print()

# Detailed results table
print("DETAILED RESULTS:")
print(f"{'Scenario':<25} {'Type':<15} {'True':<8} {'Pred':<8} {'Conf':<10} {'Uncert':<10} {'Status':<10}")
print("-" * 95)

for r in results:
    true_str = "OA" if r['true_label'] == 1 else "HL"
    pred_str = "OA" if r['prediction'] == 1 else "HL"
    status = "OK" if r['correct'] else "ERR"
    print(f"{r['scenario']:<25} {r['case_type']:<15} {true_str:<8} {pred_str:<8} {r['confidence']:.4f}  {r['uncertainty']:.4f}  {status:<10}")

print()

# Error analysis
print("ERROR ANALYSIS:")
errors = [r for r in results if not r['correct']]
if errors:
    print(f"Total Errors: {len(errors)}")
    print()
    for error in errors:
        print(f"  {error['scenario']}:")
        print(f"    Description: {error['description']}")
        print(f"    True: {'OA-Risk' if error['true_label'] == 1 else 'Healthy'}")
        print(f"    Predicted: {error['predicted_label']}")
        print(f"    Confidence: {error['confidence']:.4f}")
        print(f"    Uncertainty: {error['uncertainty']:.4f}")
        print()
else:
    print("No errors - all predictions correct!")
    print()

# Probability analysis
print("PROBABILITY ANALYSIS:")
oa_risk_probs = [r['probs'][1] for r in results if r['true_label'] == 1]
healthy_probs = [r['probs'][1] for r in results if r['true_label'] == 0]

if oa_risk_probs:
    print(f"OA-Risk samples (true): Mean={np.mean(oa_risk_probs):.4f}, Std={np.std(oa_risk_probs):.4f}")
if healthy_probs:
    print(f"Healthy samples (true): Mean={np.mean(healthy_probs):.4f}, Std={np.std(healthy_probs):.4f}")

# Confusion matrix analysis
print()
print("CONFUSION MATRIX ANALYSIS:")
true_oa_risk = [r for r in results if r['true_label'] == 1]
true_healthy = [r for r in results if r['true_label'] == 0]

oa_risk_correct = sum(1 for r in true_oa_risk if r['correct'])
oa_risk_total = len(true_oa_risk)
healthy_correct = sum(1 for r in true_healthy if r['correct'])
healthy_total = len(true_healthy)

print(f"OA-Risk: {oa_risk_correct}/{oa_risk_total} correct ({oa_risk_correct/oa_risk_total*100:.1f}%)")
print(f"Healthy: {healthy_correct}/{healthy_total} correct ({healthy_correct/healthy_total*100:.1f}%)")

# Borderline case analysis
print()
print("BORDERLINE CASE ANALYSIS:")
borderline_cases = [r for r in results if r['case_type'] == 'Borderline']
if borderline_cases:
    borderline_correct = sum(1 for r in borderline_cases if r['correct'])
    print(f"Borderline cases: {borderline_correct}/{len(borderline_cases)} correct ({borderline_correct/len(borderline_cases)*100:.1f}%)")
else:
    print("No borderline cases in test set")

# Uncertainty analysis
print()
print("UNCERTAINTY ANALYSIS:")
mean_uncertainty = np.mean([r['uncertainty'] for r in results])
print(f"Mean uncertainty: {mean_uncertainty:.4f}")
print(f"Cases with high uncertainty (>0.2): {sum(1 for r in results if r['uncertainty'] > 0.2)}")
print(f"Cases with low uncertainty (<0.05): {sum(1 for r in results if r['uncertainty'] < 0.05)}")

print()
print("=" * 80)
print("FINAL VERDICT")
print("=" * 80)

if overall_accuracy >= 0.85:
    print(f"EXCELLENT: Model accuracy {overall_accuracy*100:.1f}% meets target (85-90%)")
elif overall_accuracy >= 0.80:
    print(f"GOOD: Model accuracy {overall_accuracy*100:.1f}% is acceptable")
elif overall_accuracy >= 0.70:
    print(f"MODERATE: Model accuracy {overall_accuracy*100:.1f}% needs improvement")
else:
    print(f"POOR: Model accuracy {overall_accuracy*100:.1f}% requires significant improvement")

if len(errors) > 0:
    print(f"Model made {len(errors)} errors on {total_count} test cases")
    print("This is realistic - no medical tool is 100% accurate")
else:
    print("Model achieved perfect accuracy on test set")
    print("This may indicate test set is too easy - consider harder cases")

if mean_uncertainty > 0.1:
    print("Model shows good uncertainty estimation")
else:
    print("Model uncertainty is low - may need more realistic data")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
