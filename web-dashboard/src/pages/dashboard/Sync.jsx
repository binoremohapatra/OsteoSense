import { useEffect, useMemo, useState } from 'react';
import { RefreshCw } from 'lucide-react';
import { syncApi } from '../../api/services';
import { useAuth } from '../../context/AuthContext';
import useHealthWorkers from '../../hooks/useHealthWorkers';
import { wearableId, workerId } from '../../services/autoAssign';
import { loadFailedSyncs, recordFailedSyncs } from '../../services/referralsStore';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

const GB = 1024 * 1024 * 1024;
const LOCAL_CAP = GB;

export default function Sync() {
  const { user } = useAuth();
  const { workers, loading: workersLoading } = useHealthWorkers();
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(() => loadFailedSyncs());
  const [storage, setStorage] = useState({ usage: 0, quota: LOCAL_CAP });
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');

  const loadStatus = () => {
    setLoading(true);
    syncApi.status().then((res) => {
      setStatus(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  };

  useEffect(() => {
    loadStatus();
    if (navigator.storage?.estimate) {
      navigator.storage.estimate().then((est) => {
        setStorage({ usage: est.usage || 0, quota: est.quota || LOCAL_CAP });
      });
    } else {
      let bytes = 0;
      for (let i = 0; i < localStorage.length; i += 1) {
        const key = localStorage.key(i);
        bytes += (key?.length || 0) + (localStorage.getItem(key)?.length || 0);
      }
      setStorage({ usage: bytes * 2, quota: LOCAL_CAP });
    }
  }, []);

  const daysSince = (iso) => {
    if (!iso) return null;
    return Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
  };

  const lastSync = status?.lastScreeningUpdate || status?.lastPatientUpdate;
  const staleDays = daysSince(lastSync);
  const usagePct = Math.min(100, Math.round((storage.usage / LOCAL_CAP) * 1000) / 10);

  const fleet = useMemo(() => workers.map((worker) => {
    const isSelf = workerId(worker) === String(user?.id || user?._id || '');
    const days = isSelf ? staleDays : null;
    let health = 'unknown';
    if (isSelf) {
      if (staleDays == null) health = 'never';
      else if (staleDays >= 7) health = 'stale';
      else health = 'ok';
    }
    return { worker, isSelf, days, health };
  }), [workers, staleDays, user]);

  const handlePingBatch = async () => {
    setSending(true);
    setError('');
    try {
      const res = await syncApi.batch([]);
      const results = Array.isArray(res.results) ? res.results : [];
      setFailed(recordFailedSyncs(results));
      loadStatus();
    } catch (err) {
      setError(err.response?.data?.message || 'Could not refresh fleet sync.');
    } finally {
      setSending(false);
    }
  };

  if (loading || workersLoading) return <Spinner />;

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Fleet health</h1>
          <p>Which workers and devices have synced, how close storage is to the 1 GB local cap, and failed uploads.</p>
        </div>
        <button className="btn btn-ghost" onClick={loadStatus}>
          <RefreshCw size={15} /> Refresh
        </button>
      </div>

      <div className="stat-grid">
        <div className="card">
          <div className="muted-label">Server time</div>
          <div className="stat-number" style={{ fontSize: 18 }}>
            {status?.serverTime ? new Date(status.serverTime).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : '—'}
          </div>
        </div>
        <div className="card">
          <div className="muted-label">This device last sync</div>
          <div className="stat-number" style={{ fontSize: 18 }}>
            {lastSync ? `${staleDays}d ago` : 'None yet'}
          </div>
        </div>
        <div className="card">
          <div className="muted-label">Local storage vs 1 GB</div>
          <div className="stat-number">{usagePct}%</div>
          <div className="risk-pill-row__bar" style={{ marginTop: 10 }}>
            <div style={{ width: `${Math.min(usagePct, 100)}%`, background: usagePct > 80 ? 'var(--risk-high)' : 'var(--primary)' }} />
          </div>
        </div>
        <div className="card">
          <div className="muted-label">Failed uploads</div>
          <div className="stat-number">{failed.length}</div>
        </div>
      </div>

      <h2 className="section-title">Workers & devices</h2>
      {fleet.length === 0 ? (
        <EmptyState title="No workers" message="Active agents appear here with a derived wearable ID." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Worker</th>
                <th>Center / location</th>
                <th>Wearable</th>
                <th>Sync</th>
              </tr>
            </thead>
            <tbody>
              {fleet.map(({ worker, isSelf, days, health }) => (
                <tr key={worker.id || worker._id} style={{ cursor: 'default' }}>
                  <td>
                    <div className="name-cell">
                      <strong>{worker.fullName}</strong>
                      <span>{worker.phoneNumber || 'No phone'}</span>
                    </div>
                  </td>
                  <td>{worker.healthCenterId || '—'} · {worker.location || 'Location unset'}</td>
                  <td>{wearableId(worker)}</td>
                  <td>
                    {health === 'ok' && <span className="pill pill--ok">Synced {days}d ago</span>}
                    {health === 'stale' && <span className="pill pill--warn">No sync in {days}d</span>}
                    {health === 'never' && <span className="pill pill--warn">Never synced</span>}
                    {health === 'unknown' && <span className="pill">Heartbeat not in API</span>}
                    {isSelf ? '' : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="hint-copy">
        Last-sync timestamps exist only for the signed-in device. Other rows show roster and wearable mapping until a fleet heartbeat exists.
      </p>

      <h2 className="section-title" style={{ marginTop: 28 }}>Failed uploads</h2>
      {error && <div className="banner banner-error" style={{ marginBottom: 14 }}>{error}</div>}
      {failed.length === 0 ? (
        <EmptyState title="No recorded failures" message="Batch errors from this dashboard are kept locally so ops can see them." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Local ID</th>
                <th>When</th>
                <th>Error</th>
              </tr>
            </thead>
            <tbody>
              {failed.map((row) => (
                <tr key={`${row.localId}-${row.at}`} style={{ cursor: 'default' }}>
                  <td>{row.localId}</td>
                  <td>{new Date(row.at).toLocaleString('en-IN')}</td>
                  <td>{row.error}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <button className="btn btn-ghost" style={{ marginTop: 16 }} onClick={handlePingBatch} disabled={sending}>
        {sending ? 'Checking…' : 'Ping empty batch'}
      </button>
    </div>
  );
}
