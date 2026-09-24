"""
advanced_feature_extraction.py
------------------------------
Advanced feature extraction with more comprehensive features.
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

class AdvancedFeatureExtractor:
    def __init__(self):
        self.feature_names = []
    
    def extract_advanced_gyro_features(self, gyro_data):
        """Extract advanced gait features."""
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
            features[f'gyro_{name}_median'] = np.median(data)
            features[f'gyro_{name}_iqr'] = np.percentile(data, 75) - np.percentile(data, 25)
        
        # Frequency-domain features
        for name, data in [('flex', flexion), ('abd', abduction), ('rot', rotation)]:
            freqs, psd = signal.welch(data, fs=50, nperseg=256)
            features[f'gyro_{name}_dominant_freq'] = freqs[np.argmax(psd)]
            features[f'gyro_{name}_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
            features[f'gyro_{name}_spectral_entropy'] = entropy(psd + 1e-10)
            features[f'gyro_{name}_spectral_rolloff'] = freqs[np.where(np.cumsum(psd) >= 0.85 * np.sum(psd))[0][0]]
            features[f'gyro_{name}_total_power'] = np.sum(psd)
            features[f'gyro_{name}_band_power_ratio'] = np.sum(psd[freqs < 10]) / np.sum(psd)
        
        # Gait-specific features
        zero_crossings = np.where(np.diff(np.sign(flexion)))[0]
        if len(zero_crossings) > 1:
            stride_intervals = np.diff(zero_crossings) / 50.0
            features['cadence_hz'] = 1.0 / np.mean(stride_intervals)
            features['stride_time_mean'] = np.mean(stride_intervals)
            features['stride_time_std'] = np.std(stride_intervals)
            features['stride_time_cv'] = np.std(stride_intervals) / np.mean(stride_intervals)
            features['stride_regularity'] = 1.0 - features['stride_time_cv']
        else:
            features['cadence_hz'] = gyro_data.get('cadence', 1.2)
            features['stride_time_mean'] = 0.83
            features['stride_time_std'] = 0.1
            features['stride_time_cv'] = 0.12
            features['stride_regularity'] = gyro_data.get('gait_smoothness', 0.9)
        
        # Gait smoothness
        flexion_jerk = np.diff(flexion, n=2)
        features['gait_smoothness'] = np.sqrt(np.mean(flexion_jerk**2))
        features['gait_smoothness_normalized'] = features['gait_smoothness'] / (np.mean(np.abs(flexion)) + 1e-10)
        
        # Symmetry
        features['symmetry_ratio'] = np.std(flexion) / (np.mean(np.abs(flexion)) + 1e-10)
        features['asymmetry_index'] = np.mean(np.abs(flexion - np.roll(flexion, 1)))
        
        # Advanced features from metadata
        features['gait_variability'] = gyro_data.get('variability', 0.1)
        features['gait_asymmetry'] = gyro_data.get('asymmetry', 0.05)
        features['gait_smoothness_meta'] = gyro_data.get('gait_smoothness', 0.95)
        
        # Cross-correlation between axes
        features['flex_abd_correlation'] = np.corrcoef(flexion, abduction)[0, 1]
        features['flex_rot_correlation'] = np.corrcoef(flexion, rotation)[0, 1]
        features['abd_rot_correlation'] = np.corrcoef(abduction, rotation)[0, 1]
        
        return features
    
    def extract_advanced_piezo_features(self, piezo_data):
        """Extract advanced VAG features."""
        features = {}
        
        # Time-domain features
        features['piezo_rms'] = np.sqrt(np.mean(piezo_data**2))
        features['piezo_mean'] = np.mean(piezo_data)
        features['piezo_std'] = np.std(piezo_data)
        features['piezo_max'] = np.max(piezo_data)
        features['piezo_min'] = np.min(piezo_data)
        features['piezo_skew'] = skew(piezo_data)
        features['piezo_kurtosis'] = kurtosis(piezo_data)
        features['piezo_median'] = np.median(piezo_data)
        features['piezo_iqr'] = np.percentile(piezo_data, 75) - np.percentile(piezo_data, 25)
        
        # Frequency-domain features
        freqs, psd = signal.welch(piezo_data, fs=50, nperseg=256)
        features['piezo_dominant_freq'] = freqs[np.argmax(psd)]
        features['piezo_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
        features['piezo_spectral_entropy'] = entropy(psd + 1e-10)
        features['piezo_spectral_rolloff'] = freqs[np.where(np.cumsum(psd) >= 0.85 * np.sum(psd))[0][0]]
        
        # Band power features
        bands = [(0, 5), (5, 15), (15, 25), (25, 50)]
        for i, (low, high) in enumerate(bands):
            mask = (freqs >= low) & (freqs < high)
            features[f'piezo_band_{i}_power'] = np.sum(psd[mask])
        
        # Burst detection
        threshold = features['piezo_mean'] + 2 * features['piezo_std']
        bursts = piezo_data > threshold
        features['piezo_burst_count'] = np.sum(np.diff(bursts.astype(int)) == 1)
        features['piezo_burst_duration'] = np.sum(bursts) / 50.0
        features['piezo_burst_mean_amplitude'] = np.mean(piezo_data[bursts]) if np.sum(bursts) > 0 else 0
        
        # VAG-specific features
        features['piezo_total_power'] = np.sum(psd)
        features['piezo_low_freq_ratio'] = features['piezo_band_0_power'] / (features['piezo_total_power'] + 1e-10)
        features['piezo_high_freq_ratio'] = features['piezo_band_3_power'] / (features['piezo_total_power'] + 1e-10)
        
        # Crest factor
        features['piezo_crest_factor'] = features['piezo_max'] / (features['piezo_rms'] + 1e-10)
        
        return features
    
    def extract_advanced_emg_features(self, emg_data):
        """Extract advanced EMG features."""
        features = {}
        
        # Time-domain features
        features['emg_rms'] = np.sqrt(np.mean(emg_data**2))
        features['emg_mean'] = np.mean(emg_data)
        features['emg_std'] = np.std(emg_data)
        features['emg_max'] = np.max(emg_data)
        features['emg_min'] = np.min(emg_data)
        features['emg_median'] = np.median(emg_data)
        features['emg_iqr'] = np.percentile(emg_data, 75) - np.percentile(emg_data, 25)
        
        # Muscle activation metrics
        features['emg_mav'] = np.mean(np.abs(emg_data))
        features['emg_iemg'] = np.sum(np.abs(emg_data))
        features['emg_variance'] = np.var(emg_data)
        features['emg_waveform_length'] = np.sum(np.abs(np.diff(emg_data)))
        
        # Zero-crossing rate
        zero_crossings = np.where(np.diff(np.sign(emg_data)))[0]
        features['emg_zcr'] = len(zero_crossings) / len(emg_data)
        
        # Slope sign changes
        slope_sign_changes = np.sum(np.diff(np.diff(np.sign(emg_data))) != 0)
        features['emg_ssc'] = slope_sign_changes / len(emg_data)
        
        # Frequency-domain features
        freqs, psd = signal.welch(emg_data, fs=50, nperseg=256)
        features['emg_dominant_freq'] = freqs[np.argmax(psd)]
        features['emg_spectral_centroid'] = np.sum(freqs * psd) / np.sum(psd)
        features['emg_spectral_entropy'] = entropy(psd + 1e-10)
        features['emg_spectral_rolloff'] = freqs[np.where(np.cumsum(psd) >= 0.85 * np.sum(psd))[0][0]]
        features['emg_median_freq'] = freqs[np.where(np.cumsum(psd) >= np.sum(psd)/2)[0][0]]
        
        # Band power
        bands = [(0, 10), (10, 20), (20, 50)]
        for i, (low, high) in enumerate(bands):
            mask = (freqs >= low) & (freqs < high)
            features[f'emg_band_{i}_power'] = np.sum(psd[mask])
        
        # Muscle fatigue indicators
        features['emg_high_low_ratio'] = features['emg_band_2_power'] / (features['emg_band_0_power'] + 1e-10)
        features['emg_muscle_balance'] = features['emg_band_1_power'] / (features['emg_band_0_power'] + 1e-10)
        
        # EMG envelope features
        analytic_signal = signal.hilbert(emg_data)
        envelope = np.abs(analytic_signal)
        features['emg_envelope_mean'] = np.mean(envelope)
        features['emg_envelope_std'] = np.std(envelope)
        
        return features
    
    def extract_advanced_accel_features(self, accel_data):
        """Extract advanced accelerometer features."""
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
            features[f'accel_{name}_max'] = np.max(data)
            features[f'accel_{name}_min'] = np.min(data)
            features[f'accel_{name}_skew'] = skew(data)
            features[f'accel_{name}_kurtosis'] = kurtosis(data)
        
        # Step detection
        peaks, _ = signal.find_peaks(accel_mag, height=np.mean(accel_mag) + np.std(accel_mag))
        features['estimated_steps'] = len(peaks)
        
        if len(peaks) > 1:
            step_intervals = np.diff(peaks) / 50.0
            features['step_regularity'] = 1.0 - (np.std(step_intervals) / np.mean(step_intervals))
            features['step_time_mean'] = np.mean(step_intervals)
            features['step_time_std'] = np.std(step_intervals)
        else:
            features['step_regularity'] = accel_data.get('step_regularity', 0.8)
            features['step_time_mean'] = 0.5
            features['step_time_std'] = 0.1
        
        # Postural stability
        features['postural_sway'] = np.std(accel_x) + np.std(accel_y)
        features['postural_stability'] = accel_data.get('postural_stability', 0.9)
        
        # Activity level
        features['activity_level'] = np.mean(np.abs(np.diff(accel_mag)))
        features['activity_intensity'] = np.sum(np.abs(np.diff(accel_mag)))
        
        # Dynamic range
        features['accel_dynamic_range'] = np.max(accel_mag) - np.min(accel_mag)
        
        # Harmonic motion
        features['accel_x_y_correlation'] = np.corrcoef(accel_x, accel_y)[0, 1]
        features['accel_x_z_correlation'] = np.corrcoef(accel_x, accel_z)[0, 1]
        features['accel_y_z_correlation'] = np.corrcoef(accel_y, accel_z)[0, 1]
        
        return features
    
    def extract_advanced_clinical_features(self, clinical_data):
        """Extract advanced clinical features."""
        features = {}
        
        # Encode standard clinical factors
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
        features['pain_burning'] = 1 if 'burning' in pain_chars else 0
        features['pain_stabbing'] = 1 if 'stabbing' in pain_chars else 0
        features['pain_n_characteristics'] = len(pain_chars)
        
        # Stiffness triggers
        triggers = clinical_data.get('stiffness_triggers', [])
        features['stiffness_morning'] = 1 if 'morning' in triggers else 0
        features['stiffness_after_sitting'] = 1 if 'after_sitting' in triggers else 0
        features['stiffness_after_activity'] = 1 if 'after_activity' in triggers else 0
        features['stiffness_cold_weather'] = 1 if 'cold_weather' in triggers else 0
        features['stiffness_n_triggers'] = len(triggers)
        
        # Other symptoms
        symptoms = clinical_data.get('other_symptoms', [])
        features['symptom_warmth'] = 1 if 'warmth' in symptoms else 0
        features['symptom_redness'] = 1 if 'redness' in symptoms else 0
        features['symptom_clicking'] = 1 if 'clicking' in symptoms else 0
        features['symptom_grinding'] = 1 if 'grinding' in symptoms else 0
        features['symptom_locking'] = 1 if 'locking' in symptoms else 0
        features['symptom_giving_way'] = 1 if 'giving_way' in symptoms else 0
        features['symptom_instability'] = 1 if 'instability' in symptoms else 0
        features['symptom_reduced_mobility'] = 1 if 'reduced_mobility' in symptoms else 0
        features['symptom_n_symptoms'] = len(symptoms)
        
        # Functional difficulty
        func_diff = clinical_data.get('functional_difficulty', {})
        features['diff_standing'] = func_diff.get('standing', 0)
        features['diff_walking'] = func_diff.get('walking', 0)
        features['diff_stairs'] = func_diff.get('stairs', 0)
        features['diff_chores'] = func_diff.get('chores', 0)
        features['diff_squatting'] = func_diff.get('squatting', 0)
        features['diff_total'] = sum(func_diff.values())
        
        # Advanced clinical features
        features['pain_frequency'] = self._encode_pain_frequency(clinical_data.get('pain_frequency', 'never'))
        features['activity_limitation'] = self._encode_activity_limitation(clinical_data.get('activity_limitation', 'none'))
        features['medication_use'] = 1 if clinical_data.get('medication_use', False) else 0
        features['symptom_duration'] = self._encode_symptom_duration(clinical_data.get('duration_of_symptoms', 'none'))
        
        return features
    
    def _encode_pain_frequency(self, frequency):
        encoding = {'never': 0, 'weekly': 1, 'daily': 2}
        return encoding.get(frequency, 0)
    
    def _encode_activity_limitation(self, limitation):
        encoding = {'none': 0, 'mild': 1, 'moderate': 2, 'severe': 3}
        return encoding.get(limitation, 0)
    
    def _encode_symptom_duration(self, duration):
        encoding = {'none': 0, '<1_month': 1, '1-3_months': 2, '3-6_months': 3, 
                    '6-12_months': 4, '1-2_years': 5, '>2_years': 6}
        return encoding.get(duration, 0)
    
    def extract_all_features(self, record):
        """Extract all advanced features."""
        features = {}
        
        # Sensor features
        gyro_features = self.extract_advanced_gyro_features(record['gyro'])
        piezo_features = self.extract_advanced_piezo_features(record['piezo'])
        emg_features = self.extract_advanced_emg_features(record['emg'])
        accel_features = self.extract_advanced_accel_features(record['accel'])
        
        # Clinical features
        clinical_features = self.extract_advanced_clinical_features(record['clinical_factors'])
        
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
    extractor = AdvancedFeatureExtractor()
    return extractor.extract_all_features(record)


def main():
    """Test the advanced feature extractor."""
    from advanced_simulate_data import AdvancedDataGenerator
    
    print("Testing Advanced Feature Extractor")
    print("=" * 60)
    
    generator = AdvancedDataGenerator()
    extractor = AdvancedFeatureExtractor()
    
    # Generate test data
    for class_label in range(3):
        print(f"\nClass: {generator.class_mapping[class_label]}")
        record = generator.generate_subject(class_label, seed=42)
        
        features = extractor.extract_all_features(record)
        
        print(f"Total features extracted: {len(features)}")
        print(f"Feature keys (first 15): {list(features.keys())[:15]}")
        
        # Show some key features
        print(f"Key features:")
        print(f"  Cadence: {features.get('cadence_hz', 0):.3f} Hz")
        print(f"  Stride Regularity: {features.get('stride_regularity', 0):.3f}")
        print(f"  Gait Variability: {features.get('gait_variability', 0):.3f}")
        print(f"  Gait Asymmetry: {features.get('gait_asymmetry', 0):.3f}")
        print(f"  Piezo RMS: {features.get('piezo_rms', 0):.4f}")
        print(f"  EMG RMS: {features.get('emg_rms', 0):.4f}")
        print(f"  Step Regularity: {features.get('step_regularity', 0):.3f}")
        print(f"  Postural Stability: {features.get('postural_stability', 0):.3f}")
        print(f"  Pain Level: {features.get('pain_level', 0)}")
        print(f"  KL Grade: {features.get('mri_kl_grade', 0)}")
        print(f"  Total Symptoms: {features.get('symptom_n_symptoms', 0)}")


if __name__ == "__main__":
    main()
