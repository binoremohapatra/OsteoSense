"""
simulate_data.py
-----------------
Generates SYNTHETIC data matching the ACTUAL two-sensor hardware setup:

    1. Gyroscope (3-axis angular velocity) - motion/gait tracking
    2. Piezo disc (single-channel analog) - joint sound / vibration (crepitus)

    0 = healthy / normal joint
    1 = early OA-risk (biomechanical + acoustic markers present, pre-clinical)

NOTE ON HARDWARE CHANGE: earlier versions of this pipeline assumed an
accelerometer + gyroscope + contact mic. The team's actual build uses only
gyro + piezo disc. This file (and feature_extraction.py) reflect that.

WHY SYNTHETIC DATA, AND HOW TO REPLACE IT LATER
------------------------------------------------
No labeled clinical data exists yet, so this fabricates physiologically
plausible signals based on known OA gait/VAG biomarkers:
  - Early OA gait: increased stride-to-stride variability, higher jerk
    (less smooth movement), mild asymmetry - visible in gyro alone since
    angular velocity already captures joint rotation dynamics.
  - Early OA joint sound: broadband high-frequency crepitus bursts on top
    of normal low-frequency joint sound, more energy in 200-800 Hz band.

This is NOT a clinical model — it exists to validate the pipeline
end-to-end before real sensor data exists. Once real data is available,
replace `simulate_subject()` output with real recordings of the SAME
shape: gyro (N,3), piezo (M,).
"""

import numpy as np

GYRO_FS = 100          # Hz, gyro sample rate (typical MPU6050 config)
PIEZO_FS = 4000        # Hz, piezo disc sample rate (crepitus is broadband, needs higher fs)
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


def simulate_subject(duration_s=6.0, label=0, seed=None):
    """
    Simulate one recording session for one subject/window.
    Returns dict: {gyro: (N,3), piezo: (M,), label: int, fs_gyro, fs_piezo}
    """
    rng = np.random.default_rng(seed)
    gyro = simulate_gyro(duration_s, label, rng)
    piezo = simulate_piezo(duration_s, label, rng)
    return {
        "gyro": gyro,
        "piezo": piezo,
        "label": label,
        "fs_gyro": GYRO_FS,
        "fs_piezo": PIEZO_FS,
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
