import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AreaChart, Area, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import { Users, Stethoscope, AlertTriangle, Building2, TrendingUp, ShieldCheck, ArrowRight, Activity } from 'lucide-react';
import { globalAnalyticsApi, screeningsApi } from '../../api/services';
import { useAuth } from '../../context/AuthContext';
import useHealthWorkers from '../../hooks/useHealthWorkers';
import { groupWorkersByCenter } from '../../services/autoAssign';
import StatCard from '../../components/StatCard';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

export default function Overview() {
  const { user, isAdmin } = useAuth();
  const navigate = useNavigate();
  const { workers } = useHealthWorkers();
  const [overview, setOverview] = useState(null);
  const [trends, setTrends] = useState([]);
  const [recent, setRecent] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      globalAnalyticsApi.overview(),
      globalAnalyticsApi.trends('30d'),
      screeningsApi.list({ page: 1, limit: 5 }),
    ]).then(([o, t, s]) => {
      setOverview(o.data);
      setTrends(t.data || []);
      setRecent(s.data || []);
      setLoading(false);
    });
  }, []);

  const centers = useMemo(() => groupWorkersByCenter(workers), [workers]);

  if (loading || !overview) return <Spinner />;

  const firstName = user?.fullName?.split(' ')[0];
  const highRiskCount = overview?.riskDistribution?.high || 0;
  const totalCount = overview?.totalScreenings || 0;
  const highShare = totalCount > 0 ? Math.round((highRiskCount / totalCount) * 100) : 0;

  return (
    <div>
      <div className="page-head">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 4,
                background: isAdmin ? 'rgba(79, 103, 87, 0.12)' : 'var(--primary-surface)',
                color: 'var(--primary-dark)',
                padding: '3px 8px',
                borderRadius: 999,
                fontSize: 11,
                fontWeight: 700,
                letterSpacing: '0.03em',
                textTransform: 'uppercase',
              }}
            >
              {isAdmin ? <ShieldCheck size={12} /> : <Activity size={12} />}
              {isAdmin ? 'System Administrator View' : 'Field Health Workspace'}
            </span>
          </div>
          <h1>District Overview{firstName ? ` · ${firstName}` : ''}</h1>
          <p>Aggregated patient registries, screening velocity, risk stratification, and health center coverage.</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          {isAdmin && (
            <button className="btn btn-ghost" onClick={() => navigate('/dashboard/admin')}>
              <ShieldCheck size={15} /> Admin Hub
            </button>
          )}
          <button className="btn btn-primary" onClick={() => navigate('/dashboard/analytics')}>
            Open Full Analytics <ArrowRight size={15} />
          </button>
        </div>
      </div>

      <div className="stat-grid">
        <StatCard label="Program patients" value={overview.totalPatients} icon={Users} sub="Total registered" />
        <StatCard label="Program screenings" value={overview.totalScreenings} icon={Stethoscope} accent="#4F6757" sub="Full session logs" />
        <StatCard
          label="High risk cases"
          value={highRiskCount}
          icon={AlertTriangle}
          accent="#DC2626"
          sub={`${highShare}% high-risk rate`}
        />
        <StatCard label="Health centers" value={centers.length} icon={Building2} accent="#8B5CF6" sub="Active locations" />
      </div>

      <div className="two-col">
        <div className="chart-card">
          <div className="chart-card__header">
            <div>
              <div className="chart-card__title">Screenings Trajectory (Last 30 Days)</div>
              <div className="chart-card__subtitle">Daily volume across all health camps</div>
            </div>
            <span style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--primary-dark)', background: 'var(--primary-surface)', padding: '2px 7px', borderRadius: 999 }}>
              Live Aggregate
            </span>
          </div>

          {trends.length === 0 ? (
            <EmptyState title="Nothing yet" message="Trend data appears once camps start syncing." />
          ) : (
            <ResponsiveContainer width="100%" height={240}>
              <AreaChart data={trends} margin={{ left: -15, right: 10, top: 8, bottom: 0 }}>
                <defs>
                  <linearGradient id="overviewAreaGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4F6757" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#4F6757" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#EAE7E0" strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="date" tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }} tickLine={false} axisLine={{ stroke: '#E5E2DB' }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }} tickLine={false} axisLine={false} />
                <Tooltip
                  content={({ active, payload, label }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="custom-chart-tooltip">
                          <div className="custom-chart-tooltip__date">{label}</div>
                          <div className="custom-chart-tooltip__value">Screenings: {payload[0].value}</div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Area type="monotone" dataKey="count" stroke="#4F6757" strokeWidth={2.5} fill="url(#overviewAreaGrad)" dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="card">
          <div className="chart-card__header" style={{ marginBottom: 12 }}>
            <div>
              <div className="chart-card__title">Risk Stratification Breakdown</div>
              <div className="chart-card__subtitle">Clinical risk mix across {overview.totalScreenings} screenings</div>
            </div>
          </div>
          <div className="risk-pill-list" style={{ gap: 14 }}>
            <RiskRow label="Low Risk" count={overview.riskDistribution?.low || 0} total={overview.totalScreenings} color="#10B981" />
            <RiskRow label="Medium Risk" count={overview.riskDistribution?.medium || 0} total={overview.totalScreenings} color="#F59E0B" />
            <RiskRow label="High Risk" count={overview.riskDistribution?.high || 0} total={overview.totalScreenings} color="#EF4444" />
          </div>
        </div>
      </div>

      <h2 className="section-title" style={{ marginTop: 30 }}>Primary Health Centers</h2>
      {centers.length === 0 ? (
        <EmptyState title="No workers listed" message="Health workers appear here from their profiles (location and health center)." />
      ) : (
        <div className="care-grid" style={{ marginBottom: 28 }}>
          {centers.map((group) => (
            <button
              key={group.center}
              className="care-card"
              style={{ textAlign: 'left', width: '100%' }}
              onClick={() => navigate('/dashboard/analytics')}
            >
              <span className="care-card__cat">{group.members.length} field workers</span>
              <h3>{group.center}</h3>
              <p>{group.members.map((w) => w.fullName).slice(0, 3).join(', ')}{group.members.length > 3 ? '…' : ''}</p>
            </button>
          ))}
        </div>
      )}

      <h2 className="section-title">Recent Screenings</h2>
      {recent.length === 0 ? (
        <EmptyState title="No screenings in this workspace" message="Screenings appear here in real-time as field sessions are completed." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Pain level</th>
                <th>Risk</th>
                <th>Source</th>
              </tr>
            </thead>
            <tbody>
              {recent.map((s) => (
                <tr key={s.id} onClick={() => navigate(`/dashboard/screenings/${s.id}`)}>
                  <td>{new Date(s.screeningDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</td>
                  <td>{s.painLevel} / 10</td>
                  <td><RiskBadge level={s.riskLevel} /></td>
                  <td>{s.source === 'ml_model' ? 'ML model' : 'Fallback'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function RiskRow({ label, count, total, color }) {
  const pct = total ? Math.round((count / total) * 100) : 0;
  return (
    <div className="risk-pill-row">
      <span className="risk-pill-row__label" style={{ width: 100 }}>{label}</span>
      <div className="risk-pill-row__bar" style={{ height: 9 }}>
        <div style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="risk-pill-row__count" style={{ width: 60, textAlign: 'right' }}>
        <strong>{count}</strong> <span style={{ color: 'var(--text-tertiary)', fontSize: 12 }}>({pct}%)</span>
      </span>
    </div>
  );
}
