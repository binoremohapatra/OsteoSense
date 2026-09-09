# Integration Test Guide - OsteoSense End-to-End

## 🎯 Deployment URLs

### Backend Services
- **Node.js Backend:** `https://osteosense-tt0q.onrender.com`
- **AI Service:** `https://osteo-sense-ai-service-808g.onrender.com`

### Flutter App
- **API Base URL:** `https://osteosense-tt0q.onrender.com/api/v1`
- **Build:** `app/build/app/outputs/flutter-apk/app-debug.apk`

---

## 🧪 Integration Test Steps

### 1. Backend Health Check

```bash
# Node.js Backend
curl https://osteosense-tt0q.onrender.com/health

# AI Service
curl https://osteo-sense-ai-service-808g.onrender.com/health
```

**Expected Response:** Both should return `200 OK` with status information

---

### 2. AI Service Prediction Test

```bash
curl -X POST https://osteo-sense-ai-service-808g.onrender.com/predict \
  -H "Content-Type: application/json" \
  -d '{
    "pain_level": 8,
    "stiffness_duration": "30-60",
    "swelling": true,
    "past_injury": true,
    "gait_data": "{\"variance\": 1.23}"
  }'
```

**Expected Response:**
```json
{
  "risk_level": "high",
  "confidence": 0.85,
  "contributing_factors": ["Severe pain level reported", "Prolonged joint stiffness (>30 minutes)"],
  "reasoning": "AI prediction based on clinical symptoms and gait analysis.",
  "model_version": "1.0.0"
}
```

---

### 3. Backend Registration Test

```bash
curl -X POST https://osteosense-tt0q.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "TestPass123!",
    "role": "agent"
  }'
```

**Expected Response:** User created with tokens

---

### 4. Backend Login Test

```bash
curl -X POST https://osteosense-tt0q.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }'
```

**Expected Response:** Access token and refresh token

---

### 5. Patient Creation Test

```bash
curl -X POST https://osteosense-tt0q.onrender.com/api/v1/patients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -d '{
    "name": "Test Patient",
    "age": 45,
    "gender": "male",
    "phone": "1234567890",
    "location": "Mumbai"
  }'
```

**Expected Response:** Patient created with ID

---

### 6. Screening Creation Test (Full AI Integration)

```bash
curl -X POST https://osteosense-tt0q.onrender.com/api/v1/screenings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -d '{
    "patientId": "<PATIENT_ID>",
    "painLevel": 7,
    "stiffnessDuration": "30-60",
    "swelling": true,
    "pastInjury": false,
    "gaitFeatures": [1.2, 1.5, 1.1, 1.3, 1.4]
  }'
```

**Expected Response:**
```json
{
  "screening": {
    "id": "...",
    "riskLevel": "medium",
    "confidence": 0.78,
    "source": "ml_model",
    "contributingFactors": [...],
    "aiReasoning": "...",
    "doctorRecommendations": "..."
  }
}
```

**IMPORTANT:** `source: "ml_model"` confirms AI service is working. If `source: "fallback_rules"`, then AI service is not connected.

---

### 7. PDF Report Download Test

```bash
curl -X GET https://osteosense-tt0q.onrender.com/api/v1/screenings/<SCREENING_ID>/report \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --output report.pdf
```

**Expected Response:** PDF file downloaded successfully

---

### 8. Analytics Test

```bash
curl -X GET https://osteosense-tt0q.onrender.com/api/v1/analytics \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

**Expected Response:** Analytics data with screening counts, risk distribution

---

## 📱 Flutter App Testing

### 1. Build APK
```bash
cd app
flutter build apk --debug
```

### 2. Install on Emulator/Device
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 3. Test Flow
1. **Launch App** → Should show splash screen
2. **Register/Login** → Should authenticate successfully
3. **Create Patient** → Should save to backend
4. **Run Screening** → Should call AI service and show ML prediction
5. **Download PDF** → Should download from backend
6. **View Analytics** → Should show backend analytics

---

## 🔍 Troubleshooting

### AI Service Not Connected
- **Symptom:** Screening returns `source: "fallback_rules"`
- **Fix:** Check Node.js backend environment variable `AI_SERVICE_URL` is set correctly

### Authentication Errors
- **Symptom:** 401 Unauthorized
- **Fix:** Check token is valid and not expired

### Network Errors
- **Symptom:** Connection timeout
- **Fix:** Check backend services are live and accessible

### PDF Download Fails
- **Symptom:** PDF endpoint returns error
- **Fix:** Check screening has valid ID and backend PDF service is working

---

## ✅ Success Criteria

- ✅ Both backend services return 200 OK on health check
- ✅ AI service returns ML predictions with `source: "ml_model"`
- ✅ Backend successfully calls AI service for screenings
- ✅ Flutter app can register/login
- ✅ Flutter app can create patients
- ✅ Flutter app can run screenings with AI predictions
- ✅ Flutter app can download PDF reports
- ✅ Flutter app can view analytics

---

## 📝 Environment Variables Checklist

### Node.js Backend (Render)
- [x] `MONGODB_URI` - MongoDB connection string
- [x] `JWT_ACCESS_SECRET` - Access token secret (32+ chars)
- [x] `JWT_REFRESH_SECRET` - Refresh token secret (32+ chars)
- [x] `AI_SERVICE_URL` - `https://osteo-sense-ai-service-808g.onrender.com`
- [x] `NODE_ENV` - `production`
- [x] `PORT` - `5000`

### AI Service (Render)
- [x] `PYTHONUNBUFFERED` - `1`
- [x] `PORT` - `8000`

### Flutter App
- [x] `API_BASE_URL` - `https://osteosense-tt0q.onrender.com/api/v1`
