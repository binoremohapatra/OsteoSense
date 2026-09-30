"""
train_3class_realistic_model.py
------------------------------
Train 3-class model with Healthy, Low Risk, High Risk with realistic accuracy.
"""

import numpy as np
import pandas as pd
import joblib
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix
import logging

from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class ThreeClassDataGenerator:
    """Generate 3-class data with overlap."""
    
    def __init__(self, noise_level=0.20, overlap_level=0.12, label_noise=0.03):
        self.noise_level = noise_level
        self.overlap_level = overlap_level
        self.label_noise = label_noise
    
    def generate_3class_dataset(self, n_samples_per_class=200):
        """Generate dataset with 3 classes."""
        generator = AdvancedDataGenerator(
            noise_level=self.noise_level, 
            uncertainty_level=0.25, 
            augmentation_level=0.2
        )
        
        dataset = []
        
        for class_label in [0, 1, 2]:  # Healthy, Low Risk, High Risk
            for i in range(n_samples_per_class):
                seed = class_label * 10000 + i + 5000
                
                # Generate with some overlap
                if np.random.random() < self.overlap_level:
                    # Generate from adjacent class
                    if class_label == 0:
                        # Healthy can overlap with Low Risk
                        record = generator.generate_subject(1, seed=seed)
                    elif class_label == 1:
                        # Low Risk can overlap with Healthy or High Risk
                        target = 0 if np.random.random() < 0.5 else 2
                        record = generator.generate_subject(target, seed=seed)
                    else:
                        # High Risk can overlap with Low Risk
                        record = generator.generate_subject(1, seed=seed)
                    record['label'] = class_label
                else:
                    record = generator.generate_subject(class_label, seed=seed)
                    record['label'] = class_label
                
                # Add label noise
                if np.random.random() < self.label_noise:
                    # Flip to adjacent class
                    if class_label == 0:
                        record['label'] = 1
                    elif class_label == 1:
                        record['label'] = 0 if np.random.random() < 0.5 else 2
                    else:
                        record['label'] = 1
                
                dataset.append(record)
        
        np.random.shuffle(dataset)
        return dataset


class ThreeClassEnsembleModel:
    """Ensemble for 3-class classification."""
    
    def __init__(self):
        self.models = []
        self.scalers = []
    
    def fit(self, X_train, y_train):
        """Train ensemble for 3 classes."""
        logger.info("Training 3-class ensemble...")
        
        # Model 1: RandomForest
        rf = RandomForestClassifier(
            n_estimators=250,
            max_depth=10,
            min_samples_leaf=5,
            min_samples_split=15,
            max_features='sqrt',
            random_state=42,
            class_weight='balanced',
            bootstrap=True,
            oob_score=True
        )
        
        # Model 2: GradientBoosting
        gb = GradientBoostingClassifier(
            n_estimators=200,
            max_depth=6,
            learning_rate=0.08,
            subsample=0.8,
            min_samples_leaf=6,
            random_state=123
        )
        
        # Train each model with separate scaler
        for model in [rf, gb]:
            scaler = StandardScaler()
            X_scaled = scaler.fit_transform(X_train)
            model.fit(X_scaled, y_train)
            
            self.models.append(model)
            self.scalers.append(scaler)
        
        logger.info(f"Trained {len(self.models)} 3-class models")
    
    def predict_proba(self, X):
        """Predict probabilities for 3 classes."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        # Weighted average
        avg_probs = np.mean(all_probs, axis=0)
        
        return avg_probs
    
    def predict(self, X):
        """Predict class labels (0=Healthy, 1=Low Risk, 2=High Risk)."""
        probs = self.predict_proba(X)
        return np.argmax(probs, axis=1)
    
    def predict_with_uncertainty(self, X):
        """Predict with uncertainty estimation."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        all_probs = np.array(all_probs)
        
        # Average predictions
        avg_probs = np.mean(all_probs, axis=0)
        
        # Calculate uncertainty
        uncertainty = np.std(all_probs, axis=0)
        overall_uncertainty = np.mean(uncertainty, axis=1)
        
        return avg_probs, overall_uncertainty


def train_3class_realistic_model():
    """Train 3-class model with realistic accuracy."""
    
    logger.info("Starting 3-class realistic model training...")
    logger.info("Classes: Healthy (0), Low Risk (1), High Risk (2)")
    
    # Generate 3-class dataset
    logger.info("Generating 3-class dataset with overlap...")
    three_class_gen = ThreeClassDataGenerator(
        noise_level=0.20, 
        overlap_level=0.12, 
        label_noise=0.03
    )
    
    dataset = three_class_gen.generate_3class_dataset(n_samples_per_class=200)
    
    logger.info(f"Generated {len(dataset)} samples")
    
    # Extract features
    logger.info("Extracting advanced features...")
    extractor = AdvancedFeatureExtractor()
    feature_records = [extractor.extract_all_features(record) for record in dataset]
    
    # Convert to DataFrame
    df = pd.DataFrame(feature_records)
    
    # Separate features and labels
    X = df.drop(['label'], axis=1)
    y = df['label'].values
    
    # Handle missing values
    X = X.fillna(0)
    
    # Get feature names
    feature_names = X.columns.tolist()
    logger.info(f"Total features: {len(feature_names)}")
    
    # Convert to numpy arrays
    X = X.values
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    logger.info(f"Train samples: {len(X_train)}")
    logger.info(f"Test samples: {len(X_test)}")
    
    # Check class distribution
    unique, counts = np.unique(y_train, return_counts=True)
    logger.info(f"Train class distribution: {dict(zip(unique, counts))}")
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train 3-class ensemble
    logger.info("Training 3-class ensemble...")
    ensemble = ThreeClassEnsembleModel()
    ensemble.fit(X_train, y_train)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = ensemble.predict_proba(X_test)
    test_preds = ensemble.predict(X_test)
    
    # Classification report
    class_names = ['Healthy', 'Low Risk', 'High Risk']
    logger.info("\nClassification Report:")
    print(classification_report(y_test, test_preds, target_names=class_names))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, test_preds)
    logger.info(f"\nConfusion Matrix:\n{cm}")
    
    # Calculate metrics
    accuracy = (test_preds == y_test).mean()
    logger.info(f"\nTest Accuracy: {accuracy:.4f}")
    
    # Probability analysis
    logger.info("\nProbability Distribution by Class:")
    for i, class_name in enumerate(class_names):
        class_probs = test_probs[y_test == i]
        if len(class_probs) > 0:
            logger.info(f"{class_name}: Mean={np.mean(class_probs[:, i]):.4f}, Std={np.std(class_probs[:, i]):.4f}")
    
    # Save 3-class ensemble model
    logger.info("Saving 3-class ensemble model...")
    joblib.dump(ensemble, 'models/3class_ensemble_model.joblib')
    joblib.dump(scaler, 'models/3class_scaler.joblib')
    
    # Save feature names
    with open('models/3class_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Save metadata
    metadata = {
        'model_type': '3class_ensemble',
        'n_classes': 3,
        'class_names': ['healthy', 'low_risk', 'high_risk'],
        'n_features': len(feature_names),
        'test_accuracy': float(accuracy),
        'n_models': len(ensemble.models),
        'model_names': ['3class_RF', '3class_GB'],
        'noise_level': 0.20,
        'overlap_level': 0.12,
        'label_noise': 0.03
    }
    
    with open('models/3class_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    logger.info("3-class model training completed successfully!")
    
    return ensemble, scaler, feature_names, accuracy


def main():
    """Main training function."""
    try:
        print("=" * 80)
        print("TRAINING 3-CLASS MODEL (Healthy, Low Risk, High Risk)")
        print("=" * 80)
        
        # Train 3-class model
        ensemble, scaler, feature_names, test_accuracy = train_3class_realistic_model()
        
        print("\n" + "=" * 80)
        print("3-CLASS MODEL TRAINING COMPLETED")
        print("=" * 80)
        
        print(f"Features: {len(feature_names)}")
        print(f"Classes: Healthy, Low Risk, High Risk")
        print(f"Ensemble Models: {len(ensemble.models)}")
        print(f"Test Accuracy: {test_accuracy*100:.1f}%")
        
        print("\nSaved Models:")
        print("  - models/3class_ensemble_model.joblib (Web)")
        print("  - models/3class_scaler.joblib")
        print("  - models/3class_feature_columns.json")
        print("  - models/3class_metadata.json")
        
        print("\nKey Features:")
        print("  - 3 classes: Healthy, Low Risk, High Risk")
        print("  - Class overlap in training data")
        print("  - Label noise (3% random flips)")
        print("  - Regularized models for realistic accuracy")
        print("  - Uncertainty estimation available")
        
    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise


if __name__ == "__main__":
    main()
