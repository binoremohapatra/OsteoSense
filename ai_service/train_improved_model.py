"""
train_improved_model.py
-----------------------
Improved model training with 3 classes, temperature scaling, and ensemble.
"""

import numpy as np
import pandas as pd
import joblib
import json
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from scipy.special import softmax
import os
import logging

from improved_simulate_data import ImprovedDataGenerator
from improved_feature_extraction import ImprovedFeatureExtractor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class TemperatureScaler:
    """Temperature scaling for probability calibration."""
    
    def __init__(self):
        self.temperature = 1.0
    
    def fit(self, logits, labels):
        """Learn optimal temperature using validation set."""
        import scipy.optimize as opt
        
        def loss(temp):
            scaled_logits = logits / temp
            probs = softmax(scaled_logits, axis=1)
            # Negative log likelihood
            nll = -np.mean(np.log(probs[np.arange(len(labels)), labels] + 1e-10))
            return nll
        
        # Optimize temperature
        result = opt.minimize_scalar(loss, bounds=(0.1, 10.0), method='bounded')
        self.temperature = result.x
        logger.info(f"Optimal temperature: {self.temperature:.4f}")
    
    def transform(self, logits):
        """Apply temperature scaling."""
        return logits / self.temperature
    
    def calibrate(self, probs):
        """Calibrate probabilities using temperature."""
        # Convert to logits
        logits = np.log(probs + 1e-10)
        # Apply temperature
        scaled_logits = self.transform(logits)
        # Convert back to probabilities
        return softmax(scaled_logits, axis=1)


class EnsembleModel:
    """Ensemble of multiple models for better uncertainty estimation."""
    
    def __init__(self, n_models=5):
        self.n_models = n_models
        self.models = []
        self.scalers = []
    
    def fit(self, X_train, y_train):
        """Train ensemble of models with bootstrap sampling."""
        logger.info(f"Training ensemble of {self.n_models} models...")
        
        for i in range(self.n_models):
            logger.info(f"Training model {i+1}/{self.n_models}...")
            
            # Bootstrap sampling
            indices = np.random.choice(len(X_train), size=len(X_train), replace=True)
            X_bootstrap = X_train[indices]
            y_bootstrap = y_train[indices]
            
            # Train model
            model = RandomForestClassifier(
                n_estimators=200,
                max_depth=8,
                min_samples_leaf=4,
                random_state=42 + i,
                class_weight='balanced'
            )
            
            model.fit(X_bootstrap, y_bootstrap)
            
            # Create scaler for this model
            scaler = StandardScaler()
            scaler.fit(X_bootstrap)
            
            self.models.append(model)
            self.scalers.append(scaler)
        
        logger.info("Ensemble training completed")
    
    def predict_proba(self, X):
        """Predict probabilities by averaging ensemble predictions."""
        all_probs = []
        
        for model, scaler in zip(self.models, self.scalers):
            X_scaled = scaler.transform(X)
            probs = model.predict_proba(X_scaled)
            all_probs.append(probs)
        
        # Average predictions
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


def train_improved_model():
    """Train improved model with all enhancements."""
    
    logger.info("Starting improved model training...")
    
    # Generate improved dataset
    logger.info("Generating improved synthetic dataset...")
    generator = ImprovedDataGenerator(noise_level=0.15, uncertainty_level=0.2)
    dataset = generator.generate_dataset(n_samples_per_class=150, duration_s=6.0)
    
    logger.info(f"Generated {len(dataset)} samples")
    
    # Extract features
    logger.info("Extracting features...")
    extractor = ImprovedFeatureExtractor()
    feature_records = [extractor.extract_all_features(record) for record in dataset]
    
    # Convert to DataFrame
    df = pd.DataFrame(feature_records)
    
    # Check if df is actually a DataFrame
    logger.info(f"Type of df: {type(df)}")
    logger.info(f"Columns: {df.columns.tolist()[:10]}")
    
    # Separate features and labels
    if 'label' in df.columns:
        X = df.drop(['label'], axis=1)
        y = df['label'].values
    else:
        # If label is not in columns, use the last column
        X = df.iloc[:, :-1]
        y = df.iloc[:, -1].values
    
    # Handle missing values
    X = X.fillna(0)
    
    # Get feature names
    if hasattr(X, 'columns'):
        feature_names = X.columns.tolist()
    else:
        feature_names = [f'feature_{i}' for i in range(X.shape[1])]
    
    logger.info(f"Total features: {len(feature_names)}")
    
    # Convert to numpy arrays if needed
    if hasattr(X, 'values'):
        X = X.values
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Further split training into train/validation for temperature scaling
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
    
    # Train ensemble model
    logger.info("Training ensemble model...")
    ensemble = EnsembleModel(n_models=5)
    ensemble.fit(X_train_main, y_train_main)
    
    # Predict on validation set for temperature scaling
    val_probs = ensemble.predict_proba(X_val_scaled)
    
    # Apply temperature scaling
    logger.info("Applying temperature scaling...")
    temp_scaler = TemperatureScaler()
    
    # Convert probabilities to logits for temperature scaling
    val_logits = np.log(val_probs + 1e-10)
    temp_scaler.fit(val_logits, y_val)
    
    # Calibrate validation probabilities
    val_probs_calibrated = temp_scaler.calibrate(val_probs)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = ensemble.predict_proba(X_test_scaled)
    test_probs_calibrated = temp_scaler.calibrate(test_probs)
    test_preds = np.argmax(test_probs_calibrated, axis=1)
    
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
    
    # Save ensemble model
    logger.info("Saving ensemble model...")
    joblib.dump(ensemble, 'models/improved_ensemble_model.joblib')
    joblib.dump(scaler, 'models/improved_scaler.joblib')
    joblib.dump(temp_scaler, 'models/temperature_scaler.joblib')
    
    # Save feature names
    with open('models/improved_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Train a single XGBoost-like model for TFLite conversion
    logger.info("Training single model for TFLite conversion...")
    single_model = GradientBoostingClassifier(
        n_estimators=100,
        max_depth=6,
        learning_rate=0.1,
        random_state=42
    )
    single_model.fit(X_train_scaled, y_train_main)
    
    # Save single model
    joblib.dump(single_model, 'models/improved_single_model.joblib')
    
    # Skip TFLite conversion for now (TensorFlow DLL issue)
    logger.info("Skipping TFLite conversion (TensorFlow DLL issue)")
    logger.info("To convert to TFLite later, run: python convert_to_tflite.py")
    
    logger.info("Training completed successfully!")
    
    return ensemble, scaler, temp_scaler, feature_names


def main():
    """Main training function."""
    try:
        ensemble, scaler, temp_scaler, feature_names = train_improved_model()
        logger.info("✅ Improved model training completed successfully!")
    except Exception as e:
        logger.error(f"❌ Training failed: {e}")
        raise


if __name__ == "__main__":
    main()
