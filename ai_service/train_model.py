"""
train_model.py
---------------
Builds the dataset (simulated for now), extracts features, trains several
classical ML classifiers, evaluates them with cross-validation, and saves
the best model + the scaler + feature list to disk for use in inference.py
(and eventually, the companion app's backend).

Run:
    python3 train_model.py
"""

import json
import numpy as np
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_auc_score, roc_curve
)
import xgboost as xgb
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from simulate_data import build_dataset
from feature_extraction import extract_features

MODEL_DIR = "models"
OUTPUT_DIR = "outputs"


def build_feature_dataframe(n_per_class=150, duration_s=6.0, seed=42):
    print(f"Simulating {n_per_class * 2} recordings ({n_per_class} per class)...")
    records = build_dataset(n_per_class=n_per_class, duration_s=duration_s, seed=seed)

    rows = []
    labels = []
    for rec in records:
        feats = extract_features(rec)
        rows.append(feats)
        labels.append(rec["label"])

    df = pd.DataFrame(rows)
    df["label"] = labels
    return df


def train_and_evaluate(df, random_state=42):
    feature_cols = [c for c in df.columns if c != "label"]
    X = df[feature_cols].values
    y = df["label"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=random_state
    )

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s = scaler.transform(X_test)

    models = {
        "logistic_regression": LogisticRegression(max_iter=1000, random_state=random_state),
        "random_forest": RandomForestClassifier(
            n_estimators=300, max_depth=6, min_samples_leaf=3, random_state=random_state
        ),
        "svm_rbf": SVC(kernel="rbf", C=2.0, probability=True, random_state=random_state),
        "xgboost": xgb.XGBClassifier(
            n_estimators=200, max_depth=4, learning_rate=0.08,
            subsample=0.9, colsample_bytree=0.9, eval_metric="logloss",
            random_state=random_state
        ),
    }

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=random_state)
    results = {}

    print("\n" + "=" * 60)
    print("5-FOLD CROSS-VALIDATION (on training split, ROC-AUC)")
    print("=" * 60)
    for name, model in models.items():
        scores = cross_val_score(model, X_train_s, y_train, cv=cv, scoring="roc_auc")
        results[name] = {"cv_auc_mean": scores.mean(), "cv_auc_std": scores.std()}
        print(f"{name:20s}  AUC = {scores.mean():.3f} +/- {scores.std():.3f}")

    # pick best by CV AUC
    best_name = max(results, key=lambda k: results[k]["cv_auc_mean"])
    best_model = models[best_name]
    print(f"\nBest model by CV: {best_name}")

    # fit on full training set, evaluate on held-out test set
    best_model.fit(X_train_s, y_train)
    y_pred = best_model.predict(X_test_s)
    y_proba = best_model.predict_proba(X_test_s)[:, 1]

    test_auc = roc_auc_score(y_test, y_proba)
    print("\n" + "=" * 60)
    print(f"HELD-OUT TEST SET RESULTS ({best_name})")
    print("=" * 60)
    print(f"Test ROC-AUC: {test_auc:.3f}\n")
    print(classification_report(y_test, y_pred, target_names=["healthy", "OA-risk"]))

    cm = confusion_matrix(y_test, y_pred)
    print("Confusion matrix:")
    print(cm)

    # feature importance (if available)
    importance_df = None
    if hasattr(best_model, "feature_importances_"):
        importance_df = pd.DataFrame({
            "feature": feature_cols,
            "importance": best_model.feature_importances_
        }).sort_values("importance", ascending=False)
        print("\nTop 10 most important features:")
        print(importance_df.head(10).to_string(index=False))

    # --- save plots ---
    fpr, tpr, _ = roc_curve(y_test, y_proba)
    plt.figure(figsize=(5, 5))
    plt.plot(fpr, tpr, label=f"{best_name} (AUC={test_auc:.3f})")
    plt.plot([0, 1], [0, 1], "k--", alpha=0.3)
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curve - OA Risk Classifier")
    plt.legend()
    plt.tight_layout()
    plt.savefig(f"{OUTPUT_DIR}/roc_curve.png", dpi=150)
    plt.close()

    plt.figure(figsize=(4, 4))
    plt.imshow(cm, cmap="Blues")
    plt.xticks([0, 1], ["healthy", "OA-risk"])
    plt.yticks([0, 1], ["healthy", "OA-risk"])
    for i in range(2):
        for j in range(2):
            plt.text(j, i, str(cm[i, j]), ha="center", va="center",
                      color="white" if cm[i, j] > cm.max() / 2 else "black")
    plt.xlabel("Predicted")
    plt.ylabel("Actual")
    plt.title("Confusion Matrix")
    plt.tight_layout()
    plt.savefig(f"{OUTPUT_DIR}/confusion_matrix.png", dpi=150)
    plt.close()

    if importance_df is not None:
        plt.figure(figsize=(6, 5))
        top = importance_df.head(12)
        plt.barh(top["feature"][::-1], top["importance"][::-1])
        plt.xlabel("Importance")
        plt.title("Top Feature Importances")
        plt.tight_layout()
        plt.savefig(f"{OUTPUT_DIR}/feature_importance.png", dpi=150)
        plt.close()

    # --- save model artifacts ---
    joblib.dump(best_model, f"{MODEL_DIR}/oa_risk_model.joblib")
    joblib.dump(scaler, f"{MODEL_DIR}/scaler.joblib")
    with open(f"{MODEL_DIR}/feature_columns.json", "w") as f:
        json.dump(feature_cols, f, indent=2)
    with open(f"{MODEL_DIR}/model_metadata.json", "w") as f:
        json.dump({
            "best_model": best_name,
            "cv_results": results,
            "test_auc": float(test_auc),
            "n_features": len(feature_cols),
            "n_train": len(X_train),
            "n_test": len(X_test),
            "note": "Trained on SYNTHETIC data. Re-train on real sensor data before clinical use."
        }, f, indent=2)

    print(f"\nSaved model -> {MODEL_DIR}/oa_risk_model.joblib")
    print(f"Saved scaler -> {MODEL_DIR}/scaler.joblib")
    print(f"Saved plots -> {OUTPUT_DIR}/")

    return best_model, scaler, feature_cols, results


if __name__ == "__main__":
    df = build_feature_dataframe(n_per_class=150, duration_s=6.0, seed=42)
    df.to_csv(f"{OUTPUT_DIR}/synthetic_feature_dataset.csv", index=False)
    print(f"Saved feature dataset -> {OUTPUT_DIR}/synthetic_feature_dataset.csv  (shape={df.shape})")
    train_and_evaluate(df)
