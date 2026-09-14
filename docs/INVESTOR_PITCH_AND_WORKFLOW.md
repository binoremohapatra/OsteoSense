# OsteoSense (JointSaathi): Investor & Stakeholder Pitch

## 1. Executive Summary
**OsteoSense (JointSaathi)** is an AI-powered, offline-first mobile healthcare platform designed to democratize early-stage screening of Osteoarthritis (OA). Built specifically for resource-constrained environments like the North Eastern Region (NER) of India, it empowers grassroots healthcare workers (ASHA workers, rural nurses) to identify high-risk OA patients without requiring expensive diagnostic infrastructure.

## 2. The Problem
Osteoarthritis is a chronic condition causing severe pain and mobility issues. In regions like NER, characterized by difficult terrain and limited access to specialized orthopaedic care, undiagnosed OA is a massive burden. By the time patients travel to cities for an X-ray or MRI, the joint damage is often irreversible. There is an urgent need for an affordable, point-of-care screening tool.

## 3. The Solution
OsteoSense solves this by turning a standard smartphone into an intelligent screening device:
- **Custom Low-Cost BLE Wearable:** Utilizes a custom-built, low-cost BLE (Bluetooth Low Energy) wearable sensor (ESP32-based) to capture highly precise joint movement and gait patterns, avoiding the need for expensive diagnostic machinery.
- **Works Without Internet:** Fully functional offline (Offline-First Architecture).
- **Multilingual:** Speaks the local language (Assamese, Bengali, and 10 other Indian languages).
- **AI-Backed Assessment:** Provides immediate, preliminary risk analysis using embedded machine learning.

---

## 4. End-to-End Workflow (How the Project Works)

Here is a step-by-step breakdown of how the solution operates in the field. This is the core journey from start to finish.

### Phase 1: Setup & Onboarding
1. **Language Selection:** The healthcare worker opens the app and selects their preferred local language (e.g., Assamese).
2. **Authentication:** The worker logs in securely. If offline, the app uses cached credentials. If online, it verifies with the Node.js backend.

### Phase 2: Patient Screening
1. **Patient Registration:** The worker creates a new digital profile for the patient (Name, Age, Occupation, Medical History).
2. **Symptom Questionnaire:** The app guides the worker through a digitized, visual questionnaire to record the patient's pain levels, stiffness, and daily mobility challenges.
3. **Gait Assessment (The Core Innovation):** 
   - The worker straps the custom **BLE Wearable Device (OsteoSense Sensor)** to the patient's knee or leg.
   - The patient is asked to walk a few steps.
   - The app instantly connects via Bluetooth and captures raw IMU (Inertial Measurement Unit) data from the wearable in real-time, precisely analyzing limping, asymmetry, or restricted range of motion.

### Phase 3: AI Analysis & Results
1. **On-Device AI Inference:** 
   - The collected sensor data and questionnaire inputs are fed into the on-device **TensorFlow Lite (TFLite) Model**.
   - The model instantly calculates an OA Risk Score (e.g., "High Risk", "78% Confidence") without needing any internet connection.
2. **Result Generation & Guidance:** The app displays the risk severity, contributing factors, and immediate preventive guidance (lifestyle, nutrition, exercises).
3. **Report Generation:** A digital PDF report is instantly generated for the patient, which can be printed or shared digitally (e.g., via WhatsApp).

### Phase 4: Data Synchronization (Cloud Integration)
1. **Offline Storage:** All screening data is securely stored in the local SQLite database.
2. **Auto-Sync:** Once the healthcare worker returns to a primary health center with internet connectivity, the app automatically pushes the batched data to the **Node.js/MongoDB Backend**.
3. **Advanced Cloud AI (Optional):** The backend can route complex cases to our **Python FastAPI AI Microservice** for deeper longitudinal analysis.

---

## 5. Technical Architecture Overview

To achieve this workflow, the project uses a modern, scalable tech stack:

- **Frontend (Mobile App):** `Flutter` (Dart). Ensures the app runs on both Android and iOS smoothly.
- **Local Database:** `SQLite` (`sqflite`). Handles offline-first capabilities.
- **On-Device Machine Learning:** `TensorFlow Lite` (`tflite_flutter`). Runs the predictive model locally.
- **Backend API:** `Node.js` with `Express.js`. Manages user authentication (JWT) and data synchronization.
- **Cloud Database:** `MongoDB`. Securely stores Electronic Health Records (EHR) centrally.
- **Advanced AI Service:** `Python` with `FastAPI`. For future complex ML models and analytics.
- **Hardware Integration (Core Innovation):** `C++` (ESP32 Firmware) powering the primary low-cost BLE wearable sensor for precise gait data collection.

## 6. Competitive Advantage
- **Cost-Effective:** Traditional screening requires X-Rays/MRIs and specialists. OsteoSense requires only a smartphone.
- **Accessibility:** Specifically tailored for rural terrains with its offline capabilities and multilingual interface.
- **Scalable:** The cloud architecture allows state health departments to aggregate anonymized data to track OA prevalence across districts in real-time.

## 7. Future Roadmap
- **Telemedicine Integration:** Instant consultations with urban orthopaedic doctors.
- **Voice Input:** Voice-assisted data entry for less tech-savvy healthcare workers.
- **Computer Vision:** More granular gait analysis using the smartphone camera.
