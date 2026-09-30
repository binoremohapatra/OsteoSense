"""
improved_simulate_data.py
-------------------------
Improved synthetic data generator with noise, uncertainty, and 3 classes.
"""

import numpy as np
import json
from datetime import datetime, timedelta

class ImprovedDataGenerator:
    def __init__(self, noise_level=0.1, uncertainty_level=0.15):
        self.noise_level = noise_level
        self.uncertainty_level = uncertainty_level
        self.class_names = ['healthy', 'low_risk', 'high_risk']
        self.class_mapping = {0: 'healthy', 1: 'low_risk', 2: 'high_risk'}

    def add_noise(self, signal, noise_type='gaussian'):
        """Add realistic noise to sensor signals."""
        if noise_type == 'gaussian':
            noise = np.random.normal(0, self.noise_level, signal.shape)
        elif noise_type == 'uniform':
            noise = np.random.uniform(-self.noise_level, self.noise_level, signal.shape)
        elif noise_type == 'impulse':
            noise = np.zeros_like(signal)
            impulse_indices = np.random.choice(len(signal), size=int(len(signal)*0.05), replace=False)
            noise[impulse_indices] = np.random.uniform(-self.noise_level*2, self.noise_level*2, len(impulse_indices))
        else:
            noise = np.zeros_like(signal)
        
        return signal + noise

    def add_uncertainty(self, value, uncertainty_range):
        """Add measurement uncertainty to clinical values."""
        uncertainty = np.random.uniform(-uncertainty_range, uncertainty_range)
        return value + uncertainty

    def generate_gyro_data(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate gyroscope data with realistic patterns."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        # Base patterns for different classes
        if class_label == 0:  # Healthy
            # Smooth, regular gait
            flexion = 0.3 * np.sin(2 * np.pi * 1.2 * t) + np.random.normal(0, 0.05, samples)
            abduction = 0.15 * np.sin(2 * np.pi * 1.2 * t + np.pi/4) + np.random.normal(0, 0.03, samples)
            rotation = 0.1 * np.sin(2 * np.pi * 1.2 * t + np.pi/2) + np.random.normal(0, 0.02, samples)
            variability = 0.1
        elif class_label == 1:  # Low Risk - Make more distinct from healthy
            # Moderately irregular gait - clearly different from healthy
            flexion = 0.4 * np.sin(2 * np.pi * 1.0 * t) + 0.08 * np.sin(2 * np.pi * 2.5 * t) + np.random.normal(0, 0.12, samples)
            abduction = 0.22 * np.sin(2 * np.pi * 1.0 * t + np.pi/3) + 0.06 * np.sin(2 * np.pi * 3.0 * t) + np.random.normal(0, 0.08, samples)
            rotation = 0.14 * np.sin(2 * np.pi * 1.0 * t + np.pi/2) + np.random.normal(0, 0.05, samples)
            variability = 0.3  # Higher variability than healthy
        else:  # High Risk
            # Irregular, asymmetric gait
            flexion = 0.45 * np.sin(2 * np.pi * 0.8 * t) + 0.12 * np.sin(2 * np.pi * 2.5 * t) + np.random.normal(0, 0.15, samples)
            abduction = 0.25 * np.sin(2 * np.pi * 0.8 * t + np.pi/3) + 0.1 * np.sin(2 * np.pi * 3.5 * t) + np.random.normal(0, 0.1, samples)
            rotation = 0.18 * np.sin(2 * np.pi * 0.8 * t + np.pi/2) + np.random.normal(0, 0.06, samples)
            variability = 0.45
        
        # Add noise
        flexion = self.add_noise(flexion)
        abduction = self.add_noise(abduction)
        rotation = self.add_noise(rotation)
        
        return {
            'flexion': flexion,
            'abduction': abduction,
            'rotation': rotation,
            'variability': variability
        }

    def generate_piezo_data(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate piezo (VAG) data with realistic patterns."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            # Low amplitude, minimal VAG
            signal = 0.02 * np.random.normal(0, 1, samples)
            burst_count = np.random.randint(0, 1)
        elif class_label == 1:  # Low Risk - Clear VAG signals
            # Moderate amplitude, clear VAG
            signal = 0.08 * np.random.normal(0, 1, samples) + 0.06 * np.sin(2 * np.pi * 4 * t)
            burst_count = np.random.randint(4, 8)  # More bursts than healthy
        else:  # High Risk
            # High amplitude, significant VAG
            signal = 0.12 * np.random.normal(0, 1, samples) + 0.1 * np.sin(2 * np.pi * 3 * t) + 0.08 * np.sin(2 * np.pi * 7 * t)
            burst_count = np.random.randint(8, 15)
        
        # Add bursts
        for _ in range(burst_count):
            burst_start = np.random.randint(0, samples - 50)
            burst_length = np.random.randint(10, 30)
            burst_amplitude = np.random.uniform(0.05, 0.15)
            signal[burst_start:burst_start+burst_length] += burst_amplitude * np.random.normal(0, 1, burst_length)
        
        # Add noise
        signal = self.add_noise(signal)
        
        return signal

    def generate_emg_data(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate EMG data with realistic patterns."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            # Normal muscle activation
            base_amplitude = 0.12
            activation_pattern = 0.08 * np.sin(2 * np.pi * 1.2 * t)
        elif class_label == 1:  # Low Risk - Elevated muscle activity
            # Moderately elevated muscle activity
            base_amplitude = 0.35
            activation_pattern = 0.2 * np.sin(2 * np.pi * 1.0 * t) + 0.08 * np.random.normal(0, 1, samples)
        else:  # High Risk
            # High muscle activity, poor control
            base_amplitude = 0.5
            activation_pattern = 0.25 * np.sin(2 * np.pi * 0.8 * t) + 0.12 * np.random.normal(0, 1, samples)
        
        signal = base_amplitude + activation_pattern + np.random.normal(0, 0.05, samples)
        
        # Add noise
        signal = self.add_noise(signal)
        
        # Ensure non-negative
        signal = np.maximum(signal, 0)
        
        return signal

    def generate_accel_data(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate accelerometer data with realistic patterns."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            # Regular stepping pattern
            accel_x = 0.5 * np.sin(2 * np.pi * 1.2 * t) + np.random.normal(0, 0.1, samples)
            accel_y = 0.3 * np.sin(2 * np.pi * 1.2 * t + np.pi/2) + np.random.normal(0, 0.08, samples)
            accel_z = 0.2 + 0.15 * np.sin(2 * np.pi * 1.2 * t + np.pi/4) + np.random.normal(0, 0.05, samples)
            step_regularity = 0.9
        elif class_label == 1:  # Low Risk - Irregular stepping
            # Moderately irregular stepping
            accel_x = 0.6 * np.sin(2 * np.pi * 1.0 * t) + 0.08 * np.sin(2 * np.pi * 2.8 * t) + np.random.normal(0, 0.14, samples)
            accel_y = 0.4 * np.sin(2 * np.pi * 1.0 * t + np.pi/2) + np.random.normal(0, 0.12, samples)
            accel_z = 0.28 + 0.2 * np.sin(2 * np.pi * 1.0 * t + np.pi/4) + np.random.normal(0, 0.1, samples)
            step_regularity = 0.65  # Lower regularity than healthy
        else:  # High Risk
            # Highly irregular stepping
            accel_x = 0.65 * np.sin(2 * np.pi * 0.8 * t) + 0.12 * np.sin(2 * np.pi * 2.5 * t) + np.random.normal(0, 0.16, samples)
            accel_y = 0.45 * np.sin(2 * np.pi * 0.8 * t + np.pi/2) + 0.1 * np.sin(2 * np.pi * 4.0 * t) + np.random.normal(0, 0.14, samples)
            accel_z = 0.35 + 0.22 * np.sin(2 * np.pi * 0.8 * t + np.pi/4) + np.random.normal(0, 0.12, samples)
            step_regularity = 0.45
        
        # Add noise
        accel_x = self.add_noise(accel_x)
        accel_y = self.add_noise(accel_y)
        accel_z = self.add_noise(accel_z)
        
        return {
            'accel_x': accel_x,
            'accel_y': accel_y,
            'accel_z': accel_z,
            'step_regularity': step_regularity
        }

    def generate_clinical_data(self, class_label):
        """Generate clinical questionnaire data with uncertainty."""
        
        # Base clinical values for each class
        if class_label == 0:  # Healthy
            base_pain = np.random.randint(0, 1)  # 0 or minimal pain
            base_stiffness = 'none'
            base_swelling = False
            base_injury = np.random.choice([True, False], p=[0.05, 0.95])  # Very rare injury
            base_kl_grade = 0
        elif class_label == 1:  # Low Risk - Make more distinct
            base_pain = np.random.randint(2, 4)  # Moderate pain (2-3)
            base_stiffness = np.random.choice(['30min-1h', '1h-2h'], p=[0.7, 0.3])  # Stiffness present
            base_swelling = np.random.choice([True, False], p=[0.6, 0.4])  # More likely swelling
            base_injury = np.random.choice([True, False], p=[0.5, 0.5])  # More likely injury
            base_kl_grade = np.random.choice([1, 2], p=[0.6, 0.4])  # Clear KL grade
        else:  # High Risk
            base_pain = np.random.randint(4, 6)  # High pain (4-5)
            base_stiffness = np.random.choice(['1h-2h', '>2h'], p=[0.3, 0.7])  # Significant stiffness
            base_swelling = np.random.choice([True, False], p=[0.9, 0.1])  # Very likely swelling
            base_injury = np.random.choice([True, False], p=[0.8, 0.2])  # Very likely injury
            base_kl_grade = np.random.choice([3, 4], p=[0.6, 0.4])  # High KL grade
        
        # Add uncertainty
        pain = int(self.add_uncertainty(base_pain, 0.5))
        pain = max(0, min(5, pain))  # Clamp to valid range
        
        # For categorical values, sometimes change with uncertainty
        if np.random.random() < self.uncertainty_level:
            if class_label == 1:
                stiffness = np.random.choice(['none', '30min-1h', '1h-2h'])
            else:
                stiffness = base_stiffness
        else:
            stiffness = base_stiffness
        
        # Add uncertainty to swelling
        if np.random.random() < self.uncertainty_level:
            swelling = not base_swelling
        else:
            swelling = base_swelling
        
        return {
            'pain_level': pain,
            'stiffness_duration': stiffness,
            'swelling': swelling,
            'past_injury': base_injury,
            'mri_kl_grade': base_kl_grade,
            'pain_characteristics': self._generate_pain_characteristics(pain),
            'stiffness_triggers': self._generate_stiffness_triggers(stiffness),
            'other_symptoms': self._generate_other_symptoms(class_label),
            'functional_difficulty': self._generate_functional_difficulty(class_label)
        }

    def _generate_pain_characteristics(self, pain_level):
        """Generate pain characteristics based on pain level."""
        characteristics = []
        if pain_level > 0:
            possible = ['sharp', 'dull', 'aching', 'throbbing']
            characteristics.extend(np.random.choice(possible, size=min(pain_level, len(possible)), replace=False))
        return characteristics

    def _generate_stiffness_triggers(self, stiffness_duration):
        """Generate stiffness triggers based on duration."""
        triggers = []
        if stiffness_duration != 'none':
            possible = ['morning', 'after_sitting', 'after_activity', 'cold_weather']
            triggers.extend(np.random.choice(possible, size=np.random.randint(1, 3), replace=False))
        return triggers

    def _generate_other_symptoms(self, class_label):
        """Generate other symptoms based on class."""
        symptoms = []
        possible = ['warmth', 'redness', 'tenderness', 'clicking', 'grinding', 'locking', 'giving_way']
        
        if class_label == 0:
            num_symptoms = np.random.randint(0, 1)
        elif class_label == 1:
            num_symptoms = np.random.randint(1, 3)
        else:
            num_symptoms = np.random.randint(2, 5)
        
        symptoms.extend(np.random.choice(possible, size=num_symptoms, replace=False))
        return symptoms

    def _generate_functional_difficulty(self, class_label):
        """Generate functional difficulty scores."""
        if class_label == 0:
            return {
                'standing': np.random.randint(0, 1),
                'walking': np.random.randint(0, 1),
                'stairs': np.random.randint(0, 1),
                'chores': np.random.randint(0, 1)
            }
        elif class_label == 1:
            return {
                'standing': np.random.randint(0, 2),
                'walking': np.random.randint(0, 2),
                'stairs': np.random.randint(1, 3),
                'chores': np.random.randint(0, 2)
            }
        else:
            return {
                'standing': np.random.randint(1, 3),
                'walking': np.random.randint(1, 3),
                'stairs': np.random.randint(2, 4),
                'chores': np.random.randint(1, 3)
            }

    def generate_subject(self, class_label, duration_s=6.0, sample_rate=50, seed=None):
        """Generate complete subject data with all modalities."""
        if seed is not None:
            np.random.seed(seed)
        
        # Generate sensor data
        gyro_data = self.generate_gyro_data(class_label, duration_s, sample_rate)
        piezo_data = self.generate_piezo_data(class_label, duration_s, sample_rate)
        emg_data = self.generate_emg_data(class_label, duration_s, sample_rate)
        accel_data = self.generate_accel_data(class_label, duration_s, sample_rate)
        
        # Generate clinical data
        clinical_data = self.generate_clinical_data(class_label)
        
        # Combine into record
        record = {
            'label': class_label,
            'class_name': self.class_mapping[class_label],
            'gyro': gyro_data,
            'piezo': piezo_data,
            'emg': emg_data,
            'accel': accel_data,
            'clinical_factors': clinical_data,
            'duration': duration_s,
            'sample_rate': sample_rate,
            'metadata': {
                'noise_level': self.noise_level,
                'uncertainty_level': self.uncertainty_level,
                'generated_at': datetime.now().isoformat()
            }
        }
        
        return record

    def generate_dataset(self, n_samples_per_class=100, duration_s=6.0, sample_rate=50):
        """Generate a complete dataset with balanced classes."""
        dataset = []
        
        for class_label in range(3):
            for i in range(n_samples_per_class):
                seed = class_label * 1000 + i
                record = self.generate_subject(class_label, duration_s, sample_rate, seed)
                dataset.append(record)
        
        # Shuffle dataset
        np.random.shuffle(dataset)
        
        return dataset


def main():
    """Test the improved data generator."""
    generator = ImprovedDataGenerator(noise_level=0.1, uncertainty_level=0.15)
    
    print("Testing Improved Data Generator")
    print("=" * 60)
    
    # Generate one sample from each class
    for class_label in range(3):
        print(f"\nClass: {generator.class_mapping[class_label]}")
        record = generator.generate_subject(class_label, seed=42)
        
        print(f"  Clinical Data:")
        print(f"    Pain Level: {record['clinical_factors']['pain_level']}")
        print(f"    Stiffness: {record['clinical_factors']['stiffness_duration']}")
        print(f"    Swelling: {record['clinical_factors']['swelling']}")
        print(f"    KL Grade: {record['clinical_factors']['mri_kl_grade']}")
        
        print(f"  Sensor Statistics:")
        print(f"    Gyro Variability: {record['gyro']['variability']:.3f}")
        print(f"    Accel Regularity: {record['accel']['step_regularity']:.3f}")
        print(f"    Piezo RMS: {np.sqrt(np.mean(record['piezo']**2)):.4f}")
        print(f"    EMG Mean: {np.mean(record['emg']):.4f}")
    
    # Generate a full dataset
    print("\n" + "=" * 60)
    print("Generating Full Dataset...")
    dataset = generator.generate_dataset(n_samples_per_class=50)
    print(f"Total samples: {len(dataset)}")
    
    # Count samples per class
    class_counts = {}
    for record in dataset:
        class_name = record['class_name']
        class_counts[class_name] = class_counts.get(class_name, 0) + 1
    
    print("Class distribution:")
    for class_name, count in class_counts.items():
        print(f"  {class_name}: {count}")


if __name__ == "__main__":
    main()
