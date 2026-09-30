import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { screeningsApi } from '../../api/services';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

const NOTES_KEY = 'jointsaathi.aiReview';

function loadNotes() {
  try {
    return JSON.parse(localStorage.getItem(NOTES_KEY)) || {};
  } catch {
    return {};
  }
}

export default function ReviewQueue() {
  const navigate = useNavigate();
  const [rows, setRows] = useState([]);
  const [notes, setNotes] = useState(() => loadNotes());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    screeningsApi.list({ page: 1, limit: 50 }).then((res) => {
      setRows((res.data || []).filter((s) => s.source === 'ml_model'));
      setLoading(false);
    });
  }, []);

  const setNote = (id, patch) => {
    const next = { ...notes, [id]: { ...(notes[id] || { status: 'pending' }), ...patch } };
    setNotes(next);
    localStorage.setItem(NOTES_KEY, JSON.stringify(next));
  };

  if (loading) return <Spinner />;

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>AI review queue</h1>
          <p>Placeholder for clinician override of auto-staged scores. Nothing is written to the mobile backend.</p>
        </div>
      </div>

      {rows.length === 0 ? (
        <EmptyState title="No ML-staged screenings" message="Fallback-rule results stay out of this queue until the model path is used." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Suggested risk</th>
                <th>Confidence</th>
                <th>Review</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((s) => {
                const note = notes[s.id] || { status: 'pending', override: '' };
                return (
                  <tr key={s.id} style={{ cursor: 'default' }}>
                    <td>
                      <button className="linkish" onClick={() => navigate(`/dashboard/screenings/${s.id}`)}>
                        {new Date(s.screeningDate).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}
                      </button>
                    </td>
                    <td><RiskBadge level={s.riskLevel} /></td>
                    <td>{s.confidence != null ? `${Math.round(s.confidence * 100)}%` : '—'}</td>
                    <td>
                      <div className="row-actions" style={{ justifyContent: 'flex-start' }}>
                        <select value={note.status} onChange={(e) => setNote(s.id, { status: e.target.value })}>
                          <option value="pending">Pending</option>
                          <option value="accepted">Accept</option>
                          <option value="overridden">Override</option>
                        </select>
                        {note.status === 'overridden' && (
                          <select value={note.override || ''} onChange={(e) => setNote(s.id, { override: e.target.value })}>
                            <option value="">Set risk</option>
                            <option value="low">Low</option>
                            <option value="medium">Medium</option>
                            <option value="high">High</option>
                          </select>
                        )}
                      </div>
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
