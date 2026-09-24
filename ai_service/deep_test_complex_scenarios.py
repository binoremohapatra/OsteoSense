"""
deep_test_complex_scenarios.py
-------------------------------
Deep testing of both ML models with complex/twisted data scenarios
and simulated X-ray/MRI reports.
"""

import numpy as np
import json
import sys
sys.path.append("wearable_model")
from wearable_model.simulate_data import simulate_subject
from wearable_model.feature_extraction import extract_features
import tensorflow as tf
import time


def generate_complex_scenario(scenario_type):
    """Generate complex/twisted test scenarios."""
    if scenario_type == "borderline_case":
        # Borderline case - features between healthy and OA
        return {
            "label": 0,  # True healthy
            "complexity": "borderline",
            "pain_level": 2,  # Moderate pain
            "stiffness_duration": "30min-1h",  # Moderate stiffness
            "swelling": True,  # Some swelling
            "past_injury": True,  # Past injury
            "mri_kl_grade": 1,  # Early OA signs
        }
    elif scenario_type == "contradictory_symptoms":
        # Contradictory symptoms - some healthy, some OA markers
        return {
            "label": 1,  # True OA
            "complexity": "contradictory",
            "pain_level": 1,  # Low pain
            "stiffness_duration": "none",  # No stiffness
            "swelling": False,  # No swelling
            "past_injury": False,  # No injury
            "mri_kl_grade": 3,  # But severe MRI findings
        }
    elif scenario_type == "severe_risk":
        # Severe OA risk - all markers present
        return {
            "label": 1,  # True OA
            "complexity": "severe",
            "pain_level": 5,  # Severe pain
            "stiffness_duration": ">2h",  # Long stiffness
            "swelling": True,  # Significant swelling
            "past_injury": True,  # Past injury
            "mri_kl_grade": 4,  # Severe MRI findings
        }
    elif scenario_type == "asymptomatic_oa":
        # Asymptomatic OA - no symptoms but MRI shows OA
        return {
            "label": 1,  # True OA
            "complexity": "asymptomatic",
            "pain_level": 0,  # No pain
            "stiffness_duration": "none",  # No stiffness
            "swelling": False,  # No swelling
            "past_injury": False,  # No injury
            "mri_kl_grade": 2,  # But MRI shows OA
        }
    elif scenario_type == "recovered_patient":
        # Recovered patient - past injury but now healthy
        return {
            "label": 0,  # True healthy
            "complexity": "recovered",
            "pain_level": 0,  # No pain
            "stiffness_duration": "none",  # No stiffness
            "swelling": False,  # No swelling
            "past_injury": True,  # Past injury (recovered)
            "mri_kl_grade": 0,  # Normal MRI
        }
    else:
        return {"label": 0, "complexity": "normal"}


def simulate_xray_report(kl_grade):
    """Simulate X-ray report with detailed findings."""
    reports = {
        0: {
            "finding": "Normal joint space, no osteophytes",
            "joint_space": "Normal (3-5mm)",
            "osteophytes": "None",
            "sclerosis": "None",
            "subchondral_cysts": "None",
            "kl_grade": 0,
            "interpretation": "No radiographic evidence of OA"
        },
        1: {
            "finding": "Possible joint space narrowing, small osteophytes",
            "joint_space": "Mild narrowing (2-3mm)",
            "osteophytes": "Small, marginal",
            "sclerosis": "Mild",
            "subchondral_cysts": "None",
            "kl_grade": 1,
            "interpretation": "Doubtful OA"
        },
        2: {
            "finding": "Definite joint space narrowing, moderate osteophytes",
            "joint_space": "Moderate narrowing (1-2mm)",
            "osteophytes": "Moderate, multiple",
            "sclerosis": "Moderate",
            "subchondral_cysts": "Possible",
            "kl_grade": 2,
            "interpretation": "Mild OA"
        },
        3: {
            "finding": "Marked joint space narrowing, large osteophytes",
            "joint_space": "Severe narrowing (<1mm)",
            "osteophytes": "Large, numerous",
            "sclerosis": "Marked",
            "subchondral_cysts": "Present",
            "kl_grade": 3,
            "interpretation": "Moderate OA"
        },
        4: {
            "finding": "Severe joint space loss, large osteophytes, subchondral cysts",
            "joint_space": "Near complete loss",
            "osteophytes": "Large, extensive",
            "sclerosis": "Severe",
            "subchondral_cysts": "Multiple",
            "kl_grade": 4,
            "interpretation": "Severe OA"
        }
    }
    return reports.get(kl_grade, reports[0])


def simulate_mri_report(severity):
    """Simulate MRI report with detailed findings."""
    if severity == 0:
        return {
            "cartilage": "Intact, normal thickness",
            "bone_marrow_edema": "None",
            "meniscal_tear": "None",
            "ligament_integrity": "Normal",
            "synovitis": "None",
            "interpretation": "Normal MRI knee"
        }
    elif severity == 1:
        return {
            "cartilage": "Mild focal thinning",
            "bone_marrow_edema": "Minimal",
            "meniscal_tear": "None",
            "ligament_integrity": "Normal",
            "synovitis": "Mild",
            "interpretation": "Early degenerative changes"
        }
    elif severity == 2:
        return {
            "cartilage": "Moderate thinning, partial thickness loss",
            "bone_marrow_edema": "Moderate",
            "meniscal_tear": "Possible degenerative tear",
            "ligament_integrity": "Mild strain",
            "synovitis": "Moderate",
            "interpretation": "Moderate degenerative changes"
        }
    else:
        return {
            "cartilage": "Severe thinning, full thickness loss",
            "bone_marrow_edema": "Severe",
            "meniscal_tear": "Complex tear",
            "ligament_integrity": "Partial tear",
            "synovitis": "Severe",
            "interpretation": "Advanced degenerative changes"
        }


def test_tflite_model(features, true_label):
    """Test TFLite model with features."""
    # Prepare features - directly use the features dict keys
    feature_values = list(features.values())
    feature_array = np.array(feature_values, dtype=np.float32).reshape(1, -1)

    # Set input tensor
    interpreter.set_tensor(input_details[0]['index'], feature_array)

    # Run inference
    start_time = time.time()
    interpreter.invoke()
    inference_time = time.time() - start_time

    # Get output
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    prediction = int(np.argmax(output))
    probability = float(output[1])  # Probability of class 1 (OA-risk)

    return {
        "prediction": prediction,
        "probability": probability,
        "inference_time": float(inference_time)
    }


def run_deep_test():
    """Run deep test with complex scenarios."""
    print("=" * 80)
    print("DEEP TEST - COMPLEX SCENARIOS WITH X-RAY/MRI REPORTS")
    print("=" * 80)
    print()

    # Use wearable model features for TFLite
    print("Using wearable model feature extraction for TFLite compatibility\n")

    scenarios = [
        "borderline_case",
        "contradictory_symptoms",
        "severe_risk",
        "asymptomatic_oa",
        "recovered_patient"
    ]

    results = []

    for scenario in scenarios:
        print(f"\n{'=' * 80}")
        print(f"SCENARIO: {scenario.upper()}")
        print(f"{'=' * 80}")

        # Generate scenario
        scenario_config = generate_complex_scenario(scenario)
        true_label = scenario_config["label"]

        # Simulate sensor data
        seed = hash(scenario) % 1000000
        record = simulate_subject(duration_s=6.0, label=true_label, seed=seed)

        # Override clinical factors with scenario-specific values
        from wearable_model.clinical_factors import (
            encode_pain_level, encode_stiffness_duration, encode_swelling,
            encode_past_injury, encode_mri_kl_grade
        )

        clinical_factors = {}
        clinical_factors.update(encode_pain_level(scenario_config["pain_level"]))
        clinical_factors.update(encode_stiffness_duration(scenario_config["stiffness_duration"]))
        clinical_factors.update(encode_swelling(scenario_config["swelling"]))
        clinical_factors.update(encode_past_injury(scenario_config["past_injury"]))
        clinical_factors.update(encode_mri_kl_grade(scenario_config["mri_kl_grade"]))

        record["clinical_factors"] = clinical_factors

        # Generate X-ray and MRI reports
        xray_report = simulate_xray_report(scenario_config["mri_kl_grade"])
        mri_report = simulate_mri_report(scenario_config["mri_kl_grade"])

        # Print scenario details
        print(f"\nTrue Label: {'OA-Risk' if true_label == 1 else 'Healthy'}")
        print(f"Complexity: {scenario_config['complexity']}")
        print(f"\nClinical Factors:")
        print(f"  Pain Level: {scenario_config['pain_level']}/5")
        print(f"  Stiffness: {scenario_config['stiffness_duration']}")
        print(f"  Swelling: {scenario_config['swelling']}")
        print(f"  Past Injury: {scenario_config['past_injury']}")
        print(f"  MRI KL Grade: {scenario_config['mri_kl_grade']}")

        print(f"\nSimulated X-Ray Report:")
        print(f"  Finding: {xray_report['finding']}")
        print(f"  Joint Space: {xray_report['joint_space']}")
        print(f"  Osteophytes: {xray_report['osteophytes']}")
        print(f"  Interpretation: {xray_report['interpretation']}")

        print(f"\nSimulated MRI Report:")
        print(f"  Cartilage: {mri_report['cartilage']}")
        print(f"  Bone Marrow Edema: {mri_report['bone_marrow_edema']}")
        print(f"  Meniscal Tear: {mri_report['meniscal_tear']}")
        print(f"  Interpretation: {mri_report['interpretation']}")

        # Extract features
        features = extract_features(record)
        print(f"\nExtracted {len(features)} features")

        # Test TFLite Model only
        print(f"\n{'-' * 80}")
        print("TFLITE MODEL TEST")
        print(f"{'-' * 80}")
        tflite_result = test_tflite_model(features, true_label)
        tflite_correct = tflite_result["prediction"] == true_label
        print(f"Prediction: {'OA-Risk' if tflite_result['prediction'] == 1 else 'Healthy'}")
        print(f"Probability: {tflite_result['probability']:.4f}")
        print(f"Inference Time: {tflite_result['inference_time']*1000:.2f} ms")
        print(f"Status: {'CORRECT' if tflite_correct else 'INCORRECT'}")

        # Store results
        results.append({
            "scenario": scenario,
            "true_label": true_label,
            "tflite_prediction": tflite_result["prediction"],
            "tflite_correct": tflite_correct,
            "tflite_probability": tflite_result["probability"],
            "tflite_time": tflite_result["inference_time"],
            "xray_report": xray_report,
            "mri_report": mri_report
        })

    # Print summary
    print(f"\n{'=' * 80}")
    print("DEEP TEST SUMMARY")
    print(f"{'=' * 80}")

    tflite_correct_count = sum(1 for r in results if r["tflite_correct"])
    total_scenarios = len(results)

    print(f"\nTotal Scenarios: {total_scenarios}")
    print(f"TFLite Model Accuracy: {tflite_correct_count}/{total_scenarios} ({tflite_correct_count/total_scenarios*100:.1f}%)")

    avg_tflite_time = np.mean([r["tflite_time"] for r in results]) * 1000

    print(f"\nAverage Inference Time:")
    print(f"TFLite Model: {avg_tflite_time:.2f} ms")

    # Detailed results table
    print(f"\n{'=' * 80}")
    print("DETAILED RESULTS")
    print(f"{'=' * 80}")
    print(f"{'Scenario':<25} {'True':<10} {'TFLite':<10} {'TFLite%':<8}")
    print(f"{'-' * 80}")

    for r in results:
        true_str = "OA" if r["true_label"] == 1 else "HL"
        tflite_str = "OA" if r["tflite_prediction"] == 1 else "HL"
        tflite_prob = f"{r['tflite_probability']:.2f}"
        print(f"{r['scenario']:<25} {true_str:<10} {tflite_str:<10} {tflite_prob:<8}")

    return results


if __name__ == "__main__":
    # Load TFLite model
    print("Loading TFLite model...")
    interpreter = tf.lite.Interpreter(model_path="../app/assets/models/oa_risk_model.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print("TFLite model loaded successfully!\n")

    results = run_deep_test()
    print(f"\nDeep test completed successfully!")
