"""
simulate_data.py
-----------------
Generates SYNTHETIC data matching the ACTUAL three-sensor hardware setup:

    1. Gyroscope (3-axis angular velocity) - motion/gait tracking
    2. Piezo disc (single-channel analog) - joint sound / vibration (crepitus)
    3. EMG module (single-channel analog) - muscle activation around the joint

    0 = healthy / normal joint
    1 = early OA-risk (biomechanical + acoustic + muscular markers present, pre-clinical)

NOTE ON HARDWARE CHANGES: this pipeline started as accelerometer+gyro+mic,
then moved to gyro+piezo only, and now adds EMG back in as a third sensor.
This file (and feature_extraction.py) reflect the CURRENT three-sensor setup.

WHY SYNTHETIC DATA, AND HOW TO REPLACE IT LATER
------------------------------------------------
No labeled clinical data exists yet, so this fabricates physiologically
plausible signals based on known OA gait/VAG/EMG biomarkers:
  - Early OA gait: increased stride-to-stride variability, higher jerk
    (less smooth movement), mild asymmetry - visible in gyro alone since
    angular velocity already captures joint rotation dynamics.
  - Early OA joint sound: broadband high-frequency crepitus bursts on top
    of normal low-frequency joint sound, more energy in 200-800 Hz band.
  - Early OA muscle activation: joints under early mechanical stress often
    show COMPENSATORY muscle guarding - higher and more variable activation
    amplitude, and longer/more prolonged activation bursts than the crisp,
    efficient activation pattern of a healthy joint during gait.

This is NOT a clinical model - it exists to validate the pipeline
end-to-end before real sensor data exists. Once real data is available,
replace `simulate_subject()` output with real recordings of the SAME
shape: gyro (N,3), piezo (M,), emg (K,).
"""

import numpy as np

GYRO_FS = 100          # Hz, gyro sample rate (typical MPU6050 config)
PIEZO_FS = 4000        # Hz, piezo disc sample rate (crepitus is broadband, needs higher fs)
EMG_FS = 1000          # Hz, EMG sample rate (surface EMG useful bandwidth is ~20-450 Hz,
                       # so 1000 Hz sampling comfortably satisfies Nyquist with headroom)
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
    """
    Simulate single-channel surface EMG for one recording window.

    Real EMG during gait shows rhythmic bursts of muscle activation timed
    to the gait cycle (e.g. quadriceps firing around heel-strike/loading),
    with quiet periods in between - not continuous activation.

    Early OA -> muscles often GUARD the joint: activation bursts become
    larger in amplitude, more variable, and last longer (prolonged
    co-contraction / compensatory guarding) instead of the crisp, efficient
    burst-then-relax pattern of a healthy joint.
    """
    n = int(duration_s * EMG_FS)
    t = np.arange(n) / EMG_FS

    if label == 0:  # healthy
        burst_amplitude = 1.0
        burst_duration_frac = 0.25   # fraction of each gait cycle spent active
        amplitude_variability = 0.1
    else:  # early OA-risk
        burst_amplitude = 1.6        # compensatory guarding -> stronger activation
        burst_duration_frac = 0.45   # prolonged activation, less efficient relaxation
        amplitude_variability = 0.35  # less consistent activation across cycles

    # Build a gait-cycle-locked activation envelope (bursts of muscle firing)
    envelope = np.zeros(n)
    cycle_len_samples = int(GAIT_CYCLE_S * EMG_FS)
    n_cycles = n // cycle_len_samples + 2
    for c in range(n_cycles):
        cycle_start = c * cycle_len_samples
        this_amp = burst_amplitude * (1 + rng.normal(0, amplitude_variability))
        burst_len = int(cycle_len_samples * burst_duration_frac * (1 + rng.normal(0, 0.15)))
        burst_len = max(burst_len, 5)
        lo = cycle_start
        hi = min(n, cycle_start + burst_len)
        if lo >= n:
            break
        window = np.hanning(hi - lo)
        envelope[lo:hi] += this_amp * window

    # Raw EMG is broadband noise-like signal, amplitude-modulated by the
    # activation envelope above (this mimics real interference-pattern EMG)
    raw_noise = rng.normal(0, 1, n)
    # EMG's useful frequency content is broad (~20-450 Hz); a light high-pass-like
    # emphasis via differencing removes unrealistic DC/very-low-frequency drift
    raw_noise = np.diff(raw_noise, prepend=raw_noise[0])

    emg = envelope * raw_noise + 0.03 * rng.normal(0, 1, n)  # small baseline noise floor

    return emg.astype(np.float32)


def simulate_subject(duration_s=6.0, label=0, seed=None):
    """
    Simulate one recording session for one subject/window.
    Returns dict: {gyro, piezo, emg, label, fs_gyro, fs_piezo, fs_emg, 
                   pain_level, stiffness_duration, swelling, past_injury}
    """
    rng = np.random.default_rng(seed)
    gyro = simulate_gyro(duration_s, label, rng)
    piezo = simulate_piezo(duration_s, label, rng)
    emg = simulate_emg(duration_s, label, rng)
    
    # Simulate clinical features and demographics based on risk label
    if label == 0:
        pain_level = rng.integers(0, 3) # Low pain 0-2
        stiffness = rng.choice([0, 15]) # 0 or 15 mins
        swelling = False
        past_injury = bool(rng.choice([True, False], p=[0.1, 0.9]))
        age = rng.integers(30, 60) # Younger, healthier baseline
        height_cm = rng.uniform(155, 185)
        # Healthy BMI is typically lower
        bmi = rng.uniform(18.5, 24.9)
        weight_kg = bmi * ((height_cm / 100) ** 2)
        mri_kl_grade = rng.choice([0, 1], p=[0.9, 0.1])
        
        # Multimodal symptoms & functional
        sym_locking = False
        sym_clicking = bool(rng.choice([True, False], p=[0.1, 0.9]))
        sym_grinding = False
        sym_aching = bool(rng.choice([True, False], p=[0.2, 0.8]))
        sym_instability = False
        func_standing = rng.choice([0, 1], p=[0.8, 0.2])
        func_walking = rng.choice([0, 1], p=[0.8, 0.2])
        func_stairs = rng.choice([0, 1], p=[0.7, 0.3])
        func_chores = rng.choice([0, 1], p=[0.9, 0.1])
    else:
        pain_level = rng.integers(4, 9) # Moderate/High pain 4-8
        stiffness = rng.choice([30, 60, 90]) # 30+ mins
        swelling = bool(rng.choice([True, False], p=[0.7, 0.3]))
        past_injury = bool(rng.choice([True, False], p=[0.4, 0.6]))
        age = rng.integers(50, 85) # Older age increases OA risk
        height_cm = rng.uniform(155, 185)
        # Higher BMI correlates with OA
        bmi = rng.uniform(25.0, 35.0)
        weight_kg = bmi * ((height_cm / 100) ** 2)
        mri_kl_grade = rng.choice([2, 3, 4], p=[0.5, 0.3, 0.2])

        # Multimodal symptoms & functional
        sym_locking = bool(rng.choice([True, False], p=[0.4, 0.6]))
        sym_clicking = bool(rng.choice([True, False], p=[0.7, 0.3]))
        sym_grinding = bool(rng.choice([True, False], p=[0.6, 0.4]))
        sym_aching = bool(rng.choice([True, False], p=[0.8, 0.2]))
        sym_instability = bool(rng.choice([True, False], p=[0.5, 0.5]))
        func_standing = rng.choice([1, 2, 3], p=[0.3, 0.4, 0.3])
        func_walking = rng.choice([1, 2, 3], p=[0.2, 0.5, 0.3])
        func_stairs = rng.choice([2, 3], p=[0.6, 0.4])
        func_chores = rng.choice([1, 2, 3], p=[0.4, 0.4, 0.2])

    return {
        "gyro": gyro,
        "piezo": piezo,
        "emg": emg,
        "label": label,
        "fs_gyro": GYRO_FS,
        "fs_piezo": PIEZO_FS,
        "fs_emg": EMG_FS,
        "pain_level": float(pain_level),
        "stiffness_duration": float(stiffness),
        "swelling": 1.0 if swelling else 0.0,
        "past_injury": 1.0 if past_injury else 0.0,
        "mri_kl_grade": float(mri_kl_grade),
        "age": float(age),
        "weight_kg": float(weight_kg),
        "height_cm": float(height_cm),
        "sym_locking": 1.0 if sym_locking else 0.0,
        "sym_clicking": 1.0 if sym_clicking else 0.0,
        "sym_grinding": 1.0 if sym_grinding else 0.0,
        "sym_aching": 1.0 if sym_aching else 0.0,
        "sym_instability": 1.0 if sym_instability else 0.0,
        "func_standing": float(func_standing),
        "func_walking": float(func_walking),
        "func_stairs": float(func_stairs),
        "func_chores": float(func_chores),
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
