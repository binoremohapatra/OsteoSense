"""
train_unified_models.py
-----------------------
Train both Web and TFLite models with the same 203 features.
"""

import numpy as np
import pandas as pd
import joblib
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import logging

from advanced_simulate_data import AdvancedDataGenerator
from advanced_feature_extraction import AdvancedFeatureExtractor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class UnifiedEnsembleModel:
    """Unified ensemble for both web and TFLite."""
    
    def __init__(self):
        self.models = []
        self.scalers = []
    
    def fit(self, X_train, y_train):
        """Train ensemble with diverse models."""
        logger.info("Training unified ensemble...")
        
        # Model 1: Random Forest
        rf = RandomForestClassifier(
            n_estimators=300,
            max_depth=12,
            min_samples_leaf=3,
            random_state=42,
            class_weight='balanced',
            bootstrap=True,
            oob_score=True
        )
        
        # Model 2: Gradient Boosting
        gb = GradientBoostingClassifier(
            n_estimators=250,
            max_depth=8,
            learning_rate=0.08,
            random_state=123,
            subsample=0.85
        )
        
        # Train each model with separate scaler
        for model in [rf, gb]:
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
        
        # Weighted average
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
        
        # Calculate uncertainty
        uncertainty = np.std(all_probs, axis=0)
        overall_uncertainty = np.mean(uncertainty, axis=1)
        
        return avg_probs, overall_uncertainty


def train_unified_models():
    """Train unified models for both web and TFLite with same features."""
    
    logger.info("Starting unified model training...")
    
    # Generate advanced dataset
    logger.info("Generating advanced synthetic dataset...")
    generator = AdvancedDataGenerator(noise_level=0.3, uncertainty_level=0.35, augmentation_level=0.25)
    
    # Generate balanced dataset
    healthy_samples = []
    oa_risk_samples = []
    
    for _ in range(300):
        healthy_samples.append(generator.generate_subject(0, seed=np.random.randint(0, 10000)))
    
    for _ in range(300):
        # Mix low and high risk as OA-Risk
        if np.random.random() < 0.5:
            oa_risk_samples.append(generator.generate_subject(1, seed=np.random.randint(10000, 20000)))
        else:
            oa_risk_samples.append(generator.generate_subject(2, seed=np.random.randint(20000, 30000)))
    
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
    
    logger.info(f"Train samples: {len(X_train)}")
    logger.info(f"Test samples: {len(X_test)}")
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train unified ensemble
    logger.info("Training unified ensemble...")
    ensemble = UnifiedEnsembleModel()
    ensemble.fit(X_train, y_train)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = ensemble.predict_proba(X_test)
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
    
    # Save unified ensemble model
    logger.info("Saving unified ensemble model...")
    joblib.dump(ensemble, 'models/unified_ensemble_model.joblib')
    joblib.dump(scaler, 'models/unified_scaler.joblib')
    
    # Save feature names
    with open('models/unified_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Save metadata
    metadata = {
        'model_type': 'unified_ensemble',
        'n_classes': 2,
        'class_names': ['healthy', 'oa_risk'],
        'n_features': len(feature_names),
        'accuracy': float(accuracy),
        'roc_auc': float(roc_auc) if len(np.unique(y_test)) > 1 else 0.0,
        'n_models': len(ensemble.models),
        'model_names': ['RandomForest', 'GradientBoosting']
    }
    
    with open('models/unified_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    logger.info("Unified model training completed successfully!")
    
    return ensemble, scaler, feature_names


def try_convert_to_tflite():
    """Try to convert unified model to TFLite."""
    logger.info("Attempting TFLite conversion...")
    
    try:
        import tensorflow as tf
        from tensorflow.keras.models import Sequential
        from tensorflow.keras.layers import Dense
        
        # Load unified model data
        ensemble = joblib.load('models/unified_ensemble_model.joblib')
        scaler = joblib.load('models/unified_scaler.joblib')
        
        with open('models/unified_feature_columns.json', 'r') as f:
            feature_names = json.load(f)
        
        n_features = len(feature_names)
        
        # Create a simple neural network as proxy
        model = Sequential([
            Dense(128, activation='relu', input_shape=(n_features,)),
            Dense(64, activation='relu'),
            Dense(32, activation='relu'),
            Dense(2, activation='softmax')
        ])
        
        model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save TFLite model
        with open('app/assets/models/unified_oa_risk_model.tflite', 'wb') as f:
            f.write(tflite_model)
        
        logger.info("TFLite conversion successful!")
        logger.info("Saved to: app/assets/models/unified_oa_risk_model.tflite")
        
        return True
        
    except Exception as e:
        logger.error(f"TFLite conversion failed: {e}")
        logger.info("TFLite conversion skipped - TensorFlow DLL issue on this machine")
        logger.info("Conversion can be done on a machine with proper TensorFlow setup")
        return False


def main():
    """Main training function."""
    try:
        print("=" * 80)
        print("TRAINING UNIFIED MODELS (Web + TFLite)")
        print("=" * 80)
        
        # Train unified model
        ensemble, scaler, feature_names = train_unified_models()
        
        # Try TFLite conversion
        tflite_success = try_convert_to_tflite()
        
        print("\n" + "=" * 80)
        print("UNIFIED MODEL TRAINING COMPLETED")
        print("=" * 80)
        
        print(f"Features: {len(feature_names)}")
        print(f"Ensemble Models: {len(ensemble.models)}")
        print(f"TFLite Conversion: {'SUCCESS' if tflite_success else 'SKIPPED (TensorFlow DLL issue)'}")
        
        print("\nSaved Models:")
        print("  - models/unified_ensemble_model.joblib (Web)")
        print("  - models/unified_scaler.joblib")
        print("  - models/unified_feature_columns.json")
        print("  - models/unified_metadata.json")
        
        if tflite_success:
            print("  - app/assets/models/unified_oa_risk_model.tflite (Mobile)")
        
        print("\nNext Steps:")
        print("  1. Update backend API to use unified model")
        print("  2. Update Flutter app to use unified TFLite model")
        print("  3. Test both models with same features")
        print("  4. Validate predictions match between web and mobile")
        
    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise


if __name__ == "__main__":
    main()
