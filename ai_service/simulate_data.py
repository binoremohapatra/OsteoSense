"""
simulate_data.py
-----------------
Generates SYNTHETIC data matching the ACTUAL three-sensor hardware setup:

    1. Gyroscope (3-axis angular velocity) - motion/gait tracking
    2. Piezo disc (single-channel analog) - joint sound / vibration (crepitus)
    3. EMG (muscle activity sensor) - muscle activation patterns

    0 = healthy / normal joint
    1 = early OA-risk (biomechanical + acoustic + EMG markers present, pre-clinical)

NOTE ON HARDWARE CHANGE: earlier versions of this pipeline assumed an
accelerometer + gyroscope + contact mic. The team's actual build uses only
gyro + piezo disc + EMG. This file (and feature_extraction.py) reflect that.

WHY SYNTHETIC DATA, AND HOW TO REPLACE IT LATER
------------------------------------------------
No labeled clinical data exists yet, so this fabricates physiologically
plausible signals based on known OA gait/VAG/EMG biomarkers:
  - Early OA gait: increased stride-to-stride variability, higher jerk
    (less smooth movement), mild asymmetry - visible in gyro alone since
    angular velocity already captures joint rotation dynamics.
  - Early OA joint sound: broadband high-frequency crepitus bursts on top
    of normal low-frequency joint sound, more energy in 200-800 Hz band.
  - Early OA EMG: altered muscle recruitment patterns, increased co-contraction,
    more sustained activation during gait cycle.

This is NOT a clinical model — it exists to validate the pipeline
end-to-end before real sensor data exists. Once real data is available,
replace `simulate_subject()` output with real recordings of the SAME
shape: gyro (N,3), piezo (M,), emg (N,).
"""

import numpy as np

GYRO_FS = 100          # Hz, gyro sample rate (typical MPU6050 config)
PIEZO_FS = 4000        # Hz, piezo disc sample rate (crepitus is broadband, needs higher fs)
EMG_FS = 1000          # Hz, EMG sample rate (muscle activity sensor)
GAIT_CYCLE_S = 1.1     # nominal seconds per gait cycle (healthy adult walking)


def _gait_cycle_waveform(t, cadence_variability, jerk_factor, asymmetry, rng):
    """One synthetic knee-flexion-driven gyro signal over time vector t."""
    cycle_len = GAIT_CYCLE_S * (1 + rng.normal(0, cadence_variability))
    base_freq = 1.0 / max(cycle_len, 0.5)

    signal = (
        1.0 * np.sin(2 * np.pi * base_freq * t)
        + 0.3 * np.sin(2 * np.pi * 2 * base_freq * t + asymmetry)
        + 0.1 * np.sin(2 * np.pi * 3 * base_freq * t)
    )

    # Jerk / roughness: higher-frequency micro-perturbations.
    # Early OA -> less smooth movement -> more high-freq content.
    jerk_noise = jerk_factor * rng.normal(0, 1, size=t.shape)
    jerk_noise = np.convolve(jerk_noise, np.ones(3) / 3, mode="same")

    return signal + jerk_noise


def simulate_gyro(duration_s, label, rng):
    """Simulate 3-axis gyro (N,3) for one recording window: [flexion, ab/adduction, rotation]."""
    n = int(duration_s * GYRO_FS)
    t = np.arange(n) / GYRO_FS

    if label == 0:  # healthy
        cadence_var = 0.02
        jerk_factor = 0.08
        asymmetry = 0.05
        step_var_extra = 0.02
    else:  # early OA-risk
        cadence_var = 0.06          # more stride-to-stride variability
        jerk_factor = 0.28          # rougher, less smooth movement
        asymmetry = 0.35            # mild loading/rotation asymmetry
        step_var_extra = 0.08

    base = _gait_cycle_waveform(t, cadence_var, jerk_factor, asymmetry, rng)
    base_vel = np.gradient(base) * GYRO_FS / 50  # angular-velocity-like scaling

    gyro = np.stack([
        1.0 * base_vel + rng.normal(0, 0.3 + step_var_extra, n),   # flexion/extension (dominant axis)
        0.4 * base_vel + rng.normal(0, 0.2, n),                     # ab/adduction
        0.3 * base_vel + rng.normal(0, 0.2 + step_var_extra, n),    # internal/external rotation
    ], axis=1)

    return gyro.astype(np.float32)


def simulate_piezo(duration_s, label, rng):
    """Simulate piezo disc joint-sound signal for one recording window."""
    n = int(duration_s * PIEZO_FS)
    t = np.arange(n) / PIEZO_FS

    # Baseline low-frequency joint sound present in everyone (soft tissue movement)
    baseline = 0.3 * np.sin(2 * np.pi * 40 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * (1 / GAIT_CYCLE_S) * t))
    baseline += 0.05 * rng.normal(0, 1, n)

    if label == 1:
        # Crepitus bursts: short broadband high-frequency events near
        # heel-strike / loading phases of the gait cycle
        n_bursts = rng.integers(4, 9)
        crepitus = np.zeros(n)
        for _ in range(n_bursts):
            center = rng.integers(0, n)
            width = rng.integers(int(0.005 * PIEZO_FS), int(0.02 * PIEZO_FS))
            lo, hi = max(0, center - width), min(n, center + width)
            burst_len = hi - lo
            if burst_len <= 0:
                continue
            noise = rng.normal(0, 1, burst_len)
            freqs = rng.uniform(200, 800)
            envelope = np.hanning(burst_len)
            burst = envelope * noise * np.sin(2 * np.pi * freqs * np.arange(burst_len) / PIEZO_FS)
            crepitus[lo:hi] += 0.8 * burst
        signal = baseline + crepitus
    else:
        signal = baseline

    return signal.astype(np.float32)


def simulate_emg(duration_s, label, rng):
    """Simulate EMG signal for muscle activity during gait."""
    n = int(duration_s * EMG_FS)
    t = np.arange(n) / EMG_FS

    # Base gait cycle frequency
    gait_freq = 1.0 / GAIT_CYCLE_S

    if label == 0:  # healthy
        # Normal muscle activation: bursts at heel-strike and toe-off
        emg_base = 0.3 * np.sin(2 * np.pi * gait_freq * t)
        # Add muscle activation bursts
        for cycle_start in np.arange(0, duration_s, GAIT_CYCLE_S):
            cycle_samples = int(cycle_start * EMG_FS)
            burst_start = cycle_samples + int(0.1 * EMG_FS)  # heel-strike
            burst_end = cycle_samples + int(0.3 * EMG_FS)    # stance phase
            if burst_end < n:
                envelope = np.hanning(burst_end - burst_start)
                emg_base[burst_start:burst_end] += envelope * rng.uniform(0.5, 0.8)

        noise_level = 0.1
    else:  # early OA-risk
        # Altered muscle recruitment: more sustained activation, co-contraction
        emg_base = 0.4 * np.sin(2 * np.pi * gait_freq * t)
        # More continuous activation during stance phase
        for cycle_start in np.arange(0, duration_s, GAIT_CYCLE_S):
            cycle_samples = int(cycle_start * EMG_FS)
            burst_start = cycle_samples + int(0.05 * EMG_FS)  # earlier activation
            burst_end = cycle_samples + int(0.5 * EMG_FS)     # longer activation
            if burst_end < n:
                envelope = np.hanning(burst_end - burst_start)
                emg_base[burst_start:burst_end] += envelope * rng.uniform(0.6, 0.9)
            # Add co-contraction (activation during swing phase)
            swing_start = cycle_samples + int(0.6 * EMG_FS)
            swing_end = cycle_samples + int(0.8 * EMG_FS)
            if swing_end < n:
                envelope = np.hanning(swing_end - swing_start)
                emg_base[swing_start:swing_end] += envelope * rng.uniform(0.2, 0.4)

        noise_level = 0.15  # more noise due to altered patterns

    signal = emg_base + rng.normal(0, noise_level, n)
    return signal.astype(np.float32)


def simulate_subject(duration_s=6.0, label=0, seed=None):
    """
    Simulate one recording session for one subject/window.
    Returns dict: {gyro: (N,3), piezo: (M,), emg: (K,), accel: (J,3), label: int, fs_gyro, fs_piezo, fs_emg, fs_accel, clinical_factors, images}
    """
    rng = np.random.default_rng(seed)
    gyro = simulate_gyro(duration_s, label, rng)
    piezo = simulate_piezo(duration_s, label, rng)
    emg = simulate_emg(duration_s, label, rng)

    # Simulate accel based on gyro
    accel = rng.normal(0, 1, gyro.shape)
    if label == 1:
        accel += rng.normal(0.5, 2, gyro.shape) # rougher walking

    # Simulate clinical factors based on label
    clinical_factors = simulate_clinical_factors(label, rng)

    # Simulate image features (mock X-ray data)
    image_features = simulate_image_features(label, rng)

    return {
        "gyro": gyro,
        "piezo": piezo,
        "emg": emg,
        "accel": accel,
        "label": label,
        "fs_gyro": GYRO_FS,
        "fs_piezo": PIEZO_FS,
        "fs_emg": EMG_FS,
        "fs_accel": GYRO_FS,
        "clinical_factors": clinical_factors,
        "image_features": image_features,
    }


def simulate_clinical_factors(label, rng):
    """Simulate clinical questionnaire factors with proper encoding."""
    from clinical_factors import (
        encode_pain_level, encode_stiffness_duration, encode_swelling,
        encode_past_injury, encode_mri_kl_grade
    )

    if label == 0:  # healthy
        pain_level = rng.integers(0, 2)  # mild or no pain
        stiffness_duration = rng.choice(['none', '<30min'])
        swelling = rng.choice([True, False], p=[0.3, 0.7])
        past_injury = rng.choice([True, False], p=[0.2, 0.8])
        mri_kl_grade = rng.integers(0, 2)  # 0 or 1
    else:  # early OA-risk
        pain_level = rng.integers(2, 5)  # moderate to severe pain
        stiffness_duration = rng.choice(['30min-1h', '1h-2h', '>2h'])
        swelling = rng.choice([True, False], p=[0.7, 0.3])
        past_injury = rng.choice([True, False], p=[0.6, 0.4])
        mri_kl_grade = rng.integers(2, 4)  # 2, 3, or 4

    # Encode all factors
    factors = {}
    factors.update(encode_pain_level(pain_level))
    factors.update(encode_stiffness_duration(stiffness_duration))
    factors.update(encode_swelling(swelling))
    factors.update(encode_past_injury(past_injury))
    factors.update(encode_mri_kl_grade(mri_kl_grade))

    return factors


def simulate_image_features(label, rng):
    """Simulate X-ray image features."""
    if label == 0:  # healthy
        kl_grade = rng.integers(0, 2)
        joint_space_narrowing = rng.uniform(0.0, 0.3)
        osteophyte_presence = rng.uniform(0.0, 0.2)
    else:  # early OA-risk
        kl_grade = rng.integers(2, 4)
        joint_space_narrowing = rng.uniform(0.4, 0.8)
        osteophyte_presence = rng.uniform(0.3, 0.7)

    return {
        'xray_kl_grade': kl_grade,
        'xray_joint_space_narrowing': joint_space_narrowing,
        'xray_osteophyte_presence': osteophyte_presence,
    }


def build_dataset(n_per_class=150, duration_s=6.0, seed=42):
    """Build a list of simulated subject recordings, balanced across classes."""
    rng = np.random.default_rng(seed)
    dataset = []
    for label in (0, 1):
        for i in range(n_per_class):
            sub_seed = rng.integers(0, 1_000_000)
            dataset.append(simulate_subject(duration_s=duration_s, label=label, seed=sub_seed))
    rng.shuffle(dataset)
    return dataset


if __name__ == "__main__":
    ds = build_dataset(n_per_class=5, duration_s=6.0)
    print(f"Simulated {len(ds)} recordings")
    print("Example record shapes:", {k: (v.shape if hasattr(v, 'shape') else v) for k, v in ds[0].items()})
