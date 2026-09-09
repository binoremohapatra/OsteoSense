'use strict';

require('./setup');
const request = require('supertest');
const app = require('../src/app');

const AUTH_BASE = '/api/v1/auth';
const PATIENT_BASE = '/api/v1/patients';

async function registerAndLogin(phone = '9800000001') {
  const res = await request(app).post(`${AUTH_BASE}/register`).send({
    fullName: 'Test Agent',
    phoneNumber: phone,
    password: 'SecurePass123',
    role: 'agent',
  });
  return res.body.token || res.body.data?.accessToken;
}

async function createPatient(token, overrides = {}) {
  const res = await request(app)
    .post(PATIENT_BASE)
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Ramesh Kumar', age: 55, gender: 'male', village: 'Aalo', ...overrides });
  return res.body.patient || res.body.data;
}

// ---------------------------------------------------------------------------
// POST /patients
// ---------------------------------------------------------------------------

describe('POST /patients', () => {
  it('creates a patient and returns id + server_id', async () => {
    const token = await registerAndLogin('9800000001');
    const res = await request(app)
      .post(PATIENT_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Sita Devi', age: 62, gender: 'female', village: 'Ziro' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    const p = res.body.patient || res.body.data;
    expect(p).toBeDefined();
    expect(p.name).toBe('Sita Devi');
    expect(typeof (p.id || p._id)).toBe('string');
    expect(p.server_id).toBeDefined();
  });

  it('accepts fullName alias (Flutter sends fullName)', async () => {
    const token = await registerAndLogin('9800000002');
    const res = await request(app)
      .post(PATIENT_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ fullName: 'Mohan Lal', age: 48, gender: 'male' });
    expect(res.status).toBe(201);
    const p = res.body.patient || res.body.data;
    expect(p.name || p.fullName).toMatch(/Mohan Lal/i);
  });

  it('returns 400 for missing required fields', async () => {
    const token = await registerAndLogin('9800000003');
    const res = await request(app)
      .post(PATIENT_BASE)
      .set('Authorization', `Bearer ${token}`)
      .send({ age: 40 });
    expect(res.status).toBe(400);
  });

  it('returns 401 without a token', async () => {
    const res = await request(app)
      .post(PATIENT_BASE)
      .send({ name: 'X', age: 30, gender: 'male' });
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// GET /patients (unpaginated — Flutter mobile app)
// ---------------------------------------------------------------------------

describe('GET /patients (unpaginated)', () => {
  it('returns a raw JSON array when no page/limit params are sent', async () => {
    const token = await registerAndLogin('9800000011');
    await createPatient(token, { name: 'P1' });
    await createPatient(token, { name: 'P2' });
    const res = await request(app).get(PATIENT_BASE).set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(2);
  });

  it('does not return patients belonging to another agent', async () => {
    const tokenA = await registerAndLogin('9800000012');
    const tokenB = await registerAndLogin('9800000013');
    await createPatient(tokenA, { name: 'AgentA Patient' });
    const res = await request(app).get(PATIENT_BASE).set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(0);
  });

  it('excludes soft-deleted patients', async () => {
    const token = await registerAndLogin('9800000014');
    const patient = await createPatient(token, { name: 'To Be Deleted' });
    await request(app)
      .delete(`${PATIENT_BASE}/${patient.id || patient._id}`)
      .set('Authorization', `Bearer ${token}`);
    const res = await request(app).get(PATIENT_BASE).set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// GET /patients (paginated — web dashboard)
// ---------------------------------------------------------------------------

describe('GET /patients (paginated)', () => {
  it('returns paginated result with pagination metadata', async () => {
    const token = await registerAndLogin('9800000021');
    await createPatient(token, { name: 'P1' });
    await createPatient(token, { name: 'P2' });
    await createPatient(token, { name: 'P3' });
    const res = await request(app)
      .get(`${PATIENT_BASE}?page=1&limit=2`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBe(2);
    expect(res.body.pagination).toBeDefined();
    expect(res.body.pagination.total).toBe(3);
    expect(res.body.pagination.totalPages).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// GET /patients/search
// ---------------------------------------------------------------------------

describe('GET /patients/search', () => {
  it('finds patients by name (case-insensitive)', async () => {
    const token = await registerAndLogin('9800000031');
    await createPatient(token, { name: 'Geeta Sharma' });
    await createPatient(token, { name: 'Lakshmi Das' });
    const res = await request(app)
      .get(`${PATIENT_BASE}/search?q=geeta`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
    expect(res.body.data[0].name).toMatch(/Geeta/i);
  });

  it('finds patients by village', async () => {
    const token = await registerAndLogin('9800000032');
    await createPatient(token, { name: 'A', village: 'Hapoli' });
    await createPatient(token, { name: 'B', village: 'Ziro' });
    const res = await request(app)
      .get(`${PATIENT_BASE}/search?q=Hapoli`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
  });

  it('returns empty array when nothing matches', async () => {
    const token = await registerAndLogin('9800000033');
    await createPatient(token, { name: 'Test Patient' });
    const res = await request(app)
      .get(`${PATIENT_BASE}/search?q=ZZZNoMatch`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// GET /patients/:id
// ---------------------------------------------------------------------------

describe('GET /patients/:id', () => {
  it('returns a single patient with screeningHistoryCount', async () => {
    const token = await registerAndLogin('9800000041');
    const patient = await createPatient(token);
    const id = patient.id || patient._id;
    const res = await request(app)
      .get(`${PATIENT_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    const p = res.body.patient || res.body.data;
    expect(p.screeningHistoryCount).toBe(0);
  });

  it('returns 404 for another agent patient (IDOR guard)', async () => {
    const tokenA = await registerAndLogin('9800000042');
    const tokenB = await registerAndLogin('9800000043');
    const patientA = await createPatient(tokenA);
    const res = await request(app)
      .get(`${PATIENT_BASE}/${patientA.id || patientA._id}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(404);
  });

  it('returns 404 for an invalid id format', async () => {
    const token = await registerAndLogin('9800000044');
    const res = await request(app)
      .get(`${PATIENT_BASE}/not-a-valid-id`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// PUT /patients/:id
// ---------------------------------------------------------------------------

describe('PUT /patients/:id', () => {
  it('updates patient fields and returns updated data', async () => {
    const token = await registerAndLogin('9800000051');
    const patient = await createPatient(token, { name: 'Original Name', age: 50 });
    const id = patient.id || patient._id;
    const res = await request(app)
      .put(`${PATIENT_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Updated Name', age: 51 });
    expect(res.status).toBe(200);
    const p = res.body.patient || res.body.data;
    expect(p.name).toBe('Updated Name');
    expect(p.age).toBe(51);
  });

  it('returns 404 when updating another agent patient (IDOR guard)', async () => {
    const tokenA = await registerAndLogin('9800000052');
    const tokenB = await registerAndLogin('9800000053');
    const patientA = await createPatient(tokenA);
    const res = await request(app)
      .put(`${PATIENT_BASE}/${patientA.id || patientA._id}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ name: 'Hijacked' });
    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// DELETE /patients/:id
// ---------------------------------------------------------------------------

describe('DELETE /patients/:id', () => {
  it('soft-deletes a patient and returns success', async () => {
    const token = await registerAndLogin('9800000061');
    const patient = await createPatient(token);
    const res = await request(app)
      .delete(`${PATIENT_BASE}/${patient.id || patient._id}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('patient is no longer visible after deletion', async () => {
    const token = await registerAndLogin('9800000062');
    const patient = await createPatient(token);
    const id = patient.id || patient._id;
    await request(app).delete(`${PATIENT_BASE}/${id}`).set('Authorization', `Bearer ${token}`);
    const getRes = await request(app)
      .get(`${PATIENT_BASE}/${id}`)
      .set('Authorization', `Bearer ${token}`);
    expect(getRes.status).toBe(404);
  });

  it('returns 404 when deleting another agent patient (IDOR guard)', async () => {
    const tokenA = await registerAndLogin('9800000063');
    const tokenB = await registerAndLogin('9800000064');
    const patientA = await createPatient(tokenA);
    const res = await request(app)
      .delete(`${PATIENT_BASE}/${patientA.id || patientA._id}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(404);
  });
});
