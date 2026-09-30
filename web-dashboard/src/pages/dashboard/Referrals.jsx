import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { patientsApi, screeningsApi } from '../../api/services';
import { getPatientAssignment } from '../../services/assignmentService';
import { loadReferrals, upsertReferral } from '../../services/referralsStore';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

const STATUSES = ['queued', 'referred', 'seen', 'closed'];

export default function Referrals() {
  const navigate = useNavigate();
  const [screenings, setScreenings] = useState([]);
  const [referrals, setReferrals] = useState(() => loadReferrals());
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [facilities, setFacilities] = useState(['District hospital']);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const res = await screeningsApi.list({ riskLevel: 'high', page: 1, limit: 50 });
      const rows = res.data || [];
      const map = new Map();
      await Promise.all(
        [...new Set(rows.map((s) => s.patientId))].map(async (pid) => {
          if (!pid) return;
          try {
            const p = await patientsApi.getById(pid, { allPatients: true });
            map.set(pid, p.data);
          } catch {
            map.set(pid, null);
          }
        })
      );
      if (cancelled) return;
      setScreenings(rows);

      // Collect unique facilities from assigned workers
      const facilitySet = new Set(['District hospital']);
      const assignments = await Promise.all(
        [...new Set(rows.map((s) => s.patientId))].map(async (pid) => {
          if (!pid) return null;
          const patient = map.get(pid);
          if (!patient) return null;
          try {
            const assignment = await getPatientAssignment(patient);
            if (assignment.worker?.healthCenterId) {
              facilitySet.add(assignment.worker.healthCenterId);
            }
            return { patientId: pid, assignment };
          } catch {
            return null;
          }
        })
      );
      
      const uniqueFacilities = [...facilitySet];
      setFacilities(uniqueFacilities);

      let next = loadReferrals();
      rows.forEach((screening) => {
        if (next.some((row) => row.screeningId === screening.id)) return;
        const patient = map.get(screening.patientId);
        const assignmentData = assignments.find(a => a?.patientId === screening.patientId);
        const worker = assignmentData?.assignment?.worker;
        
        next = upsertReferral({
          screeningId: screening.id,
          patientId: screening.patientId,
          patientName: patient?.name || 'Unknown patient',
          village: patient?.village || '',
          facility: worker?.healthCenterId || uniqueFacilities[0] || 'District hospital',
          status: 'queued',
          outcome: '',
        });
      });
      setReferrals(next);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const visible = referrals.filter((row) => !statusFilter || row.status === statusFilter);

  const updateRow = (screeningId, patch) => {
    const current = referrals.find((row) => row.screeningId === screeningId);
    if (!current) return;
    setReferrals(upsertReferral({ ...current, ...patch }));
  };

  if (loading) return <Spinner />;

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Referral queue</h1>
          <p>High-risk flags become a follow-up: facility, status, and outcome — dashboard-only, not written back to the mobile API.</p>
        </div>
      </div>

      <div className="filters-row">
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="">All statuses</option>
          {STATUSES.map((status) => (
            <option key={status} value={status}>{status}</option>
          ))}
        </select>
      </div>

      {visible.length === 0 ? (
        <EmptyState title="No high-risk referrals" message="When a screening is flagged high risk, it lands here automatically." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Village</th>
                <th>Risk</th>
                <th>Facility</th>
                <th>Status</th>
                <th>Outcome</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((row) => {
                const screening = screenings.find((s) => s.id === row.screeningId);
                return (
                  <tr key={row.screeningId} style={{ cursor: 'default' }}>
                    <td>
                      <button className="linkish" onClick={() => navigate(`/dashboard/screenings/${row.screeningId}`)}>
                        {row.patientName}
                      </button>
                    </td>
                    <td>{row.village || '—'}</td>
                    <td><RiskBadge level={screening?.riskLevel || 'high'} /></td>
                    <td>
                      <select
                        value={row.facility}
                        onChange={(e) => updateRow(row.screeningId, { facility: e.target.value, status: row.status === 'queued' ? 'referred' : row.status })}
                      >
                        {[row.facility, ...facilities].filter((v, i, arr) => v && arr.indexOf(v) === i).map((facility) => (
                          <option key={facility} value={facility}>{facility}</option>
                        ))}
                      </select>
                    </td>
                    <td>
                      <select value={row.status} onChange={(e) => updateRow(row.screeningId, { status: e.target.value })}>
                        {STATUSES.map((status) => (
                          <option key={status} value={status}>{status}</option>
                        ))}
                      </select>
                    </td>
                    <td>
                      <input
                        type="text"
                        placeholder="Follow-up note"
                        value={row.outcome || ''}
                        onChange={(e) => updateRow(row.screeningId, { outcome: e.target.value })}
                      />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
