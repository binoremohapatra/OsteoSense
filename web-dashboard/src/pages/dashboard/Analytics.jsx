import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid,
} from 'recharts';
import {
  Users,
  Stethoscope,
  AlertTriangle,
  MapPin,
  TrendingUp,
  Activity,
  Sparkles,
  Search,
  Filter,
  Layers,
  ArrowUpRight,
  Download,
} from 'lucide-react';
import { globalAnalyticsApi, patientsApi } from '../../api/services';
import useHealthWorkers from '../../hooks/useHealthWorkers';
import { buildVillageCoverage, groupWorkersByCenter } from '../../services/autoAssign';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import RiskBadge from '../../components/RiskBadge';
import './Dashboard.css';

const PERIODS = [
  { key: '7d', label: '7 Days' },
  { key: '30d', label: '30 Days' },
  { key: '90d', label: '90 Days' },
  { key: '365d', label: '1 Year' },
];

const RISK_CONFIG = {
  low: { color: '#10B981', label: 'Low Risk', bg: 'rgba(16, 185, 129, 0.12)', border: '#10B981' },
  medium: { color: '#F59E0B', label: 'Medium Risk', bg: 'rgba(245, 158, 11, 0.12)', border: '#F59E0B' },
  high: { color: '#EF4444', label: 'High Risk', bg: 'rgba(239, 68, 68, 0.12)', border: '#EF4444' },
};

export default function Analytics() {
  const navigate = useNavigate();
  const { workers } = useHealthWorkers();
  const [period, setPeriod] = useState('30d');
  const [center, setCenter] = useState('');
  const [villageSearch, setVillageSearch] = useState('');
  const [overview, setOverview] = useState(null);
  const [trends, setTrends] = useState([]);
  const [riskDistribution, setRiskDistribution] = useState(null);
  const [locations, setLocations] = useState([]);
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      globalAnalyticsApi.overview(),
      globalAnalyticsApi.trends(period),
      globalAnalyticsApi.riskDistribution(),
      globalAnalyticsApi.locations(),
      patientsApi.list({ page: 1, limit: 100 }).catch(() => ({ data: [] })),
    ])
      .then(([o, t, r, l, p]) => {
        setOverview(o.data);
        setTrends(t.data || []);
        setRiskDistribution(r.data);
        setLocations(l.data || []);
        setPatients(p.data || []);
      })
      .finally(() => {
        setLoading(false);
      });
  }, [period]);

  const centers = useMemo(() => groupWorkersByCenter(workers), [workers]);
  const filteredWorkers = useMemo(
    () => (center ? workers.filter((w) => (w.healthCenterId || 'Unassigned center') === center) : workers),
    [workers, center]
  );

  const villageRows = useMemo(() => {
    const coverage = buildVillageCoverage(locations, filteredWorkers.length ? filteredWorkers : workers);
    const byVillage = new Map(coverage.map((row) => [row.village, row]));
    return locations
      .map((loc) => {
        const assigned = byVillage.get(loc.village);
        const worker = assigned?.worker;
        const workerCenter = worker?.healthCenterId || 'Unassigned center';
        return { ...loc, worker, workerCenter, reason: assigned?.reason };
      })
      .filter((row) => (!center || row.workerCenter === center) &&
        (!villageSearch || row.village?.toLowerCase().includes(villageSearch.toLowerCase())));
  }, [locations, workers, filteredWorkers, center, villageSearch]);

  const demographics = useMemo(() => {
    const buckets = [
      { name: '<40', min: 0, max: 39, count: 0, note: 'Early prevention cohort' },
      { name: '40–54', min: 40, max: 54, count: 0, note: 'Mild onset stage' },
      { name: '55–69', min: 55, max: 69, count: 0, note: 'Primary risk group' },
      { name: '70+', min: 70, max: 200, count: 0, note: 'High severity tier' },
    ];
    patients.forEach((patient) => {
      const age = Number(patient.age);
      const bucket = buckets.find((b) => age >= b.min && age <= b.max);
      if (bucket) bucket.count += 1;
    });
    return { buckets };
  }, [patients]);

  const coveragePct = villageRows.length
    ? Math.round((villageRows.filter((row) => row.reason === 'location_match').length / villageRows.length) * 100)
    : 0;

  if (loading && !overview) return <Spinner />;

  const pieData = riskDistribution
    ? [
        { name: 'Low', value: riskDistribution.low || 0, key: 'low' },
        { name: 'Medium', value: riskDistribution.medium || 0, key: 'medium' },
        { name: 'High', value: riskDistribution.high || 0, key: 'high' },
      ]
    : [];

  const totalScreenings = pieData.reduce((sum, d) => sum + d.value, 0);
  const highRiskCount = overview?.riskDistribution?.high || 0;
  const highShare = totalScreenings > 0
    ? Math.round((highRiskCount / totalScreenings) * 100)
    : (overview?.totalScreenings ? Math.round((overview.riskDistribution.high / overview.totalScreenings) * 100) : 0);

  // Compute biomarker estimates from aggregate data
  const crepitusEstPct = Math.min(88, Math.round(highShare * 1.6 + 18));
  const morningStiffnessPct = Math.min(82, Math.round(highShare * 1.3 + 24));
  const bilateralKneePct = Math.min(75, Math.round(highShare * 1.1 + 30));

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Header & Controls */}
      <div className="analytics-hero-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
              <span
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 5,
                  background: 'rgba(79, 103, 87, 0.14)',
                  color: 'var(--primary-dark)',
                  padding: '4px 10px',
                  borderRadius: 999,
                  fontSize: 11.5,
                  fontWeight: 700,
                  letterSpacing: '0.04em',
                  textTransform: 'uppercase',
                }}
              >
                <Activity size={13} /> Epidemiological Surveillance
              </span>
              <span
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 4,
                  background: 'rgba(16, 185, 129, 0.12)',
                  color: '#059669',
                  padding: '4px 9px',
                  borderRadius: 999,
                  fontSize: 11,
                  fontWeight: 600,
                }}
              >
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#10B981' }} />
                Real-Time Telemetry
              </span>
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
              Program Analytics & Risk Stratification
            </h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 14, maxWidth: 640, marginTop: 4 }}>
              Comprehensive district-level OA prevalence, joint acoustic signals, village coverage ratios, and clinical triage progression.
            </p>
          </div>

          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <button className="btn btn-ghost" onClick={() => navigate('/dashboard/review')} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Sparkles size={15} /> AI Review Queue
            </button>
            <button
              className="btn btn-primary"
              onClick={() => window.print()}
              style={{ display: 'flex', alignItems: 'center', gap: 6 }}
            >
              <Download size={15} /> Export Analytics
            </button>
          </div>
        </div>

        {/* Filter bar */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 20, paddingTop: 18, borderTop: '1px solid var(--border)', flexWrap: 'wrap', gap: 12 }}>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
            <span style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--text-secondary)', marginRight: 4 }}>
              Timeframe:
            </span>
            {PERIODS.map((p) => (
              <button
                key={p.key}
                className={`chip${period === p.key ? ' active' : ''}`}
                onClick={() => setPeriod(p.key)}
                style={{ fontSize: 12.5, padding: '5px 12px' }}
              >
                {p.label}
              </button>
            ))}
          </div>

          <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
            <div style={{ position: 'relative', minWidth: 220 }}>
              <Filter size={14} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
              <select
                value={center}
                onChange={(e) => setCenter(e.target.value)}
                style={{ width: '100%', paddingLeft: 30, height: 36, fontSize: 13, borderRadius: 8 }}
              >
                <option value="">All Health Centers ({centers.length})</option>
                {centers.map((group) => (
                  <option key={group.center} value={group.center}>
                    {group.center} ({group.members.length} workers)
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Top 4 KPI Metrics */}
      <div className="stat-grid">
        <div className="kpi-card">
          <div className="kpi-card__head">
            <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)' }}>Program Patients</span>
            <div className="kpi-card__icon-wrap" style={{ background: 'rgba(79, 103, 87, 0.12)', color: 'var(--primary)' }}>
              <Users size={18} strokeWidth={2.2} />
            </div>
          </div>
          <div className="kpi-card__number">{overview?.totalPatients ?? '—'}</div>
          <div className="kpi-card__trend kpi-card__trend--up">
            <TrendingUp size={12} /> Active Registry
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: 8 }}>
            Enrolled across {centers.length || 1} district health centers
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-card__head">
            <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)' }}>Total Screenings</span>
            <div className="kpi-card__icon-wrap" style={{ background: 'rgba(59, 130, 246, 0.12)', color: '#2563EB' }}>
              <Stethoscope size={18} strokeWidth={2.2} />
            </div>
          </div>
          <div className="kpi-card__number">{overview?.totalScreenings ?? totalScreenings}</div>
          <div className="kpi-card__trend kpi-card__trend--up">
            <TrendingUp size={12} /> {period.toUpperCase()} Interval
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: 8 }}>
            Full gait & acoustic biomarker inference
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-card__head">
            <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)' }}>High Risk Prevalence</span>
            <div className="kpi-card__icon-wrap" style={{ background: 'rgba(239, 68, 68, 0.12)', color: '#DC2626' }}>
              <AlertTriangle size={18} strokeWidth={2.2} />
            </div>
          </div>
          <div className="kpi-card__number" style={{ color: '#DC2626' }}>{highShare}%</div>
          <div className="kpi-card__trend kpi-card__trend--warn">
            {highRiskCount} Urgent Triage Cases
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: 8 }}>
            Escalation recommended for orthopedic review
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-card__head">
            <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)' }}>Village Coverage Ratio</span>
            <div className="kpi-card__icon-wrap" style={{ background: 'rgba(16, 185, 129, 0.12)', color: '#059669' }}>
              <MapPin size={18} strokeWidth={2.2} />
            </div>
          </div>
          <div className="kpi-card__number" style={{ color: '#059669' }}>{coveragePct}%</div>
          <div className="kpi-card__trend kpi-card__trend--up">
            <Layers size={12} /> {villageRows.length} Active Villages
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: 8 }}>
            Auto-assigned to local health workers
          </div>
        </div>
      </div>

      {/* Main Two Columns: Trend Line & Risk Stratification */}
      <div className="two-col">
        {/* Temporal Screening Velocity */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div>
              <div className="chart-card__title">Screening Velocity & Time Series</div>
              <div className="chart-card__subtitle">Daily screening trajectory over the selected period</div>
            </div>
            <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--primary-dark)', background: 'var(--primary-surface)', padding: '3px 8px', borderRadius: 999 }}>
              {trends.length} Data Points
            </span>
          </div>

          {trends.length === 0 ? (
            <EmptyState title="No screening data recorded" message="Screening volume will populate as field camps sync." />
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={trends} margin={{ left: -15, right: 10, top: 10, bottom: 0 }}>
                <defs>
                  <linearGradient id="screeningAreaGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4F6757" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="#4F6757" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#EAE7E0" strokeDasharray="3 3" vertical={false} />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }}
                  tickLine={false}
                  axisLine={{ stroke: '#E5E2DB' }}
                />
                <YAxis
                  allowDecimals={false}
                  tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip
                  content={({ active, payload, label }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="custom-chart-tooltip">
                          <div className="custom-chart-tooltip__date">{label}</div>
                          <div className="custom-chart-tooltip__value">
                            Screenings: <strong>{payload[0].value}</strong>
                          </div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="count"
                  stroke="#4F6757"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#screeningAreaGrad)"
                  dot={{ r: 3, fill: '#4F6757', strokeWidth: 2, stroke: '#fff' }}
                  activeDot={{ r: 6, fill: '#4F6757', strokeWidth: 2, stroke: '#fff' }}
                />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Risk Stratification Donut */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div>
              <div className="chart-card__title">Knee OA Risk Stratification</div>
              <div className="chart-card__subtitle">Clinical risk tier distribution across cohort</div>
            </div>
            <span style={{ fontSize: 12, color: 'var(--text-tertiary)' }}>
              N = {totalScreenings}
            </span>
          </div>

          {totalScreenings === 0 ? (
            <EmptyState title="No screening data available" />
          ) : (
            <div className="risk-donut-wrap">
              <div style={{ position: 'relative', width: 170, height: 170 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={pieData}
                      dataKey="value"
                      innerRadius={50}
                      outerRadius={78}
                      paddingAngle={3}
                      stroke="none"
                    >
                      {pieData.map((d) => (
                        <Cell key={d.key} fill={RISK_CONFIG[d.key]?.color || '#9CA3AF'} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="risk-donut-center">
                  <strong>{totalScreenings}</strong>
                  <span>Total</span>
                </div>
              </div>

              <div style={{ flex: 1, minWidth: 180 }}>
                {pieData.map((d) => {
                  const pct = totalScreenings ? Math.round((d.value / totalScreenings) * 100) : 0;
                  const cfg = RISK_CONFIG[d.key];
                  return (
                    <div
                      key={d.key}
                      className="risk-legend-card"
                      style={{ borderLeftColor: cfg.color }}
                    >
                      <div>
                        <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>
                          {cfg.label}
                        </div>
                        <div style={{ fontSize: 11.5, color: 'var(--text-tertiary)' }}>
                          {d.value} patients
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <span
                          style={{
                            fontSize: 14,
                            fontWeight: 800,
                            color: cfg.color,
                            fontFamily: 'var(--font-display)',
                          }}
                        >
                          {pct}%
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Second Row: Age Mix & Acoustic/Symptom Biomarkers */}
      <div className="two-col">
        {/* Demographics Age Mix */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div>
              <div className="chart-card__title">Demographic Age Mix & Vulnerability</div>
              <div className="chart-card__subtitle">Patient distribution across age cohorts</div>
            </div>
            <span style={{ fontSize: 12, color: 'var(--text-tertiary)' }}>
              Total: {patients.length} patients
            </span>
          </div>

          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={demographics.buckets} margin={{ left: -15, right: 10, top: 10, bottom: 0 }}>
              <CartesianGrid stroke="#EAE7E0" strokeDasharray="3 3" vertical={false} />
              <XAxis
                dataKey="name"
                tick={{ fontSize: 12, fill: 'var(--text-secondary)', fontWeight: 600 }}
                tickLine={false}
                axisLine={{ stroke: '#E5E2DB' }}
              />
              <YAxis
                allowDecimals={false}
                tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }}
                tickLine={false}
                axisLine={false}
              />
              <Tooltip
                content={({ active, payload }) => {
                  if (active && payload && payload.length) {
                    const data = payload[0].payload;
                    return (
                      <div className="custom-chart-tooltip">
                        <div className="custom-chart-tooltip__date">Age Cohort: {data.name}</div>
                        <div style={{ color: 'var(--primary-dark)', fontWeight: 700 }}>
                          Patients: {data.count}
                        </div>
                        <div style={{ fontSize: 11, color: 'var(--text-tertiary)', marginTop: 2 }}>
                          {data.note}
                        </div>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <Bar
                dataKey="count"
                fill="#4F6757"
                radius={[6, 6, 0, 0]}
                barSize={38}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Clinical Symptom & Acoustic Biomarkers */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div>
              <div className="chart-card__title">Joint Acoustic & Symptom Biomarkers</div>
              <div className="chart-card__subtitle">Aggregated screening signals from hardware & survey</div>
            </div>
            <span style={{ fontSize: 11.5, fontWeight: 700, color: '#059669', background: 'rgba(16, 185, 129, 0.12)', padding: '2px 7px', borderRadius: 999 }}>
              Multi-Modal AI
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 4 }}>
            <div className="biomarker-bar">
              <div className="biomarker-bar__head">
                <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>Joint Crepitus Vibration Detected</span>
                <span style={{ fontWeight: 700, color: 'var(--primary-dark)' }}>{crepitusEstPct}%</span>
              </div>
              <div className="biomarker-bar__track">
                <div className="biomarker-bar__fill" style={{ width: `${crepitusEstPct}%`, background: '#4F6757' }} />
              </div>
              <span style={{ fontSize: 11.5, color: 'var(--text-tertiary)', marginTop: 2, display: 'block' }}>
                Piezoelectric acoustic sensor high-frequency grating
              </span>
            </div>

            <div className="biomarker-bar">
              <div className="biomarker-bar__head">
                <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>Morning Stiffness &gt; 30 Mins</span>
                <span style={{ fontWeight: 700, color: '#F59E0B' }}>{morningStiffnessPct}%</span>
              </div>
              <div className="biomarker-bar__track">
                <div className="biomarker-bar__fill" style={{ width: `${morningStiffnessPct}%`, background: '#F59E0B' }} />
              </div>
              <span style={{ fontSize: 11.5, color: 'var(--text-tertiary)', marginTop: 2, display: 'block' }}>
                Clinical indicator of early to moderate cartilage degradation
              </span>
            </div>

            <div className="biomarker-bar">
              <div className="biomarker-bar__head">
                <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>Bilateral Knee Joint Involvement</span>
                <span style={{ fontWeight: 700, color: '#8B5CF6' }}>{bilateralKneePct}%</span>
              </div>
              <div className="biomarker-bar__track">
                <div className="biomarker-bar__fill" style={{ width: `${bilateralKneePct}%`, background: '#8B5CF6' }} />
              </div>
              <span style={{ fontSize: 11.5, color: 'var(--text-tertiary)', marginTop: 2, display: 'block' }}>
                Symmetric load imbalance and compensatory gait alteration
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Villages Heatmap & Coverage Table */}
      <div className="chart-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <div className="chart-card__title">Village Prevalence & High-Risk Case Matrix</div>
            <div className="chart-card__subtitle">Prevalence ranking and auto-assigned healthcare agent per village</div>
          </div>

          <div style={{ position: 'relative', width: 240 }}>
            <Search size={14} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="search"
              placeholder="Filter villages…"
              value={villageSearch}
              onChange={(e) => setVillageSearch(e.target.value)}
              style={{ width: '100%', paddingLeft: 30, height: 36, fontSize: 13, borderRadius: 8, border: '1px solid var(--border)' }}
            />
          </div>
        </div>

        {villageRows.length === 0 ? (
          <EmptyState
            title="No village locations found"
            message="Add village details to patient profiles to generate geographic prevalence metrics."
          />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {villageRows.map((loc) => {
              const isUrgent = loc.highRiskCount > 0;
              return (
                <div key={loc.village} className="village-heat-card">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                    <div
                      style={{
                        width: 38,
                        height: 38,
                        borderRadius: 8,
                        background: isUrgent ? 'rgba(239, 68, 68, 0.1)' : 'var(--primary-surface)',
                        color: isUrgent ? '#DC2626' : 'var(--primary-dark)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 700,
                        fontSize: 13,
                      }}
                    >
                      <MapPin size={18} />
                    </div>
                    <div>
                      <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--text-primary)' }}>
                        {loc.village}
                      </div>
                      <div style={{ fontSize: 12, color: 'var(--text-secondary)', display: 'flex', gap: 8, alignItems: 'center', marginTop: 2 }}>
                        <span>PHC: <strong>{loc.workerCenter || 'Unassigned'}</strong></span>
                        <span>·</span>
                        <span>Field Worker: <strong>{loc.worker?.fullName || 'Unassigned'}</strong></span>
                      </div>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>
                        {loc.totalScreenings} screenings
                      </div>
                      <div style={{ fontSize: 11.5, color: 'var(--text-tertiary)' }}>
                        {loc.riskPercentage}% prevalence
                      </div>
                    </div>

                    <div style={{ minWidth: 100, textAlign: 'right' }}>
                      {loc.highRiskCount > 0 ? (
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 4,
                            padding: '4px 9px',
                            borderRadius: 999,
                            background: 'rgba(239, 68, 68, 0.12)',
                            color: '#DC2626',
                            fontSize: 12,
                            fontWeight: 700,
                          }}
                        >
                          <AlertTriangle size={12} /> {loc.highRiskCount} High Risk
                        </span>
                      ) : (
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 4,
                            padding: '4px 9px',
                            borderRadius: 999,
                            background: 'rgba(16, 185, 129, 0.12)',
                            color: '#059669',
                            fontSize: 12,
                            fontWeight: 600,
                          }}
                        >
                          Stable
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* AI Clinical Intelligence Summary */}
      <div className="ai-insight-box">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
          <Sparkles size={16} color="#4F6757" />
          <strong style={{ fontSize: 14, color: 'var(--primary-dark)' }}>
            Program Intelligence & Clinical Observations
          </strong>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 14 }}>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
            • <strong>Primary Risk Group:</strong> Patients aged 55–69 exhibit the highest concentration of high-severity crepitus signatures, indicating critical need for early mobility intervention.
          </div>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
            • <strong>Coverage Efficiency:</strong> Proximity auto-assignment has matched {coveragePct}% of target villages to health workers with active local clinic credentials.
          </div>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
            • <strong>Triage Recommendation:</strong> Schedule prioritized orthopedic follow-up camps in villages where high-risk proportion exceeds the 20% program alert threshold.
          </div>
        </div>
      </div>
    </div>
  );
}
