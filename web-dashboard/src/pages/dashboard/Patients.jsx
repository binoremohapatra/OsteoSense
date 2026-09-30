import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Pencil, Trash2, Stethoscope } from 'lucide-react';
import { patientsApi } from '../../api/services';
import { getPatientAssignment, assignmentLabel } from '../../services/assignmentService';
import { useAuth } from '../../context/AuthContext';
import RiskBadge from '../../components/RiskBadge';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import Pagination from '../../components/Pagination';
import PatientFormModal from '../../components/PatientFormModal';
import './Dashboard.css';

export default function Patients() {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [patients, setPatients] = useState([]);
  const [patientAssignments, setPatientAssignments] = useState(new Map());
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 });
  const [loading, setLoading] = useState(true);
  const [assignmentsLoading, setAssignmentsLoading] = useState(false);
  const [searchInput, setSearchInput] = useState('');
  const [village, setVillage] = useState('');
  const [riskLevel, setRiskLevel] = useState('');
  const [page, setPage] = useState(1);
  const [modalPatient, setModalPatient] = useState(undefined); // undefined = closed, null = new, obj = edit

  const loadAssignments = useCallback(async (patientList) => {
    if (!patientList.length) return;
    
    setAssignmentsLoading(true);
    const assignmentsMap = new Map();
    
    await Promise.all(
      patientList.map(async (patient) => {
        try {
          const assignment = await getPatientAssignment(patient);
          assignmentsMap.set(patient.id, assignment);
        } catch (error) {
          console.error(`Failed to get assignment for patient ${patient.id}:`, error);
          assignmentsMap.set(patient.id, { worker: null, reason: 'error', score: 0 });
        }
      })
    );
    
    setPatientAssignments(assignmentsMap);
    setAssignmentsLoading(false);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      if (searchInput.trim().length >= 2) {
        const res = await patientsApi.search(searchInput.trim(), { allPatients: isAdmin ? 'true' : undefined });
        setPatients(res.data || []);
        setPagination({ page: 1, totalPages: 1, total: res.data?.length || 0 });
        await loadAssignments(res.data || []);
      } else {
        const params = { page, limit: 20 };
        if (isAdmin) params.allPatients = 'true';
        if (village.trim()) params.village = village.trim();
        if (riskLevel) params.riskLevel = riskLevel;
        const res = await patientsApi.list(params);
        setPatients(res.data || []);
        setPagination(res.pagination || { page: 1, totalPages: 1, total: 0 });
        await loadAssignments(res.data || []);
      }
    } finally {
      setLoading(false);
    }
  }, [page, village, riskLevel, searchInput, loadAssignments, isAdmin]);

  useEffect(() => {
    load();
  }, [load]);

  const handleDelete = async (patient) => {
    if (!window.confirm(`Remove ${patient.name} from your patient list?`)) return;
    await patientsApi.remove(patient.id);
    load();
  };

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Patients</h1>
          <p>This login’s records, with workers attached automatically from village and location.</p>
        </div>

      </div>

      <div className="filters-row">
        <div style={{ position: 'relative' }}>
          <input
            type="search"
            placeholder="Search by name or village…"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            style={{ paddingLeft: 34 }}
          />
          <Search size={15} style={{ position: 'absolute', left: 11, top: 11, color: 'var(--text-tertiary)' }} />
        </div>
        <input
          type="text"
          placeholder="Filter by village"
          value={village}
          onChange={(e) => { setVillage(e.target.value); setPage(1); }}
          disabled={searchInput.trim().length >= 2}
        />
        <select value={riskLevel} onChange={(e) => { setRiskLevel(e.target.value); setPage(1); }} disabled={searchInput.trim().length >= 2}>
          <option value="">All risk levels</option>
          <option value="low">Low risk</option>
          <option value="medium">Medium risk</option>
          <option value="high">High risk</option>
        </select>
      </div>

      {loading ? (
        <Spinner />
      ) : patients.length === 0 ? (
        <EmptyState
          title="No patients found"
          message="Add your first patient to start screening."
        />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Age / Gender</th>
                <th>Village</th>
                <th>Assigned Health Worker</th>
                <th>Latest screening</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {patients.map((p) => {
                const { worker, reason } = patientAssignments.get(p.id) || { worker: null, reason: 'loading', score: 0 };
                return (
                <tr key={p.id} onClick={() => navigate(`/dashboard/patients/${p.id}`)}>
                  <td>
                    <div className="name-cell">
                      <strong>{p.name}</strong>
                      <span>{p.contact || 'No contact on file'}</span>
                    </div>
                  </td>
                  <td>{p.age} &middot; {p.gender}</td>
                  <td>{p.village || '—'}</td>
                  <td>
                    <div className="name-cell">
                      <strong>{worker?.fullName || 'Unassigned'}</strong>
                      <span>{assignmentLabel(reason)}</span>
                    </div>
                  </td>
                  <td>
                    <RiskBadge level={p.latestScreening?.riskLevel} />
                  </td>
                  <td>
                    <div className="row-actions" onClick={(e) => e.stopPropagation()}>
                      <button className="btn-icon" title="New screening" onClick={() => navigate(`/dashboard/screenings/new?patientId=${p.id}`)}>
                        <Stethoscope size={15} />
                      </button>
                      <button className="btn-icon" title="Edit" onClick={() => setModalPatient(p)}>
                        <Pencil size={15} />
                      </button>
                      <button className="btn-icon" title="Delete" onClick={() => handleDelete(p)}>
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              );
              })}
            </tbody>
          </table>
          {searchInput.trim().length < 2 && (
            <Pagination page={pagination.page} totalPages={pagination.totalPages} total={pagination.total} onChange={setPage} />
          )}
        </div>
      )}

      {modalPatient !== undefined && (
        <PatientFormModal
          patient={modalPatient}
          onClose={() => setModalPatient(undefined)}
          onSaved={() => {
            setModalPatient(undefined);
            load();
          }}
        />
      )}
    </div>
  );
}
