"""
improved_feature_extraction.py
-----------------------------
Improved feature extraction for 3-class model with uncertainty.
"""

import numpy as np
from scipy import signal
from scipy.stats import entropy, skew, kurtosis
import sys
sys.path.append("wearable_model")
from wearable_model.clinical_factors import (
    encode_pain_level, encode_stiffness_duration, encode_swelling,
    encode_past_injury, encode_mri_kl_grade
)

class ImprovedFeatureExtractor:
    def __init__(self):
        self.feature_names = []
    
    def extract_gyro_features(self, gyro_data):
        """Extract comprehensive gait features from gyroscope data."""
        flexion = gyro_data['flexion']
        abduction = gyro_data['abduction']
        rotation = gyro_data['rotation']
        
        features = {}
        
        # Time-domain features
        for name, data in [('flex', flexion), ('abd', abduction), ('rot', rotation)]:
            features[f'gyro_{name}_rms'] = np.sqrt(np.mean(data**2))
            features[f'gyro_{name}_mean'] = np.mean(data)
            features[f'gyro_{name}_std'] = np.std(data)
            features[f'gyro_{name}_max'] = np.max(data)
            features[f'gyro_{name}_min'] = np.min(data)
            features[f'gyro_{name}_range'] = np.max(data) - np.min(data)
            features[f'gyro_{name}_skew'] = skew(data)
            features[f'gyro_{name}_kurtosis'] = kurtosis(data)
        
        # Frequency-domain features
        for name, data in [('flex', flexion), ('abd', abduction), ('rot', rotation)]:
            freqs, psd = signal.welch(data, fs=50, nperseg=256)
            features[f'gyro_{name}_dominant_freq'] = freqs[np.argmax(psd)]
            features[f'gyro_{name}_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
            features[f'gyro_{name}_spectral_entropy'] = entropy(psd + 1e-10)
            features[f'gyro_{name}_total_power'] = np.sum(psd)
        
        # Gait-specific features
        # Stride detection (zero-crossing based)
        zero_crossings = np.where(np.diff(np.sign(flexion)))[0]
        if len(zero_crossings) > 1:
            stride_intervals = np.diff(zero_crossings) / 50.0  # Convert to seconds
            features['cadence_hz'] = 1.0 / np.mean(stride_intervals)
            features['stride_time_mean'] = np.mean(stride_intervals)
            features['stride_time_std'] = np.std(stride_intervals)
            features['stride_regularity'] = 1.0 - (np.std(stride_intervals) / np.mean(stride_intervals))
        else:
            features['cadence_hz'] = 1.2  # Default value
            features['stride_time_mean'] = 0.83
            features['stride_time_std'] = 0.1
            features['stride_regularity'] = 0.9
        
        # Gait smoothness (jerk)
        flexion_jerk = np.diff(flexion, n=2)
        features['gait_smoothness'] = np.sqrt(np.mean(flexion_jerk**2))
        
        # Symmetry
        features['symmetry_ratio'] = np.std(flexion) / (np.mean(np.abs(flexion)) + 1e-10)
        
        return features
    
    def extract_piezo_features(self, piezo_data):
        """Extract VAG (vibration) features from piezo data."""
        features = {}
        
        # Time-domain features
        features['piezo_rms'] = np.sqrt(np.mean(piezo_data**2))
        features['piezo_mean'] = np.mean(piezo_data)
        features['piezo_std'] = np.std(piezo_data)
        features['piezo_max'] = np.max(piezo_data)
        features['piezo_min'] = np.min(piezo_data)
        features['piezo_skew'] = skew(piezo_data)
        features['piezo_kurtosis'] = kurtosis(piezo_data)
        
        # Frequency-domain features
        freqs, psd = signal.welch(piezo_data, fs=50, nperseg=256)
        features['piezo_dominant_freq'] = freqs[np.argmax(psd)]
        features['piezo_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
        features['piezo_spectral_entropy'] = entropy(psd + 1e-10)
        
        # Band power features
        bands = [(0, 5), (5, 15), (15, 25)]
        for i, (low, high) in enumerate(bands):
            mask = (freqs >= low) & (freqs < high)
            features[f'piezo_band_{i}_power'] = np.sum(psd[mask])
        
        # Burst detection
        threshold = features['piezo_mean'] + 2 * features['piezo_std']
        bursts = piezo_data > threshold
        features['piezo_burst_count'] = np.sum(np.diff(bursts.astype(int)) == 1)
        features['piezo_burst_duration'] = np.sum(bursts) / 50.0
        
        # VAG-specific features
        features['piezo_total_power'] = np.sum(psd)
        features['piezo_low_freq_ratio'] = features['piezo_band_0_power'] / (features['piezo_total_power'] + 1e-10)
        
        return features
    
    def extract_emg_features(self, emg_data):
        """Extract muscle activity features from EMG data."""
        features = {}
        
        # Time-domain features
        features['emg_rms'] = np.sqrt(np.mean(emg_data**2))
        features['emg_mean'] = np.mean(emg_data)
        features['emg_std'] = np.std(emg_data)
        features['emg_max'] = np.max(emg_data)
        features['emg_min'] = np.min(emg_data)
        
        # Muscle activation metrics
        features['emg_mav'] = np.mean(np.abs(emg_data))  # Mean Absolute Value
        features['emg_iemg'] = np.sum(np.abs(emg_data))  # Integrated EMG
        features['emg_variance'] = np.var(emg_data)
        
        # Zero-crossing rate
        zero_crossings = np.where(np.diff(np.sign(emg_data)))[0]
        features['emg_zcr'] = len(zero_crossings) / len(emg_data)
        
        # Frequency-domain features
        freqs, psd = signal.welch(emg_data, fs=50, nperseg=256)
        features['emg_dominant_freq'] = freqs[np.argmax(psd)]
        features['emg_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
        features['emg_spectral_entropy'] = entropy(psd + 1e-10)
        features['emg_median_freq'] = freqs[np.where(np.cumsum(psd) >= np.sum(psd)/2)[0][0]]
        
        # Band power
        bands = [(0, 10), (10, 20), (20, 50)]
        for i, (low, high) in enumerate(bands):
            mask = (freqs >= low) & (freqs < high)
            features[f'emg_band_{i}_power'] = np.sum(psd[mask])
        
        # Muscle fatigue indicators (after band power is calculated)
        features['emg_high_low_ratio'] = features['emg_band_2_power'] / (features['emg_band_0_power'] + 1e-10)
        
        return features
    
    def extract_accel_features(self, accel_data):
        """Extract movement features from accelerometer data."""
        accel_x = accel_data['accel_x']
        accel_y = accel_data['accel_y']
        accel_z = accel_data['accel_z']
        
        features = {}
        
        # Magnitude
        accel_mag = np.sqrt(accel_x**2 + accel_y**2 + accel_z**2)
        
        # Time-domain features
        for name, data in [('x', accel_x), ('y', accel_y), ('z', accel_z), ('mag', accel_mag)]:
            features[f'accel_{name}_rms'] = np.sqrt(np.mean(data**2))
            features[f'accel_{name}_mean'] = np.mean(data)
            features[f'accel_{name}_std'] = np.std(data)
        
        # Step detection
        # Use acceleration magnitude peaks
        peaks, _ = signal.find_peaks(accel_mag, height=np.mean(accel_mag) + np.std(accel_mag))
        features['estimated_steps'] = len(peaks)
        
        if len(peaks) > 1:
            step_intervals = np.diff(peaks) / 50.0
            features['step_regularity'] = 1.0 - (np.std(step_intervals) / np.mean(step_intervals))
        else:
            features['step_regularity'] = accel_data.get('step_regularity', 0.8)
        
        # Postural stability
        features['postural_sway'] = np.std(accel_x) + np.std(accel_y)
        
        # Activity level
        features['activity_level'] = np.mean(np.abs(np.diff(accel_mag)))
        
        return features
    
    def extract_clinical_features(self, clinical_data):
        """Extract encoded clinical features."""
        features = {}
        
        # Encode clinical factors
        pain_encoded = encode_pain_level(clinical_data.get('pain_level', 0))
        stiffness_encoded = encode_stiffness_duration(clinical_data.get('stiffness_duration', 'none'))
        swelling_encoded = encode_swelling(clinical_data.get('swelling', False))
        injury_encoded = encode_past_injury(clinical_data.get('past_injury', False))
        kl_encoded = encode_mri_kl_grade(clinical_data.get('mri_kl_grade', 0))
        
        features.update(pain_encoded)
        features.update(stiffness_encoded)
        features.update(swelling_encoded)
        features.update(injury_encoded)
        features.update(kl_encoded)
        
        # Pain characteristics
        pain_chars = clinical_data.get('pain_characteristics', [])
        features['pain_sharp'] = 1 if 'sharp' in pain_chars else 0
        features['pain_dull'] = 1 if 'dull' in pain_chars else 0
        features['pain_aching'] = 1 if 'aching' in pain_chars else 0
        features['pain_throbbing'] = 1 if 'throbbing' in pain_chars else 0
        
        # Stiffness triggers
        triggers = clinical_data.get('stiffness_triggers', [])
        features['stiffness_morning'] = 1 if 'morning' in triggers else 0
        features['stiffness_after_sitting'] = 1 if 'after_sitting' in triggers else 0
        features['stiffness_after_activity'] = 1 if 'after_activity' in triggers else 0
        
        # Other symptoms
        symptoms = clinical_data.get('other_symptoms', [])
        features['symptom_warmth'] = 1 if 'warmth' in symptoms else 0
        features['symptom_redness'] = 1 if 'redness' in symptoms else 0
        features['symptom_clicking'] = 1 if 'clicking' in symptoms else 0
        features['symptom_grinding'] = 1 if 'grinding' in symptoms else 0
        features['symptom_locking'] = 1 if 'locking' in symptoms else 0
        features['symptom_giving_way'] = 1 if 'giving_way' in symptoms else 0
        
        # Functional difficulty
        func_diff = clinical_data.get('functional_difficulty', {})
        features['diff_standing'] = func_diff.get('standing', 0)
        features['diff_walking'] = func_diff.get('walking', 0)
        features['diff_stairs'] = func_diff.get('stairs', 0)
        features['diff_chores'] = func_diff.get('chores', 0)
        
        return features
    
    def extract_all_features(self, record):
        """Extract all features from a complete record."""
        features = {}
        
        # Sensor features
        gyro_features = self.extract_gyro_features(record['gyro'])
        piezo_features = self.extract_piezo_features(record['piezo'])
        emg_features = self.extract_emg_features(record['emg'])
        accel_features = self.extract_accel_features(record['accel'])
        
        # Clinical features
        clinical_features = self.extract_clinical_features(record['clinical_factors'])
        
        # Combine all features
        features.update(gyro_features)
        features.update(piezo_features)
        features.update(emg_features)
        features.update(accel_features)
        features.update(clinical_features)
        
        # Add label
        features['label'] = record['label']
        
        return features


def extract_features(record):
    """Convenience function for feature extraction."""
    extractor = ImprovedFeatureExtractor()
    return extractor.extract_all_features(record)


def main():
    """Test the improved feature extractor."""
    from improved_simulate_data import ImprovedDataGenerator
    
    print("Testing Improved Feature Extractor")
    print("=" * 60)
    
    generator = ImprovedDataGenerator()
    extractor = ImprovedFeatureExtractor()
    
    # Generate test data
    for class_label in range(3):
        print(f"\nClass: {generator.class_mapping[class_label]}")
        record = generator.generate_subject(class_label, seed=42)
        
        features = extractor.extract_all_features(record)
        
        print(f"Total features extracted: {len(features)}")
        print(f"Feature keys (first 10): {list(features.keys())[:10]}")
        
        # Show some key features
        print(f"Key features:")
        print(f"  Cadence: {features.get('cadence_hz', 0):.3f} Hz")
        print(f"  Stride Regularity: {features.get('stride_regularity', 0):.3f}")
        print(f"  Piezo RMS: {features.get('piezo_rms', 0):.4f}")
        print(f"  EMG RMS: {features.get('emg_rms', 0):.4f}")
        print(f"  Step Regularity: {features.get('step_regularity', 0):.3f}")
        print(f"  Pain Level: {features.get('pain_level', 0)}")
        print(f"  KL Grade: {features.get('mri_kl_grade', 0)}")


if __name__ == "__main__":
    main()
