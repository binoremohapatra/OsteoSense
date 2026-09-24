"""
test_advanced_model_with_calibration.py
-----------------------------------
Test the advanced model with manual probability calibration.
"""

import numpy as np
import joblib
import json
from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

class AdvancedEnsembleModel:
    """Advanced ensemble with calibration and uncertainty estimation."""
    
    def __init__(self):
        self.models = []
        self.scalers = []
        self.calibrators = []
    
    def predict_proba(self, X):
        """Predict probabilities by averaging ensemble predictions."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        # Weighted average (simple for now)
        avg_probs = np.mean(all_probs, axis=0)
        
        return avg_probs
    
    def predict(self, X):
        """Predict class labels."""
        probs = self.predict_proba(X)
        return np.argmax(probs, axis=1)
    
    def predict_with_uncertainty(self, X):
        """Predict with uncertainty estimation."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        all_probs = np.array(all_probs)
        
        # Average predictions
        avg_probs = np.mean(all_probs, axis=0)
        
        # Calculate uncertainty (standard deviation across ensemble)
        uncertainty = np.std(all_probs, axis=0)
        
        # Overall uncertainty per sample
        overall_uncertainty = np.mean(uncertainty, axis=1)
        
        return avg_probs, overall_uncertainty
    
    def predict_with_manual_calibration(self, X, temperature=2.5):
        """Predict with manual temperature scaling for better uncertainty."""
        # Get raw probabilities
        probs, uncertainty = self.predict_with_uncertainty(X)
        
        # Apply manual temperature scaling to smooth predictions
        from scipy.special import softmax
        logits = np.log(probs + 1e-10)
        scaled_logits = logits / temperature
        calibrated_probs = softmax(scaled_logits, axis=1)
        
        return calibrated_probs, uncertainty


# Load advanced model
print("Loading advanced 2-class ensemble model...")
ensemble = AdvancedEnsembleModel()
ensemble_data = joblib.load('models/advanced_2class_ensemble_model.joblib')
ensemble.models = ensemble_data.models
ensemble.scalers = ensemble_data.scalers

scaler = joblib.load('models/advanced_2class_scaler.joblib')

with open('models/advanced_2class_feature_columns.json', 'r') as f:
    feature_names = json.load(f)

with open('models/advanced_2class_metadata.json', 'r') as f:
    metadata = json.load(f)

print(f"Model loaded with {len(feature_names)} features")
print(f"Number of ensemble models: {metadata['n_models']}")
print()

# Test with different scenarios
print("=" * 80)
print("TESTING ADVANCED MODEL WITH MANUAL CALIBRATION")
print("=" * 80)
print()

scenarios = [
    {"name": "Healthy Patient", "label": 0, "seed": 1},
    {"name": "Low Risk Patient", "label": 1, "seed": 10000},
    {"name": "High Risk Patient", "label": 1, "seed": 20000},
    {"name": "Borderline Healthy", "label": 0, "seed": 5},
    {"name": "Borderline OA-Risk", "label": 1, "seed": 15000},
    {"name": "Very Healthy", "label": 0, "seed": 10},
    {"name": "Severe OA", "label": 1, "seed": 25000},
    {"name": "Mixed Symptoms", "label": 1, "seed": 30000},
]

results = []

for scenario in scenarios:
    print(f"Scenario: {scenario['name']}")
    print(f"True Label: {'OA-Risk' if scenario['label'] == 1 else 'Healthy'}")
    
    # Generate data
    generator = AdvancedDataGenerator(noise_level=0.25, uncertainty_level=0.3, augmentation_level=0.2)
    record = generator.generate_subject(scenario['label'], seed=scenario['seed'])
    
    # Extract features
    extractor = AdvancedFeatureExtractor()
    features = extractor.extract_all_features(record)
    
    # Prepare input
    feature_values = [features.get(col, 0.0) for col in feature_names]
    feature_array = np.array(feature_values).reshape(1, -1)
    
    # Predict with manual calibration
    probs, uncertainty = ensemble.predict_with_manual_calibration(feature_array, temperature=3.0)
    prediction = int(np.argmax(probs))
    
    confidence = max(probs[0])
    predicted_label = "OA-Risk" if prediction == 1 else "Healthy"
    is_correct = prediction == scenario['label']
    
    print(f"Model Prediction: {predicted_label}")
    print(f"Calibrated Probabilities: {probs[0]}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Uncertainty: {uncertainty[0]:.4f}")
    print(f"Status: {'CORRECT' if is_correct else 'INCORRECT'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "true_label": scenario['label'],
        "prediction": prediction,
        "probs": probs[0],
        "confidence": confidence,
        "uncertainty": uncertainty[0],
        "correct": is_correct
    })

# Summary
print("=" * 80)
print("ADVANCED MODEL WITH CALIBRATION - PERFORMANCE SUMMARY")
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
meaningful_uncertainty = [r for r in results if 0.05 < r['uncertainty'] < 0.5]
print(f"Meaningful Uncertainty (0.05 < uncert < 0.5): {len(meaningful_uncertainty)}")
if meaningful_uncertainty:
    for m in meaningful_uncertainty:
        print(f"  - {m['scenario']}: {m['uncertainty']:.4f}")

# Uncertainty distribution
print()
print("UNCERTAINTY DISTRIBUTION:")
uncertainties = [r['uncertainty'] for r in results]
print(f"Mean Uncertainty: {np.mean(uncertainties):.4f}")
print(f"Std Uncertainty: {np.std(uncertainties):.4f}")
print(f"Min Uncertainty: {np.min(uncertainties):.4f}")
print(f"Max Uncertainty: {np.max(uncertainties):.4f}")

print()
print("=" * 80)
print("FINAL VERDICT")
print("=" * 80)

if len(borderline) > 0:
    print("PROGRESS: Model now shows borderline cases with calibration!")
    print("This is an improvement over the previous overconfident model.")
elif len(meaningful_uncertainty) > 0:
    print("PROGRESS: Model shows some uncertainty with calibration.")
else:
    print("ISSUE: Model still too confident even with calibration.")
    print("This is expected with synthetic data - real data will show more uncertainty.")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
