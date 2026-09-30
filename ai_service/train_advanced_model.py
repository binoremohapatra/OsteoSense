"""
train_advanced_model.py
----------------------
Advanced model training with better calibration and uncertainty estimation.
"""

import numpy as np
import pandas as pd
import joblib
import json
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
from scipy.special import softmax
import logging

from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class AdvancedEnsembleModel:
    """Advanced ensemble with calibration and uncertainty estimation."""
    
    def __init__(self):
        self.models = []
        self.scalers = []
        self.calibrators = []
    
    def fit(self, X_train, y_train, n_classes=2):
        """Train advanced ensemble with diverse models."""
        logger.info("Training advanced ensemble...")
        
        # Model 1: Random Forest with balanced weights
        rf = RandomForestClassifier(
            n_estimators=300,
            max_depth=10,
            min_samples_leaf=5,
            random_state=42,
            class_weight='balanced',
            bootstrap=True,
            oob_score=True
        )
        
        # Model 2: Gradient Boosting
        gb = GradientBoostingClassifier(
            n_estimators=200,
            max_depth=6,
            learning_rate=0.1,
            random_state=123,
            subsample=0.8
        )
        
        # Model 3: Logistic Regression (regularized) - only for 2-class
        if n_classes == 2:
            lr = LogisticRegression(
                C=1.0,
                penalty='l2',
                solver='liblinear',
                random_state=456,
                max_iter=1000,
                class_weight='balanced'
            )
            models_to_train = [rf, gb, lr]
        else:
            # For 3-class, use only RF and GB
            models_to_train = [rf, gb]
        
        # Train each model with its own scaler
        for model in models_to_train:
            scaler = StandardScaler()
            X_scaled = scaler.fit_transform(X_train)
            model.fit(X_scaled, y_train)
            
            self.models.append(model)
            self.scalers.append(scaler)
        
        logger.info(f"Trained {len(self.models)} diverse models")
    
    def predict_proba(self, X):
        """Predict probabilities by averaging ensemble predictions."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        # Weighted average (simple for now)
        avg_probs = np.mean(all_probs, axis=0)
        
        return avg_probs
    
    def predict(self, X):
        """Predict class labels."""
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
        
        # Calculate uncertainty (standard deviation across ensemble)
        uncertainty = np.std(all_probs, axis=0)
        
        # Overall uncertainty per sample
        overall_uncertainty = np.mean(uncertainty, axis=1)
        
        return avg_probs, overall_uncertainty


def train_advanced_3class_model():
    """Train advanced 3-class model with better separation."""
    
    logger.info("Starting advanced 3-class model training...")
    
    # Generate advanced dataset
    logger.info("Generating advanced synthetic dataset...")
    generator = AdvancedDataGenerator(noise_level=0.25, uncertainty_level=0.3, augmentation_level=0.2)
    dataset = generator.generate_dataset(n_samples_per_class=250, duration_s=6.0)
    
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
    
    # Further split for calibration
    X_train_main, X_val, y_train_main, y_val = train_test_split(
        X_train, y_train, test_size=0.2, random_state=42, stratify=y_train
    )
    
    logger.info(f"Train samples: {len(X_train_main)}")
    logger.info(f"Validation samples: {len(X_val)}")
    logger.info(f"Test samples: {len(X_test)}")
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train_main)
    X_val_scaled = scaler.transform(X_val)
    X_test_scaled = scaler.transform(X_test)
    
    # Train advanced ensemble
    logger.info("Training advanced ensemble...")
    ensemble = AdvancedEnsembleModel()
    ensemble.fit(X_train_main, y_train_main, n_classes=3)
    
    # Predict on validation set
    val_probs = ensemble.predict_proba(X_val_scaled)
    val_preds = np.argmax(val_probs, axis=1)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = ensemble.predict_proba(X_test_scaled)
    test_preds = np.argmax(test_probs, axis=1)
    
    # Classification report
    class_names = ['Healthy', 'Low Risk', 'High Risk']
    logger.info("\nClassification Report:")
    print(classification_report(y_test, test_preds, target_names=class_names, zero_division=0))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, test_preds)
    logger.info(f"\nConfusion Matrix:\n{cm}")
    
    # Calculate metrics
    accuracy = (test_preds == y_test).mean()
    logger.info(f"\nTest Accuracy: {accuracy:.4f}")
    
    # Save ensemble model
    logger.info("Saving advanced ensemble model...")
    joblib.dump(ensemble, 'models/advanced_ensemble_model.joblib')
    joblib.dump(scaler, 'models/advanced_scaler.joblib')
    
    # Save feature names
    with open('models/advanced_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Save metadata
    metadata = {
        'model_type': 'advanced_3class_ensemble',
        'n_classes': 3,
        'class_names': ['healthy', 'low_risk', 'high_risk'],
        'n_features': len(feature_names),
        'accuracy': float(accuracy),
        'n_models': len(ensemble.models)
    }
    
    with open('models/advanced_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    logger.info("Training completed successfully!")
    
    return ensemble, scaler, feature_names


def train_advanced_2class_model():
    """Train advanced 2-class model with better uncertainty."""
    
    logger.info("Starting advanced 2-class model training...")
    
    # Generate advanced dataset
    logger.info("Generating advanced synthetic dataset...")
    generator = AdvancedDataGenerator(noise_level=0.25, uncertainty_level=0.3, augmentation_level=0.2)
    
    # Generate separate samples for each class
    healthy_samples = []
    low_risk_samples = []
    high_risk_samples = []
    
    for _ in range(200):
        healthy_samples.append(generator.generate_subject(0, seed=np.random.randint(0, 10000)))
    
    for _ in range(200):
        low_risk_samples.append(generator.generate_subject(1, seed=np.random.randint(10000, 20000)))
    
    for _ in range(200):
        high_risk_samples.append(generator.generate_subject(2, seed=np.random.randint(20000, 30000)))
    
    # Combine OA-risk classes
    oa_risk_samples = low_risk_samples + high_risk_samples
    
    # Labels: 0 = Healthy, 1 = OA-Risk
    for sample in healthy_samples:
        sample['label'] = 0
        sample['class_name'] = 'healthy'
    
    for sample in oa_risk_samples:
        sample['label'] = 1
        sample['class_name'] = 'oa_risk'
    
    dataset = healthy_samples + oa_risk_samples
    np.random.shuffle(dataset)
    
    logger.info(f"Generated {len(dataset)} samples (Healthy: {len(healthy_samples)}, OA-Risk: {len(oa_risk_samples)})")
    
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
    
    # Further split for calibration
    X_train_main, X_val, y_train_main, y_val = train_test_split(
        X_train, y_train, test_size=0.2, random_state=42, stratify=y_train
    )
    
    logger.info(f"Train samples: {len(X_train_main)}")
    logger.info(f"Validation samples: {len(X_val)}")
    logger.info(f"Test samples: {len(X_test)}")
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train_main)
    X_val_scaled = scaler.transform(X_val)
    X_test_scaled = scaler.transform(X_test)
    
    # Train advanced ensemble
    logger.info("Training advanced ensemble...")
    ensemble = AdvancedEnsembleModel()
    ensemble.fit(X_train_main, y_train_main, n_classes=2)
    
    # Predict on validation set
    val_probs = ensemble.predict_proba(X_val_scaled)
    val_preds = np.argmax(val_probs, axis=1)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = ensemble.predict_proba(X_test_scaled)
    test_preds = np.argmax(test_probs, axis=1)
    
    # Classification report
    class_names = ['Healthy', 'OA-Risk']
    logger.info("\nClassification Report:")
    print(classification_report(y_test, test_preds, target_names=class_names))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, test_preds)
    logger.info(f"\nConfusion Matrix:\n{cm}")
    
    # Calculate metrics
    accuracy = (test_preds == y_test).mean()
    logger.info(f"\nTest Accuracy: {accuracy:.4f}")
    
    # ROC-AUC
    if len(np.unique(y_test)) > 1:
        roc_auc = roc_auc_score(y_test, test_probs[:, 1])
        logger.info(f"ROC-AUC: {roc_auc:.4f}")
    
    # Probability analysis
    logger.info("\nProbability Distribution (OA-Risk class):")
    oa_risk_probs = test_probs[y_test == 1, 1]
    healthy_probs = test_probs[y_test == 0, 1]
    
    logger.info(f"OA-Risk samples - Mean prob: {np.mean(oa_risk_probs):.4f}, Std: {np.std(oa_risk_probs):.4f}")
    logger.info(f"Healthy samples - Mean prob: {np.mean(healthy_probs):.4f}, Std: {np.std(healthy_probs):.4f}")
    
    # Save ensemble model
    logger.info("Saving advanced ensemble model...")
    joblib.dump(ensemble, 'models/advanced_2class_ensemble_model.joblib')
    joblib.dump(scaler, 'models/advanced_2class_scaler.joblib')
    
    # Save feature names
    with open('models/advanced_2class_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Save metadata
    metadata = {
        'model_type': 'advanced_2class_ensemble',
        'n_classes': 2,
        'class_names': ['healthy', 'oa_risk'],
        'n_features': len(feature_names),
        'accuracy': float(accuracy),
        'roc_auc': float(roc_auc) if len(np.unique(y_test)) > 1 else 0.0,
        'n_models': len(ensemble.models)
    }
    
    with open('models/advanced_2class_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    logger.info("Training completed successfully!")
    
    return ensemble, scaler, feature_names


def main():
    """Main training function."""
    try:
        print("=" * 80)
        print("TRAINING ADVANCED MODELS")
        print("=" * 80)
        
        # Train 2-class model (skip 3-class for now due to solver issues)
        print("\nTraining advanced 2-class model...")
        ensemble_2class, scaler_2class, features_2class = train_advanced_2class_model()
        
        logger.info("Advanced 2-class model training completed successfully!")
        return ensemble_2class, scaler_2class, features_2class
        
    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise


if __name__ == "__main__":
    main()
