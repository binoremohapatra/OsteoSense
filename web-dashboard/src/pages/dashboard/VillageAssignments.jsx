import { useMemo, useState, useEffect } from 'react';
import { MapPin, User } from 'lucide-react';
import useHealthWorkers from '../../hooks/useHealthWorkers';
import { patientsApi } from '../../api/services';
import { getAllVillageAssignments, getPatientAssignment, assignmentLabel } from '../../services/assignmentService';
import { groupWorkersByCenter, wearableId } from '../../services/autoAssign';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

export default function VillageAssignments() {
  const { workers, loading: workersLoading } = useHealthWorkers();
  const [patients, setPatients] = useState([]);
  const [patientAssignments, setPatientAssignments] = useState(new Map());
  const [loadingPatients, setLoadingPatients] = useState(true);
  const [assignments, setAssignments] = useState([]);
  const [loadingAssignments, setLoadingAssignments] = useState(true);

  useEffect(() => {
    patientsApi
      .list({ page: 1, limit: 100, allPatients: true })
      .then(async (res) => {
        const patientList = res.data || [];
        setPatients(patientList);
        
        // Load assignments for patients
        const assignmentsMap = new Map();
        await Promise.all(
          patientList.map(async (patient) => {
            try {
              const assignment = await getPatientAssignment(patient);
              assignmentsMap.set(patient.id, assignment);
            } catch (error) {
              assignmentsMap.set(patient.id, { worker: null, reason: 'error', score: 0 });
            }
          })
        );
        setPatientAssignments(assignmentsMap);
      })
      .finally(() => setLoadingPatients(false));
  }, []);

  useEffect(() => {
    getAllVillageAssignments()
      .then(setAssignments)
      .catch(() => setAssignments([]))
      .finally(() => setLoadingAssignments(false));
  }, []);

  const villagesFromPatients = useMemo(
    () => [...new Set(patients.map((p) => p.village).filter(Boolean))],
    [patients]
  );

  const centers = useMemo(() => groupWorkersByCenter(workers), [workers]);

  const matched = assignments.filter((row) => row.worker).length;

  if (workersLoading || loadingPatients || loadingAssignments) return <Spinner />;

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Coverage map</h1>
          <p>Village-to-health-worker mapping from backend assignments and auto-assignment logic.</p>
        </div>
      </div>

      <div className="stat-grid">
        <div className="card">
          <div className="muted-label">Active workers</div>
          <div className="stat-number">{workers.length}</div>
        </div>
        <div className="card">
          <div className="muted-label">Health centers</div>
          <div className="stat-number">{centers.length}</div>
        </div>
        <div className="card">
          <div className="muted-label">Villages in caseload</div>
          <div className="stat-number">{villagesFromPatients.length}</div>
        </div>
        <div className="card">
          <div className="muted-label">Location-matched</div>
          <div className="stat-number">{matched}</div>
        </div>
      </div>

      <h2 className="section-title">Village → worker</h2>
      {assignments.length === 0 ? (
        <EmptyState title="No village assignments yet" message="Village assignments are configured in the backend to map villages to specific health workers." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Village</th>
                <th>Location</th>
                <th>Assigned worker</th>
                <th>Health center</th>
              </tr>
            </thead>
            <tbody>
              {assignments.map((row) => (
                <tr key={row.id} style={{ cursor: 'default' }}>
                  <td>
                    <div className="name-cell">
                      <strong>{row.village}</strong>
                    </div>
                  </td>
                  <td>{row.location || '—'}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <User size={14} />
                      {row.worker?.fullName || 'Unassigned'}
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <MapPin size={14} />
                      {row.worker?.healthCenterId || '—'}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <h2 className="section-title" style={{ marginTop: 30 }}>Patients in program</h2>
      {patients.length === 0 ? (
        <EmptyState title="No patients found" message="Add patients to see the auto-assignment mapping in action." />
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Village</th>
                <th>Auto-assigned worker</th>
                <th>Wearable</th>
              </tr>
            </thead>
            <tbody>
              {patients.map((patient) => {
                const { worker, reason } = patientAssignments.get(patient.id) || { worker: null, reason: 'loading', score: 0 };
                return (
                  <tr key={patient.id} style={{ cursor: 'default' }}>
                    <td>
                      <div className="name-cell">
                        <strong>{patient.name}</strong>
                        <span>{patient.age} · {patient.gender}</span>
                      </div>
                    </td>
                    <td>{patient.village || '—'}</td>
                    <td>
                      <div className="name-cell">
                        <strong>{worker?.fullName || 'Unassigned'}</strong>
                        <span>{assignmentLabel(reason)}</span>
                      </div>
                    </td>
                    <td>{worker ? wearableId(worker) : '—'}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      <h2 className="section-title" style={{ marginTop: 30 }}>Workers by health center</h2>
      {centers.length === 0 ? (
        <EmptyState title="No health workers found" />
      ) : (
        <div className="care-grid">
          {centers.map((group) => (
            <div className="care-card" key={group.center}>
              <span className="care-card__cat">{group.members.length} workers</span>
              <h3>{group.center}</h3>
              <ul className="plain-list">
                {group.members.map((worker) => (
                  <li key={worker.id || worker._id}>
                    <strong>{worker.fullName}</strong>
                    <span>{worker.location || 'Location not set'} · {wearableId(worker)}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
