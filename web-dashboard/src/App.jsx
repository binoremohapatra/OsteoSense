import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import DashboardLayout from './layouts/DashboardLayout';

import Landing from './pages/Landing';
import Login from './pages/Login';

import Overview from './pages/dashboard/Overview';
import Patients from './pages/dashboard/Patients';
import PatientDetail from './pages/dashboard/PatientDetail';
import Screenings from './pages/dashboard/Screenings';
import NewScreening from './pages/dashboard/NewScreening';
import ScreeningDetail from './pages/dashboard/ScreeningDetail';
import Analytics from './pages/dashboard/Analytics';
import PreventiveCare from './pages/dashboard/PreventiveCare';
import Sync from './pages/dashboard/Sync';
import Referrals from './pages/dashboard/Referrals';
import ReviewQueue from './pages/dashboard/ReviewQueue';
import Profile from './pages/dashboard/Profile';
import AdminSection from './pages/admin/AdminSection';

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Navigate to="/login" replace />} />

          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <DashboardLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Overview />} />
            <Route path="patients" element={<Patients />} />
            <Route path="patients/:id" element={<PatientDetail />} />
            <Route path="screenings" element={<Screenings />} />
            <Route path="screenings/new" element={<NewScreening />} />
            <Route path="screenings/:id" element={<ScreeningDetail />} />
            <Route path="analytics" element={<Analytics />} />
            <Route path="referrals" element={<Referrals />} />
            <Route path="review" element={<ReviewQueue />} />
            <Route path="preventive-care" element={<PreventiveCare />} />
            <Route path="sync" element={<Sync />} />
            <Route path="admin" element={<AdminSection />} />
            <Route path="profile" element={<Profile />} />
          </Route>

          <Route path="*" element={<Landing />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
