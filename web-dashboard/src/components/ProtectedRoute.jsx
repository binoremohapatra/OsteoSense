import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import Spinner from './Spinner';

export default function ProtectedRoute({ children }) {
  const { user, loading, logout } = useAuth();
  const location = useLocation();

  if (loading) return <Spinner />;
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />;

  // Web dashboard is strictly restricted to administrator accounts
  if (user.role !== 'admin') {
    logout();
    return (
      <Navigate
        to="/login"
        replace
        state={{ error: 'Access restricted: Only administrators are authorized to access the web dashboard.' }}
      />
    );
  }

  return children;
}
