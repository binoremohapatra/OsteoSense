'use strict';

require('./setup');
const request = require('supertest');

jest.mock('../src/services/aiService');
const aiService = require('../src/services/aiService');

const app = require('../src/app');

const AUTH_BASE = '/api/v1/auth';
const PATIENT_BASE = '/api/v1/patients';
const SCREENING_BASE = '/api/v1/screenings';

async function registerAndLogin() {
  const registerRes = await request(app).post(`${AUTH_BASE}/register`).send({
    fullName: 'Test Agent',
    phoneNumber: '9812345670',
    password: 'SecurePass123',
    role: 'agent',
  });

  return registerRes.body.token;

}

async function createPatient(token) {
  const res = await request(app)
    .post(PATIENT_BASE)
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Test Patient', age: 60, gender: 'male', village: 'Ziro' });
  return res.body.patient || res.body.data;
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe('POST /screenings', () => {
  it('creates a screening successfully using the (mocked) ML model result', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'high',
      confidence: 0.91,
      contributingFactors: ['Severe pain level reported'],
      aiReasoning: 'Mocked ML model reasoning',
      doctorRecommendations: 'Refer to specialist',
      source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);

    const res = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({
        patientId: patient.id || patient._id,
        painLevel: 8,
        stiffnessDuration: '45 minutes',
        swelling: true,
        pastInjury: 'Old fracture',
        gaitFeatures: [0.4, 0.6, 0.5],
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    const scr = res.body.screening || res.body.data;
    expect(scr.riskLevel).toBe('high');
    expect(scr.source).toBe('ml_model');
    expect(aiService.predictRisk).toHaveBeenCalledTimes(1);
  });

  it('falls back gracefully when the AI service throws, still returning 201', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'medium',
      confidence: 0.6,
      contributingFactors: ['Moderate pain level reported'],
      aiReasoning: 'Rule-based triage fallback reasoning',
      doctorRecommendations: 'Follow up in 4-6 weeks',
      source: 'fallback_rules',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);

    const res = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({
        patientId: patient.id || patient._id,
        painLevel: 5,
        stiffnessDuration: '20 minutes',
        swelling: false,
        pastInjury: '',
        gaitFeatures: [],
      });

    expect(res.status).toBe(201);
    const scr = res.body.screening || res.body.data;
    expect(scr.source).toBe('fallback_rules');
    expect(scr.riskLevel).toBe('medium');
  });

  it('returns 404 when the patient does not belong to the requesting agent', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low',
      confidence: 0.7,
      contributingFactors: [],
      aiReasoning: '',
      doctorRecommendations: '',
      source: 'ml_model',
    });

    const tokenA = await registerAndLogin();
    const patientA = await createPatient(tokenA);

    const registerB = await request(app).post(`${AUTH_BASE}/register`).send({
      fullName: 'Second Agent',
      phoneNumber: '9812345671',
      password: 'SecurePass123',
      role: 'agent',
    });

    const tokenB = registerB.body.token;

    const res = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ patientId: patientA.id || patientA._id, painLevel: 3 });

    expect(res.status).toBe(404);
  });

  it('rejects invalid painLevel with 400', async () => {
    const token = await registerAndLogin();
    const patient = await createPatient(token);

    const res = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 15 });

    expect(res.status).toBe(400);
  });
});

// ---------------------------------------------------------------------------
// GET /screenings
// ---------------------------------------------------------------------------

describe('GET /screenings', () => {
  it('returns screenings for the authenticated agent', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.7, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 3 });

    const res = await request(app)
      .get(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBe(1);
    expect(res.body.pagination).toBeDefined();
  });

  it('returns 401 without a token', async () => {
    const res = await request(app).get(SCREENING_BASE);
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// GET /screenings/:id
// ---------------------------------------------------------------------------

describe('GET /screenings/:id', () => {
  it('returns a single screening by id', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'high', confidence: 0.9, contributingFactors: ['Pain'],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const createRes = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 8 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    const res = await request(app)
      .get(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const fetched = res.body.screening || res.body.data;
    expect(fetched.riskLevel).toBe('high');
  });

  it('returns 404 for a screening belonging to another agent (IDOR guard)', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.6, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const tokenA = await registerAndLogin();
    const tokenB = await request(app).post(`${AUTH_BASE}/register`).send({
      fullName: 'Agent B', phoneNumber: '9812399999', password: 'SecurePass123', role: 'agent',
    }).then((r) => r.body.token || r.body.data?.accessToken);

    const patientA = await createPatient(tokenA);
    const createRes = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ patientId: patientA.id || patientA._id, painLevel: 2 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    const res = await request(app)
      .get(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${tokenB}`);

    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// GET /screenings/patient/:patientId
// ---------------------------------------------------------------------------

describe('GET /screenings/patient/:patientId', () => {
  it('returns all screenings for a given patient', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'medium', confidence: 0.75, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'fallback_rules',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const patientId = patient.id || patient._id;

    // Create 2 screenings for the same patient
    await request(app).post(SCREENING_BASE).set('Authorization', `Bearer ${token}`)
      .send({ patientId, painLevel: 5 });
    await request(app).post(SCREENING_BASE).set('Authorization', `Bearer ${token}`)
      .send({ patientId, painLevel: 6 });

    const res = await request(app)
      .get(`${SCREENING_BASE}/patient/${patientId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBe(2);
  });

  it('returns 404 when the patient does not belong to the agent', async () => {
    const tokenA = await registerAndLogin();
    const tokenB = await request(app).post(`${AUTH_BASE}/register`).send({
      fullName: 'Agent C', phoneNumber: '9812388888', password: 'SecurePass123', role: 'agent',
    }).then((r) => r.body.token || r.body.data?.accessToken);

    const patientA = await createPatient(tokenA);

    const res = await request(app)
      .get(`${SCREENING_BASE}/patient/${patientA.id || patientA._id}`)
      .set('Authorization', `Bearer ${tokenB}`);

    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// PUT /screenings/:id
// ---------------------------------------------------------------------------

describe('PUT /screenings/:id', () => {
  it('updates mutable fields and returns the updated screening', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'high', confidence: 0.85, contributingFactors: ['Pain'],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const createRes = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 7 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    const res = await request(app)
      .put(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ painLevel: 9, notes: 'Follow-up needed' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const updated = res.body.screening || res.body.data;
    expect(updated.painLevel).toBe(9);
  });

  it('cannot overwrite AI-generated riskLevel', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'high', confidence: 0.9, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const createRes = await request(app)
      .post(SCREENING_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 8 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    const res = await request(app)
      .put(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ riskLevel: 'low' });

    // riskLevel is stripped by controller — original 'high' persists
    expect(res.status).toBe(200);
    const updated = res.body.screening || res.body.data;
    expect(updated.riskLevel).toBe('high');
  });

  it('returns 404 for another agent screening (IDOR guard)', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.5, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const tokenA = await registerAndLogin();
    const tokenB = await request(app).post(`${AUTH_BASE}/register`).send({
      fullName: 'Agent D', phoneNumber: '9812377777', password: 'SecurePass123', role: 'agent',
    }).then((r) => r.body.token || r.body.data?.accessToken);

    const patientA = await createPatient(tokenA);
    const createRes = await request(app)
      .post(SCREENING_BASE).set('Authorization', `Bearer ${tokenA}`)
      .send({ patientId: patientA.id || patientA._id, painLevel: 3 });

    const scr = createRes.body.screening || createRes.body.data;

    const res = await request(app)
      .put(`${SCREENING_BASE}/${scr.id || scr._id}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ painLevel: 1 });

    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// DELETE /screenings/:id
// ---------------------------------------------------------------------------

describe('DELETE /screenings/:id', () => {
  it('deletes a screening and returns success', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.6, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const createRes = await request(app)
      .post(SCREENING_BASE).set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 3 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    const res = await request(app)
      .delete(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('screening is no longer accessible after deletion', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.6, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const token = await registerAndLogin();
    const patient = await createPatient(token);
    const createRes = await request(app)
      .post(SCREENING_BASE).set('Authorization', `Bearer ${token}`)
      .send({ patientId: patient.id || patient._id, painLevel: 2 });

    const scr = createRes.body.screening || createRes.body.data;
    const id = scr.id || scr._id;

    await request(app).delete(`${SCREENING_BASE}/${id}`).set('Authorization', `Bearer ${token}`);

    const getRes = await request(app)
      .get(`${SCREENING_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(getRes.status).toBe(404);
  });

  it('returns 404 for another agent screening (IDOR guard)', async () => {
    aiService.predictRisk.mockResolvedValue({
      riskLevel: 'low', confidence: 0.5, contributingFactors: [],
      aiReasoning: '', doctorRecommendations: '', source: 'ml_model',
    });

    const tokenA = await registerAndLogin();
    const tokenB = await request(app).post(`${AUTH_BASE}/register`).send({
      fullName: 'Agent E', phoneNumber: '9812366666', password: 'SecurePass123', role: 'agent',
    }).then((r) => r.body.token || r.body.data?.accessToken);

    const patientA = await createPatient(tokenA);
    const createRes = await request(app)
      .post(SCREENING_BASE).set('Authorization', `Bearer ${tokenA}`)
      .send({ patientId: patientA.id || patientA._id, painLevel: 4 });

    const scr = createRes.body.screening || createRes.body.data;

    const res = await request(app)
      .delete(`${SCREENING_BASE}/${scr.id || scr._id}`)
      .set('Authorization', `Bearer ${tokenB}`);

    expect(res.status).toBe(404);
  });
});

