import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Pencil, Stethoscope, Trash2 } from 'lucide-react';
import { patientsApi, screeningsApi } from '../../api/services';
import useHealthWorkers from '../../hooks/useHealthWorkers';
import { assignWorker, assignmentLabel, wearableId } from '../../services/autoAssign';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import PatientFormModal from '../../components/PatientFormModal';
import './Dashboard.css';

export default function PatientDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { workers } = useHealthWorkers();
  const [patient, setPatient] = useState(null);
  const [screenings, setScreenings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);

  const load = async () => {
    setLoading(true);
    const [pRes, sRes] = await Promise.all([
      patientsApi.getById(id, { allPatients: true }),
      screeningsApi.byPatient(id),
    ]);
    setPatient(pRes.data);
    setScreenings(sRes.data || []);
    setLoading(false);
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleDelete = async () => {
    if (!window.confirm(`Remove ${patient.name} from your patient list?`)) return;
    await patientsApi.remove(id);
    navigate('/dashboard/patients');
  };

  if (loading) return <Spinner />;
  if (!patient) return <EmptyState title="Patient not found" />;

  const assignment = assignWorker(patient, workers);

  return (
    <div>
      <button className="back-link" onClick={() => navigate('/dashboard/patients')}>
        <ArrowLeft size={15} /> All patients
      </button>

      <div className="detail-header">
        <div>
          <h1>{patient.name}</h1>
          <div className="detail-header__meta">
            <span><strong>{patient.age}</strong> years &middot; {patient.gender}</span>
            <span>Village: <strong>{patient.village || '—'}</strong></span>
            <span>Contact: <strong>{patient.contact || '—'}</strong></span>
            {patient.occupation && <span>Occupation: <strong>{patient.occupation}</strong></span>}
            <span>Worker: <strong>{assignment.worker?.fullName || 'Unassigned'}</strong> ({assignmentLabel(assignment.reason)})</span>
          </div>
        </div>
        <div className="detail-header__actions">
          <button className="btn btn-primary" onClick={() => navigate(`/dashboard/screenings/new?patientId=${patient.id}`)}>
            <Stethoscope size={16} /> New screening
          </button>
          <button className="btn btn-ghost" onClick={() => setEditing(true)}>
            <Pencil size={15} /> Edit
          </button>
          <button className="btn btn-danger" onClick={handleDelete}>
            <Trash2 size={15} />
          </button>
        </div>
      </div>

      <div className="stat-grid" style={{ marginBottom: 30 }}>
        <div className="card">
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 6 }}>Screening history</div>
          <div style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 700 }}>{screenings.length}</div>
        </div>
        <div className="card">
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 6 }}>Most recent risk</div>
          <RiskBadge level={screenings[0]?.riskLevel} size="lg" />
        </div>
        <div className="card">
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 6 }}>Height / Weight</div>
          <div style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 700 }}>
            {patient.height || '—'} cm &middot; {patient.weight || '—'} kg
          </div>
        </div>
        <div className="card">
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 6 }}>Wearable on assigned worker</div>
          <div style={{ fontFamily: 'var(--font-display)', fontSize: 18, fontWeight: 700 }}>
            {assignment.worker ? wearableId(assignment.worker) : '—'}
          </div>
        </div>
      </div>

      <h2 className="section-title">Screening history</h2>
      {screenings.length === 0 ? (
        <EmptyState
          title="No screenings yet"
          message="Run this patient's first OA risk screening."
          action={<button className="btn btn-primary" onClick={() => navigate(`/dashboard/screenings/new?patientId=${patient.id}`)}>Start screening</button>}
        />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Pain level</th>
                <th>Risk</th>
                <th>Confidence</th>
                <th>Source</th>
              </tr>
            </thead>
            <tbody>
              {screenings.map((s) => (
                <tr key={s.id} onClick={() => navigate(`/dashboard/screenings/${s.id}`)}>
                  <td>{new Date(s.screeningDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
                  <td>{s.painLevel} / 10</td>
                  <td><RiskBadge level={s.riskLevel} /></td>
                  <td>{s.confidence != null ? `${Math.round(s.confidence * 100)}%` : '—'}</td>
                  <td>{s.source === 'ml_model' ? 'ML model' : 'Fallback rules'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {editing && (
        <PatientFormModal
          patient={patient}
          onClose={() => setEditing(false)}
          onSaved={() => {
            setEditing(false);
            load();
          }}
        />
      )}
    </div>
  );
}
