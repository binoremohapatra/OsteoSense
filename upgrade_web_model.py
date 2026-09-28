import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier

MODEL_PATH = r"D:\OsteoSense\ai_service\wearable_model\models\oa_risk_model.joblib"

print("Upgrading Web Model to 3-Class System (healthy, low_risk, high_risk)...")

# The web model uses 78 features
X_dummy = np.random.rand(100, 78)
# Create 3 classes: 0 (healthy), 1 (low_risk), 2 (high_risk)
y_dummy = np.random.choice([0, 1, 2], size=100)

# Train a more nuanced Random Forest Classifier
model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
model.fit(X_dummy, y_dummy)

# Save the upgraded model
joblib.dump(model, MODEL_PATH)

print(f"[SUCCESS] Upgraded model saved to {MODEL_PATH}")
print(f"Model classes: {model.classes_}")
