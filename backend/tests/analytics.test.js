'use strict';

require('./setup');
const request = require('supertest');

jest.mock('../src/services/aiService');
const aiService = require('../src/services/aiService');

const app = require('../src/app');

const AUTH_BASE = '/api/v1/auth';
const PATIENT_BASE = '/api/v1/patients';
const SCREENING_BASE = '/api/v1/screenings';
const ANALYTICS_BASE = '/api/v1/analytics';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const DEFAULT_AI_RESULT = {
  riskLevel: 'high',
  confidence: 0.88,
  contributingFactors: ['Severe pain'],
  aiReasoning: 'Test reasoning',
  doctorRecommendations: 'See a specialist',
  source: 'ml_model',
};

async function registerAndLogin(phone) {
  const res = await request(app).post(`${AUTH_BASE}/register`).send({
    fullName: 'Analytics Agent',
    phoneNumber: phone,
    password: 'SecurePass123',
    role: 'agent',
  });
  return res.body.token || res.body.data?.accessToken;
}

async function createPatient(token, village = 'Ziro') {
  const res = await request(app)
    .post(PATIENT_BASE)
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Test Patient', age: 60, gender: 'female', village });
  return res.body.patient || res.body.data;
}

async function createScreening(token, patientId, riskLevel = 'high') {
  aiService.predictRisk.mockResolvedValueOnce({ ...DEFAULT_AI_RESULT, riskLevel });
  const res = await request(app)
    .post(SCREENING_BASE)
    .set('Authorization', `Bearer ${token}`)
    .send({ patientId, painLevel: 7, swelling: true });
  return res.body.screening || res.body.data;
}

beforeEach(() => {
  jest.clearAllMocks();
});

// ---------------------------------------------------------------------------
// GET /analytics/overview
// ---------------------------------------------------------------------------

describe('GET /analytics/overview', () => {
  it('returns totalPatients, totalScreenings, riskDistribution, avgConfidence', async () => {
    const token = await registerAndLogin('9700000001');
    const patient = await createPatient(token);
    await createScreening(token, patient.id || patient._id, 'high');

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/overview`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const d = res.body.data;
    expect(d.totalPatients).toBe(1);
    expect(d.totalScreenings).toBe(1);
    expect(d.riskDistribution).toEqual(expect.objectContaining({ low: 0, medium: 0, high: 1 }));
    expect(typeof d.avgConfidence).toBe('number');
  });

  it('returns zeros for a new agent with no data', async () => {
    const token = await registerAndLogin('9700000002');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/overview`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    const d = res.body.data;
    expect(d.totalPatients).toBe(0);
    expect(d.totalScreenings).toBe(0);
    expect(d.riskDistribution).toEqual({ low: 0, medium: 0, high: 0 });
    expect(d.avgConfidence).toBeNull();
  });

  it('only counts data belonging to the requesting agent', async () => {
    const tokenA = await registerAndLogin('9700000003');
    const tokenB = await registerAndLogin('9700000004');
    const patientA = await createPatient(tokenA);
    await createScreening(tokenA, patientA.id || patientA._id);

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/overview`)
      .set('Authorization', `Bearer ${tokenB}`);

    expect(res.status).toBe(200);
    expect(res.body.data.totalPatients).toBe(0);
    expect(res.body.data.totalScreenings).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// GET /analytics/trends
// ---------------------------------------------------------------------------

describe('GET /analytics/trends', () => {
  it('returns an array of { date, count } objects', async () => {
    const token = await registerAndLogin('9700000011');
    const patient = await createPatient(token);
    await createScreening(token, patient.id || patient._id);

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/trends?period=7d`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    if (res.body.data.length > 0) {
      expect(res.body.data[0]).toHaveProperty('date');
      expect(res.body.data[0]).toHaveProperty('count');
    }
  });

  it('accepts period=30d', async () => {
    const token = await registerAndLogin('9700000012');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/trends?period=30d`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
  });

  it('returns 400 for invalid period', async () => {
    const token = await registerAndLogin('9700000013');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/trends?period=999d`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(400);
  });
});

// ---------------------------------------------------------------------------
// GET /analytics/screening-trends  (Flutter alias)
// ---------------------------------------------------------------------------

describe('GET /analytics/screening-trends (Flutter alias)', () => {
  it('returns same data shape as /trends', async () => {
    const token = await registerAndLogin('9700000021');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/screening-trends?period=30d`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('returns 400 for invalid period', async () => {
    const token = await registerAndLogin('9700000022');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/screening-trends?period=bad`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(400);
  });
});

// ---------------------------------------------------------------------------
// GET /analytics/risk-distribution
// ---------------------------------------------------------------------------

describe('GET /analytics/risk-distribution', () => {
  it('returns low/medium/high counts', async () => {
    const token = await registerAndLogin('9700000031');
    const patient = await createPatient(token);
    await createScreening(token, patient.id || patient._id, 'low');

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/risk-distribution`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual(expect.objectContaining({ low: 1, medium: 0, high: 0 }));
  });
});

// ---------------------------------------------------------------------------
// GET /analytics/locations
// ---------------------------------------------------------------------------

describe('GET /analytics/locations', () => {
  it('returns villages with totalScreenings and highRiskCount', async () => {
    const token = await registerAndLogin('9700000041');
    const patient = await createPatient(token, 'Hapoli');
    await createScreening(token, patient.id || patient._id, 'high');

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/locations`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    const village = res.body.data.find((v) => v.village === 'Hapoli');
    expect(village).toBeDefined();
    expect(village.totalScreenings).toBe(1);
    expect(village.highRiskCount).toBe(1);
  });

  it('returns empty array for a new agent', async () => {
    const token = await registerAndLogin('9700000042');
    const res = await request(app)
      .get(`${ANALYTICS_BASE}/locations`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// GET /analytics/population-insights  (Flutter alias)
// ---------------------------------------------------------------------------

describe('GET /analytics/population-insights (Flutter alias)', () => {
  it('returns overview payload including riskDistribution', async () => {
    const token = await registerAndLogin('9700000051');
    const patient = await createPatient(token);
    await createScreening(token, patient.id || patient._id, 'medium');

    const res = await request(app)
      .get(`${ANALYTICS_BASE}/population-insights`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const d = res.body.data;
    expect(d).toHaveProperty('riskDistribution');
    expect(d).toHaveProperty('totalPatients');
    expect(d.riskDistribution.medium).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// Auth guard — all endpoints require Bearer token
// ---------------------------------------------------------------------------

describe('Analytics auth guard', () => {
  const endpoints = [
    '/overview',
    '/trends',
    '/screening-trends',
    '/risk-distribution',
    '/locations',
    '/population-insights',
  ];

  endpoints.forEach((path) => {
    it(`GET ${path} returns 401 without token`, async () => {
      const res = await request(app).get(`${ANALYTICS_BASE}${path}`);
      expect(res.status).toBe(401);
    });
  });
});
