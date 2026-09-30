"""
train_improved_2class_model.py
-------------------------------
Improved 2-class model with better uncertainty estimation.
"""

import numpy as np
import pandas as pd
import joblib
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from scipy.special import softmax
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
            nll = -np.mean(np.log(probs[np.arange(len(labels)), labels] + 1e-10))
            return nll
        
        result = opt.minimize_scalar(loss, bounds=(0.1, 10.0), method='bounded')
        self.temperature = result.x
        logger.info(f"Optimal temperature: {self.temperature:.4f}")
    
    def transform(self, logits):
        """Apply temperature scaling."""
        return logits / self.temperature
    
    def calibrate(self, probs):
        """Calibrate probabilities using temperature."""
        logits = np.log(probs + 1e-10)
        scaled_logits = self.transform(logits)
        return softmax(scaled_logits, axis=1)


def train_improved_2class_model():
    """Train improved 2-class model with uncertainty."""
    
    logger.info("Starting improved 2-class model training...")
    
    # Generate improved dataset
    logger.info("Generating improved synthetic dataset...")
    generator = ImprovedDataGenerator(noise_level=0.15, uncertainty_level=0.2)
    
    # Generate more data for better separation
    healthy_samples = generator.generate_dataset(n_samples_per_class=0, duration_s=6.0)
    low_risk_samples = []
    high_risk_samples = []
    
    # Generate separate samples for each class
    for _ in range(150):
        low_risk_samples.append(generator.generate_subject(1, seed=np.random.randint(1000, 2000)))
    
    for _ in range(150):
        high_risk_samples.append(generator.generate_subject(2, seed=np.random.randint(2000, 3000)))
    
    for _ in range(150):
        healthy_samples.append(generator.generate_subject(0, seed=np.random.randint(0, 1000)))
    
    # Combine OA-risk classes (Low Risk + High Risk = OA-Risk)
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
    logger.info("Extracting features...")
    extractor = ImprovedFeatureExtractor()
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
    
    # Further split for temperature scaling
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
    
    # Train model with class weights
    logger.info("Training model with class weights...")
    class_weights = {0: 1.0, 1: 1.5}  # Give more weight to OA-Risk class
    
    model = RandomForestClassifier(
        n_estimators=300,
        max_depth=8,
        min_samples_leaf=4,
        random_state=42,
        class_weight='balanced'
    )
    
    model.fit(X_train_scaled, y_train_main)
    
    # Predict on validation set for temperature scaling
    val_probs = model.predict_proba(X_val_scaled)
    
    # Apply temperature scaling
    logger.info("Applying temperature scaling...")
    temp_scaler = TemperatureScaler()
    val_logits = np.log(val_probs + 1e-10)
    temp_scaler.fit(val_logits, y_val)
    
    # Calibrate probabilities
    val_probs_calibrated = temp_scaler.calibrate(val_probs)
    
    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_probs = model.predict_proba(X_test_scaled)
    test_probs_calibrated = temp_scaler.calibrate(test_probs)
    test_preds = np.argmax(test_probs_calibrated, axis=1)
    
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
        roc_auc = roc_auc_score(y_test, test_probs_calibrated[:, 1])
        logger.info(f"ROC-AUC: {roc_auc:.4f}")
    
    # Show probability distribution
    logger.info("\nProbability Distribution (OA-Risk class):")
    oa_risk_probs = test_probs_calibrated[y_test == 1, 1]
    healthy_probs = test_probs_calibrated[y_test == 0, 1]
    
    logger.info(f"OA-Risk samples - Mean prob: {np.mean(oa_risk_probs):.4f}, Std: {np.std(oa_risk_probs):.4f}")
    logger.info(f"Healthy samples - Mean prob: {np.mean(healthy_probs):.4f}, Std: {np.std(healthy_probs):.4f}")
    
    # Save model
    logger.info("Saving improved model...")
    joblib.dump(model, 'models/improved_2class_model.joblib')
    joblib.dump(scaler, 'models/improved_2class_scaler.joblib')
    joblib.dump(temp_scaler, 'models/improved_2class_temp_scaler.joblib')
    
    # Save feature names
    with open('models/improved_2class_feature_columns.json', 'w') as f:
        json.dump(feature_names, f, indent=2)
    
    # Save metadata
    metadata = {
        'model_type': 'improved_2class',
        'temperature': float(temp_scaler.temperature),
        'n_classes': 2,
        'class_names': ['healthy', 'oa_risk'],
        'n_features': len(feature_names),
        'accuracy': float(accuracy),
        'roc_auc': float(roc_auc) if len(np.unique(y_test)) > 1 else 0.0
    }
    
    with open('models/improved_2class_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    logger.info("Training completed successfully!")
    
    return model, scaler, temp_scaler, feature_names


def main():
    """Main training function."""
    try:
        model, scaler, temp_scaler, feature_names = train_improved_2class_model()
        logger.info("✅ Improved 2-class model training completed successfully!")
    except Exception as e:
        logger.error(f"❌ Training failed: {e}")
        raise


if __name__ == "__main__":
    main()
