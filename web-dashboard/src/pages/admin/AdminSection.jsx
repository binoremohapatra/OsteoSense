import { useEffect, useState } from 'react';
import {
  Shield,
  Users,
  Database,
  Sliders,
  History,
  CheckCircle2,
  AlertTriangle,
  UserPlus,
  RefreshCw,
  Lock,
  Server,
  Activity,
} from 'lucide-react';
import { adminApi, authApi } from '../../api/services';
import { useAuth } from '../../context/AuthContext';
import Spinner from '../../components/Spinner';
import Modal from '../../components/Modal';
import '../dashboard/Dashboard.css';

export default function AdminSection() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState(null);
  const [adminsList, setAdminsList] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [settings, setSettings] = useState({
    highRiskAlertThreshold: 20,
    autoAssignmentEnabled: true,
    dataRetentionDays: 365,
    smsAlertsEnabled: true,
    emailAlertsEnabled: true,
    adminContactEmail: 'admin@jointsaathi.org',
  });
  const [healthWorkers, setHealthWorkers] = useState([]);
  const [savingSettings, setSavingSettings] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [newAdminForm, setNewAdminForm] = useState({
    fullName: '',
    phoneNumber: '',
    password: '',
    adminRole: 'district_admin',
    department: 'District Public Health Administration',
    jurisdiction: 'District Screening Camps',
  });
  const [adminError, setAdminError] = useState('');
  const [creatingAdmin, setCreatingAdmin] = useState(false);

  const fetchAllAdminData = async () => {
    setLoading(true);
    try {
      const [ovRes, secRes, logsRes, setsRes, workersRes] = await Promise.all([
        adminApi.getOverview().catch(() => ({ data: null })),
        adminApi.getSection().catch(() => ({ data: { admins: [] } })),
        adminApi.getAuditLogs().catch(() => ({ data: [] })),
        adminApi.getSettings().catch(() => ({ data: null })),
        authApi.healthWorkers().catch(() => ({ data: [] })),
      ]);

      if (ovRes?.data) setOverview(ovRes.data);
      if (secRes?.data?.admins) setAdminsList(secRes.data.admins);
      if (logsRes?.data) setAuditLogs(logsRes.data);
      if (setsRes?.data) setSettings((prev) => ({ ...prev, ...setsRes.data }));
      if (workersRes?.data) setHealthWorkers(workersRes.data);
    } catch (err) {
      console.error('Failed to load admin data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllAdminData();
  }, []);

  const handleSaveSettings = async (e) => {
    e.preventDefault();
    setSavingSettings(true);
    setSaveMessage('');
    try {
      await adminApi.updateSettings(settings);
      setSaveMessage('System settings saved and updated in database successfully.');
      setTimeout(() => setSaveMessage(''), 4000);
      const updatedLogs = await adminApi.getAuditLogs();
      setAuditLogs(updatedLogs.data || []);
    } catch (err) {
      setSaveMessage(err.response?.data?.message || 'Failed to update settings.');
    } finally {
      setSavingSettings(false);
    }
  };

  const handleCreateAdmin = async (e) => {
    e.preventDefault();
    setCreatingAdmin(true);
    setAdminError('');
    try {
      await adminApi.createAdmin(newAdminForm);
      setShowAddAdminModal(false);
      setNewAdminForm({
        fullName: '',
        phoneNumber: '',
        password: '',
        adminRole: 'district_admin',
        department: 'District Public Health Administration',
        jurisdiction: 'District Screening Camps',
      });
      await fetchAllAdminData();
    } catch (err) {
      setAdminError(err.response?.data?.message || 'Could not create administrator account.');
    } finally {
      setCreatingAdmin(false);
    }
  };

  if (loading && !overview) return <Spinner />;

  return (
    <div>
      <div className="page-head">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 5,
                background: 'rgba(79, 103, 87, 0.12)',
                color: 'var(--primary-dark)',
                padding: '3px 9px',
                borderRadius: '999px',
                fontSize: 11.5,
                fontWeight: 700,
                letterSpacing: '0.04em',
                textTransform: 'uppercase',
              }}
            >
              <Shield size={13} /> Admin Database Section
            </span>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 4,
                background: 'rgba(16, 185, 129, 0.12)',
                color: '#059669',
                padding: '3px 8px',
                borderRadius: '999px',
                fontSize: 11,
                fontWeight: 600,
              }}
            >
              <CheckCircle2 size={12} /> System Active
            </span>
          </div>
          <h1>Administration & Database Hub</h1>
          <p>
            Central control for administrator accounts, database integrity, system-wide configuration, and compliance audit logs.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-ghost" onClick={fetchAllAdminData}>
            <RefreshCw size={15} /> Refresh
          </button>
          <button className="btn btn-primary" onClick={() => setShowAddAdminModal(true)}>
            <UserPlus size={16} /> Add Administrator
          </button>
        </div>
      </div>

      <div className="tab-row" style={{ marginTop: 10, marginBottom: 24 }}>
        <button
          className={`chip${activeTab === 'overview' ? ' active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          <Server size={14} style={{ marginRight: 6 }} /> System & Database
        </button>
        <button
          className={`chip${activeTab === 'admins' ? ' active' : ''}`}
          onClick={() => setActiveTab('admins')}
        >
          <Shield size={14} style={{ marginRight: 6 }} /> Admin Accounts ({adminsList.length || 1})
        </button>
        <button
          className={`chip${activeTab === 'logs' ? ' active' : ''}`}
          onClick={() => setActiveTab('logs')}
        >
          <History size={14} style={{ marginRight: 6 }} /> Audit Logs ({auditLogs.length})
        </button>
        <button
          className={`chip${activeTab === 'settings' ? ' active' : ''}`}
          onClick={() => setActiveTab('settings')}
        >
          <Sliders size={14} style={{ marginRight: 6 }} /> System Configuration
        </button>
      </div>

      {activeTab === 'overview' && (
        <>
          <div className="stat-grid">
            <div className="card" style={{ position: 'relative', overflow: 'hidden' }}>
              <div className="muted-label">Database Collections</div>
              <div className="stat-number">5 Core</div>
              <div style={{ fontSize: 12.5, color: 'var(--text-tertiary)', marginTop: 6 }}>
                Users, Admins, Patients, Screenings, PreventiveCare
              </div>
            </div>
            <div className="card">
              <div className="muted-label">Registered Health Workers</div>
              <div className="stat-number">{overview?.metrics?.totalWorkers ?? healthWorkers.length}</div>
              <div style={{ fontSize: 12.5, color: 'var(--text-tertiary)', marginTop: 6 }}>
                Active in Field Camps
              </div>
            </div>
            <div className="card">
              <div className="muted-label">Total Patients in Database</div>
              <div className="stat-number">{overview?.metrics?.totalPatients ?? '—'}</div>
              <div style={{ fontSize: 12.5, color: 'var(--text-tertiary)', marginTop: 6 }}>
                Stored with End-to-End Records
              </div>
            </div>
            <div className="card">
              <div className="muted-label">High-Risk Case Volume</div>
              <div className="stat-number" style={{ color: 'var(--risk-high-dark)' }}>
                {overview?.metrics?.highRiskCount ?? '—'}
              </div>
              <div style={{ fontSize: 12.5, color: 'var(--text-tertiary)', marginTop: 6 }}>
                {overview?.metrics?.highRiskRate ?? 0}% of all screenings
              </div>
            </div>
          </div>

          <div className="two-col" style={{ marginTop: 20 }}>
            <div className="card">
              <h3 className="section-title">Current Admin Session Record</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--divider)', paddingBottom: 10 }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 13.5 }}>Administrator Name</span>
                  <strong style={{ fontSize: 13.5 }}>{user?.fullName || overview?.admin?.fullName}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--divider)', paddingBottom: 10 }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 13.5 }}>Admin Phone / ID</span>
                  <strong style={{ fontSize: 13.5 }}>{user?.phoneNumber || overview?.admin?.phoneNumber}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--divider)', paddingBottom: 10 }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 13.5 }}>Administrative Level</span>
                  <span className="pill pill--ok">{overview?.admin?.adminRole || 'Super Administrator'}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--divider)', paddingBottom: 10 }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 13.5 }}>Assigned Department</span>
                  <strong style={{ fontSize: 13.5 }}>{overview?.admin?.department || 'District Public Health'}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 13.5 }}>Session Security</span>
                  <span style={{ fontSize: 13, color: '#059669', display: 'flex', alignItems: 'center', gap: 5, fontWeight: 600 }}>
                    <Lock size={13} /> Bearer JWT Protected
                  </span>
                </div>
              </div>
            </div>

            <div className="card">
              <h3 className="section-title">Database Section Capabilities</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {[
                  'Full cross-worker patient and screening visibility',
                  'System-wide analytics and epidemiological aggregation',
                  'Admin-level audit trail logging in MongoDB',
                  'Field health worker assignment and jurisdiction rules',
                  'Dynamic risk threshold and notification management',
                ].map((cap, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13.5 }}>
                    <CheckCircle2 size={16} color="#4F6757" />
                    <span>{cap}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      {activeTab === 'admins' && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 className="section-title" style={{ margin: 0 }}>Registered System Administrators in Database</h3>
            <button className="btn btn-primary btn-sm" onClick={() => setShowAddAdminModal(true)}>
              <UserPlus size={15} /> Add New Admin
            </button>
          </div>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Administrator</th>
                  <th>Phone Number</th>
                  <th>Role / Level</th>
                  <th>Department</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {adminsList.length === 0 ? (
                  <tr>
                    <td>{user?.fullName || 'System Administrator'}</td>
                    <td>{user?.phoneNumber || '9999999999'}</td>
                    <td><span className="pill pill--ok">superadmin</span></td>
                    <td>District Public Health & Screening Administration</td>
                    <td><span className="pill pill--ok">Active</span></td>
                  </tr>
                ) : (
                  adminsList.map((adm) => (
                    <tr key={adm.id || adm._id}>
                      <td>
                        <strong>{adm.fullName}</strong>
                      </td>
                      <td>{adm.phoneNumber}</td>
                      <td>
                        <span className="pill pill--ok">{adm.adminRole || 'admin'}</span>
                      </td>
                      <td>{adm.department || 'Public Health'}</td>
                      <td>
                        <span className="pill pill--ok">Active</span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === 'logs' && (
        <div className="card">
          <h3 className="section-title">Administrative Audit Trail & Activity Logs</h3>
          <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
            Immutable administrative logs stored in the Admin database collection.
          </p>
          {auditLogs.length === 0 ? (
            <div style={{ padding: 24, textAlign: 'center', color: 'var(--text-secondary)' }}>
              No audit logs recorded yet.
            </div>
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Timestamp</th>
                    <th>Action</th>
                    <th>Details</th>
                    <th>Performed By</th>
                    <th>IP Address</th>
                  </tr>
                </thead>
                <tbody>
                  {auditLogs.map((log, idx) => (
                    <tr key={idx}>
                      <td style={{ fontSize: 12.5, whiteSpace: 'nowrap' }}>
                        {new Date(log.timestamp).toLocaleString('en-IN', {
                          day: 'numeric',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                          second: '2-digit',
                        })}
                      </td>
                      <td>
                        <span
                          style={{
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: 700,
                            color: 'var(--primary-dark)',
                            background: 'var(--primary-surface)',
                            padding: '2px 6px',
                            borderRadius: 4,
                          }}
                        >
                          {log.action}
                        </span>
                      </td>
                      <td style={{ fontSize: 13 }}>{log.details}</td>
                      <td>{log.performedBy || 'System Admin'}</td>
                      <td style={{ fontFamily: 'monospace', fontSize: 12, color: 'var(--text-tertiary)' }}>
                        {log.ipAddress || '127.0.0.1'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {activeTab === 'settings' && (
        <div className="card">
          <h3 className="section-title">Global Database & Administration Configuration</h3>
          {saveMessage && (
            <div
              style={{
                padding: '10px 14px',
                borderRadius: 8,
                background: saveMessage.includes('Failed') ? 'var(--risk-high-surface)' : 'var(--primary-surface)',
                color: saveMessage.includes('Failed') ? 'var(--risk-high-dark)' : 'var(--primary-dark)',
                fontSize: 13.5,
                fontWeight: 600,
                marginBottom: 16,
              }}
            >
              {saveMessage}
            </div>
          )}
          <form onSubmit={handleSaveSettings} style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
            <div className="field">
              <label htmlFor="highRiskAlertThreshold">High Risk Triage Alert Threshold (%)</label>
              <input
                id="highRiskAlertThreshold"
                type="number"
                min={1}
                max={100}
                value={settings.highRiskAlertThreshold}
                onChange={(e) => setSettings({ ...settings, highRiskAlertThreshold: Number(e.target.value) })}
                required
              />
              <span style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: 4 }}>
                Triggers visual program alerts if high-risk cases exceed this share in any health center.
              </span>
            </div>

            <div className="field">
              <label htmlFor="adminContactEmail">Primary Administrator Contact Email</label>
              <input
                id="adminContactEmail"
                type="email"
                value={settings.adminContactEmail}
                onChange={(e) => setSettings({ ...settings, adminContactEmail: e.target.value })}
                required
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 4 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontSize: 14 }}>
                <input
                  type="checkbox"
                  checked={settings.autoAssignmentEnabled}
                  onChange={(e) => setSettings({ ...settings, autoAssignmentEnabled: e.target.checked })}
                />
                Enable automated village-to-worker proximity mapping
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontSize: 14 }}>
                <input
                  type="checkbox"
                  checked={settings.smsAlertsEnabled}
                  onChange={(e) => setSettings({ ...settings, smsAlertsEnabled: e.target.checked })}
                />
                Send SMS escalation alerts to PHC officers for high-risk crepitus readings
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontSize: 14 }}>
                <input
                  type="checkbox"
                  checked={settings.emailAlertsEnabled}
                  onChange={(e) => setSettings({ ...settings, emailAlertsEnabled: e.target.checked })}
                />
                Enable automated weekly epidemiological reports
              </label>
            </div>

            <div>
              <button className="btn btn-primary" type="submit" disabled={savingSettings}>
                {savingSettings ? 'Saving Configuration…' : 'Save System Settings in Database'}
              </button>
            </div>
          </form>
        </div>
      )}

      {showAddAdminModal && (
        <Modal title="Register New Administrator" onClose={() => setShowAddAdminModal(false)}>
          {adminError && <div className="banner banner-error" style={{ marginBottom: 14 }}>{adminError}</div>}
          <form onSubmit={handleCreateAdmin} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="field">
              <label htmlFor="adminFullName">Full Name</label>
              <input
                id="adminFullName"
                value={newAdminForm.fullName}
                onChange={(e) => setNewAdminForm({ ...newAdminForm, fullName: e.target.value })}
                placeholder="Dr. Rajesh Varma"
                required
              />
            </div>
            <div className="field">
              <label htmlFor="adminPhoneNumber">Phone Number (10 digits)</label>
              <input
                id="adminPhoneNumber"
                type="tel"
                value={newAdminForm.phoneNumber}
                onChange={(e) => setNewAdminForm({ ...newAdminForm, phoneNumber: e.target.value })}
                placeholder="9876543210"
                required
              />
            </div>
            <div className="field">
              <label htmlFor="adminPassword">Initial Password</label>
              <input
                id="adminPassword"
                type="password"
                value={newAdminForm.password}
                onChange={(e) => setNewAdminForm({ ...newAdminForm, password: e.target.value })}
                placeholder="••••••••"
                required
              />
            </div>
            <div className="field">
              <label htmlFor="adminRoleSelect">Admin Level</label>
              <select
                id="adminRoleSelect"
                value={newAdminForm.adminRole}
                onChange={(e) => setNewAdminForm({ ...newAdminForm, adminRole: e.target.value })}
              >
                <option value="district_admin">District Health Administrator</option>
                <option value="clinical_director">Clinical / Medical Director</option>
                <option value="superadmin">Super Administrator</option>
                <option value="system_admin">System Administrator</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="adminDept">Department</label>
              <input
                id="adminDept"
                value={newAdminForm.department}
                onChange={(e) => setNewAdminForm({ ...newAdminForm, department: e.target.value })}
                placeholder="District Public Health Administration"
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 10 }}>
              <button type="button" className="btn btn-ghost" onClick={() => setShowAddAdminModal(false)}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary" disabled={creatingAdmin}>
                {creatingAdmin ? 'Creating…' : 'Create Administrator'}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
