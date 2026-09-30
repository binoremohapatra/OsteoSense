import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Download, User, UserCheck } from 'lucide-react';
import { screeningsApi } from '../../api/services';
import { getPatientAssignment, assignmentLabel } from '../../services/assignmentService';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import WaveformChart from '../../components/WaveformChart';
import { extractSensorSeries, hasSensorData } from '../../utils/sensorSeries';
import { riskStyle } from '../../utils/risk';
import './Dashboard.css';

export default function ScreeningDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [screening, setScreening] = useState(null);
  const [loading, setLoading] = useState(true);
  const [downloading, setDownloading] = useState(false);
  const [assignment, setAssignment] = useState(null);

  useEffect(() => {
    screeningsApi.getById(id).then((res) => {
      setScreening(res.data);
      setLoading(false);
      
      // Load assignment for the patient
      if (res.data?.patientId) {
        const patient = typeof res.data.patientId === 'object' ? res.data.patientId : { id: res.data.patientId };
        getPatientAssignment(patient).then(setAssignment).catch(() => {
          setAssignment({ worker: null, reason: 'error', score: 0 });
        });
      }
    });
  }, [id]);

  const handleDownload = async () => {
    setDownloading(true);
    try {
      const blob = await screeningsApi.downloadReport(id);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `screening-report-${id}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } finally {
      setDownloading(false);
    }
  };

  if (loading) return <Spinner />;
  if (!screening) return <EmptyState title="Screening not found" />;

  const patient = screening.patientId;
  const style = riskStyle(screening.riskLevel);
  const series = extractSensorSeries(screening);

  return (
    <div>
      <button className="back-link" onClick={() => navigate(-1)}>
        <ArrowLeft size={15} /> Back
      </button>

      <div className="detail-header">
        <div>
          <h1>Session</h1>
          <div className="detail-header__meta">
            <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <User size={14} />
              {typeof patient === 'object' ? (
                <a onClick={() => navigate(`/dashboard/patients/${patient._id || patient.id}`)} style={{ cursor: 'pointer', fontWeight: 600 }}>
                  {patient.name}
                </a>
              ) : (
                'Patient'
              )}
            </span>
            <span>{new Date(screening.screeningDate).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</span>
          </div>
        </div>
        <button className="btn btn-primary" onClick={handleDownload} disabled={downloading}>
          <Download size={16} /> {downloading ? 'Preparing…' : 'Download PDF report'}
        </button>
      </div>

      <div className="result-panel" style={{ background: style.bg }}>
        <div className="result-panel__gauge" style={{ borderColor: style.border, color: style.color }}>
          {screening.confidence != null ? `${Math.round(screening.confidence * 100)}%` : '—'}
        </div>
        <div className="result-panel__text">
          <h2 style={{ color: style.color }}>{screening.riskLevel} risk</h2>
          <p>{screening.aiReasoning || 'No AI reasoning recorded for this screening.'}</p>
          <span className="mock-result__source" style={{ marginTop: 10, display: 'inline-block' }}>
            {screening.source === 'ml_model' ? 'ml_model' : 'fallback_rules'}
          </span>
        </div>
      </div>

      <h2 className="section-title">Sensor traces</h2>
      {!hasSensorData(series) ? (
        <div className="card" style={{ marginBottom: 22 }}>
          <EmptyState
            title="No IMU / EMG / Piezo arrays on this session"
            message="When the phone syncs gaitRawData or channel objects, motion, muscle, and acoustic waveforms show here."
          />
        </div>
      ) : (
        <div className="waveform-grid">
          <WaveformChart title="IMU / motion" data={series.imu} color="#4F6757" />
          <WaveformChart title="EMG / muscle" data={series.emg} color="#C4A252" />
          <WaveformChart title="Piezo / acoustic" data={series.piezo} color="#B87070" />
        </div>
      )}

      <div className="two-col">
        <div className="card">
          <h3 className="section-title">Clinical inputs</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Row label="Pain level" value={`${screening.painLevel} / 10`} />
            <Row label="Stiffness duration" value={screening.stiffnessDuration || '—'} />
            <Row label="Swelling" value={screening.swelling ? 'Present' : 'None reported'} />
            <Row label="Past injury" value={screening.pastInjury || 'None reported'} />
          </div>

          {screening.contributingFactors?.length > 0 && (
            <div style={{ marginTop: 20 }}>
              <h3 className="section-title">Contributing factors</h3>
              <div>
                {screening.contributingFactors.map((f) => (
                  <span className="factor-chip" key={f}>{f}</span>
                ))}
              </div>
            </div>
          )}

          {screening.doctorRecommendations && (
            <div style={{ marginTop: 20 }}>
              <h3 className="section-title">Recommendations</h3>
              <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.6 }}>
                {screening.doctorRecommendations}
              </p>
            </div>
          )}
        </div>

        <div className="card">
          <h3 className="section-title">Patient</h3>
          {typeof patient === 'object' ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <Row label="Name" value={patient.name} />
              <Row label="Age" value={patient.age} />
              <Row label="Gender" value={patient.gender} />
              <Row label="Village" value={patient.village || '—'} />
              {assignment && (
                <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid var(--divider)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
                    <UserCheck size={14} />
                    <strong style={{ fontSize: 13.5 }}>Assigned Health Worker</strong>
                  </div>
                  <div style={{ fontSize: 13.5 }}>
                    <strong>{assignment.worker?.fullName || 'Unassigned'}</strong>
                    {assignment.worker && (
                      <span style={{ color: 'var(--text-tertiary)', marginLeft: 8 }}>
                        · {assignmentLabel(assignment.reason)}
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>
          ) : (
            <p style={{ color: 'var(--text-tertiary)', fontSize: 13.5 }}>Patient details unavailable.</p>
          )}
        </div>
      </div>
    </div>
  );
}

function Row({ label, value }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13.5 }}>
      <span style={{ color: 'var(--text-secondary)' }}>{label}</span>
      <strong style={{ textTransform: 'capitalize' }}>{value}</strong>
    </div>
  );
}
