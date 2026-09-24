"""
test_model_accuracy.py
----------------------
Test model accuracy with simple approach to compare current performance.
"""

import numpy as np
import json
import joblib
from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

# Load advanced model
print("Loading Advanced Ensemble Model...")

class AdvancedEnsembleModel:
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

ensemble = AdvancedEnsembleModel()
ensemble_data = joblib.load('models/advanced_2class_ensemble_model.joblib')
ensemble.models = ensemble_data.models
ensemble.scalers = ensemble_data.scalers
advanced_scaler = joblib.load('models/advanced_2class_scaler.joblib')
with open('models/advanced_2class_feature_columns.json', 'r') as f:
    advanced_feature_names = json.load(f)

print(f"Advanced Model loaded with {len(advanced_feature_names)} features")
print(f"Number of ensemble models: {len(ensemble.models)}")
print()

print("=" * 80)
print("TESTING ADVANCED MODEL ACCURACY")
print("=" * 80)
print()

# Generate test dataset
print("Generating test dataset...")
generator = AdvancedDataGenerator(noise_level=0.25, uncertainty_level=0.3, augmentation_level=0.2)

# Generate separate test samples
test_samples = []
for class_label in [0, 1]:  # Healthy and OA-Risk
    for i in range(50):  # 50 samples per class
        seed = class_label * 10000 + i + 5000  # Different seeds from training
        record = generator.generate_subject(class_label, seed=seed)
        record['label'] = class_label
        test_samples.append(record)

print(f"Generated {len(test_samples)} test samples")
print()

# Extract features and test
print("Extracting features and testing...")
extractor = AdvancedFeatureExtractor()

correct_count = 0
total_count = 0
healthy_correct = 0
healthy_total = 0
oa_risk_correct = 0
oa_risk_total = 0

all_confidences = []
all_uncertainties = []

predictions_by_class = {0: [], 1: []}
true_labels = []

for record in test_samples:
    true_label = record['label']
    true_labels.append(true_label)
    
    # Extract features
    features = extractor.extract_all_features(record)
    feature_values = [features.get(col, 0.0) for col in advanced_feature_names]
    feature_array = np.array(feature_values).reshape(1, -1)
    
    # Predict
    probs, uncertainty = ensemble.predict_with_uncertainty(feature_array)
    prediction = int(np.argmax(probs))
    confidence = max(probs[0])
    
    predictions_by_class[true_label].append(probs[0])
    all_confidences.append(confidence)
    all_uncertainties.append(uncertainty[0])
    
    # Count accuracy
    if prediction == true_label:
        correct_count += 1
        if true_label == 0:
            healthy_correct += 1
        else:
            oa_risk_correct += 1
    
    total_count += 1
    if true_label == 0:
        healthy_total += 1
    else:
        oa_risk_total += 1

# Calculate accuracy
overall_accuracy = correct_count / total_count if total_count > 0 else 0
healthy_accuracy = healthy_correct / healthy_total if healthy_total > 0 else 0
oa_risk_accuracy = oa_risk_correct / oa_risk_total if oa_risk_total > 0 else 0

print("=" * 80)
print("ACCURACY RESULTS")
print("=" * 80)
print(f"Overall Accuracy: {correct_count}/{total_count} ({overall_accuracy*100:.1f}%)")
print(f"Healthy Accuracy: {healthy_correct}/{healthy_total} ({healthy_accuracy*100:.1f}%)")
print(f"OA-Risk Accuracy: {oa_risk_correct}/{oa_risk_total} ({oa_risk_accuracy*100:.1f}%)")
print()

print("=" * 80)
print("CONFIDENCE ANALYSIS")
print("=" * 80)
print(f"Mean Confidence: {np.mean(all_confidences):.4f}")
print(f"Std Confidence: {np.std(all_confidences):.4f}")
print(f"Min Confidence: {np.min(all_confidences):.4f}")
print(f"Max Confidence: {np.max(all_confidences):.4f}")
print()

print("=" * 80)
print("UNCERTAINTY ANALYSIS")
print("=" * 80)
print(f"Mean Uncertainty: {np.mean(all_uncertainties):.4f}")
print(f"Std Uncertainty: {np.std(all_uncertainties):.4f}")
print(f"Min Uncertainty: {np.min(all_uncertainties):.4f}")
print(f"Max Uncertainty: {np.max(all_uncertainties):.4f}")
print()

print("=" * 80)
print("PROBABILITY DISTRIBUTION BY CLASS")
print("=" * 80)

healthy_probs = predictions_by_class[0]
oa_risk_probs = predictions_by_class[1]

print("Healthy samples:")
if healthy_probs:
    healthy_probs_array = np.array(healthy_probs)
    print(f"  Mean Healthy prob: {np.mean(healthy_probs_array[:, 0]):.4f}")
    print(f"  Mean OA-Risk prob: {np.mean(healthy_probs_array[:, 1]):.4f}")
    print(f"  Std OA-Risk prob: {np.std(healthy_probs_array[:, 1]):.4f}")

print("OA-Risk samples:")
if oa_risk_probs:
    oa_risk_probs_array = np.array(oa_risk_probs)
    print(f"  Mean Healthy prob: {np.mean(oa_risk_probs_array[:, 0]):.4f}")
    print(f"  Mean OA-Risk prob: {np.mean(oa_risk_probs_array[:, 1]):.4f}")
    print(f"  Std OA-Risk prob: {np.std(oa_risk_probs_array[:, 1]):.4f}")

print()

# Check for borderline cases
print("=" * 80)
print("BORDERLINE CASES ANALYSIS")
print("=" * 80)

borderline_count = 0
for probs in all_confidences:
    if 0.3 < probs < 0.7:
        borderline_count += 1

print(f"Borderline cases (0.3 < confidence < 0.7): {borderline_count}/{total_count} ({borderline_count/total_count*100:.1f}%)")

# Check for meaningful uncertainty
meaningful_uncertainty_count = 0
for uncertainty in all_uncertainties:
    if 0.05 < uncertainty < 0.5:
        meaningful_uncertainty_count += 1

print(f"Meaningful uncertainty (0.05 < uncert < 0.5): {meaningful_uncertainty_count}/{total_count} ({meaningful_uncertainty_count/total_count*100:.1f}%)")
print()

print("=" * 80)
print("FINAL VERDICT")
print("=" * 80)

if overall_accuracy > 0.8:
    print(f"EXCELLENT: Model accuracy is {overall_accuracy*100:.1f}% - very good performance!")
elif overall_accuracy > 0.7:
    print(f"GOOD: Model accuracy is {overall_accuracy*100:.1f}% - acceptable performance.")
elif overall_accuracy > 0.6:
    print(f"MODERATE: Model accuracy is {overall_accuracy*100:.1f}% - needs improvement.")
else:
    print(f"POOR: Model accuracy is {overall_accuracy*100:.1f}% - significant improvement needed.")

if borderline_count > 0:
    print(f"Model shows {borderline_count} borderline cases - good uncertainty estimation.")
else:
    print("Model shows no borderline cases - may be overconfident on synthetic data.")

if meaningful_uncertainty_count > 0:
    print(f"Model shows {meaningful_uncertainty_count} cases with meaningful uncertainty.")
else:
    print("Model shows very low uncertainty - synthetic data issue.")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
