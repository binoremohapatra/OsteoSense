import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { ShieldCheck, Lock, CheckCircle2, ArrowLeft, KeyRound } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './Auth.css';

export default function Login() {
  const { login, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [form, setForm] = useState({ phoneNumber: '', password: '' });
  const [error, setError] = useState(location.state?.error || '');
  const [submitting, setSubmitting] = useState(false);

  const from = location.state?.from?.pathname || '/dashboard';

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const fillAdminCredentials = () => {
    setForm({ phoneNumber: '9999999999', password: 'admin123' });
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const user = await login(form.phoneNumber.trim(), form.password);
      if (user?.role !== 'admin') {
        await logout();
        setError('Access restricted: Only administrators are authorized to sign in to the web dashboard.');
        return;
      }
      navigate(from, { replace: true });
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Invalid administrator credentials. Please verify your phone number and password.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth">
      <div className="auth__panel">
        {/* Back to home */}
        <Link
          to="/"
          style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            color: 'var(--text-secondary)', fontSize: 13, fontWeight: 600,
            marginBottom: 20, textDecoration: 'none',
            transition: 'color .15s',
          }}
          onMouseEnter={e => e.currentTarget.style.color = 'var(--primary-dark)'}
          onMouseLeave={e => e.currentTarget.style.color = 'var(--text-secondary)'}
        >
          <ArrowLeft size={15} /> Back to home
        </Link>

        <Link to="/" className="auth__brand">
          <span className="auth__brand-mark">
            <img src="/favicon.jpeg" alt="JointSaathi" className="auth__brand-logo" />
          </span>
          JointSaathi
        </Link>

        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginBottom: 12 }}>
          <span
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 5,
              background: 'rgba(79, 103, 87, 0.12)',
              color: 'var(--primary-dark)',
              padding: '4px 10px',
              borderRadius: '999px',
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: '0.03em',
              textTransform: 'uppercase',
            }}
          >
            <ShieldCheck size={14} /> Administrator Portal
          </span>
          <span
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 4,
              background: 'rgba(16, 185, 129, 0.12)',
              color: '#059669',
              padding: '4px 9px',
              borderRadius: '999px',
              fontSize: 11.5,
              fontWeight: 600,
            }}
          >
            <Lock size={12} /> Secure Auth
          </span>
        </div>

        <h1>Administrator Sign In</h1>
        <p>Access district-wide screening telemetry, patient registries, and system database administration.</p>

        {error && <div className="banner banner-error">{error}</div>}

        <div
          style={{
            background: 'var(--primary-surface)',
            border: '1px solid rgba(79, 103, 87, 0.2)',
            borderRadius: '10px',
            padding: '12px 14px',
            marginBottom: '18px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 10,
          }}
        >
          <div style={{ fontSize: 13, color: 'var(--primary-dark)' }}>
            <strong>Demo Admin Account:</strong>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 2 }}>Phone: 9999999999 · Pass: admin123</div>
          </div>
          <button
            type="button"
            className="btn btn-ghost btn-sm"
            onClick={fillAdminCredentials}
            style={{
              fontSize: 12,
              fontWeight: 600,
              padding: '6px 10px',
              height: 'auto',
              background: '#fff',
              border: '1px solid rgba(79, 103, 87, 0.3)',
            }}
          >
            <KeyRound size={13} style={{ marginRight: 4 }} /> Autofill
          </button>
        </div>

        <form className="auth__form" onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="phoneNumber">Admin Phone Number</label>
            <input
              id="phoneNumber"
              name="phoneNumber"
              type="tel"
              inputMode="numeric"
              placeholder="9999999999"
              value={form.phoneNumber}
              onChange={handleChange}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              name="password"
              type="password"
              placeholder="••••••••"
              value={form.password}
              onChange={handleChange}
              required
            />
          </div>
          <button className="btn btn-primary auth__submit" type="submit" disabled={submitting}>
            {submitting ? 'Authenticating Administrator…' : 'Sign in to Admin Dashboard'}
          </button>
        </form>

        <div style={{ marginTop: 22, paddingTop: 18, borderTop: '1px solid var(--divider)', display: 'flex', flexDirection: 'column', gap: 8, fontSize: 13, color: 'var(--text-secondary)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <CheckCircle2 size={14} color="#4F6757" />
            <span>Database-driven role verification enabled</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <ShieldCheck size={14} color="#4F6757" />
            <span>Web dashboard access restricted strictly to Administrator role</span>
          </div>
        </div>
      </div>

      <div className="auth__visual">
        <div className="auth__visual-content">
          <span className="auth__visual-kicker">
            <i /> JOINTSAATHI · DISTRICT HEALTH COMMAND
          </span>
          <h2>Centralized oversight for community knee health.</h2>
          <p className="auth__visual-copy">
            Monitor real-time OA screening risk distribution, field worker telemetry, auto-assignments, and database records across all primary health centers.
          </p>
          <div className="auth__visual-cards" aria-hidden="true">
            <div className="auth__metric">
              <strong>100%</strong>
              <span>Coverage Index</span>
            </div>
            <div className="auth__metric">
              <strong>5 Core</strong>
              <span>DB Collections</span>
            </div>
            <div className="auth__metric">
              <strong>&lt; 500ms</strong>
              <span>Risk Inference</span>
            </div>
          </div>
          <blockquote>
            “Full visibility into high-risk joint prevalence across every village camp without losing individual patient follow-up fidelity.”
          </blockquote>
          <span className="auth__visual-attribution">
            National Health Mission & Public Health Screening Architecture
          </span>
        </div>
      </div>
    </div>
  );
}
