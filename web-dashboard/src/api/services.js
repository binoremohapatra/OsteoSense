import client from './client';

// ---------- Auth ----------
export const authApi = {
  register: (payload) => client.post('/auth/register', payload).then((r) => r.data),
  login: (payload) => client.post('/auth/login', payload).then((r) => r.data),
  logout: (refreshToken) => client.post('/auth/logout', { refreshToken }).then((r) => r.data),
  me: () => client.get('/auth/me').then((r) => r.data),
  healthWorkers: () => client.get('/users/health-workers').then((r) => r.data),
};

// ---------- Patients ----------
export const patientsApi = {
  create: (payload) => client.post('/patients', payload).then((r) => r.data),
  list: (params) => client.get('/patients', { params }).then((r) => r.data),
  listAll: (params) => client.get('/patients', { params: { ...params, allPatients: 'true' } }).then((r) => r.data),
  search: (q, params = {}) => client.get('/patients/search', { params: { q, ...params } }).then((r) => r.data),
  getById: (id, params = {}) => client.get(`/patients/${id}`, { params }).then((r) => r.data),
  update: (id, payload) => client.put(`/patients/${id}`, payload).then((r) => r.data),
  remove: (id) => client.delete(`/patients/${id}`).then((r) => r.data),
};

// ---------- Screenings ----------
export const screeningsApi = {
  create: (payload) => client.post('/screenings', payload).then((r) => r.data),
  list: (params) => client.get('/screenings', { params }).then((r) => r.data),
  listAll: (params) => client.get('/screenings', { params: { ...params, allScreenings: 'true' } }).then((r) => r.data),
  getById: (id) => client.get(`/screenings/${id}`).then((r) => r.data),
  byPatient: (patientId) => client.get(`/screenings/patient/${patientId}`).then((r) => r.data),
  downloadReportUrl: (id) => `/screenings/${id}/report`,
  downloadReport: (id) =>
    client.get(`/screenings/${id}/report`, { responseType: 'blob' }).then((r) => r.data),
};

// ---------- Analytics ----------
export const analyticsApi = {
  overview: () => client.get('/analytics/overview').then((r) => r.data),
  trends: (period = '30d') => client.get('/analytics/trends', { params: { period } }).then((r) => r.data),
  riskDistribution: () => client.get('/analytics/risk-distribution').then((r) => r.data),
  locations: () => client.get('/analytics/locations').then((r) => r.data),
};

// ---------- Global Analytics ----------
export const globalAnalyticsApi = {
  overview: () => client.get('/global-analytics/overview').then((r) => r.data),
  trends: (period = '30d') => client.get('/global-analytics/trends', { params: { period } }).then((r) => r.data),
  riskDistribution: () => client.get('/global-analytics/risk-distribution').then((r) => r.data),
  locations: () => client.get('/global-analytics/locations').then((r) => r.data),
};

// ---------- Sync ----------
export const syncApi = {
  batch: (items) => client.post('/sync/batch', { items }).then((r) => r.data),
  status: () => client.get('/sync/status').then((r) => r.data),
};

// ---------- Preventive Care ----------
export const preventiveCareApi = {
  list: (params) => client.get('/preventive-care', { params }).then((r) => r.data),
};

// ---------- Village Assignments ----------
export const villageAssignmentApi = {
  list: (params) => client.get('/village-assignments', { params }).then((r) => r.data),
  getHealthWorkerForVillage: (village) => client.get(`/village-assignments/health-worker/${encodeURIComponent(village)}`).then((r) => r.data),
};

// ---------- Admin Database Section & Portal ----------
export const adminApi = {
  getOverview: () => client.get('/admin/overview').then((r) => r.data),
  getSection: () => client.get('/admin/section').then((r) => r.data),
  getAuditLogs: () => client.get('/admin/audit-logs').then((r) => r.data),
  logAction: (payload) => client.post('/admin/audit-logs', payload).then((r) => r.data),
  getSettings: () => client.get('/admin/settings').then((r) => r.data),
  updateSettings: (payload) => client.put('/admin/settings', payload).then((r) => r.data),
  createAdmin: (payload) => client.post('/admin/create', payload).then((r) => r.data),
};



