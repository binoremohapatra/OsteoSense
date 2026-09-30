"""
test_both_models_comparison.py
------------------------------
Test both TFLite and Web models with complex scenarios to compare accuracy.
"""

import numpy as np
import json
import joblib
from scipy.special import softmax
import sys
sys.path.append("wearable_model")
from wearable_model.feature_extraction import extract_features as wearable_extract_features
from improved_simulate_data import ImprovedDataGenerator
from improved_feature_extraction import ImprovedFeatureExtractor

# Load web model
print("Loading Web Model (sklearn)...")
try:
    web_model = joblib.load('models/oa_risk_model.joblib')
    web_scaler = joblib.load('models/scaler.joblib')
    with open('models/feature_columns.json', 'r') as f:
        web_feature_names = json.load(f)
    print(f"Web Model loaded with {len(web_feature_names)} features")
except Exception as e:
    print(f"Error loading web model: {e}")
    web_model = None

# Load advanced model
print("\nLoading Advanced Ensemble Model...")
try:
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
except Exception as e:
    print(f"Error loading advanced model: {e}")
    ensemble = None

# Load TFLite model
print("\nLoading TFLite Model...")
try:
    try:
        import tflite_runtime.interpreter as tflite
    except ImportError:
        import tensorflow.lite as tflite
    
    interpreter = tflite.Interpreter(model_path='../app/assets/models/oa_risk_model.tflite')
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    tflite_input_shape = input_details[0]['shape']
    tflite_output_shape = output_details[0]['shape']
    print(f"TFLite Model loaded")
    print(f"Input shape: {tflite_input_shape}")
    print(f"Output shape: {tflite_output_shape}")
except Exception as e:
    print(f"Error loading TFLite model: {e}")
    interpreter = None

print("\n" + "=" * 80)
print("TESTING BOTH MODELS WITH COMPLEX SCENARIOS")
print("=" * 80)
print()

# Generate test scenarios
generator = ImprovedDataGenerator(noise_level=0.15, uncertainty_level=0.2)

scenarios = [
    {"name": "Healthy Patient", "label": 0, "seed": 1},
    {"name": "Low Risk Patient", "label": 1, "seed": 1000},
    {"name": "High Risk Patient", "label": 1, "seed": 2000},
    {"name": "Borderline Healthy", "label": 0, "seed": 5},
    {"name": "Borderline OA-Risk", "label": 1, "seed": 1500},
    {"name": "Very Healthy", "label": 0, "seed": 10},
    {"name": "Severe OA", "label": 1, "seed": 2500},
    {"name": "Mixed Symptoms", "label": 1, "seed": 3000},
    {"name": "Asymptomatic OA", "label": 1, "seed": 4000},
    {"name": "Recovered Patient", "label": 0, "seed": 5000},
]

results = []

for scenario in scenarios:
    print(f"Testing: {scenario['name']}")
    print(f"True Label: {'OA-Risk' if scenario['label'] == 1 else 'Healthy'}")
    
    # Generate data
    record = generator.generate_subject(scenario['label'], seed=scenario['seed'])
    
    # Test Web Model
    web_prediction = None
    web_confidence = None
    if web_model is not None:
        try:
            # Extract features for web model
            wearable_features = wearable_extract_features(record)
            feature_values = [wearable_features.get(col, 0.0) for col in web_feature_names]
            feature_array = np.array(feature_values).reshape(1, -1)
            feature_scaled = web_scaler.transform(feature_array)
            
            web_probs = web_model.predict_proba(feature_scaled)
            web_prediction = int(np.argmax(web_probs))
            web_confidence = float(max(web_probs[0]))
        except Exception as e:
            print(f"  Web Model Error: {e}")
            web_prediction = None
            web_confidence = None
    
    # Test Advanced Model
    advanced_prediction = None
    advanced_confidence = None
    advanced_uncertainty = None
    if ensemble is not None:
        try:
            # Extract features for advanced model
            advanced_extractor = ImprovedFeatureExtractor()
            advanced_features = advanced_extractor.extract_all_features(record)
            feature_values = [advanced_features.get(col, 0.0) for col in advanced_feature_names]
            feature_array = np.array(feature_values).reshape(1, -1)
            
            advanced_probs, advanced_uncertainty = ensemble.predict_with_uncertainty(feature_array)
            advanced_prediction = int(np.argmax(advanced_probs))
            advanced_confidence = max(advanced_probs[0])
            advanced_uncertainty = advanced_uncertainty[0]
        except Exception as e:
            print(f"  Advanced Model Error: {e}")
    
    # Test TFLite Model
    tflite_prediction = None
    tflite_confidence = None
    if interpreter is not None:
        try:
            # Extract features for TFLite model
            wearable_features = wearable_extract_features(record)
            feature_values = [wearable_features.get(col, 0.0) for col in web_feature_names]  # TFLite uses same features
            
            # Pad or truncate to match expected input shape
            if len(feature_values) < tflite_input_shape[1]:
                feature_values += [0.0] * (tflite_input_shape[1] - len(feature_values))
            else:
                feature_values = feature_values[:tflite_input_shape[1]]
            
            feature_array = np.array(feature_values, dtype=np.float32).reshape(tflite_input_shape)
            
            interpreter.set_tensor(input_details[0]['index'], feature_array)
            interpreter.invoke()
            tflite_output = interpreter.get_tensor(output_details[0]['index'])
            
            tflite_prediction = int(np.argmax(tflite_output[0]))
            tflite_confidence = max(tflite_output[0])
        except Exception as e:
            print(f"  TFLite Model Error: {e}")
    
    # Check correctness
    web_correct = web_prediction == scenario['label'] if web_prediction is not None else None
    advanced_correct = advanced_prediction == scenario['label'] if advanced_prediction is not None else None
    tflite_correct = tflite_prediction == scenario['label'] if tflite_prediction is not None else None
    
    print(f"  Web Model: {'OA-Risk' if web_prediction == 1 else 'Healthy'} (Conf: {web_confidence:.4f if web_confidence is not None else 0:.4f}) - {'OK' if web_correct else 'ERR'}")
    print(f"  Advanced Model: {'OA-Risk' if advanced_prediction == 1 else 'Healthy'} (Conf: {advanced_confidence:.4f if advanced_confidence is not None else 0:.4f}, Uncert: {advanced_uncertainty:.4f if advanced_uncertainty is not None else 0:.4f}) - {'OK' if advanced_correct else 'ERR'}")
    print(f"  TFLite Model: {'OA-Risk' if tflite_prediction == 1 else 'Healthy'} (Conf: {tflite_confidence:.4f if tflite_confidence is not None else 0:.4f}) - {'OK' if tflite_correct else 'ERR'}")
    print()
    
    results.append({
        "scenario": scenario['name'],
        "true_label": scenario['label'],
        "web_prediction": web_prediction,
        "web_confidence": web_confidence,
        "web_correct": web_correct,
        "advanced_prediction": advanced_prediction,
        "advanced_confidence": advanced_confidence,
        "advanced_uncertainty": advanced_uncertainty,
        "advanced_correct": advanced_correct,
        "tflite_prediction": tflite_prediction,
        "tflite_confidence": tflite_confidence,
        "tflite_correct": tflite_correct,
    })

# Summary
print("=" * 80)
print("MODEL COMPARISON SUMMARY")
print("=" * 80)
print()

# Calculate accuracies
web_correct_count = sum(1 for r in results if r['web_correct'] == True)
web_total_count = sum(1 for r in results if r['web_correct'] is not None)
web_accuracy = web_correct_count / web_total_count if web_total_count > 0 else 0

advanced_correct_count = sum(1 for r in results if r['advanced_correct'] == True)
advanced_total_count = sum(1 for r in results if r['advanced_correct'] is not None)
advanced_accuracy = advanced_correct_count / advanced_total_count if advanced_total_count > 0 else 0

tflite_correct_count = sum(1 for r in results if r['tflite_correct'] == True)
tflite_total_count = sum(1 for r in results if r['tflite_correct'] is not None)
tflite_accuracy = tflite_correct_count / tflite_total_count if tflite_total_count > 0 else 0

print(f"Web Model Accuracy: {web_correct_count}/{web_total_count} ({web_accuracy*100:.1f}%)")
print(f"Advanced Model Accuracy: {advanced_correct_count}/{advanced_total_count} ({advanced_accuracy*100:.1f}%)")
print(f"TFLite Model Accuracy: {tflite_correct_count}/{tflite_total_count} ({tflite_accuracy*100:.1f}%)")
print()

# Confidence analysis
print("CONFIDENCE ANALYSIS:")
if web_total_count > 0:
    web_confs = [r['web_confidence'] for r in results if r['web_confidence'] is not None]
    print(f"  Web Model - Mean: {np.mean(web_confs):.4f}, Std: {np.std(web_confs):.4f}, Min: {np.min(web_confs):.4f}, Max: {np.max(web_confs):.4f}")

if advanced_total_count > 0:
    advanced_confs = [r['advanced_confidence'] for r in results if r['advanced_confidence'] is not None]
    print(f"  Advanced Model - Mean: {np.mean(advanced_confs):.4f}, Std: {np.std(advanced_confs):.4f}, Min: {np.min(advanced_confs):.4f}, Max: {np.max(advanced_confs):.4f}")

if tflite_total_count > 0:
    tflite_confs = [r['tflite_confidence'] for r in results if r['tflite_confidence'] is not None]
    print(f"  TFLite Model - Mean: {np.mean(tflite_confs):.4f}, Std: {np.std(tflite_confs):.4f}, Min: {np.min(tflite_confs):.4f}, Max: {np.max(tflite_confs):.4f}")

print()

# Uncertainty analysis
if advanced_total_count > 0:
    advanced_uncerts = [r['advanced_uncertainty'] for r in results if r['advanced_uncertainty'] is not None]
    print(f"Advanced Model Uncertainty - Mean: {np.mean(advanced_uncerts):.4f}, Std: {np.std(advanced_uncerts):.4f}")
    print()

# Detailed results table
print("DETAILED RESULTS:")
print(f"{'Scenario':<25} {'True':<8} {'Web':<8} {'Adv':<8} {'TFLite':<8}")
print("-" * 65)
for r in results:
    true_str = "OA" if r['true_label'] == 1 else "HL"
    web_str = f"{'OA' if r['web_prediction'] == 1 else 'HL'}" if r['web_prediction'] is not None else "N/A"
    adv_str = f"{'OA' if r['advanced_prediction'] == 1 else 'HL'}" if r['advanced_prediction'] is not None else "N/A"
    tflite_str = f"{'OA' if r['tflite_prediction'] == 1 else 'HL'}" if r['tflite_prediction'] is not None else "N/A"
    print(f"{r['scenario']:<25} {true_str:<8} {web_str:<8} {adv_str:<8} {tflite_str:<8}")

print()
print("=" * 80)
print("FINAL VERDICT")
print("=" * 80)

if web_accuracy > 0.8 and tflite_accuracy > 0.8:
    print("Both models performing well on test scenarios!")
elif advanced_accuracy > 0.8:
    print("Advanced model performing best - consider updating other models.")
elif web_accuracy > tflite_accuracy:
    print("Web model performing better than TFLite - check TFLite conversion.")
elif tflite_accuracy > web_accuracy:
    print("TFLite model performing better than web - check web model training.")
else:
    print("Both models need improvement - more training data required.")

print()
print("=" * 80)
print("TEST COMPLETED")
print("=" * 80)
