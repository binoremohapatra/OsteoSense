"""
advanced_simulate_data.py
-------------------------
Advanced synthetic data generator with more realistic patterns and better class separation.
"""

import numpy as np
import json
from datetime import datetime
from scipy import signal

class AdvancedDataGenerator:
    def __init__(self, noise_level=0.2, uncertainty_level=0.25, augmentation_level=0.15):
        self.noise_level = noise_level
        self.uncertainty_level = uncertainty_level
        self.augmentation_level = augmentation_level
        self.class_names = ['healthy', 'low_risk', 'high_risk']
        self.class_mapping = {0: 'healthy', 1: 'low_risk', 2: 'high_risk'}
    
    def augment_signal(self, sig, augmentation_type='random'):
        """Apply data augmentation to signals."""
        if augmentation_type == 'random':
            aug_type = np.random.choice(['jitter', 'scaling', 'magnitude', 'time_warp'])
        else:
            aug_type = augmentation_type
        
        if aug_type == 'jitter':
            # Add small random noise
            noise = np.random.normal(0, self.augmentation_level * 0.1, sig.shape)
            return sig + noise
        elif aug_type == 'scaling':
            # Scale the signal
            scale = np.random.uniform(0.9, 1.1)
            return sig * scale
        elif aug_type == 'magnitude':
            # Change magnitude
            magnitude = np.random.uniform(0.8, 1.2)
            return sig * magnitude
        elif aug_type == 'time_warp':
            # Slight time distortion
            sig_len = len(sig)
            warped = np.interp(np.linspace(0, sig_len, sig_len + int(sig_len * 0.1)), 
                               np.arange(sig_len), sig)
            return warped[:sig_len]
        else:
            return sig
    
    def generate_realistic_gyro(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate more realistic gyroscope data with gait cycle variations."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        # Base gait parameters for different classes
        if class_label == 0:  # Healthy
            cadence = 1.2  # steps per second
            stride_length = 0.6  # meters
            variability = 0.08
            asymmetry = 0.05
            gait_smoothness = 0.95
        elif class_label == 1:  # Low Risk
            cadence = 1.0  # slightly slower
            stride_length = 0.55  # slightly shorter
            variability = 0.18  # more variable
            asymmetry = 0.15  # more asymmetric
            gait_smoothness = 0.75  # less smooth
        else:  # High Risk
            cadence = 0.8  # much slower
            stride_length = 0.45  # much shorter
            variability = 0.35  # highly variable
            asymmetry = 0.30  # highly asymmetric
            gait_smoothness = 0.50  # very rough
        
        # Generate gait cycles with realistic variations
        n_cycles = int(cadence * duration_s)
        cycle_duration = duration_s / n_cycles
        
        # Generate individual cycles with variations
        flexion = np.zeros(samples)
        abduction = np.zeros(samples)
        rotation = np.zeros(samples)
        
        for i in range(n_cycles):
            cycle_start = int(i * cycle_duration * sample_rate)
            cycle_end = int((i + 1) * cycle_duration * sample_rate)
            cycle_samples = cycle_end - cycle_start
            
            if cycle_samples <= 0:
                continue
            
            # Add cycle-to-cycle variability
            cycle_cadence = cadence * (1 + np.random.uniform(-variability, variability))
            cycle_asymmetry = asymmetry * (1 + np.random.uniform(-0.2, 0.2))
            
            t_cycle = np.linspace(0, cycle_duration, cycle_samples)
            
            # Base patterns with cycle variations
            flexion_cycle = 0.3 * np.sin(2 * np.pi * cycle_cadence * t_cycle)
            abduction_cycle = 0.15 * np.sin(2 * np.pi * cycle_cadence * t_cycle + np.pi/4) * (1 + cycle_asymmetry)
            rotation_cycle = 0.1 * np.sin(2 * np.pi * cycle_cadence * t_cycle + np.pi/2)
            
            # Add intra-cycle variations
            if class_label > 0:
                # Add tremor/irregularity for OA patients
                tremor_freq = np.random.uniform(8, 12)
                tremor_amplitude = 0.05 * class_label
                flexion_cycle += tremor_amplitude * np.sin(2 * np.pi * tremor_freq * t_cycle)
            
            # Smoothness factor
            if gait_smoothness < 0.8:
                # Add roughness
                roughness = (1 - gait_smoothness) * 0.1
                flexion_cycle += np.random.normal(0, roughness, cycle_samples)
            
            # Place in full signal
            flexion[cycle_start:cycle_end] = flexion_cycle
            abduction[cycle_start:cycle_end] = abduction_cycle
            rotation[cycle_start:cycle_end] = rotation_cycle
        
        # Add noise
        flexion += np.random.normal(0, self.noise_level * 0.05, samples)
        abduction += np.random.normal(0, self.noise_level * 0.03, samples)
        rotation += np.random.normal(0, self.noise_level * 0.02, samples)
        
        # Apply augmentation
        flexion = self.augment_signal(flexion)
        abduction = self.augment_signal(abduction)
        rotation = self.augment_signal(rotation)
        
        return {
            'flexion': flexion,
            'abduction': abduction,
            'rotation': rotation,
            'cadence': cadence,
            'variability': variability,
            'asymmetry': asymmetry,
            'gait_smoothness': gait_smoothness
        }
    
    def generate_realistic_piezo(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate more realistic VAG (vibration) data."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            base_amplitude = 0.015
            burst_amplitude = 0.03
            burst_frequency = 0.05  # Very rare
            dominant_freq = 5  # Hz
        elif class_label == 1:  # Low Risk
            base_amplitude = 0.08
            burst_amplitude = 0.12
            burst_frequency = 0.25  # More frequent
            dominant_freq = 8  # Hz
        else:  # High Risk
            base_amplitude = 0.15
            burst_amplitude = 0.25
            burst_frequency = 0.50  # Frequent
            dominant_freq = 12  # Hz
        
        # Base signal
        signal = base_amplitude * np.random.normal(0, 1, samples)
        
        # Add periodic components
        signal += burst_amplitude * np.sin(2 * np.pi * dominant_freq * t)
        
        # Add higher harmonics for OA
        if class_label > 0:
            for harmonic in [2, 3]:
                harmonic_freq = dominant_freq * harmonic
                harmonic_amp = burst_amplitude / harmonic
                signal += harmonic_amp * np.sin(2 * np.pi * harmonic_freq * t)
        
        # Add bursts
        n_bursts = int(burst_frequency * duration_s * 10)
        for _ in range(n_bursts):
            burst_start = np.random.randint(0, samples - 50)
            burst_length = np.random.randint(15, 40)
            burst_signal = np.random.normal(0, burst_amplitude, burst_length)
            signal[burst_start:burst_start+burst_length] += burst_signal
        
        # Add noise
        signal += np.random.normal(0, self.noise_level * 0.02, samples)
        
        # Apply augmentation
        signal = self.augment_signal(signal)
        
        return signal
    
    def generate_realistic_emg(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate more realistic EMG data with muscle activation patterns."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            base_activation = 0.12
            activation_variability = 0.05
            muscle_coactivation = 0.02
            fatigue_rate = 0.001
        elif class_label == 1:  # Low Risk
            base_activation = 0.35
            activation_variability = 0.12
            muscle_coactivation = 0.08
            fatigue_rate = 0.003
        else:  # High Risk
            base_activation = 0.55
            activation_variability = 0.20
            muscle_coactivation = 0.15
            fatigue_rate = 0.005
        
        # Generate muscle activation cycles
        n_cycles = int(duration_s * 1.2)  # Similar to gait
        cycle_duration = duration_s / n_cycles
        
        signal = np.zeros(samples)
        
        for i in range(n_cycles):
            cycle_start = int(i * cycle_duration * sample_rate)
            cycle_end = int((i + 1) * cycle_duration * sample_rate)
            cycle_samples = cycle_end - cycle_start
            
            if cycle_samples <= 0:
                continue
            
            t_cycle = np.linspace(0, cycle_duration, cycle_samples)
            
            # Muscle activation pattern (bell-shaped during stance phase)
            activation = base_activation * np.exp(-((t_cycle - cycle_duration/3)**2) / (2 * (cycle_duration/6)**2))
            
            # Add variability
            activation += np.random.normal(0, activation_variability, cycle_samples)
            
            # Add coactivation (abnormal muscle firing)
            if class_label > 0:
                coactivation = muscle_coactivation * np.random.normal(0, 1, cycle_samples)
                activation += coactivation
            
            # Add fatigue over time
            fatigue_factor = 1 - fatigue_rate * (i / n_cycles)
            activation *= fatigue_factor
            
            # Ensure non-negative
            activation = np.maximum(activation, 0)
            
            signal[cycle_start:cycle_end] = activation
        
        # Add continuous low-level activity
        signal += base_activation * 0.1 * np.random.normal(0, 1, samples)
        
        # Add noise
        signal += np.random.normal(0, self.noise_level * 0.03, samples)
        
        # Apply augmentation
        signal = self.augment_signal(signal)
        
        # Ensure non-negative
        signal = np.maximum(signal, 0)
        
        return signal
    
    def generate_realistic_accel(self, class_label, duration_s=6.0, sample_rate=50):
        """Generate more realistic accelerometer data with step detection."""
        samples = int(duration_s * sample_rate)
        t = np.linspace(0, duration_s, samples)
        
        if class_label == 0:  # Healthy
            step_force = 0.5
            step_regularity = 0.95
            step_duration = 0.5
            postural_stability = 0.95
        elif class_label == 1:  # Low Risk
            step_force = 0.6
            step_regularity = 0.75
            step_duration = 0.6
            postural_stability = 0.75
        else:  # High Risk
            step_force = 0.7
            step_regularity = 0.50
            step_duration = 0.8
            postural_stability = 0.50
        
        # Generate step pattern
        n_steps = int(duration_s / step_duration)
        step_interval = samples // n_steps
        
        accel_x = np.zeros(samples)
        accel_y = np.zeros(samples)
        accel_z = np.zeros(samples)
        
        for i in range(n_steps):
            step_start = i * step_interval
            step_center = step_start + step_interval // 2
            step_end = (i + 1) * step_interval
            
            if step_end >= samples:
                step_end = samples - 1
            
            # Step impact (impulse)
            impact_width = int(step_interval * 0.15)
            impact_start = max(0, step_center - impact_width // 2)
            impact_end = min(samples, step_center + impact_width // 2)
            
            # Add step variation
            step_variation = 1 + np.random.uniform(-0.2, 0.2) if class_label > 0 else 1
            
            accel_x[impact_start:impact_end] += step_force * step_variation * np.random.normal(0, 0.1, impact_end - impact_start)
            accel_y[impact_start:impact_end] += step_force * 0.6 * step_variation * np.random.normal(0, 0.1, impact_end - impact_start)
            accel_z[impact_start:impact_end] += step_force * 0.3 * step_variation * np.random.normal(0, 0.1, impact_end - impact_start)
        
        # Add continuous gravity
        accel_z += 0.2
        
        # Add postural sway
        sway_amplitude = (1 - postural_stability) * 0.2
        accel_x += sway_amplitude * np.sin(2 * np.pi * 0.5 * t)
        accel_y += sway_amplitude * np.sin(2 * np.pi * 0.5 * t + np.pi/4)
        
        # Add noise
        accel_x += np.random.normal(0, self.noise_level * 0.08, samples)
        accel_y += np.random.normal(0, self.noise_level * 0.06, samples)
        accel_z += np.random.normal(0, self.noise_level * 0.04, samples)
        
        # Apply augmentation
        accel_x = self.augment_signal(accel_x)
        accel_y = self.augment_signal(accel_y)
        accel_z = self.augment_signal(accel_z)
        
        return {
            'accel_x': accel_x,
            'accel_y': accel_y,
            'accel_z': accel_z,
            'step_regularity': step_regularity,
            'postural_stability': postural_stability
        }
    
    def generate_advanced_clinical_data(self, class_label):
        """Generate more detailed clinical data with realistic uncertainty."""
        
        # Base clinical values with better separation
        if class_label == 0:  # Healthy
            base_pain = np.random.randint(0, 1)  # Very low pain
            base_stiffness = 'none'
            base_swelling = False
            base_injury = np.random.choice([True, False], p=[0.02, 0.98])  # Very rare
            base_kl_grade = 0
            pain_frequency = 'never'
            activity_limitation = 'none'
            medication_use = False
        elif class_label == 1:  # Low Risk - More distinct
            base_pain = np.random.randint(2, 4)  # Moderate pain
            base_stiffness = np.random.choice(['30min-1h', '1h-2h'], p=[0.8, 0.2])
            base_swelling = np.random.choice([True, False], p=[0.7, 0.3])
            base_injury = np.random.choice([True, False], p=[0.6, 0.4])
            base_kl_grade = np.random.choice([1, 2], p=[0.7, 0.3])
            pain_frequency = np.random.choice(['daily', 'weekly'], p=[0.6, 0.4])
            activity_limitation = np.random.choice(['mild', 'moderate'], p=[0.7, 0.3])
            medication_use = np.random.choice([True, False], p=[0.4, 0.6])
        else:  # High Risk
            base_pain = np.random.randint(4, 6)  # High pain
            base_stiffness = np.random.choice(['1h-2h', '>2h'], p=[0.3, 0.7])
            base_swelling = np.random.choice([True, False], p=[0.95, 0.05])
            base_injury = np.random.choice([True, False], p=[0.85, 0.15])
            base_kl_grade = np.random.choice([3, 4], p=[0.7, 0.3])
            pain_frequency = 'daily'
            activity_limitation = np.random.choice(['moderate', 'severe'], p=[0.6, 0.4])
            medication_use = True
        
        # Add uncertainty
        pain = int(base_pain + np.random.uniform(-0.5, 0.5))
        pain = max(0, min(5, pain))
        
        # Uncertainty in categorical values
        if np.random.random() < self.uncertainty_level:
            stiffness_options = ['none', '30min-1h', '1h-2h', '>2h']
            # Allow one-step transitions
            current_idx = stiffness_options.index(base_stiffness)
            possible_indices = [max(0, current_idx - 1), min(len(stiffness_options) - 1, current_idx + 1)]
            stiffness = stiffness_options[np.random.choice(possible_indices)]
        else:
            stiffness = base_stiffness
        
        # Add clinical uncertainty
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
            'pain_frequency': pain_frequency,
            'activity_limitation': activity_limitation,
            'medication_use': medication_use,
            'pain_characteristics': self._generate_pain_characteristics(pain),
            'stiffness_triggers': self._generate_stiffness_triggers(stiffness),
            'other_symptoms': self._generate_other_symptoms(class_label),
            'functional_difficulty': self._generate_functional_difficulty(class_label),
            'duration_of_symptoms': self._generate_symptom_duration(class_label)
        }
    
    def _generate_pain_characteristics(self, pain_level):
        characteristics = []
        if pain_level > 0:
            possible = ['sharp', 'dull', 'aching', 'throbbing', 'burning', 'stabbing']
            n_chars = min(pain_level + 1, len(possible))
            characteristics.extend(np.random.choice(possible, size=n_chars, replace=False))
        return characteristics
    
    def _generate_stiffness_triggers(self, stiffness_duration):
        triggers = []
        if stiffness_duration != 'none':
            possible = ['morning', 'after_sitting', 'after_activity', 'cold_weather', 'humid_weather']
            n_triggers = np.random.randint(2, 4)
            triggers.extend(np.random.choice(possible, size=n_triggers, replace=False))
        return triggers
    
    def _generate_other_symptoms(self, class_label):
        symptoms = []
        possible = ['warmth', 'redness', 'tenderness', 'clicking', 'grinding', 'locking', 
                    'giving_way', 'instability', 'reduced_mobility', 'swelling']
        
        if class_label == 0:
            num_symptoms = np.random.randint(0, 1)
        elif class_label == 1:
            num_symptoms = np.random.randint(2, 4)
        else:
            num_symptoms = np.random.randint(4, 7)
        
        symptoms.extend(np.random.choice(possible, size=num_symptoms, replace=False))
        return symptoms
    
    def _generate_functional_difficulty(self, class_label):
        if class_label == 0:
            return {
                'standing': np.random.randint(0, 1),
                'walking': np.random.randint(0, 1),
                'stairs': np.random.randint(0, 1),
                'chores': np.random.randint(0, 1),
                'squatting': np.random.randint(0, 1)
            }
        elif class_label == 1:
            return {
                'standing': np.random.randint(0, 2),
                'walking': np.random.randint(0, 2),
                'stairs': np.random.randint(1, 3),
                'chores': np.random.randint(0, 2),
                'squatting': np.random.randint(1, 3)
            }
        else:
            return {
                'standing': np.random.randint(1, 3),
                'walking': np.random.randint(1, 3),
                'stairs': np.random.randint(2, 4),
                'chores': np.random.randint(1, 3),
                'squatting': np.random.randint(2, 4)
            }
    
    def _generate_symptom_duration(self, class_label):
        if class_label == 0:
            return np.random.choice(['none', '<1_month'], p=[0.9, 0.1])
        elif class_label == 1:
            return np.random.choice(['1-3_months', '3-6_months', '6-12_months'], p=[0.3, 0.4, 0.3])
        else:
            return np.random.choice(['6-12_months', '1-2_years', '>2_years'], p=[0.2, 0.4, 0.4])
    
    def generate_subject(self, class_label, duration_s=6.0, sample_rate=50, seed=None):
        """Generate complete subject data with advanced realism."""
        if seed is not None:
            np.random.seed(seed)
        
        # Generate sensor data
        gyro_data = self.generate_realistic_gyro(class_label, duration_s, sample_rate)
        piezo_data = self.generate_realistic_piezo(class_label, duration_s, sample_rate)
        emg_data = self.generate_realistic_emg(class_label, duration_s, sample_rate)
        accel_data = self.generate_realistic_accel(class_label, duration_s, sample_rate)
        
        # Generate clinical data
        clinical_data = self.generate_advanced_clinical_data(class_label)
        
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
                'augmentation_level': self.augmentation_level,
                'generated_at': datetime.now().isoformat()
            }
        }
        
        return record
    
    def generate_dataset(self, n_samples_per_class=200, duration_s=6.0, sample_rate=50):
        """Generate a complete dataset with balanced classes."""
        dataset = []
        
        for class_label in range(3):
            for i in range(n_samples_per_class):
                seed = class_label * 10000 + i
                record = self.generate_subject(class_label, duration_s, sample_rate, seed)
                dataset.append(record)
        
        # Shuffle dataset
        np.random.shuffle(dataset)
        
        return dataset


def main():
    """Test the advanced data generator."""
    generator = AdvancedDataGenerator(noise_level=0.2, uncertainty_level=0.25, augmentation_level=0.15)
    
    print("Testing Advanced Data Generator")
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
        print(f"    Pain Frequency: {record['clinical_factors']['pain_frequency']}")
        print(f"    Activity Limitation: {record['clinical_factors']['activity_limitation']}")
        
        print(f"  Sensor Statistics:")
        print(f"    Gait Cadence: {record['gyro']['cadence']:.3f} Hz")
        print(f"    Gait Variability: {record['gyro']['variability']:.3f}")
        print(f"    Gait Asymmetry: {record['gyro']['asymmetry']:.3f}")
        print(f"    Step Regularity: {record['accel']['step_regularity']:.3f}")
        print(f"    Postural Stability: {record['accel']['postural_stability']:.3f}")
        print(f"    Piezo RMS: {np.sqrt(np.mean(record['piezo']**2)):.4f}")
        print(f"    EMG Mean: {np.mean(record['emg']):.4f}")
    
    # Generate a full dataset
    print("\n" + "=" * 60)
    print("Generating Full Dataset...")
    dataset = generator.generate_dataset(n_samples_per_class=100)
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
