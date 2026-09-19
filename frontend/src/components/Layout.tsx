import { Outlet, Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { useSignalR } from '../hooks/useSignalR';

export default function Layout() {
  const { user, logout } = useAuthStore();
  const navigate         = useNavigate();
  useSignalR();

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <nav className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between shadow-sm">
        <div className="flex items-center gap-6">
          <span className="font-bold text-blue-700 text-lg">SupportDesk</span>
          {user?.role === 'Customer' && <>
            <Link to="/tickets"     className="text-sm text-gray-600 hover:text-blue-600">My Tickets</Link>
            <Link to="/tickets/new" className="text-sm text-gray-600 hover:text-blue-600">Submit Ticket</Link>
          </>}
          {(user?.role === 'Agent' || user?.role === 'Supervisor' || user?.role === 'Admin') && <>
            <Link to="/dashboard"   className="text-sm text-gray-600 hover:text-blue-600">Dashboard</Link>
          </>}
          {(user?.role === 'Supervisor' || user?.role === 'Admin') && <>
            <Link to="/analytics"   className="text-sm text-gray-600 hover:text-blue-600">Analytics</Link>
          </>}
          {user?.role === 'Admin' && <>
            <Link to="/admin/users" className="text-sm text-gray-600 hover:text-blue-600">Users</Link>
          </>}
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-500">{user?.fullName} · <span className="font-medium text-blue-600">{user?.role}</span></span>
          <button onClick={handleLogout} className="btn-secondary text-sm py-1">Logout</button>
        </div>
      </nav>
      <main className="flex-1 p-6 max-w-7xl mx-auto w-full">
        <Outlet />
      </main>
    </div>
  );
}
