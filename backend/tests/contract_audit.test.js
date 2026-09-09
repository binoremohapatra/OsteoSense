'use strict';

require('./setup');
const request = require('supertest');
const app = require('../src/app');
const PreventiveCare = require('../src/models/PreventiveCare');

// Mock aiService for deterministic ML model prediction responses
jest.mock('../src/services/aiService');
const aiService = require('../src/services/aiService');

const AUTH_BASE = '/api/v1/auth';
const PATIENT_BASE = '/api/v1/patients';
const SCREENING_BASE = '/api/v1/screenings';
const ANALYTICS_BASE = '/api/v1/analytics';
const PREVENTIVE_BASE = '/api/v1/preventive-care';
const SYNC_BASE = '/api/v1/sync';

beforeEach(() => {
  jest.clearAllMocks();
});

describe('End-to-End Workflow Audit & Contract Verification', () => {
  // Workflow 1: Register -> Login -> Dashboard Overview
  describe('Workflow 1: Auth and Dashboard', () => {
    it('registers with phoneNumber or phone alias and logs in', async () => {
      // 1. Register with phone alias (mobile style)
      const regRes = await request(app).post(`${AUTH_BASE}/register`).send({
        fullName: 'Dr. Anita Roy',
        phone: '9876543210',
        password: 'Password123!',
        role: 'agent',
        healthCenterId: 'PHC-TAWANG-01',
        location: 'Tawang, Arunachal Pradesh',
      });

      expect(regRes.status).toBe(201);
      expect(regRes.body.success).toBe(true);
      expect(regRes.body.data.user.id).toBeDefined();
      expect(regRes.body.data.user.phoneNumber).toBe('9876543210');
      expect(regRes.body.data.accessToken).toBeDefined();
      expect(regRes.body.data.refreshToken).toBeDefined();
      expect(regRes.body.token).toBe(regRes.body.data.accessToken);

      // 2. Login with phoneNumber (web dashboard style)
      const loginRes = await request(app).post(`${AUTH_BASE}/login`).send({
        phoneNumber: '9876543210',
        password: 'Password123!',
      });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.data.accessToken).toBeDefined();
      const { accessToken } = loginRes.body.data;

      // 3. Verify /auth/me profile
      const meRes = await request(app)
        .get(`${AUTH_BASE}/me`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(meRes.status).toBe(200);
      expect(meRes.body.data.user.fullName).toBe('Dr. Anita Roy');
      expect(meRes.body.data.user.healthCenterId).toBe('PHC-TAWANG-01');

      // 4. Check initial Overview stats
      const ovRes = await request(app)
        .get(`${ANALYTICS_BASE}/overview`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(ovRes.status).toBe(200);
      expect(ovRes.body.data.totalPatients).toBe(0);
      expect(ovRes.body.data.totalScreenings).toBe(0);
      expect(ovRes.body.data.riskDistribution).toEqual({ low: 0, medium: 0, high: 0 });
      expect(ovRes.body.data.avgConfidence).toBeNull();
    });
  });

  // Workflow 2: Create patient -> Patient list -> Patient search -> Patient details -> Patient update -> Soft delete
  describe('Workflow 2: Patient Lifecycle', () => {
    let token;

    beforeEach(async () => {
      const reg = await request(app).post(`${AUTH_BASE}/register`).send({
        fullName: 'Field Worker',
        phoneNumber: '9876543211',
        password: 'Password123!',
        role: 'agent',
      });
      token = reg.body.data.accessToken;
    });

    it('creates, lists, searches with partial query, updates, and soft-deletes a patient', async () => {
      // 1. Create patient
      const createRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Tenzin Norbu',
          age: 58,
          gender: 'male',
          village: 'Tawang',
          contact: '9876500001',
          occupation: 'Farmer',
          height: 165,
          weight: 70,
        });

      expect(createRes.status).toBe(201);
      const patient = createRes.body.data;
      expect(patient.id).toBeDefined();
      expect(patient.name).toBe('Tenzin Norbu');

      // 2. List patients
      const listRes = await request(app)
        .get(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .query({ page: 1, limit: 20 });

      expect(listRes.status).toBe(200);
      expect(listRes.body.data).toHaveLength(1);
      expect(listRes.body.data[0].id).toBe(patient.id);
      expect(listRes.body.pagination.total).toBe(1);

      // 3. Search patients with partial prefix ("Tenz")
      const searchRes = await request(app)
        .get(`${PATIENT_BASE}/search`)
        .set('Authorization', `Bearer ${token}`)
        .query({ q: 'Tenz' });

      expect(searchRes.status).toBe(200);
      expect(searchRes.body.data).toHaveLength(1);
      expect(searchRes.body.data[0].id).toBe(patient.id);

      // 4. Get patient detail by ID
      const detailRes = await request(app)
        .get(`${PATIENT_BASE}/${patient.id}`)
        .set('Authorization', `Bearer ${token}`);

      expect(detailRes.status).toBe(200);
      expect(detailRes.body.data.name).toBe('Tenzin Norbu');
      expect(detailRes.body.data.screeningHistoryCount).toBe(0);

      // 5. Update patient
      const updateRes = await request(app)
        .put(`${PATIENT_BASE}/${patient.id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ occupation: 'Senior Farmer', weight: 68 });

      expect(updateRes.status).toBe(200);
      expect(updateRes.body.data.occupation).toBe('Senior Farmer');
      expect(updateRes.body.data.weight).toBe(68);

      // 6. Delete patient (soft delete)
      const delRes = await request(app)
        .delete(`${PATIENT_BASE}/${patient.id}`)
        .set('Authorization', `Bearer ${token}`);

      expect(delRes.status).toBe(200);

      // 7. Verification: patient no longer appears in active list or active search
      const afterList = await request(app)
        .get(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`);
      const listData = Array.isArray(afterList.body) ? afterList.body : afterList.body.data;
      expect(listData).toHaveLength(0);

      const afterGet = await request(app)
        .get(`${PATIENT_BASE}/${patient.id}`)
        .set('Authorization', `Bearer ${token}`);
      expect(afterGet.status).toBe(404);
    });
  });

  // Workflow 3 & 4: Screening -> AI Prediction -> Risk result -> PDF report
  describe('Workflow 3 & 4: Screening Flow and PDF Generation', () => {
    let token;
    let patientId;

    beforeEach(async () => {
      const reg = await request(app).post(`${AUTH_BASE}/register`).send({
        fullName: 'Screening Agent',
        phoneNumber: '9876543212',
        password: 'Password123!',
        role: 'agent',
      });
      token = reg.body.data.accessToken;

      const pRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Pema Wangmo', age: 62, gender: 'female', village: 'Ziro' });
      patientId = pRes.body.data.id;
    });

    it('creates a screening, inspects details, and downloads a valid PDF report', async () => {
      aiService.predictRisk.mockResolvedValue({
        riskLevel: 'high',
        confidence: 0.88,
        contributingFactors: ['Severe pain level reported', 'Joint swelling observed'],
        aiReasoning: 'Combined severe symptoms and significant gait variance indicate elevated OA risk.',
        doctorRecommendations: 'Refer to specialist immediately.',
        source: 'ml_model',
      });

      // 1. Submit screening
      const scrRes = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({
          patientId,
          painLevel: 8,
          stiffnessDuration: '30 minutes',
          swelling: true,
          pastInjury: 'Twisted knee 2021',
          gaitFeatures: [0.35, 0.45, 0.65, 0.55],
        });

      expect(scrRes.status).toBe(201);
      const screening = scrRes.body.data;
      expect(screening.id).toBeDefined();
      expect(screening.riskLevel).toBe('high');
      expect(screening.confidence).toBe(0.88);
      expect(screening.source).toBe('ml_model');

      // 2. Fetch screening detail with populated patientId
      const getScr = await request(app)
        .get(`${SCREENING_BASE}/${screening.id}`)
        .set('Authorization', `Bearer ${token}`);

      expect(getScr.status).toBe(200);
      expect(getScr.body.data.patientId.name).toBe('Pema Wangmo');
      expect(getScr.body.data.patientId.village).toBe('Ziro');

      // 3. Fetch screenings by patient
      const byPat = await request(app)
        .get(`${SCREENING_BASE}/patient/${patientId}`)
        .set('Authorization', `Bearer ${token}`);

      expect(byPat.status).toBe(200);
      expect(byPat.body.data).toHaveLength(1);
      expect(byPat.body.data[0].id).toBe(screening.id);

      // 4. Download PDF report
      const pdfRes = await request(app)
        .get(`${SCREENING_BASE}/${screening.id}/report`)
        .set('Authorization', `Bearer ${token}`);

      expect(pdfRes.status).toBe(200);
      expect(pdfRes.headers['content-type']).toBe('application/pdf');
      expect(pdfRes.headers['content-disposition']).toContain('attachment');
      // Verify PDF magic header %PDF-
      expect(pdfRes.body.slice(0, 5).toString('ascii')).toBe('%PDF-');
    });
  });

  // Workflow 5: Analytics overview, trends, risk distribution, and locations
  describe('Workflow 5: Analytics and Metrics', () => {
    let token;

    beforeEach(async () => {
      const reg = await request(app).post(`${AUTH_BASE}/register`).send({
        fullName: 'Analytics Agent',
        phoneNumber: '9876543213',
        password: 'Password123!',
        role: 'agent',
      });
      token = reg.body.data.accessToken;

      // Create patients
      const p1 = (await request(app).post(PATIENT_BASE).set('Authorization', `Bearer ${token}`).send({
        name: 'Patient A', age: 50, gender: 'female', village: 'Tawang',
      })).body.data.id;

      const p2 = (await request(app).post(PATIENT_BASE).set('Authorization', `Bearer ${token}`).send({
        name: 'Patient B', age: 60, gender: 'male', village: 'Tawang',
      })).body.data.id;

      const p3 = (await request(app).post(PATIENT_BASE).set('Authorization', `Bearer ${token}`).send({
        name: 'Patient C', age: 70, gender: 'female', village: 'Bomdila',
      })).body.data.id;

      aiService.predictRisk
        .mockResolvedValueOnce({ riskLevel: 'high', confidence: 0.9, contributingFactors: [], aiReasoning: '', doctorRecommendations: '', source: 'ml_model' })
        .mockResolvedValueOnce({ riskLevel: 'medium', confidence: 0.7, contributingFactors: [], aiReasoning: '', doctorRecommendations: '', source: 'ml_model' })
        .mockResolvedValueOnce({ riskLevel: 'low', confidence: 0.8, contributingFactors: [], aiReasoning: '', doctorRecommendations: '', source: 'fallback_rules' });

      await request(app).post(SCREENING_BASE).set('Authorization', `Bearer ${token}`).send({ patientId: p1, painLevel: 9 });
      await request(app).post(SCREENING_BASE).set('Authorization', `Bearer ${token}`).send({ patientId: p2, painLevel: 5 });
      await request(app).post(SCREENING_BASE).set('Authorization', `Bearer ${token}`).send({ patientId: p3, painLevel: 2 });
    });

    it('returns accurate overview KPIs, trends, risk distribution, and location statistics', async () => {
      // 1. Overview
      const ovRes = await request(app).get(`${ANALYTICS_BASE}/overview`).set('Authorization', `Bearer ${token}`);
      expect(ovRes.status).toBe(200);
      expect(ovRes.body.data.totalPatients).toBe(3);
      expect(ovRes.body.data.totalScreenings).toBe(3);
      expect(ovRes.body.data.riskDistribution).toEqual({ low: 1, medium: 1, high: 1 });
      expect(ovRes.body.data.avgConfidence).toBe(0.8);

      // 2. Trends for 30d
      const trendRes = await request(app).get(`${ANALYTICS_BASE}/trends`).set('Authorization', `Bearer ${token}`).query({ period: '30d' });
      expect(trendRes.status).toBe(200);
      expect(Array.isArray(trendRes.body.data)).toBe(true);
      expect(trendRes.body.data.length).toBeGreaterThan(0);
      expect(trendRes.body.data[0].count).toBe(3);

      // 3. Risk Distribution
      const distRes = await request(app).get(`${ANALYTICS_BASE}/risk-distribution`).set('Authorization', `Bearer ${token}`);
      expect(distRes.status).toBe(200);
      expect(distRes.body.data).toEqual({ low: 1, medium: 1, high: 1 });

      // 4. Locations (Tawang has 2 screenings, 1 high risk; Bomdila has 1 screening, 0 high risk)
      const locRes = await request(app).get(`${ANALYTICS_BASE}/locations`).set('Authorization', `Bearer ${token}`);
      expect(locRes.status).toBe(200);
      expect(locRes.body.data).toHaveLength(2);
      const tawang = locRes.body.data.find((l) => l.village === 'Tawang');
      expect(tawang).toBeDefined();
      expect(tawang.totalScreenings).toBe(2);
      expect(tawang.highRiskCount).toBe(1);
      expect(tawang.riskPercentage).toBe(50);
    });
  });

  // Workflow 6: Preventive Care content
  describe('Workflow 6: Preventive Care', () => {
    beforeAll(async () => {
      await PreventiveCare.create([
        { category: 'exercises', language: 'en', title: 'Leg raises', content: 'Raise legs' },
        { category: 'diet', language: 'en', title: 'Anti-inflammatory diet', content: 'Turmeric' },
        { category: 'exercises', language: 'hi', title: 'पैर उठाना', content: 'सीधा पैर उठाएं' },
      ]);
    });

    it('retrieves preventive care items filtered by category and language without auth', async () => {
      const enExercises = await request(app).get(PREVENTIVE_BASE).query({ category: 'exercises', lang: 'en' });
      expect(enExercises.status).toBe(200);
      expect(enExercises.body.data).toHaveLength(1);
      expect(enExercises.body.data[0].title).toBe('Leg raises');

      const hiExercises = await request(app).get(PREVENTIVE_BASE).query({ category: 'exercises', lang: 'hi' });
      expect(hiExercises.status).toBe(200);
      expect(hiExercises.body.data).toHaveLength(1);
      expect(hiExercises.body.data[0].title).toBe('पैर उठाना');
    });
  });

  // Workflow 7: Offline sync workflow with local ID reconciliation
  describe('Workflow 7: Offline Sync and Local ID Reconciliation', () => {
    let token;

    beforeEach(async () => {
      const reg = await request(app).post(`${AUTH_BASE}/register`).send({
        fullName: 'Sync Agent',
        phoneNumber: '9876543214',
        password: 'Password123!',
        role: 'agent',
      });
      token = reg.body.data.accessToken;

      aiService.predictRisk.mockResolvedValue({
        riskLevel: 'medium',
        confidence: 0.74,
        contributingFactors: [],
        aiReasoning: 'Sync screening reasoning',
        doctorRecommendations: 'Routine checkup',
        source: 'ml_model',
      });
    });

    it('checks sync status and processes batch with localId reconciliation', async () => {
      // 1. Initial sync status
      const statusRes = await request(app).get(`${SYNC_BASE}/status`).set('Authorization', `Bearer ${token}`);
      expect(statusRes.status).toBe(200);
      expect(statusRes.body.data.serverTime).toBeDefined();

      // 2. Batch payload where screening references local-patient-1 created in the same batch
      const batchPayload = {
        items: [
          {
            type: 'patient',
            localId: 'local-patient-1',
            action: 'create',
            data: { name: 'Offline Patient', age: 48, gender: 'female', village: 'Pasighat' },
          },
          {
            type: 'screening',
            localId: 'local-screening-1',
            action: 'create',
            data: {
              patientId: 'local-patient-1', // referencing localId from preceding item!
              painLevel: 6,
              stiffnessDuration: '20 minutes',
              swelling: false,
              pastInjury: '',
              gaitFeatures: [0.2, 0.4],
            },
          },
        ],
      };

      const syncRes = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${token}`)
        .send(batchPayload);

      expect(syncRes.status).toBe(200);
      expect(syncRes.body.success).toBe(true);
      expect(syncRes.body.results).toHaveLength(2);

      const patientResult = syncRes.body.results[0];
      const screeningResult = syncRes.body.results[1];

      expect(patientResult.localId).toBe('local-patient-1');
      expect(patientResult.success).toBe(true);
      expect(patientResult.serverId).toBeDefined();

      expect(screeningResult.localId).toBe('local-screening-1');
      expect(screeningResult.success).toBe(true);
      expect(screeningResult.serverId).toBeDefined();

      // 3. Verify screening is saved in DB pointing to the resolved serverId
      const scr = await request(app)
        .get(`${SCREENING_BASE}/${screeningResult.serverId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(scr.status).toBe(200);
      expect(scr.body.data.patientId.name).toBe('Offline Patient');
    });

    it('gracefully handles empty sync batch', async () => {
      const res = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${token}`)
        .send({ items: [] });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.results).toEqual([]);
    });

    it('processes Flutter app native batch sync payload { patients, screenings }', async () => {
      const flutterSyncPayload = {
        patients: [
          {
            localId: 101,
            name: 'Kalsang Doma',
            age: 52,
            gender: 'female',
            village: 'Bomdila',
            _sync_action: 'insert',
          },
        ],
        screenings: [
          {
            localId: 201,
            patient_id: 101, // references local patient ID
            user_id: 1,
            screening_date: new Date().toISOString(),
            pain_level: 7,
            stiffness_duration: '45 minutes',
            swelling: 1,
            past_injury: 'Prior fall',
            gait_data: '[0.4, 0.6, 0.5]',
            _sync_action: 'insert',
          },
        ],
      };

      const res = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${token}`)
        .send(flutterSyncPayload);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.results.patients).toHaveLength(1);
      expect(res.body.results.screenings).toHaveLength(1);

      const pSync = res.body.results.patients[0];
      expect(pSync.localId).toBe(101);
      expect(pSync.serverId).toBeDefined();
      expect(pSync.success).toBe(true);

      const sSync = res.body.results.screenings[0];
      expect(sSync.localId).toBe(201);
      expect(sSync.serverId).toBeDefined();
      expect(sSync.success).toBe(true);

      // Verify screening references the created patient
      const scr = await request(app)
        .get(`${SCREENING_BASE}/${sSync.serverId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(scr.status).toBe(200);
      expect(scr.body.data.patientId._id).toBe(pSync.serverId);
    });
  });

  // Dedicated Mobile App Contract Verification Suite
  describe('Flutter Mobile App Strict Contract Verification', () => {
    let appUserToken;
    let appPatientServerId;

    beforeEach(async () => {
      const regRes = await request(app).post(`${AUTH_BASE}/register`).send({
        full_name: 'Mobile Health Worker',
        phone_number: '9876543299',
        password: 'Password123!',
        health_center_id: 'HC-BOMDILA-01',
        location: 'West Kameng',
      });
      appUserToken = regRes.body.token;

      const pRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${appUserToken}`)
        .send({
          localId: 42,
          fullName: 'Dorjee Khandu',
          age: 65,
          gender: 'male',
          contact: '9876500099',
          village: 'Dirang',
          address: 'Main Market',
          occupation: 'Artisan',
        });
      appPatientServerId = pRes.body.patient._id;
    });

    it('satisfies AuthProvider login and register contracts', async () => {
      // 1. Signup with user.toMap() payload (snake_case from Flutter)
      const signupPayload = {
        full_name: 'Fresh Worker',
        phone_number: '9876543288',
        password: 'Password123!',
        health_center_id: 'HC-BOMDILA-02',
        location: 'West Kameng',
      };

      const regRes = await request(app).post(`${AUTH_BASE}/register`).send(signupPayload);
      expect(regRes.status).toBe(201);
      expect(regRes.body.token).toBeDefined();
      expect(regRes.body.refreshToken).toBeDefined();
      expect(regRes.body.user).toBeDefined();

      const user = regRes.body.user;
      expect(typeof user.id).toBe('number'); // prefs.setInt('current_user_id', _currentUser!.id!)
      expect(user.full_name).toBe('Fresh Worker');
      expect(user.phone_number).toBe('9876543288');
      expect(typeof user.password).toBe('string');
      expect(user.created_at).toBeDefined();
      expect(user.updated_at).toBeDefined();

      // 2. Login with phone and password
      const loginRes = await request(app).post(`${AUTH_BASE}/login`).send({
        phone: '9876543288',
        password: 'Password123!',
      });
      expect(loginRes.status).toBe(200);
      expect(loginRes.body.token).toBeDefined();
      expect(loginRes.body.refreshToken).toBeDefined();
      expect(loginRes.body.user).toBeDefined();
      expect(typeof loginRes.body.user.id).toBe('number');

      // 3. /auth/me for User.fromMap(userData['data'] ?? userData)
      const meRes = await request(app).get(`${AUTH_BASE}/me`).set('Authorization', `Bearer ${loginRes.body.token}`);
      expect(meRes.status).toBe(200);
      expect(meRes.body.user).toBeDefined();
      expect(typeof meRes.body.data.id).toBe('number');
      expect(meRes.body.data.full_name).toBe('Fresh Worker');
    });

    it('satisfies PatientProvider addPatient and getPatients contracts', async () => {
      // 1. addPatient sends { localId, fullName, age, gender, contact, village, address, occupation }
      // and reads response['patient']['_id']
      const patientPayload = {
        localId: 43,
        fullName: 'Sonam Tashi',
        age: 50,
        gender: 'female',
        contact: '9876500088',
        village: 'Rupa',
        address: 'Hill Road',
        occupation: 'Weaver',
      };

      const createRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${appUserToken}`)
        .send(patientPayload);

      expect(createRes.status).toBe(201);
      expect(createRes.body.patient).toBeDefined();
      expect(createRes.body.patient._id).toBeDefined();

      // 2. getPatients() returns direct List<dynamic> (JSON Array)
      const listRes = await request(app)
        .get(PATIENT_BASE)
        .set('Authorization', `Bearer ${appUserToken}`);

      expect(listRes.status).toBe(200);
      expect(Array.isArray(listRes.body)).toBe(true);
      expect(listRes.body.length).toBeGreaterThanOrEqual(2);

      const pItem = listRes.body.find((p) => p._id === appPatientServerId);
      expect(pItem).toBeDefined();
      expect(pItem.id).toBeNull(); // ensures (map['id'] as int?) is null without casting error
      expect(pItem.name).toBe('Dorjee Khandu');
      expect(pItem.fullName).toBe('Dorjee Khandu');
      expect(pItem.server_id).toBe(appPatientServerId);
      expect(pItem.created_at).toBeDefined();
      expect(pItem.updated_at).toBeDefined();
      expect(pItem.synced).toBe(1);
    });

    it('satisfies ScreeningProvider createScreening contract', async () => {
      aiService.predictRisk.mockResolvedValueOnce({
        riskLevel: 'high',
        confidence: 0.91,
        contributingFactors: ['High pain score', 'Morning stiffness > 30 min'],
        aiReasoning: 'Consistent signs of OA progression',
        doctorRecommendations: 'Refer for X-ray',
        source: 'ml_model',
      });

      const screeningPayload = {
        patientId: appPatientServerId,
        painLevel: 9,
        stiffnessDuration: '60 minutes',
        swelling: true,
        pastInjury: 'Knee fracture 2019',
        gaitFeatures: [0.15, 0.25, 0.45],
      };

      const res = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${appUserToken}`)
        .send(screeningPayload);

      expect(res.status).toBe(201);
      expect(res.body.screening).toBeDefined();

      const scr = res.body.screening;
      expect(scr._id).toBeDefined();
      expect(scr.riskLevel).toBe('high');
      expect(typeof scr.confidence).toBe('number');
      expect(Array.isArray(scr.contributingFactors)).toBe(true); // (serverResult['contributingFactors'] as List)
      expect(scr.aiReasoning).toBeDefined();
      expect(scr.doctorRecommendations).toBeDefined();
    });
  });
});
