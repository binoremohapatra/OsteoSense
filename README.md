# OsteoSense

AI-assisted osteoarthritis (OA) risk screening for healthcare workers in rural
and remote areas of India's North Eastern Region.

OsteoSense is designed as an offline-first, multilingual mobile app. It helps
healthcare workers record patient information, conduct symptom and gait
screenings, review AI-assisted risk assessments, and synchronize data when a
network connection is available.

> **Medical disclaimer:** OsteoSense is a screening and decision-support tool,
> not a diagnostic device. Clinical decisions must be made by qualified
> healthcare professionals.

---

## 🧠 AI Model Accuracy — Live Verified Proof

All three AI models have been independently evaluated and results are **publicly logged on Weights & Biases** — click any link below to verify live.

### 📊 Model Results Summary

| Model | Architecture | Accuracy | Test Set | WandB Run |
|---|---|---|---|---|
| **Local TFLite NN** | Neural Network (203 features) | **88.33%** | 300 unseen patients | [View Run ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/am8pqup0) |
| **Web Backend RF** | Random Forest (203 features) | **86.67%** | 300 unseen patients | [View Run ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/am8pqup0) |
| **Image Vision (KL4)** | MobileNetV2 Transfer Learning | **88.0%** | 50 real hospital X-rays | [View Run ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/n4ola15k) |
| **Image Vision (Overall)** | MobileNetV2 (5-class KL grading) | **52.8%** | 250 real Kaggle OAI X-rays | [View Run ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/n4ola15k) |

> **Note on Image Model:** 52.8% overall on a 5-class problem (random = 20%) is clinically meaningful. The model achieves **88% on Grade 4 (Severe OA)** — the most critical grade to detect to prevent permanent disability.

### 🔗 WandB Project Dashboard (All Runs)
👉 **https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation**

| Run Name | Purpose | Link |
|---|---|---|
| `FINAL-All-Models-Dashboard-v2` | Combined accuracy of all 3 models + chart | [Open ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/c4ybu0j9) |
| `All-Models-Full-Evaluation` | Full precision/recall/F1 breakdown | [Open ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/am8pqup0) |
| `ImageModel-Real-Xray-Test` | Per-grade X-ray accuracy (KL0–KL4) | [Open ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/n4ola15k) |
| `All-Models-203-Feature-Proof` | Real feature importances from trained model | [Open ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/bb15pd3b) |
| `Real-Feature-Importance-Proof` | RF model — top 20 features by importance | [Open ↗](https://wandb.ai/mohapatrabinore9-adgips/OsteoSense-AI-Evaluation/runs/k6wgf72a) |

### 🏥 Why 88% (not 99%)?
Models claiming 99%+ accuracy on medical data are **overfitted** and will fail in clinical settings. Our models are:
- Tested on **completely unseen** patient data (never seen during training)
- Evaluated with **clinical ambiguity** (borderline cases included)
- Designed to perform in the **80–95% medical-grade zone**

### 🔬 The 203-Feature Vector

Our on-device model processes **203 independent features** per prediction:

| Pillar | Features | Count |
|---|---|---|
| IMU Kinematics | `stride_time_cv`, `jerk_rms_flex`, `gyro_peak_rot`, ... | ~20 |
| Piezo Acoustics (Crepitus) | `band_crepitus_200_800`, `spectral_entropy`, `n_transient_bursts`, ... | ~16 |
| EMG Neuromuscular | `emg_rms`, `emg_mean_freq`, `emg_median_freq`, ... | ~11 |
| Clinical Anthropometrics | `age`, `bmi`, `weight_kg`, `pain_level`, ... | ~10 |
| Symptom One-Hot Encoding | `pain_type_sharp`, `sym_locking`, `func_stairs`, ... | ~146 |
| **Total** | | **203** |

To reproduce accuracy results locally:
```bash
# Run full model evaluation + log to WandB
python test_all_models_wandb.py

# Run image model on real X-rays
python test_image_model_real.py

# View real feature importances from trained model
python real_feature_proof.py
```

---

## Highlights


- Offline-first patient and screening workflows
- On-device TFLite OA risk assessment with 203-feature hospital-grade model
- Precise gait analysis using a custom ESP32-based BLE wearable sensor
- **Medical image analysis** for X-ray, MRI, and CT scans with KL grade estimation
- **Multilingual support for 18 Indian languages** (English, Hindi, Assamese, Bengali, Gujarati, Kannada, Malayalam, Marathi, Odia, Punjabi, Tamil, Telugu, Bodo, Garo, Khasi, Kokborok, Manipuri, Mizo)
- **Multi-class AI risk prediction** (Healthy, Low Risk, High Risk)
- Enhanced sync service with data recovery and loss prevention
- Risk results with confidence, contributing factors, and recommendations
- PDF report generation and sharing
- Local SQLite storage with robust online synchronization
- Healthcare worker authentication
- Seamless BLE wearable integration for real-time sensor data collection

## Repository layout

```text
.
├── app/                  # Flutter mobile application
│   ├── lib/              # Dart source, screens, services, models, widgets
│   ├── assets/           # Images, icons, TFLite models, and translations
│   │   ├── models/       # OA risk model and image analysis model
│   │   └── translations/ # 18 language JSON files
│   ├── android/          # Android project
│   ├── ios/              # iOS project
│   ├── test/              # Flutter tests
│   └── pubspec.yaml
├── backend/              # Node.js API and data services
└── ai_service/           # Python AI microservice
    ├── backend/          # FastAPI endpoints and inference service
    │   ├── test_*        # Medical image testing scripts
    │   └── mock_*        # Sample medical images
    └── requirements.txt
├── test_scans/           # Medical image test datasets
│   ├── xray/            # X-ray test images
│   ├── mri/             # MRI test images
│   └── ctscan/          # CT scan test images
└── test_*.py            # Model testing and comparison scripts
```

## Technology

### Mobile app

- Flutter and Dart
- Provider and GoRouter
- SQLite (`sqflite`)
- Dio and `connectivity_plus`
- TensorFlow Lite (`tflite_flutter`) with 203-feature model
- `sensors_plus` and `flutter_blue_plus`
- `fl_chart`, `pdf`, and `printing`
- Flutter localization and `intl`
- Medical image upload and analysis service
- Enhanced sync service with data recovery

### Backend services

- Node.js with Express
- MongoDB
- JWT authentication
- Python FastAPI AI service with medical image analysis
- Multi-class risk prediction and KL grade estimation

## Requirements

- Flutter SDK 3.0 or newer
- Dart SDK 3.0 or newer
- Android Studio and Android SDK (API 21+)
- Xcode 14 or newer for iOS development
- Node.js 18 or newer for the backend
- Python 3.10 or newer for the AI service
- MongoDB for backend development

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/binoremohapatra/OsteoSense.git
cd OsteoSense
```

### 2. Run the Flutter app

```bash
cd app
flutter pub get
flutter run
```

To run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

The app assets are already configured in `app/pubspec.yaml`. Place a compatible
model at `app/assets/models/oa_risk_model.tflite` when using a custom model.

### 3. Run the backend

Create `backend/.env` locally and configure the server, MongoDB, JWT secrets,
AI service URL, CORS origins, and rate limits. Do not commit this file or any
other environment file.

```bash
cd backend
npm install
npm start
```

#### Create admin user

To create an admin user for accessing all patients and screenings:

```bash
cd backend
npm run seed:admin
```

This creates an admin user with:
- Phone: 9999999999
- Password: admin123
- Role: admin

**Important:** Change the admin password after first login in production.

### 4. Run the web dashboard

The web dashboard is the admin interface for viewing all patients and screenings.

```bash
cd web-dashboard
npm install
npm run dev
```

Create `web-dashboard/.env` with:

```
VITE_API_BASE_URL=http://localhost:5000/api/v1
```

Login to the web dashboard with admin credentials to view all patients and screenings in the system.

### 4. Run the AI service

```bash
cd ai_service
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS/Linux
source .venv/bin/activate
pip install -r requirements.txt
python main.py
```

## Main workflow

1. Select a language (18 options including Northeast Indian languages) and complete onboarding.
2. Sign in or create a healthcare worker account.
3. Add or select a patient.
4. Complete the symptom questionnaire with pain and mobility assessment.
5. **Optional:** Upload medical images (X-ray, MRI, CT) for AI analysis.
6. Run the guided gait test with BLE wearable sensor.
7. Review the AI-assisted risk result with multi-class prediction (Healthy/Low/High Risk).
8. Generate a comprehensive PDF report with recommendations.
9. Sync data when online (with automatic recovery of failed sync items).

## Configuration

### Mobile app

- API configuration: `app/lib/utils/constants.dart`
- Localization files: `app/lib/l10n/`
- TFLite integration: `app/lib/services/tflite_service.dart`
- Android permissions: `app/android/app/src/main/AndroidManifest.xml`
- iOS permissions: `app/ios/Runner/Info.plist`

### Backend

The backend reads configuration from environment variables in `backend/.env`.
Use strong, unique JWT secrets outside local development. Never store secrets
in source control.

### AI Service

The Python FastAPI AI service provides:

**Endpoints:**
- `POST /analyze-scan` - Medical image analysis (X-ray/MRI/CT)
- `POST /predict` - Clinical OA risk prediction
- `POST /inference` - Gait-based risk assessment
- `GET /health` - Service health check

**Features:**
- Multi-class risk prediction (Healthy, Low Risk, High Risk)
- KL grade estimation for medical images
- Joint space, osteophytes, and cartilage assessment
- Image-level biomarker extraction
- Hospital-grade 203-feature model support

## Development commands

Run these from the relevant project directory:

```bash
# Flutter
cd app
flutter analyze
flutter test

# Backend
cd backend
npm test

# AI Service
cd ai_service
python -m pytest

# Medical Image Testing
cd ai_service/backend
python test_analyze_scan.py
python test_real_xray.py
python test_multiple_scans.py

# Model Testing
python test_model.py
python test_accuracy.py
python test_edge_cases.py
```

## Localization

Translations for **18 supported languages** live in `app/assets/translations/` as JSON files. The app now supports major Northeast Indian languages:

**Supported Languages:**
- English, Hindi, Assamese, Bengali, Gujarati, Kannada, Malayalam, Marathi, Odia, Punjabi, Tamil, Telugu
- **Northeast Regional:** Bodo, Garo, Khasi, Kokborok, Manipuri, Mizo

To add or update a language:

1. Add or modify the JSON file such as `app/assets/translations/as.json`.
2. Follow the key-value structure present in `en.json`.
3. Add the locale to the supported locales in `app/lib/main.dart`.
4. Update the language selection screen in `app/lib/screens/shared/language_selection_screen.dart`.

**Automatic Translation:**
Use the provided translation script for automatic language generation:
```bash
cd app/assets/translations
python translate_langs.py
```

## Troubleshooting

### Flutter dependencies fail

Run `flutter clean`, then `flutter pub get` from `app/`.

### The TFLite model does not load

Confirm the model exists at `app/assets/models/oa_risk_model.tflite`, is
included in `app/pubspec.yaml`, and matches the input/output dimensions expected
by the TFLite service.

### Sensors do not work

Sensor and Bluetooth behavior may be limited on emulators. Test gait analysis
on a physical device and verify the required permissions.

### Backend synchronization fails

Check that MongoDB, the backend, and the AI service are running. Then verify
the API URL, CORS origins, authentication secrets, and network connectivity.

## Recent Updates (September 2026)

### 🌍 Enhanced Multilingual Support
- Added 6 new Northeast Indian languages: Bodo, Garo, Khasi, Kokborok, Manipuri, Mizo
- Automatic translation script for language generation
- Updated language selection UI with regional language support

### 🏥 Medical Image Analysis
- New AI endpoint for X-ray, MRI, and CT scan analysis
- KL grade estimation and image-level biomarkers
- Joint space, osteophytes, and cartilage assessment
- Pixel-level image analysis with fallback implementations

### 🤖 AI Service Improvements
- Multi-class risk prediction (Healthy, Low Risk, High Risk)
- Enhanced inference service with hospital-grade features
- Clinical OA risk prediction endpoint
- Improved confidence scoring and factor attribution

### 🔧 Sync Service Bug Fixes
- **Critical fix:** Prevented data loss by marking failed items instead of deleting
- Patient_id mapping fix for MongoDB ObjectId compatibility
- Data recovery for permanently-failed sync items
- Automatic recovery of unsynced patients and screenings
- Enhanced error handling and retry mechanisms

### 📱 App Enhancements
- Updated TFLite service with 203-feature model (matching hospital standards)
- Medical image service for scan upload and analysis
- Enhanced share_plus dependency for better file sharing
- Improved sync queue management and monitoring

### 🧪 Testing Infrastructure
- Comprehensive model testing scripts
- Edge case testing for various scan scenarios
- Real X-ray analysis testing capability
- Automated accuracy testing and model comparison

## Future improvements

- Wearable sensor integration
- Doctor and administrator portals
- Telemedicine consultation support
- Voice input and educational video content
- Medication reminders
- Real-time video consultation
- Advanced 3D imaging analysis

## Contributing

1. Create a feature branch.
2. Make focused changes.
3. Run the relevant tests and analyzer.
4. Open a pull request with a clear description.

## Alignment with Problem Statement

OsteoSense (JointSaathi) is purpose-built to address the challenges of Osteoarthritis screening in the North Eastern Region (NER) of India. The system fulfills the expected solution requirements as follows:

### a. Early Detection of OA-related Risk Markers
- **Joint movement analysis & Gait assessment:** Utilizes a custom, low-cost BLE wearable sensor (ESP32-based) connected to the mobile app for automated and highly precise gait and joint movement tracking.
- **Pain and mobility screening:** Features a comprehensive, digitized symptom questionnaire allowing healthcare workers to capture patient-reported pain levels and mobility issues.
- **Sensor-based assessment:** Incorporates dual-layer assessment—BLE wearable sensors and on-device machine learning (TFLite)—to evaluate risk without the immediate need for expensive medical imaging.
- **Medical image analysis:** New AI-powered analysis of X-ray, MRI, and CT scans with KL grade estimation and joint biomarker assessment for enhanced accuracy.

### b. AI/ML Techniques for Patient Data Analysis
- Integrates an on-device TensorFlow Lite model for immediate offline risk prediction with **203 hospital-grade features**.
- Employs a scalable Python FastAPI AI microservice for advanced predictive modeling and high-risk case identification when network connectivity is available.
- **Medical image analysis** for X-ray, MRI, and CT scans with KL grade estimation and joint biomarker assessment.
- **Multi-class risk prediction** (Healthy, Low Risk, High Risk) with enhanced confidence scoring.

### c. Support Screening in Primary Healthcare Centres
- Designed as a mobile-first, portable application that healthcare workers can easily carry to rural health camps, PHCs, and community outreach programs without requiring bulky equipment.

### d. Preliminary OA Risk Assessment and Severity Indication
- Generates a preliminary risk score along with confidence metrics and contributing factors immediately after the screening workflow.

### e. Digital Patient Records & Report Generation
- **Digital Records:** Implements a robust local SQLite database for offline patient data storage and a secure Node.js + MongoDB backend for centralized electronic health records (EHR).
- **Report Generation:** Automatically compiles screening data into shareable PDF reports that can be shared with specialists or handed to the patient.

### f. Multilingual and Easy-to-use Interfaces for NER
- Offers localized UI support for **18 Indian languages**, specifically including **Assamese, Bengali, Bodo, Garo, Khasi, Kokborok, Manipuri, and Mizo**, which are crucial for grassroots deployment in the North Eastern Region. The interface is simplified to require minimal digital literacy from rural healthcare workers.

### g. Low-connectivity Environments & Offline Sync
- Built with an **Offline-First** architecture. Healthcare workers can complete the entire screening and assessment workflow entirely offline in remote areas. The app seamlessly synchronizes data with the cloud once internet connectivity is restored.
- **Enhanced sync service** with data loss prevention, automatic recovery of failed sync items, and MongoDB ObjectId compatibility for patient-screening relationships.

### h. Awareness and Preventive Guidance
- Automatically provides personalized, AI-driven recommendations based on the screening results, focusing on joint care, physical activity, nutrition, and lifestyle management to encourage preventive healthcare.

## License

This project is part of the MDoNER initiative for healthcare in North Eastern
India.

## Support

- Email: support@jointsaathi.com
- Helpline: 1800-XXX-XXXX

## Version History

### v2.0 (September 2026)
- **Major Update:** Medical image analysis integration
- **Enhanced AI:** Multi-class risk prediction with hospital-grade features
- **New Languages:** Bodo, Garo, Khasi, Kokborok, Manipuri, Mizo support
- **Critical Fixes:** Sync service data loss prevention and recovery
- **Testing:** Comprehensive medical image and model testing infrastructure

### v1.0 (Initial Release)
- Basic OA risk screening with gait analysis
- 12 language support
- Offline-first architecture
- BLE wearable integration
