import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowLeft, Shuffle } from 'lucide-react';
import { patientsApi, screeningsApi } from '../../api/services';
import PatientPicker from '../../components/PatientPicker';
import './Dashboard.css';

export default function NewScreening() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const preselectedId = searchParams.get('patientId');

  const [patient, setPatient] = useState(null);
  const [painLevel, setPainLevel] = useState(5);
  const [stiffnessDuration, setStiffnessDuration] = useState('15 minutes');
  const [swelling, setSwelling] = useState(false);
  const [pastInjury, setPastInjury] = useState('');
  const [gaitFeatures, setGaitFeatures] = useState([]);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (preselectedId) {
      patientsApi.getById(preselectedId, { allPatients: true }).then((res) => setPatient(res.data)).catch(() => {});
    }
  }, [preselectedId]);

  const generateGaitReading = () => {
    setGaitFeatures(Array.from({ length: 4 }, () => Math.round(Math.random() * 100) / 100));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!patient) {
      setError('Select a patient before submitting a screening.');
      return;
    }
    setError('');
    setSubmitting(true);
    try {
      const res = await screeningsApi.create({
        patientId: patient.id,
        painLevel,
        stiffnessDuration,
        swelling,
        pastInjury,
        gaitFeatures,
      });
      navigate(`/dashboard/screenings/${res.data.id}`, { replace: true });
    } catch (err) {
      const apiErrors = err.response?.data?.errors;
      setError(apiErrors?.[0]?.message || err.response?.data?.message || 'Could not submit screening.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <button className="back-link" onClick={() => navigate(-1)}>
        <ArrowLeft size={15} /> Back
      </button>

      <div className="page-head">
        <div>
          <h1>New screening</h1>
          <p>Symptoms and gait data go straight to the AI risk model.</p>
        </div>
      </div>

      {error && <div className="banner banner-error" style={{ marginBottom: 18, maxWidth: 640 }}>{error}</div>}

      <form onSubmit={handleSubmit} className="card" style={{ maxWidth: 640, display: 'flex', flexDirection: 'column', gap: 22 }}>
        <div className="field">
          <label>Patient</label>
          <PatientPicker value={patient} onChange={setPatient} />
        </div>

        <div className="field">
          <label>Pain level</label>
          <div className="slider-field">
            <input type="range" min="0" max="10" value={painLevel} onChange={(e) => setPainLevel(Number(e.target.value))} />
            <span className="slider-field__value">{painLevel}/10</span>
          </div>
        </div>

        <div className="form-grid">
          <div className="field">
            <label>Morning stiffness duration</label>
            <select value={stiffnessDuration} onChange={(e) => setStiffnessDuration(e.target.value)}>
              <option>Under 15 minutes</option>
              <option>15 minutes</option>
              <option>30 minutes</option>
              <option>1 hour</option>
              <option>Over 1 hour</option>
            </select>
          </div>
          <div className="field">
            <label>Swelling observed</label>
            <select value={swelling ? 'yes' : 'no'} onChange={(e) => setSwelling(e.target.value === 'yes')}>
              <option value="no">No</option>
              <option value="yes">Yes</option>
            </select>
          </div>
        </div>

        <div className="field">
          <label>Past injury (optional)</label>
          <textarea rows={2} value={pastInjury} onChange={(e) => setPastInjury(e.target.value)} placeholder="e.g. Twisted knee in 2019" />
        </div>

        <div className="field">
          <label>Gait sensor reading</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button type="button" className="btn btn-ghost btn-sm" onClick={generateGaitReading}>
              <Shuffle size={14} /> Capture reading
            </button>
            <span style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'monospace' }}>
              {gaitFeatures.length ? `[${gaitFeatures.join(', ')}]` : 'No reading captured yet'}
            </span>
          </div>
          <span className="field-hint">On the mobile app this comes from the phone’s motion sensor during a short walk test.</span>
        </div>

        <button className="btn btn-primary" type="submit" disabled={submitting} style={{ alignSelf: 'flex-start', padding: '12px 26px' }}>
          {submitting ? 'Predicting risk…' : 'Submit screening'}
        </button>
      </form>
    </div>
  );
}
