import json
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import xgboost as xgb

from simulate_data import build_dataset
from feature_extraction import extract_features

def main():
    print("Simulating dataset...")
    records = build_dataset(n_per_class=1000, duration_s=6.0, seed=42)

    rows = []
    labels = []
    for rec in records:
        feats = extract_features(rec)
        rows.append(feats)
        labels.append(rec["label"])

    df = pd.DataFrame(rows)
    feature_cols = [c for c in df.columns]
    X = df.values
    y = labels

    print(f"Dataset shape: {X.shape}")

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s = scaler.transform(X_test)

    print("Training XGBoost (48 Features)...")
    model = xgb.XGBClassifier(
        n_estimators=200, max_depth=4, learning_rate=0.08,
        subsample=0.9, colsample_bytree=0.9, eval_metric="logloss",
        random_state=42
    )
    model.fit(X_train_s, y_train)

    joblib.dump(model, "models/oa_risk_model.joblib")
    joblib.dump(scaler, "models/scaler.joblib")
    with open("models/feature_columns.json", "w") as f:
        json.dump(feature_cols, f, indent=2)

    print("Successfully trained and exported XGBoost Multimodal Model!")

if __name__ == "__main__":
    main()
