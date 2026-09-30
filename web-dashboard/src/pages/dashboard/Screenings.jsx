import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { patientsApi, screeningsApi } from '../../api/services';
import { useAuth } from '../../context/AuthContext';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import Pagination from '../../components/Pagination';
import './Dashboard.css';

export default function Screenings() {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [searchParams] = useSearchParams();
  const patientIdFilter = searchParams.get('patientId') || '';

  const [screenings, setScreenings] = useState([]);
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 });
  const [loading, setLoading] = useState(true);
  const [riskLevel, setRiskLevel] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [page, setPage] = useState(1);
  const nameCache = useRef(new Map());
  const [, forceRender] = useState(0);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 20 };
      if (isAdmin) params.allScreenings = 'true';
      if (riskLevel) params.riskLevel = riskLevel;
      if (startDate) params.startDate = startDate;
      if (endDate) params.endDate = endDate;
      if (patientIdFilter) params.patientId = patientIdFilter;
      const res = await screeningsApi.list(params);
      setScreenings(res.data || []);
      setPagination(res.pagination || { page: 1, totalPages: 1, total: 0 });

      const uniqueIds = [...new Set((res.data || []).map((s) => s.patientId))].filter(
        (pid) => pid && !nameCache.current.has(pid)
      );
      if (uniqueIds.length) {
        const fetched = await Promise.all(
          uniqueIds.map((pid) => patientsApi.getById(pid, isAdmin ? { allPatients: 'true' } : {}).then((r) => [pid, r.data]).catch(() => [pid, null]))
        );
        fetched.forEach(([pid, data]) => nameCache.current.set(pid, data));
        forceRender((n) => n + 1);
      }
    } finally {
      setLoading(false);
    }
  }, [page, riskLevel, startDate, endDate, patientIdFilter, isAdmin]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Screenings</h1>
          <p>Every OA risk screening you’ve submitted, newest first.</p>
        </div>

      </div>

      <div className="filters-row">
        <select value={riskLevel} onChange={(e) => { setRiskLevel(e.target.value); setPage(1); }}>
          <option value="">All risk levels</option>
          <option value="low">Low risk</option>
          <option value="medium">Medium risk</option>
          <option value="high">High risk</option>
        </select>
        <input type="date" value={startDate} onChange={(e) => { setStartDate(e.target.value); setPage(1); }} />
        <input type="date" value={endDate} onChange={(e) => { setEndDate(e.target.value); setPage(1); }} />
        {patientIdFilter && (
          <button className="chip active" onClick={() => navigate('/dashboard/screenings')}>
            Filtered by patient &times;
          </button>
        )}
      </div>

      {loading ? (
        <Spinner />
      ) : screenings.length === 0 ? (
        <EmptyState
          title="No screenings found"
          message="Try a different filter, or run a new screening."
        />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Date</th>
                <th>Pain</th>
                <th>Risk</th>
                <th>Confidence</th>
                <th>Source</th>
              </tr>
            </thead>
            <tbody>
              {screenings.map((s) => {
                const patient = nameCache.current.get(s.patientId);
                return (
                  <tr key={s.id} onClick={() => navigate(`/dashboard/screenings/${s.id}`)}>
                    <td>
                      <div className="name-cell">
                        <strong>{patient?.name || 'Loading…'}</strong>
                        <span>{patient?.village || ''}</span>
                      </div>
                    </td>
                    <td>{new Date(s.screeningDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
                    <td>{s.painLevel} / 10</td>
                    <td><RiskBadge level={s.riskLevel} /></td>
                    <td>{s.confidence != null ? `${Math.round(s.confidence * 100)}%` : '—'}</td>
                    <td>{s.source === 'ml_model' ? 'ML model' : 'Fallback'}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <Pagination page={pagination.page} totalPages={pagination.totalPages} total={pagination.total} onChange={setPage} />
        </div>
      )}
    </div>
  );
}
