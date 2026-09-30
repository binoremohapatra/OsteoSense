"""
test_api.py
------------
Exercises the API end-to-end using FastAPI's TestClient (no server/port
needed to run this). Also doubles as a REFERENCE for how the ESP32/app
side should format its HTTP requests.

Run:
    python3 test_api.py
"""

import sys
import os
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))

from fastapi.testclient import TestClient
from .main import app
from .simulate_data import simulate_subject

# TestClient must be used as a context manager so FastAPI's startup event
# (which calls init_db()) actually fires before requests are made.
client = TestClient(app)
client.__enter__()


def record_to_payload(record, device_id):
    """
    Converts a simulate_subject() record (gyro (N,3), piezo (M,)) into the
    flat-list JSON format the real API expects — this is exactly what the
    ESP32/app firmware needs to replicate when sending real data.
    """
    return {
        "device_id": device_id,
        "gyro": record["gyro"].flatten().tolist(),
        "piezo": record["piezo"].tolist(),
        "emg": record["emg"].tolist(),
        "accel": record.get("accel", np.zeros((0, 3))).flatten().tolist(),
        "fs_gyro": record["fs_gyro"],
        "fs_piezo": record["fs_piezo"],
        "fs_emg": record.get("fs_emg", 1000),
        "fs_accel": record.get("fs_accel", 100),
        "painLevel": int(record.get("pain_level", 0)),
        "stiffnessDuration": str(record.get("stiffness_duration", "0")),
        "swelling": bool(record.get("swelling", False)),
        "pastInjury": bool(record.get("past_injury", False)),
        "past_surgery": bool(record.get("past_surgery", False)),
        "mri_kl_grade": int(record.get("mri_kl_grade", 0)),
        
        "med_hx_diagnosis": bool(record.get("med_hx_diagnosis", False)),
        "med_hx_joint_pain": bool(record.get("med_hx_joint_pain", False)),
        "med_hx_chronic": bool(record.get("med_hx_chronic", False)),
        "med_hx_inflammation": bool(record.get("med_hx_inflammation", False)),
        "med_hx_cartilage": bool(record.get("med_hx_cartilage", False)),
        "med_hx_ligament": bool(record.get("med_hx_ligament", False)),
        "med_hx_fracture": bool(record.get("med_hx_fracture", False)),
        
        "sym_locking": bool(record.get("sym_locking", False)),
        "sym_clicking": bool(record.get("sym_clicking", False)),
        "sym_grinding": bool(record.get("sym_grinding", False)),
        "sym_instability": bool(record.get("sym_instability", False)),
        
        "pain_type_sharp": bool(record.get("pain_type_sharp", False)),
        "pain_type_dull": bool(record.get("pain_type_dull", False)),
        "pain_type_burning": bool(record.get("pain_type_burning", False)),
        "pain_type_aching": bool(record.get("pain_type_aching", False)),
        "pain_type_stabbing": bool(record.get("pain_type_stabbing", False)),
        "pain_type_throbbing": bool(record.get("pain_type_throbbing", False)),
        
        "func_standing": float(record.get("func_standing", 0.0)),
        "func_walking": float(record.get("func_walking", 0.0)),
        "func_stairs": float(record.get("func_stairs", 0.0)),
        "func_chores": float(record.get("func_chores", 0.0)),
    }


def main():
    print("1) Health check")
    r = client.get("/health")
    print(f"   {r.status_code} -> {r.json()}\n")
    assert r.status_code == 200

    device_id = "esp32-test-001"

    print("2) Submitting a healthy-looking session")
    healthy_rec = simulate_subject(label=0, seed=101)
    r = client.post("/sessions", json=record_to_payload(healthy_rec, device_id))
    print(f"   {r.status_code} -> {r.json()}\n")
    assert r.status_code == 200

    print("3) Submitting an OA-risk-looking session")
    oa_rec = simulate_subject(label=1, seed=202)
    r = client.post("/sessions", json=record_to_payload(oa_rec, device_id))
    print(f"   {r.status_code} -> {r.json()}\n")
    assert r.status_code == 200

    print("4) Simulating a worsening trend across 6 sessions")
    for i, seed in enumerate([301, 302, 303, 304, 305, 306]):
        # bias later sessions toward OA-risk to fabricate a "worsening" pattern for the demo
        label = 1 if i >= 3 else 0
        rec = simulate_subject(label=label, seed=seed)
        r = client.post("/sessions", json=record_to_payload(rec, device_id))
        print(f"   session {i+1}: risk_score={r.json()['risk_score']:.3f}  label={r.json()['risk_label']}")
    print()

    print("5) Fetching full session history")
    r = client.get(f"/sessions/{device_id}")
    print(f"   {r.status_code} -> {len(r.json())} sessions returned\n")
    assert r.status_code == 200

    print("6) Fetching trend")
    r = client.get(f"/trend/{device_id}")
    trend = r.json()
    print(f"   {r.status_code} -> rolling_average={trend['rolling_average']:.3f}, "
          f"trend_direction={trend['trend_direction']}, n_sessions={trend['n_sessions']}\n")
    assert r.status_code == 200

    print("7) Testing unknown device_id (should 404)")
    r = client.get("/trend/nonexistent-device")
    print(f"   {r.status_code} -> {r.json()}\n")
    assert r.status_code == 404

    print("8) Testing malformed payload (gyro length not divisible by 3, should 422)")
    bad_payload = record_to_payload(healthy_rec, device_id)
    bad_payload["gyro"] = bad_payload["gyro"][:-1]  # drop one value to break the triplet alignment
    r = client.post("/sessions", json=bad_payload)
    print(f"   {r.status_code} -> validation error as expected\n")
    assert r.status_code == 422

    print("ALL TESTS PASSED")


if __name__ == "__main__":
    main()
