import { useAuth } from '../../context/AuthContext';
import './Dashboard.css';

export default function Profile() {
  const { user } = useAuth();
  if (!user) return null;

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>My profile</h1>
          <p>Your field agent account details.</p>
        </div>
      </div>

      <div className="card" style={{ maxWidth: 480, display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Row label="Full name" value={user.fullName} />
        <Row label="Phone number" value={user.phoneNumber} />
        <Row label="Role" value={user.role} />
        <Row label="Health center ID" value={user.healthCenterId || '—'} />
        <Row label="Location" value={user.location || '—'} />
        <Row label="Account status" value={user.isActive ? 'Active' : 'Inactive'} />
      </div>
    </div>
  );
}

function Row({ label, value }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14, borderBottom: '1px solid var(--divider)', paddingBottom: 12 }}>
      <span style={{ color: 'var(--text-secondary)' }}>{label}</span>
      <strong style={{ textTransform: 'capitalize' }}>{value}</strong>
    </div>
  );
}
