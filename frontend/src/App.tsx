import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useAuthStore } from './store/authStore';
import Layout from './components/Layout';
import LoginPage from './features/auth/LoginPage';
import RegisterPage from './features/auth/RegisterPage';
import SubmitTicketPage from './features/tickets/SubmitTicketPage';
import MyTicketsPage from './features/tickets/MyTicketsPage';
import TicketDetailPage from './features/tickets/TicketDetailPage';
import AgentDashboard from './features/dashboard/AgentDashboard';
import AnalyticsDashboard from './features/analytics/AnalyticsDashboard';
import UserManagementPage from './features/admin/UserManagementPage';

const ProtectedRoute = ({ children, roles }: { children: JSX.Element; roles?: string[] }) => {
  const { isAuthenticated, user } = useAuthStore();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (roles && user && !roles.includes(user.role)) return <Navigate to="/" replace />;
  return children;
};

const HomeRedirect = () => {
  const { user } = useAuthStore();
  if (!user) return <Navigate to="/login" />;
  return user.role === 'Customer'
    ? <Navigate to="/tickets" />
    : <Navigate to="/dashboard" />;
};

export default function App() {
  return (
    <BrowserRouter>
      <Toaster position="top-right" />
      <Routes>
        <Route path="/login"    element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
          <Route index element={<HomeRedirect />} />
          <Route path="tickets" element={
            <ProtectedRoute roles={['Customer']}>
              <MyTicketsPage />
            </ProtectedRoute>
          } />
          <Route path="tickets/new" element={
            <ProtectedRoute roles={['Customer']}>
              <SubmitTicketPage />
            </ProtectedRoute>
          } />
          <Route path="tickets/:id" element={<TicketDetailPage />} />
          <Route path="dashboard" element={
            <ProtectedRoute roles={['Agent','Supervisor','Admin']}>
              <AgentDashboard />
            </ProtectedRoute>
          } />
          <Route path="analytics" element={
            <ProtectedRoute roles={['Supervisor','Admin']}>
              <AnalyticsDashboard />
            </ProtectedRoute>
          } />
          <Route path="admin/users" element={
            <ProtectedRoute roles={['Admin']}>
              <UserManagementPage />
            </ProtectedRoute>
          } />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
