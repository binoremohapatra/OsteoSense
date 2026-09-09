# PART A: COMPLETE UI AUDIT - JointSaathi Flutter App

## EXECUTIVE SUMMARY
This audit documents every screen in the Flutter app, their data requirements, provider usage, model backing, and network status. This serves as the ground truth for backend alignment in Part B.

---

## MODEL CLASSES (lib/models/)

### Patient Model
**Fields:** id, serverId, name, age, gender, contact, village, address, occupation, createdAt, updatedAt, synced
**toMap keys:** id, server_id, name, age, gender, contact, village, address, occupation, created_at, updated_at, synced
**fromMap keys:** id, server_id, name, age, gender, contact, village, address, occupation, created_at, updated_at, synced

### Screening Model  
**Fields:** id, serverId, patientId, userId, screeningDate, painLevel, stiffnessDuration, swelling, pastInjury, gaitData, riskLevel, confidence, contributingFactors, aiReasoning, doctorRecommendations, synced
**toMap keys:** id, server_id, patient_id, user_id, screening_date, pain_level, stiffness_duration, swelling, past_injury, gait_data, risk_level, confidence, contributing_factors, ai_reasoning, doctor_recommendations, synced
**fromMap keys:** id, server_id, patient_id, user_id, screening_date, pain_level, stiffness_duration, swelling, past_injury, gait_data, risk_level, confidence, contributing_factors, ai_reasoning, doctor_recommendations, synced

### User Model
**Fields:** id, fullName, phoneNumber, password, healthCenterId, location, createdAt, updatedAt
**toMap keys:** id, full_name, phone_number, password, health_center_id, location, created_at, updated_at
**toApiMap keys:** id, fullName, phoneNumber, password, healthCenterId, location, createdAt, updatedAt
**fromMap keys:** id, full_name/fName, phone_number/phoneNumber, password, health_center_id/healthCenterId, location, created_at/createdAt, updated_at/updatedAt

### PreventiveCare Model
**Fields:** id, category, title, content, imageUrl, createdAt
**toMap keys:** id, category, title, content, image_url, created_at
**fromMap keys:** id, category, title, content, image_url, created_at

---

## PROVIDER CLASSES (lib/providers/)

### PatientProvider
**Public Methods:**
- loadPatients() - loads from API first, falls back to local DB
- searchPatients(query) - searches local DB
- filterByRiskLevel(riskLevel) - filters local DB by risk
- addPatient(patient) - saves locally first, tries API sync
- updatePatient(patient) - updates local DB, tries API sync
- deletePatient(patientId) - deletes from local DB
- selectPatient(patient) - sets selected patient
- loadPatientById(patientId) - loads single patient from local DB

**Data Expected/Returned:**
- Uses Patient model
- Screening data has draft field for in-memory storage

### ScreeningProvider
**Public Methods:**
- loadScreenings() - loads from local DB
- loadScreeningsByPatient(patientId) - loads screenings for patient from local DB
- saveScreening(screening) - saves locally, tries API sync if patient has serverId
- updateScreening(screening) - updates local DB
- deleteScreening(screeningId) - deletes from local DB
- setCurrentScreening(screening) - sets current screening
- clearCurrentScreening() - clears current screening
- getRiskDistribution() - returns risk level counts from local DB
- getScreeningsOverTime() - returns screening trends from local DB
- getTotalScreenings() - returns total count from local DB
- setDraftAnswers(...) - stores symptom questionnaire answers in memory
- clearDraft() - clears draft answers
- setDraftGaitData(data) - stores gait data in memory

**Data Expected/Returned:**
- Uses Screening model
- Draft fields: draftPatientId, draftPainLevel, draftStiffnessDuration, draftSwelling, draftPastInjury, draftPastInjuryDetail, draftGaitData

### AuthProvider
**Public Methods:**
- loadCurrentUser() - loads from API first, falls back to local DB
- login(phoneNumber, password) - tries API login, falls back to local DB
- signup(user) - tries API signup, falls back to local DB
- demoLogin(role) - creates dummy user in memory
- logout() - clears auth state
- updateProfile(updatedUser) - updates local DB
- setRole(role) - sets user role
- saveUserRole() - saves role to SharedPreferences

**Data Expected/Returned:**
- Uses User model
- Stores auth token, refresh token, current user ID, user role in SharedPreferences

### SettingsProvider
**Public Methods:**
- loadSettings() - loads from SharedPreferences
- setLanguage(language) - saves to SharedPreferences
- setNotificationsEnabled(enabled) - saves to SharedPreferences
- setAutoSyncEnabled(enabled) - saves to SharedPreferences
- checkConnectivity() - checks network status
- updatePendingSyncCount() - placeholder for sync count
- clearOfflineData() - placeholder for data clearing
- startConnectivityListener() - starts connectivity monitoring

**Data Expected/Returned:**
- Stores language, notificationsEnabled, autoSyncEnabled, connectionStatus, pendingSyncCount

---

## SCREEN AUDIT (lib/screens/)

### AGENT SCREENS (lib/screens/agent/)

#### 1. HomeScreen (home_screen.dart)
**Path:** lib/screens/agent/home_screen.dart
**Data Displayed:**
- authProvider.currentUser.fullName (header greeting)
- authProvider.currentUser.location (header location)
- patientProvider.patients list (recent patients section)
- patientProvider.patients[].name, age, gender (patient cards)
- screeningProvider.screenings (for weekly goal and risk distribution)
- settingsProvider.isConnected (sync badge)

**Data Collected/Submitted:** None (display only)

**Providers Used:**
- AuthProvider (read: currentUser)
- PatientProvider (read: patients, methods: loadPatients)
- ScreeningProvider (read: screenings, methods: loadScreenings, getRiskDistribution)
- SettingsProvider (read: isConnected, methods: checkConnectivity, startConnectivityListener)

**Model Classes:** Patient, Screening, User

**Network/API Calls:** 
- PatientProvider.loadPatients() calls ApiService.getPatients() (API first, local fallback)
- ScreeningProvider.loadScreenings() is local-only (no API call in current implementation)

**Router Data:** None (initial route)

---

#### 2. PatientListScreen (patient_list_screen.dart)
**Path:** lib/screens/agent/patient_list_screen.dart
**Data Displayed:**
- patientProvider.patients list (patient cards)
- patientProvider.patients[].name, age, gender, village (card subtitle)
- patient.lastScreening.riskLevel (risk badge on card - **NOTE: this field doesn't exist on Patient model, accessing undefined field**)

**Data Collected/Submitted:** None (display only)

**Providers Used:**
- PatientProvider (read: patients, isLoading, errorMessage, methods: loadPatients, searchPatients, filterByRiskLevel)

**Model Classes:** Patient

**Network/API Calls:**
- PatientProvider.loadPatients() calls ApiService.getPatients() (API first, local fallback)
- PatientProvider.searchPatients() is local-only
- PatientProvider.filterByRiskLevel() is local-only

**Router Data:** None

---

#### 3. AddPatientScreen (add_patient_screen.dart)
**Path:** lib/screens/agent/add_patient_screen.dart
**Data Displayed:** None (form input only)

**Data Collected/Submitted:**
- name (text input)
- age (number input)
- gender (dropdown: male, female, other)
- occupation (text input, optional)
- contact (phone number, optional)
- village (text input, optional)
- address (text input, optional)

**Providers Used:**
- PatientProvider (methods: addPatient)

**Model Classes:** Patient

**Network/API Calls:**
- PatientProvider.addPatient() calls ApiService.createPatient() (API sync after local save)

**Router Data:** None

---

#### 4. EditPatientScreen (edit_patient_screen.dart)
**Path:** lib/screens/agent/edit_patient_screen.dart
**Data Displayed:**
- patient.name, age, gender, contact, village, address, occupation (form pre-population)
- height, weight (text inputs - **NOTE: these fields are collected but NOT saved to Patient model**)

**Data Collected/Submitted:**
- name (text input)
- age (number input)
- gender (dropdown: male, female, other)
- occupation (text input, optional)
- contact (phone number, optional)
- village (text input, optional)
- address (text input, optional)
- height (cm, text input - **COLLECTED BUT NOT SAVED**)
- weight (kg, text input - **COLLECTED BUT NOT SAVED**)

**Providers Used:**
- PatientProvider (methods: updatePatient)

**Model Classes:** Patient

**Network/API Calls:**
- PatientProvider.updatePatient() calls ApiService.updatePatient() (API sync after local update)

**Router Data:** 
- extra: Patient? (patient to edit)

---

#### 5. PatientProfileScreen (patient_profile_screen.dart)
**Path:** lib/screens/agent/patient_profile_screen.dart
**Data Displayed:**
- patient.name, age, gender, village (header card)
- screeningProvider.screenings[].riskLevel, confidence, screeningDate (risk gauge and timeline)
- screeningProvider.screenings[].contributingFactors (timeline item)
- patient.age, gender (metrics cards)
- height, weight (metrics cards - **NOTE: hardcoded as '--' since not in Patient model**)

**Data Collected/Submitted:** None (display only)

**Providers Used:**
- PatientProvider (read: selectedPatient, methods: loadPatientById)
- ScreeningProvider (read: screenings, methods: loadScreeningsByPatient)

**Model Classes:** Patient, Screening

**Network/API Calls:**
- PatientProvider.loadPatientById() is local-only
- ScreeningProvider.loadScreeningsByPatient() is local-only

**Router Data:**
- route: /agent/patient/:patientId (patientId from path parameter)

---

#### 6. ReportsScreen (reports_screen.dart)
**Path:** lib/screens/agent/reports_screen.dart
**Data Displayed:**
- patientProvider.patients.length (total patients stat)
- _overallStats.totalPatients, highRiskCount, weeklyScreenings (from AnalyticsService)
- _riskDistribution.low, medium, high (pie chart)
- _screeningTrends (line chart)
- _jointAffection (joint affection data)
- _populationInsights (AI insights text)

**Data Collected/Submitted:** None (display only)

**Providers Used:**
- PatientProvider (read: patients)
- AnalyticsService (methods: getOverallStatistics, getRiskDistribution, getScreeningTrends, getJointAffection, getPopulationInsights)

**Model Classes:** None (uses AnalyticsService which calls API)

**Network/API Calls:**
- AnalyticsService methods call ApiService.getAnalyticsData() and related endpoints

**Router Data:** None

---

#### 7. SettingsScreen (settings_screen.dart)
**Path:** lib/screens/agent/settings_screen.dart
**Data Displayed:**
- settingsProvider.language (language setting)
- settingsProvider.notificationsEnabled (notifications toggle)
- settingsProvider.autoSyncEnabled (auto-sync toggle)
- Storage usage (hardcoded as 5.2 MB)

**Data Collected/Submitted:**
- language selection (English, Hindi)
- notifications toggle
- auto-sync toggle
- clear cache action (placeholder)

**Providers Used:**
- SettingsProvider (read: language, notificationsEnabled, autoSyncEnabled, methods: setLanguage, setNotificationsEnabled, setAutoSyncEnabled)

**Model Classes:** None

**Network/API Calls:** None (local SharedPreferences only)

**Router Data:** None

---

### SHARED SCREENS (lib/screens/shared/)

#### 8. LoginScreen (login_screen.dart)
**Path:** lib/screens/shared/login_screen.dart
**Data Displayed:** None (form input only)

**Data Collected/Submitted:**
- phoneNumber (text input)
- password (text input, obscured)
- fullName (text input - only in register mode)
- Demo login option (no credentials required)

**Providers Used:**
- AuthProvider (methods: login, signup, demoLogin)

**Model Classes:** User

**Network/API Calls:**
- AuthProvider.login() calls ApiService.login() (API first, local fallback)
- AuthProvider.signup() calls ApiService.register() (API first, local fallback)
- AuthProvider.demoLogin() is local-only (creates dummy user in memory)

**Router Data:**
- query param: role (default 'agent')

---

#### 9. SignupScreen (signup_screen.dart)
**Path:** lib/screens/shared/signup_screen.dart
**Data Displayed:** None (form input only)

**Data Collected/Submitted:**
- fullName (text input)
- phoneNumber (text input, 10 digits)
- password (text input, min 6 chars, obscured)
- healthCenterId (text input, optional - agent only)
- location (text input, optional - agent only)

**Providers Used:**
- AuthProvider (methods: signup, demoLogin)

**Model Classes:** User

**Network/API Calls:**
- AuthProvider.signup() calls ApiService.register() (API first, local fallback)
- Currently calls demoLogin() instead of actual signup (temporary implementation)

**Router Data:**
- query param: role (default 'agent')

---

#### 10. SymptomQuestionnaireScreen (symptom_questionnaire_screen.dart)
**Path:** lib/screens/shared/symptom_questionnaire_screen.dart
**Data Displayed:** None (form input only)

**Data Collected/Submitted:**
- painLevel (slider: 0-10)
- stiffnessDuration (chips: none, <30, 30-60, >60)
- swelling (toggle: yes/no)
- pastInjury (toggle: yes/no)
- pastInjuryDetail (text input - if pastInjury is yes)

**Providers Used:**
- ScreeningProvider (methods: setDraftAnswers)
- PatientProvider (read: selectedPatientId, patients)

**Model Classes:** Screening (draft data only)

**Network/API Calls:** None (stores draft in memory only)

**Router Data:**
- extra: int? (patientId, optional)
- Navigates to: /screening/gait

---

#### 11. GaitTestScreen (gait_test_screen.dart)
**Path:** lib/screens/shared/gait_test_screen.dart
**Data Displayed:**
- patient.name, age (patient info card)

**Data Collected/Submitted:**
- gaitFeatures (from SensorService - accelerometer + gyroscope data during 30-second walk test)

**Providers Used:**
- PatientProvider (read: selectedPatient)
- ScreeningProvider (methods: setDraftGaitData)
- SensorService (methods: startRecording, stopRecording, getFeatureVector)

**Model Classes:** Patient, Screening (draft gait data)

**Network/API Calls:** None (local sensor data only)

**Router Data:** None
- Navigates to: /screening/processing

---

#### 12. ProcessingScreen (processing_screen.dart)
**Path:** lib/screens/shared/processing_screen.dart
**Data Displayed:** None (processing animation only)

**Data Collected/Submitted:** None (uses draft data from ScreeningProvider)

**Providers Used:**
- ScreeningProvider (read: draftPatientId, draftPainLevel, draftStiffnessDuration, draftSwelling, draftPastInjury, draftPastInjuryDetail, draftGaitData, methods: saveScreening, clearDraft)
- TFLiteService (methods: loadModel, predictRisk)

**Model Classes:** Screening

**Network/API Calls:**
- ScreeningProvider.saveScreening() calls ApiService.createScreening() (API sync if patient has serverId, otherwise local-only)
- TFLiteService.predictRisk() is local-only (fallback when API unavailable)

**Router Data:** None
- Navigates to: /screening/result

---

#### 13. RiskResultScreen (risk_result_screen.dart)
**Path:** lib/screens/shared/risk_result_screen.dart
**Data Displayed:**
- screening.riskLevel (risk gauge and summary)
- screening.confidence (confidence percentage)
- screening.painLevel, stiffnessDuration, swelling, pastInjury, gaitData (contributing factors calculation)
- screening.contributingFactors (factors display)
- screening.aiReasoning (not displayed on this screen)
- screening.doctorRecommendations (recommendations display)

**Data Collected/Submitted:** None (display only)

**Providers Used:** None (uses screening object passed via router)

**Model Classes:** Screening

**Network/API Calls:** None

**Router Data:**
- extra: Screening? (screening result to display)

---

#### 14. DetailedReportScreen (detailed_report_screen.dart)
**Path:** lib/screens/shared/detailed_report_screen.dart
**Data Displayed:**
- patient.name, age, gender, village, occupation (patient header)
- screening.riskLevel, confidence, screeningDate (risk banner)
- screening.painLevel, stiffnessDuration, swelling, pastInjury (symptoms card)
- screening.gaitData (gait card - presence check only)
- screening.contributingFactors (factors card)
- screening.aiReasoning (AI reasoning card)
- screening.doctorRecommendations (recommendations card)

**Data Collected/Submitted:** None (display only)

**Providers Used:** None (uses screening and patient objects passed via router)

**Model Classes:** Screening, Patient

**Network/API Calls:** None

**Router Data:**
- extra: Map<String, dynamic> with 'screening' and 'patient'

---

#### 15. PreventiveCareHomeScreen (preventive_care_home_screen.dart)
**Path:** lib/screens/shared/preventive_care_home_screen.dart
**Data Displayed:**
- Hardcoded category data (exercises, diet, lifestyle)
- Category metadata: id, title, subtitle, icon, articleCount, gradient

**Data Collected/Submitted:** None (display only)

**Providers Used:** None

**Model Classes:** PreventiveCare (not used - hardcoded data)

**Network/API Calls:** None (hardcoded local data)

**Router Data:** None
- Navigates to: /preventive-care/category/:id

---

#### 16. PreventiveCareCategoryScreen (preventive_care_category_screen.dart)
**Path:** lib/screens/shared/preventive_care_category_screen.dart
**Data Displayed:**
- Hardcoded article data based on category (exercises, diet, lifestyle)
- Article metadata: id, title, summary, icon, readTime, content

**Data Collected/Submitted:** None (display only)

**Providers Used:** None

**Model Classes:** PreventiveCare (not used - hardcoded data)

**Network/API Calls:** None (hardcoded local data)

**Router Data:**
- path parameter: :id (categoryId)
- extra: Map with categoryTitle, gradient, icon (optional)
- Navigates to: /preventive-care/article/:id

---

#### 17. PreventiveCareArticleScreen (preventive_care_article_screen.dart)
**Path:** lib/screens/shared/preventive_care_article_screen.dart
**Data Displayed:**
- article.title, summary, icon, readTime, content (full article display)

**Data Collected/Submitted:** None (display only)

**Providers Used:** None

**Model Classes:** PreventiveCare (not used - hardcoded data)

**Network/API Calls:** None (hardcoded local data)

**Router Data:**
- path parameter: :id (articleId)
- extra: Map with 'article' and 'gradient' (optional)

---

### USER SCREENS (lib/screens/user/)

#### 18. UserHomeScreen (user_home_screen.dart)
**Path:** lib/screens/user/user_home_screen.dart
**Data Displayed:**
- authProvider.currentUser.fullName (welcome card)

**Data Collected/Submitted:** None (display only)

**Providers Used:**
- AuthProvider (read: currentUser, methods: logout)

**Model Classes:** User

**Network/API Calls:** None

**Router Data:** None
- Navigates to: /screening/symptoms, /preventive-care/home

---

## API SERVICE ENDPOINTS (lib/services/api_service.dart)

### Auth Endpoints
- POST /auth/login - {phoneNumber, password} → {token, refreshToken, user}
- POST /auth/register - {fullName, phoneNumber, password, healthCenterId, location, createdAt, updatedAt} → {token, refreshToken, user}
- GET /auth/me → {data/user}
- POST /auth/logout

### Patient Endpoints
- GET /patients → [patient array]
- POST /patients - {localId, fullName, age, gender, contact, village, address, occupation} → {patient: {_id, ...}}
- PUT /patients/:id - {fullName, age, gender, contact, village, address, occupation} → updated patient

### Screening Endpoints
- POST /screenings - {patientId, painLevel, stiffnessDuration, swelling, pastInjury, gaitFeatures} → {screening: {_id, riskLevel, confidence, contributingFactors, aiReasoning, doctorRecommendations}}
- GET /screenings/:id → screening
- GET /screenings/patient/:patientId → [screenings array]
- PUT /screenings/:id - updated screening data
- DELETE /screenings/:id

### Preventive Care Endpoints
- GET /preventive-care/articles → [articles array]
- GET /preventive-care/articles/category/:category → [articles array]
- GET /preventive-care/articles/:id → article

### Analytics Endpoints
- GET /analytics/:type → analytics data
- GET /analytics/population-insights → insights
- GET /analytics/export?format= → export data

### User Management Endpoints
- PUT /users/profile - updated profile data
- POST /users/change-password - {oldPassword, newPassword}

### Health Center Endpoints
- GET /health-centers → [health centers array]
- PUT /health-centers/:id - updated health center data

### Sync Endpoints
- POST /sync/push - {changes: [...]} → sync result
- GET /sync/pull?lastSync= → [changes array]
- GET /sync/status → sync status
- POST /sync/batch - batch sync data

---

## ROUTER CONFIGURATION (lib/router/app_router.dart)

### Routes and Data Requirements

1. **/splash** → SplashScreen (no data)
2. **/language** → LanguageSelectionScreen (no data)
3. **/onboarding** → OnboardingScreen (no data)
4. **/role** → RoleSelectionScreen (no data)
5. **/login?role=** → LoginScreen (role query param)
6. **/signup?role=** → SignupScreen (role query param)
7. **/agent/home** → AgentHomeScreen (no data, requires auth)
8. **/agent/patients** → PatientListScreen (no data)
9. **/user/home** → UserHomeScreen (no data, requires auth)
10. **/agent/add-patient** → AddPatientScreen (no data)
11. **/agent/edit-patient** → EditPatientScreen (extra: Patient?)
12. **/screening/symptoms** → SymptomQuestionnaireScreen (extra: int? patientId)
13. **/screening/gait** → GaitTestScreen (no data)
14. **/screening/processing** → ProcessingScreen (no data)
15. **/screening/result** → RiskResultScreen (extra: Screening?)
16. **/screening/report** → DetailedReportScreen (extra: Map with 'screening' and 'patient')
17. **/screening/pdf** → PdfPreviewScreen (extra: Map with 'screening' and 'patient')
18. **/preventive-care/home** → PreventiveCareHomeScreen (no data)
19. **/preventive-care/category/:id** → PreventiveCareCategoryScreen (path param: id, extra: category metadata)
20. **/preventive-care/article/:id** → PreventiveCareArticleScreen (path param: id, extra: article and gradient)

---

## CRITICAL FINDINGS FOR BACKEND ALIGNMENT

### Field Mismatches Identified

1. **Patient Model vs EditPatientScreen:**
   - EditPatientScreen collects `height` and `weight` fields
   - Patient model does NOT have these fields
   - These fields are displayed in PatientProfileScreen as hardcoded '--'
   - **ACTION REQUIRED:** Add height and weight to Patient model if these should be persisted

2. **PatientListScreen Risk Level Access:**
   - PatientListScreen accesses `patient.lastScreening.riskLevel`
   - Patient model does NOT have a `lastScreening` field
   - **ACTION REQUIRED:** Either add lastScreening relation to Patient model or change the screen to load screenings separately

3. **Screening Model API Field Naming:**
   - Flutter uses camelCase (painLevel, stiffnessDuration)
   - Local DB uses snake_case (pain_level, stiffness_duration)
   - API service sends camelCase to backend
   - **ACTION REQUIRED:** Ensure backend Mongoose schema accepts camelCase OR add serialization layer

4. **Screening Submission Missing jointType:**
   - SymptomQuestionnaireScreen does NOT collect jointType
   - GaitTestScreen does NOT collect jointType
   - Screening model does NOT have jointType field
   - UI screens reference "joint selection" in background image but no actual joint selection UI exists
   - **ACTION REQUIRED:** Determine if jointType is needed and add to UI and model if so

5. **User Model Field Naming:**
   - User model has both toMap() (snake_case) and toApiMap() (camelCase)
   - fromMap() handles both naming conventions
   - **ACTION REQUIRED:** Ensure backend accepts camelCase from toApiMap()

### Missing Backend Endpoints

1. **Analytics Endpoints:** 
   - AnalyticsService calls these but they may not exist on backend
   - GET /analytics/:type
   - GET /analytics/population-insights
   - GET /analytics/export?format=

2. **Health Center Endpoints:**
   - API service defines these but may not be used
   - GET /health-centers
   - PUT /health-centers/:id

3. **Sync Endpoints:**
   - API service defines these but sync functionality may not be fully implemented
   - POST /sync/push
   - GET /sync/pull
   - GET /sync/status
   - POST /sync/batch

### Network/API Call Status

**Screens with API calls:**
- HomeScreen: PatientProvider.loadPatients() (API first)
- PatientListScreen: PatientProvider.loadPatients() (API first)
- AddPatientScreen: PatientProvider.addPatient() (API sync after local)
- EditPatientScreen: PatientProvider.updatePatient() (API sync after local)
- LoginScreen: AuthProvider.login/signup() (API first)
- SignupScreen: AuthProvider.signup() (API first, currently bypassed)
- ProcessingScreen: ScreeningProvider.saveScreening() (API sync if patient has serverId)
- ReportsScreen: AnalyticsService calls (API calls)

**Screens that are local-only:**
- PatientProfileScreen: loads from local DB only
- SymptomQuestionnaireScreen: stores draft in memory only
- GaitTestScreen: local sensor data only
- RiskResultScreen: displays passed data only
- DetailedReportScreen: displays passed data only
- PreventiveCare screens: hardcoded local data only
- SettingsScreen: SharedPreferences only

---

## DATABASE SCHEMA (lib/services/database_helper.dart)

### Tables and Columns

**users:**
- id, full_name, phone_number, password, health_center_id, location, created_at, updated_at

**patients:**
- id, server_id, name, age, gender, contact, village, address, occupation, created_at, updated_at, synced, deleted

**screenings:**
- id, server_id, patient_id, user_id, screening_date, pain_level, stiffness_duration, swelling, past_injury, gait_data, risk_level, confidence, contributing_factors, ai_reasoning, doctor_recommendations, synced, deleted

**preventive_care:**
- id, category, title, content, image_url, created_at

**sync_queue:**
- id, table_name, record_id, action, data, created_at, retry_count

**Additional tables created dynamically:**
- article_progress (if needed)
- user_settings (if needed)
- sync_metadata (if needed)
- audit_logs (if needed)

---

## END OF PART A AUDIT

This completes the comprehensive UI audit. All screens, their data requirements, provider usage, model backing, and network status have been documented. This serves as the reference for Part B backend alignment.