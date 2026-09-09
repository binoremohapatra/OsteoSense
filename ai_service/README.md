# OA Risk Classifier — SIH26004

ML pipeline that turns gyroscope-only gait data + piezo disc joint-sound
data into an early osteoarthritis risk score.

## Files

| File | Purpose |
|---|---|
| `simulate_data.py` | Generates **synthetic** sensor data (healthy vs OA-risk) so the pipeline can be built/tested before real data exists |
| `feature_extraction.py` | Turns raw gyro/piezo windows into ~34 hand-crafted gait + acoustic (VAG) features |
| `train_model.py` | Builds the dataset, trains 4 classifiers (Logistic Regression, Random Forest, SVM, XGBoost), cross-validates, saves the best one |
| `inference.py` | Loads the saved model and scores a new recording; includes a simple trend-tracking helper for multi-session monitoring |
| `models/` | Saved model, scaler, feature list, metadata (generated after running `train_model.py`) |
| `outputs/` | ROC curve, confusion matrix, feature importance plots, and the generated feature CSV |

## Quick start

```bash
pip install -r requirements.txt
python3 train_model.py      # simulates data, trains, saves model + plots
python3 inference.py        # loads the model, scores fresh simulated samples
```

## ⚠️ Read this before your demo — about the synthetic data

The cross-validation and test AUC you'll see are **1.000 (perfect)**. That is
**not a real result** — it happens because I built deterministic, cleanly
separable differences into the synthetic healthy vs OA-risk signals (e.g. OA
samples always get more jerk, more crepitus bursts). Real biological data is
messy, overlapping, and nowhere near this separable.

**Use this pipeline to show:**
- The full sensor → feature → model → risk-score → trend pipeline works end-to-end
- Which features you believe are clinically meaningful and why (see below)
- That your model comparison / evaluation methodology is sound

**Do NOT present the 1.000 AUC as a real accuracy claim.** If a judge asks
about it, the honest answer is: *"This is trained on synthetic data to
validate the pipeline architecture; real accuracy will be established once
we collect labeled data from our prototype / public VAG and gait datasets."*
That answer is stronger than fabricated confidence — it shows you know the
difference.

## Feature groups (what the model actually looks at)

**Gait (from gyro only — 3-axis angular velocity):**
- Cadence, stride time, stride-time variability (coefficient of variation)
- Jerk RMS per axis (movement smoothness — early OA correlates with rougher, less smooth movement)
- Gyro RMS/peak per axis (joint angular velocity)
- High-frequency-to-total-power ratio (smoothness index)
- Stride amplitude variability (asymmetry proxy)

**Acoustic / VAG (from piezo disc):**
- Band energy ratios: low (0-100Hz, soft tissue), mid (100-200Hz), crepitus band (200-800Hz), high (800-2000Hz)
- Spectral entropy (crepitus is broadband/noise-like → higher entropy)
- Dominant frequency, zero-crossing rate
- Transient burst count + burst energy ratio (discrete clicks/pops — the actual acoustic signature of crepitus)
- 6 log-mel-band energies (cheap MFCC substitute, no extra audio library dependency)

These map to features reported in real vibroarthrography (VAG) and OA gait
literature — worth citing in your report for credibility.

## How to plug in real data (the important part)

1. **Public datasets** — look for a VAG (vibroarthrography) dataset and a
   gait dataset (e.g. GaitRec-style) as a stopgap before you have your own
   prototype data. Match the shape: `gyro (N,3)`, `piezo (M,)`.
2. **Your own prototype data** — once the ESP32 rig is logging real
   sessions, write a loader that reads your CSV/log format into the same
   dict shape used by `simulate_subject()`:
   ```python
   record = {"gyro": gyro_array, "piezo": piezo_array,
             "fs_gyro": 100, "fs_piezo": 4000, "label": 0_or_1}
   ```
3. Everything downstream (`feature_extraction.py`, `train_model.py`,
   `inference.py`) works unchanged — only the data source changes.
4. **Labels are the hard part.** You almost certainly won't have clinical
   OA diagnoses to label with. Realistic options for a hackathon: self-reported
   joint pain/stiffness as a weak label, age/risk-factor-based proxy labels,
   or just demoing on public labeled datasets and being upfront that your
   own prototype data is unlabeled/exploratory at this stage.

## Model choice rationale (for your pitch)

Classical ML (not deep learning) because:
- Dataset will be small — a few dozen to a few hundred subjects at most, realistically
- Hand-crafted features are explainable to non-ML judges and clinicians
- Runs comfortably in the phone app or a lightweight backend, no GPU/edge inference needed
- Random Forest / XGBoost feature importances double as a "why" explanation for each risk score — useful for a health app where trust matters
