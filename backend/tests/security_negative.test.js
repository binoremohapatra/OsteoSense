'use strict';

require('./setup');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const env = require('../src/config/env');

jest.mock('../src/services/aiService');
const aiService = require('../src/services/aiService');

const AUTH_BASE = '/api/v1/auth';
const PATIENT_BASE = '/api/v1/patients';
const SCREENING_BASE = '/api/v1/screenings';
const ANALYTICS_BASE = '/api/v1/analytics';
const SYNC_BASE = '/api/v1/sync';

async function createAgent(phoneNumber, fullName = 'Agent') {
  const res = await request(app).post(`${AUTH_BASE}/register`).send({
    fullName,
    phoneNumber,
    password: 'Password123!',
    role: 'agent',
  });
  return res.body.data;
}

beforeEach(() => {
  jest.clearAllMocks();
  aiService.predictRisk.mockResolvedValue({
    riskLevel: 'low',
    confidence: 0.85,
    contributingFactors: [],
    aiReasoning: 'Normal',
    doctorRecommendations: 'None',
    source: 'fallback_rules',
  });
});

describe('Security & Negative Testing Audit', () => {
  describe('IDOR (Insecure Direct Object Reference) Protection', () => {
    let agentA, agentB;
    let patientA;
    let screeningA;

    beforeEach(async () => {
      agentA = await createAgent('9870000001', 'Agent Alice');
      agentB = await createAgent('9870000002', 'Agent Bob');

      // Patient belonging to Agent A
      const pRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${agentA.accessToken}`)
        .send({ name: 'Alice Patient', age: 40, gender: 'female', village: 'Village A' });
      patientA = pRes.body.data;

      // Screening belonging to Agent A
      const sRes = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${agentA.accessToken}`)
        .send({ patientId: patientA.id, painLevel: 5 });
      screeningA = sRes.body.data;
    });

    it('prevents Agent B from reading Agent A patient', async () => {
      const res = await request(app)
        .get(`${PATIENT_BASE}/${patientA.id}`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from updating Agent A patient', async () => {
      const res = await request(app)
        .put(`${PATIENT_BASE}/${patientA.id}`)
        .set('Authorization', `Bearer ${agentB.accessToken}`)
        .send({ name: 'Hacked Name' });
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from deleting Agent A patient', async () => {
      const res = await request(app)
        .delete(`${PATIENT_BASE}/${patientA.id}`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from creating a screening for Agent A patient', async () => {
      const res = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${agentB.accessToken}`)
        .send({ patientId: patientA.id, painLevel: 3 });
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from reading Agent A screening', async () => {
      const res = await request(app)
        .get(`${SCREENING_BASE}/${screeningA.id}`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from reading screenings by patient for Agent A patient', async () => {
      const res = await request(app)
        .get(`${SCREENING_BASE}/patient/${patientA.id}`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from downloading Agent A PDF report', async () => {
      const res = await request(app)
        .get(`${SCREENING_BASE}/${screeningA.id}/report`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(404);
    });

    it('prevents Agent B from creating a screening for Agent A patient via offline sync', async () => {
      const res = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${agentB.accessToken}`)
        .send({
          items: [
            {
              type: 'screening',
              localId: 'idor-scr-1',
              action: 'create',
              data: { patientId: patientA.id, painLevel: 7 },
            },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.results[0].success).toBe(false);
      expect(res.body.results[0].error).toContain('not found or not owned');
    });

    it('prevents Agent B from updating Agent A patient via offline sync', async () => {
      const res = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${agentB.accessToken}`)
        .send({
          items: [
            {
              type: 'patient',
              localId: 'idor-pat-1',
              action: 'update',
              data: { id: patientA.id, name: 'Tampered' },
            },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.results[0].success).toBe(false);
      expect(res.body.results[0].error).toContain('not found or not owned');
    });

    it('isolates analytics so Agent B cannot see Agent A data', async () => {
      const res = await request(app)
        .get(`${ANALYTICS_BASE}/overview`)
        .set('Authorization', `Bearer ${agentB.accessToken}`);
      expect(res.status).toBe(200);
      expect(res.body.data.totalPatients).toBe(0);
      expect(res.body.data.totalScreenings).toBe(0);
    });
  });

  describe('Authentication Negative Testing', () => {
    let agent;

    beforeEach(async () => {
      agent = await createAgent('9870000003', 'Auth Tester');
    });

    it('rejects login with wrong password', async () => {
      const res = await request(app).post(`${AUTH_BASE}/login`).send({
        phoneNumber: '9870000003',
        password: 'WrongPassword!',
      });
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects login with nonexistent phone number', async () => {
      const res = await request(app).post(`${AUTH_BASE}/login`).send({
        phoneNumber: '9999999999',
        password: 'AnyPassword!',
      });
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects malformed Authorization header', async () => {
      const res1 = await request(app).get(`${AUTH_BASE}/me`).set('Authorization', 'Basic 12345');
      expect(res1.status).toBe(401);

      const res2 = await request(app).get(`${AUTH_BASE}/me`).set('Authorization', 'Bearer');
      expect(res2.status).toBe(401);
    });

    it('rejects invalid JWT signature', async () => {
      const fakeToken = jwt.sign({ sub: '6512f9a2b8e4a2d1f8c9e123' }, 'wrong_secret');
      const res = await request(app).get(`${AUTH_BASE}/me`).set('Authorization', `Bearer ${fakeToken}`);
      expect(res.status).toBe(401);
    });

    it('rejects expired JWT token', async () => {
      const expiredToken = jwt.sign(
        { sub: agent.user.id },
        env.JWT_ACCESS_SECRET,
        { expiresIn: '-10s' }
      );
      const res = await request(app).get(`${AUTH_BASE}/me`).set('Authorization', `Bearer ${expiredToken}`);
      expect(res.status).toBe(401);
    });

    it('revokes refresh token on logout and rejects subsequent refresh with it', async () => {
      // 1. Logout
      const logoutRes = await request(app)
        .post(`${AUTH_BASE}/logout`)
        .set('Authorization', `Bearer ${agent.accessToken}`)
        .send({ refreshToken: agent.refreshToken });
      expect(logoutRes.status).toBe(200);

      // 2. Attempting refresh with revoked token must fail with 401
      const refRes = await request(app)
        .post(`${AUTH_BASE}/refresh`)
        .send({ refreshToken: agent.refreshToken });
      expect(refRes.status).toBe(401);
      expect(refRes.body.message).toContain('revoked');
    });
  });

  describe('Input Validation and Negative Testing', () => {
    let token;

    beforeEach(async () => {
      const agent = await createAgent('9870000004', 'Validation Tester');
      token = agent.accessToken;
    });

    it('rejects negative age and excessive age for patient', async () => {
      const negAge = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Invalid Age', age: -5, gender: 'male' });
      expect(negAge.status).toBe(400);

      const excessAge = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Invalid Age', age: 250, gender: 'male' });
      expect(excessAge.status).toBe(400);
    });

    it('rejects invalid gender enum', async () => {
      const res = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Invalid Gender', age: 30, gender: 'unknown' });
      expect(res.status).toBe(400);
    });

    it('rejects invalid painLevel (<0 or >10)', async () => {
      const pRes = await request(app)
        .post(PATIENT_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Pain Patient', age: 50, gender: 'female' });
      const patientId = pRes.body.data.id;

      const tooHigh = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ patientId, painLevel: 11 });
      expect(tooHigh.status).toBe(400);

      const tooLow = await request(app)
        .post(SCREENING_BASE)
        .set('Authorization', `Bearer ${token}`)
        .send({ patientId, painLevel: -1 });
      expect(tooLow.status).toBe(400);
    });

    it('handles malformed ObjectId gracefully without 500 crashes', async () => {
      const res1 = await request(app)
        .get(`${PATIENT_BASE}/not-a-valid-id`)
        .set('Authorization', `Bearer ${token}`);
      expect([400, 404]).toContain(res1.status);

      const res2 = await request(app)
        .get(`${SCREENING_BASE}/not-a-valid-id`)
        .set('Authorization', `Bearer ${token}`);
      expect([400, 404]).toContain(res2.status);

      const res3 = await request(app)
        .get(`${SCREENING_BASE}/not-a-valid-id/report`)
        .set('Authorization', `Bearer ${token}`);
      expect([400, 404]).toContain(res3.status);
    });

    it('rejects invalid analytics period query with 400', async () => {
      const res = await request(app)
        .get(`${ANALYTICS_BASE}/trends`)
        .set('Authorization', `Bearer ${token}`)
        .query({ period: 'invalid-period' });
      expect(res.status).toBe(400);
      expect(res.body.message).toContain('period must be one of');
    });

    it('processes mixed valid and invalid batch sync items without failing the entire batch', async () => {
      const res = await request(app)
        .post(`${SYNC_BASE}/batch`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          items: [
            {
              type: 'patient',
              localId: 'valid-pat',
              action: 'create',
              data: { name: 'Valid In Batch', age: 35, gender: 'other' },
            },
            {
              type: 'screening',
              localId: 'invalid-scr',
              action: 'create',
              data: { patientId: '6512f9a2b8e4a2d1f8c9e999', painLevel: 4 }, // Non-existent patient
            },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.results).toHaveLength(2);
      expect(res.body.results[0].success).toBe(true);
      expect(res.body.results[1].success).toBe(false);
      expect(res.body.results[1].error).toBeDefined();
    });
  });
});
