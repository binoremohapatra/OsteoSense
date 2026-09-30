import { useEffect, useState } from 'react';
import { Link, NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutGrid,
  Users,
  Stethoscope,
  BarChart3,
  HeartPulse,
  RefreshCw,
  LogOut,
  Activity,
  Menu,
  X,
  ClipboardList,
  Shield,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './DashboardLayout.css';
// import logo from '../public/favicon.jpeg'; 

const BASE_NAV = [
  { to: '/dashboard', label: 'Overview', icon: LayoutGrid, end: true },
  { to: '/dashboard/analytics', label: 'Analytics', icon: BarChart3 },
  { to: '/dashboard/patients', label: 'Patients', icon: Users },
  { to: '/dashboard/screenings', label: 'Screenings', icon: Stethoscope },
  { to: '/dashboard/referrals', label: 'Referrals', icon: ClipboardList },
  { to: '/dashboard/preventive-care', label: 'Preventive care', icon: HeartPulse },
  { to: '/dashboard/sync', label: 'Fleet health', icon: RefreshCw },
];

export default function DashboardLayout() {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [navOpen, setNavOpen] = useState(false);

  const navItems = [
    ...BASE_NAV,
    ...(isAdmin ? [{ to: '/dashboard/admin', label: 'Admin Hub', icon: Shield }] : []),
  ];

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  // Close the mobile nav drawer whenever the route changes.
  useEffect(() => {
    setNavOpen(false);
  }, [location.pathname]);

  // Prevent background scroll while the mobile nav drawer is open.
  useEffect(() => {
    if (!navOpen) return undefined;
    const { overflow } = document.body.style;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = overflow;
    };
  }, [navOpen]);

  const pageLabel =
    location.pathname.startsWith('/dashboard/profile') ? 'Profile'
    : location.pathname.startsWith('/dashboard/admin') ? 'Admin Hub'
    : location.pathname.startsWith('/dashboard/patients/') ? 'Patient'
    : location.pathname.startsWith('/dashboard/screenings/') ? 'Session'
    : navItems.find((item) => (item.end ? location.pathname === item.to : location.pathname.startsWith(item.to)))?.label || 'Dashboard';

  const initials = (user?.fullName || '?')
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <div className="shell">
      <div className="shell__mobilebar">
        <button
          className="shell__menu-btn"
          onClick={() => setNavOpen(true)}
          aria-label="Open navigation menu"
          aria-expanded={navOpen}
        >
          <Menu size={20} />
        </button>
        <Link to="/dashboard" className="shell__brand">
          <span className="shell__brand-mark">
            <img src="/favicon.jpeg" alt="JointSaathi" className="shell__brand-logo" />
          </span>
          <span className="shell__brand-name">JointSaathi</span>
        </Link>
        <span className="shell__mobile-title">{pageLabel}</span>
      </div>

      {navOpen && <div className="shell__scrim" onClick={() => setNavOpen(false)} />}

      <aside className={`shell__sidebar${navOpen ? ' shell__sidebar--open' : ''}`}>
        <div className="shell__brand">
          <span className="shell__brand-mark">
            <img src="/favicon.jpeg" alt="JointSaathi" className="shell__brand-logo" />
          </span>
          <span className="shell__brand-name">JointSaathi</span>
          <button className="shell__close-btn" onClick={() => setNavOpen(false)} aria-label="Close navigation menu">
            <X size={18} />
          </button>
        </div>

        <nav className="shell__nav">
          {navItems.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) => `shell__nav-item${isActive ? ' shell__nav-item--active' : ''}`}
            >
              <Icon size={17.5} strokeWidth={2.1} />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="shell__sidebar-footer">
          <Link to="/dashboard/profile" className="shell__user">
            <span className="shell__avatar" style={isAdmin ? { background: 'var(--primary-dark)', color: '#fff' } : {}}>
              {initials}
            </span>
            <div className="shell__user-info">
              <span className="shell__user-name">{user?.fullName}</span>
              <span className="shell__user-role">
                {isAdmin ? 'System Administrator' : (user?.healthCenterId || user?.role)}
              </span>
            </div>
          </Link>
          <button className="shell__logout" onClick={handleLogout}>
            <LogOut size={16} />
            Log out
          </button>
        </div>
      </aside>

      <main className="shell__main">
        <div className="shell__topbar">
          <div>
            <span className="shell__crumb">{isAdmin ? 'Admin Portal' : 'Workspace'}</span>
            <strong>{pageLabel}</strong>
          </div>
          <div className="shell__topbar-user">
            <span className="shell__status-dot" style={isAdmin ? { background: '#10B981' } : {}} />
            {user?.fullName || (isAdmin ? 'System Administrator' : 'Health worker')}
            {isAdmin && (
              <span
                style={{
                  marginLeft: 8,
                  fontSize: 10.5,
                  fontWeight: 800,
                  letterSpacing: '0.05em',
                  textTransform: 'uppercase',
                  background: 'rgba(79, 103, 87, 0.15)',
                  color: 'var(--primary-dark)',
                  padding: '2px 7px',
                  borderRadius: 999,
                }}
              >
                ADMIN
              </span>
            )}
          </div>
        </div>
        <Outlet />
      </main>
    </div>
  );
}
