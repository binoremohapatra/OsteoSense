"""
feature_extraction.py
----------------------
Converts raw sensor windows (gyro, piezo) into a fixed-length feature
vector for classical ML (Random Forest / XGBoost / SVM).

Two feature groups, matching the two-sensor hardware setup:
  1. GAIT features        -> from gyro (3-axis angular velocity)
  2. PIEZO/VAG features   -> from piezo disc (joint sound/vibration)

No accelerometer, no separate mic - gyro alone carries the gait dynamics
signal, and the piezo disc is the vibration/sound pickup (previously
planned as a contact mic; functionally equivalent for feature purposes).

Design choice: classical hand-crafted features (not raw signal to a deep
net) because:
  - Dataset will be small (hackathon timeframe, limited subjects)
  - Features map to clinically-recognized OA biomarkers -> explainable
  - Runs easily inside a phone app, no on-device deep learning needed
"""

import numpy as np
from scipy import signal as sp_signal
from scipy.stats import entropy as shannon_entropy

GYRO_FS_DEFAULT = 100
PIEZO_FS_DEFAULT = 4000
EMG_FS_DEFAULT = 1000


# ---------------------------------------------------------------------------
# GAIT FEATURES (from gyro only)
# ---------------------------------------------------------------------------

def _find_stride_peaks(gyro_axis, fs):
    """Find approximate stride events (peaks) in the dominant gyro axis (flexion/extension)."""
    min_distance = int(0.5 * fs)  # assume strides are at least 0.5s apart
    peaks, _ = sp_signal.find_peaks(gyro_axis, distance=min_distance)
    return peaks


def extract_gait_features(gyro, fs=GYRO_FS_DEFAULT):
    """
    gyro: (N, 3) array -> [flexion/extension, ab/adduction, rotation]
    Returns dict of scalar gait features, derived entirely from angular velocity.
    """
    feats = {}
    flex = gyro[:, 0]  # dominant axis for gait cycle (knee flexion/extension)

    peaks = _find_stride_peaks(flex, fs)
    if len(peaks) >= 3:
        stride_intervals = np.diff(peaks) / fs
        feats["cadence_hz"] = 1.0 / np.mean(stride_intervals)
        feats["stride_time_mean"] = np.mean(stride_intervals)
        feats["stride_time_cv"] = np.std(stride_intervals) / (np.mean(stride_intervals) + 1e-8)
    else:
        feats["cadence_hz"] = 0.0
        feats["stride_time_mean"] = 0.0
        feats["stride_time_cv"] = 0.0

    # Jerk = derivative of angular velocity -> smoothness of movement.
    # Lower smoothness (higher jerk) is an early-OA marker.
    for i, axis_name in enumerate(["flex", "abad", "rot"]):
        axis = gyro[:, i]
        jerk = np.diff(axis) * fs
        feats[f"jerk_rms_{axis_name}"] = np.sqrt(np.mean(jerk ** 2))
        feats[f"gyro_rms_{axis_name}"] = np.sqrt(np.mean(axis ** 2))
        feats[f"gyro_peak_{axis_name}"] = np.max(np.abs(axis))
        feats[f"gyro_std_{axis_name}"] = np.std(axis)

    # Overall movement smoothness index: rougher / less smooth movement ->
    # more high-frequency energy relative to total, in the dominant axis
    freqs, psd = sp_signal.welch(flex, fs=fs, nperseg=min(256, len(flex)))
    total_power = np.sum(psd) + 1e-8
    high_freq_mask = freqs > (fs / 4)
    feats["gait_high_freq_ratio"] = np.sum(psd[high_freq_mask]) / total_power

    # Stride-to-stride amplitude variability (asymmetry proxy)
    if len(peaks) >= 3:
        peak_vals = flex[peaks]
        feats["stride_amplitude_cv"] = np.std(peak_vals) / (np.abs(np.mean(peak_vals)) + 1e-8)
    else:
        feats["stride_amplitude_cv"] = 0.0

    return feats


# ---------------------------------------------------------------------------
# PIEZO / VAG (vibroarthrography) FEATURES
# ---------------------------------------------------------------------------

def _band_energy(freqs, psd, lo, hi):
    mask = (freqs >= lo) & (freqs < hi)
    return np.sum(psd[mask])


def extract_piezo_features(piezo_signal, fs=PIEZO_FS_DEFAULT):
    """
    piezo_signal: (M,) raw piezo disc waveform for one window.
    Returns dict of scalar acoustic / VAG features.
    Frequency bands chosen to separate normal soft-tissue sound (~low freq)
    from crepitus / grinding (broadband, elevated 200-800 Hz energy).
    """
    feats = {}

    freqs, psd = sp_signal.welch(piezo_signal, fs=fs, nperseg=min(1024, len(piezo_signal)))
    total_power = np.sum(psd) + 1e-8

    feats["piezo_total_power"] = total_power
    feats["band_low_0_100"] = _band_energy(freqs, psd, 0, 100) / total_power
    feats["band_mid_100_200"] = _band_energy(freqs, psd, 100, 200) / total_power
    feats["band_crepitus_200_800"] = _band_energy(freqs, psd, 200, 800) / total_power
    feats["band_high_800_2000"] = _band_energy(freqs, psd, 800, min(2000, fs / 2)) / total_power

    # Spectral entropy: crepitus/grinding is broadband and noise-like ->
    # higher spectral entropy than smooth, tonal healthy joint sounds
    psd_norm = psd / total_power
    feats["spectral_entropy"] = shannon_entropy(psd_norm + 1e-12)

    feats["dominant_freq"] = freqs[np.argmax(psd)]

    # Zero-crossing rate: proxy for "clickiness" / high-frequency burst content
    zero_crossings = np.sum(np.diff(np.sign(piezo_signal)) != 0)
    feats["zero_crossing_rate"] = zero_crossings / len(piezo_signal)

    # Envelope-based burst detection: crepitus shows up as discrete
    # clicks/pops, not continuous sound
    envelope = np.abs(sp_signal.hilbert(piezo_signal))
    threshold = np.mean(envelope) + 3 * np.std(envelope)
    burst_mask = envelope > threshold
    burst_edges = np.diff(burst_mask.astype(int))
    n_bursts = np.sum(burst_edges == 1)
    feats["n_transient_bursts"] = n_bursts
    feats["burst_energy_ratio"] = np.sum(envelope[burst_mask] ** 2) / (np.sum(envelope ** 2) + 1e-8)

    # Simple MFCC-like log-mel-band energies (cheap substitute, no extra dependency)
    feats.update(_simple_mel_bands(freqs, psd, n_bands=6))

    return feats


def _simple_mel_bands(freqs, psd, n_bands=6, fmax=1000):
    """Lightweight mel-like log-energy bands as an MFCC substitute."""
    def hz_to_mel(f):
        return 2595 * np.log10(1 + f / 700)

    def mel_to_hz(m):
        return 700 * (10 ** (m / 2595) - 1)

    mel_edges = np.linspace(hz_to_mel(0), hz_to_mel(fmax), n_bands + 2)
    hz_edges = mel_to_hz(mel_edges)

    feats = {}
    for i in range(n_bands):
        lo, hi = hz_edges[i], hz_edges[i + 2]
        e = _band_energy(freqs, psd, lo, hi)
        feats[f"melband_{i}"] = np.log1p(e)
    return feats


# ---------------------------------------------------------------------------
# EMG FEATURES (muscle activation around the joint)
# ---------------------------------------------------------------------------

def extract_emg_features(emg_signal, fs=EMG_FS_DEFAULT):
    """
    emg_signal: (K,) raw single-channel surface EMG waveform for one window.
    Returns dict of scalar EMG features.

    These map to standard EMG analysis metrics used in biomechanics/rehab
    research (time-domain amplitude features + frequency-domain features),
    plus activation-burst features that target the "compensatory guarding"
    pattern (larger, longer, more variable muscle activation bursts) that's
    an early-OA marker independent of gait timing or joint sound.
    """
    feats = {}

    # --- Time-domain amplitude features ---
    feats["emg_rms"] = np.sqrt(np.mean(emg_signal ** 2))
    feats["emg_mav"] = np.mean(np.abs(emg_signal))  # Mean Absolute Value - standard EMG amplitude metric
    feats["emg_std"] = np.std(emg_signal)

    # Waveform length: cumulative sum of absolute differences between
    # consecutive samples - a standard EMG feature capturing signal
    # complexity/activity level over the window
    feats["emg_waveform_length"] = np.sum(np.abs(np.diff(emg_signal)))

    # Zero-crossing rate: how often the signal crosses zero - relates to
    # the signal's dominant frequency content and activation level
    zero_crossings = np.sum(np.diff(np.sign(emg_signal)) != 0)
    feats["emg_zero_crossing_rate"] = zero_crossings / len(emg_signal)

    # --- Frequency-domain features ---
    freqs, psd = sp_signal.welch(emg_signal, fs=fs, nperseg=min(512, len(emg_signal)))
    total_power = np.sum(psd) + 1e-8

    # Median frequency: the frequency that splits total power in half.
    # A standard EMG fatigue/quality indicator - shifts are associated
    # with altered muscle fiber recruitment patterns.
    cumulative_power = np.cumsum(psd)
    median_freq_idx = np.searchsorted(cumulative_power, total_power / 2)
    feats["emg_median_freq"] = freqs[min(median_freq_idx, len(freqs) - 1)]

    # Mean frequency: power-weighted average frequency
    feats["emg_mean_freq"] = np.sum(freqs * psd) / total_power

    # Band energy ratio: EMG's typical useful bandwidth is ~20-450 Hz;
    # a shift in energy distribution within this band can reflect altered
    # motor unit recruitment
    low_mask = (freqs >= 20) & (freqs < 100)
    high_mask = (freqs >= 100) & (freqs < 450)
    feats["emg_low_band_ratio"] = np.sum(psd[low_mask]) / total_power
    feats["emg_high_band_ratio"] = np.sum(psd[high_mask]) / total_power

    # --- Activation-burst features (gait-cycle-locked muscle guarding pattern) ---
    # Envelope via Hilbert transform, same technique used for piezo burst detection
    envelope = np.abs(sp_signal.hilbert(emg_signal))
    threshold = np.mean(envelope) + 0.5 * np.std(envelope)
    active_mask = envelope > threshold

    # Duty cycle: fraction of the window spent in an "activated" state.
    # Prolonged/inefficient activation (compensatory guarding) raises this.
    feats["emg_duty_cycle"] = np.mean(active_mask)

    # Activation variability: how much the envelope amplitude varies
    # during active periods - less consistent activation is an OA marker
    if np.any(active_mask):
        feats["emg_activation_amplitude_cv"] = (
            np.std(envelope[active_mask]) / (np.mean(envelope[active_mask]) + 1e-8)
        )
    else:
        feats["emg_activation_amplitude_cv"] = 0.0

    return feats


# ---------------------------------------------------------------------------
# ACCELEROMETER FEATURES (from phone sensor)
# ---------------------------------------------------------------------------

def extract_accel_features(accel, fs=100):
    """
    accel: (J, 3) array
    """
    feats = {}
    if len(accel) == 0:
        feats["accel_rms"] = 0.0
        feats["estimated_steps"] = 0.0
        feats["regularity_score"] = 0.0
        return feats

    # Simply calculate RMS across all axes
    rms_x = np.sqrt(np.mean(accel[:, 0]**2))
    rms_y = np.sqrt(np.mean(accel[:, 1]**2))
    rms_z = np.sqrt(np.mean(accel[:, 2]**2))
    feats["accel_rms"] = (rms_x + rms_y + rms_z) / 3.0
    
    # Estimate steps simply by finding peaks in the norm
    accel_norm = np.linalg.norm(accel, axis=1)
    peaks, _ = sp_signal.find_peaks(accel_norm, distance=int(fs*0.5))
    feats["estimated_steps"] = float(len(peaks))
    
    # Regularity score (autocorrelation of norm)
    norm_centered = accel_norm - np.mean(accel_norm)
    if np.sum(norm_centered**2) > 0:
        autocorr = np.correlate(norm_centered, norm_centered, mode='full')
        autocorr = autocorr[len(autocorr)//2:] / np.max(autocorr)
        feats["regularity_score"] = np.mean(autocorr)
    else:
        feats["regularity_score"] = 0.0
        
    return feats


# ---------------------------------------------------------------------------
# COMBINE INTO ONE FEATURE VECTOR
# ---------------------------------------------------------------------------

def extract_features(record):
    """
    record: dict as produced by simulate_data.simulate_subject()
            (or, later, real sensor recordings with the SAME keys/shapes:
             'gyro' (N,3), 'piezo' (M,), 'emg' (K,), 'fs_gyro', 'fs_piezo', 'fs_emg',
             'clinical_factors' (dict), 'image_features' (dict))
    Returns: dict of all features (gait + piezo + emg + clinical + image), flat, ready for a DataFrame row.
    """
    gait_feats = extract_gait_features(record["gyro"], fs=record.get("fs_gyro", GYRO_FS_DEFAULT))
    piezo_feats = extract_piezo_features(record["piezo"], fs=record.get("fs_piezo", PIEZO_FS_DEFAULT))
    emg_feats = extract_emg_features(record["emg"], fs=record.get("fs_emg", EMG_FS_DEFAULT))

    accel = record.get("accel", np.zeros((0, 3)))
    accel_feats = extract_accel_features(accel, fs=record.get("fs_accel", GYRO_FS_DEFAULT))

    # Get clinical factors (already encoded)
    clinical_feats = record.get("clinical_factors", {})

    # Get image features (already extracted)
    image_feats = record.get("image_features", {})

    # Prefix clinical and image features to avoid name collisions
    clinical_feats_prefixed = {f"clinical_{k}": v for k, v in clinical_feats.items()}
    image_feats_prefixed = {f"image_{k}": v for k, v in image_feats.items()}

    all_feats = {**gait_feats, **piezo_feats, **emg_feats, **accel_feats, **clinical_feats_prefixed, **image_feats_prefixed}
    return all_feats


if __name__ == "__main__":
    from simulate_data import simulate_subject  # type: ignore
    rec0 = simulate_subject(label=0, seed=1)
    rec1 = simulate_subject(label=1, seed=2)
    f0 = extract_features(rec0)
    f1 = extract_features(rec1)
    print("Healthy sample features:")
    for k, v in f0.items():
        print(f"  {k}: {v:.4f}")
    print("\nOA-risk sample features:")
    for k, v in f1.items():
        print(f"  {k}: {v:.4f}")
