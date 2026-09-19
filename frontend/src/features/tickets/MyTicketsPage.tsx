import { Link } from 'react-router-dom';
import { format } from 'date-fns';
import { useMyTickets } from '../../hooks/useTickets';
import { StatusBadge, PriorityBadge } from '../../components/StatusBadge';

export default function MyTicketsPage() {
  const { data: tickets, isLoading, error } = useMyTickets();

  if (isLoading) return <div className="text-center py-12 text-gray-500">Loading your tickets…</div>;
  if (error)     return <div className="text-center py-12 text-red-500">Failed to load tickets.</div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">My Tickets</h1>
        <Link to="/tickets/new" className="btn-primary">+ New Ticket</Link>
      </div>

      {!tickets?.length ? (
        <div className="card text-center py-12">
          <p className="text-gray-400 text-lg mb-2">No tickets yet</p>
          <p className="text-gray-400 text-sm mb-4">Have an issue? Let us know.</p>
          <Link to="/tickets/new" className="btn-primary inline-block">Submit your first ticket</Link>
        </div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ticket #</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {tickets.map(ticket => (
                <tr key={ticket.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <Link to={`/tickets/${ticket.id}`} className="text-blue-600 hover:underline font-mono text-sm">
                      {ticket.ticketNumber}
                    </Link>
                  </td>
                  <td className="px-6 py-4">
                    <Link to={`/tickets/${ticket.id}`} className="text-gray-900 hover:text-blue-600 font-medium">
                      {ticket.title}
                    </Link>
                    <p className="text-xs text-gray-400 mt-0.5">{ticket.category}</p>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap"><StatusBadge status={ticket.status} /></td>
                  <td className="px-6 py-4 whitespace-nowrap"><PriorityBadge priority={ticket.priority} /></td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format(new Date(ticket.createdAt), 'MMM d, yyyy')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
