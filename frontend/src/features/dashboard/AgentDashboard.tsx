import { useState } from 'react';
import { Link } from 'react-router-dom';
import { format } from 'date-fns';
import { useTickets } from '../../hooks/useTickets';
import { StatusBadge, PriorityBadge } from '../../components/StatusBadge';
import type { TicketFilters } from '../../types';

export default function AgentDashboard() {
  const [filters, setFilters] = useState<TicketFilters>({ page: 1, pageSize: 20 });
  const { data, isLoading }   = useTickets(filters);

  const setFilter = (key: keyof TicketFilters, value: string) =>
    setFilters(f => ({ ...f, [key]: value || undefined, page: 1 }));

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Agent Dashboard</h1>
        <span className="text-sm text-gray-500">{data?.total ?? 0} tickets total</span>
      </div>

      {/* Filters */}
      <div className="card mb-4">
        <div className="flex flex-wrap gap-4">
          <div>
            <label className="label text-xs">Status</label>
            <select className="input text-sm py-1.5"
              onChange={e => setFilter('status', e.target.value)}>
              <option value="">All</option>
              <option>Open</option>
              <option>InProgress</option>
              <option>Escalated</option>
              <option>Closed</option>
            </select>
          </div>
          <div>
            <label className="label text-xs">Priority</label>
            <select className="input text-sm py-1.5"
              onChange={e => setFilter('priority', e.target.value)}>
              <option value="">All</option>
              <option>Critical</option>
              <option>High</option>
              <option>Medium</option>
              <option>Low</option>
            </select>
          </div>
          <div>
            <label className="label text-xs">Category</label>
            <select className="input text-sm py-1.5"
              onChange={e => setFilter('category', e.target.value)}>
              <option value="">All</option>
              <option>Authentication</option>
              <option>Billing</option>
              <option>Technical Support</option>
              <option>Account</option>
              <option>Feature Request</option>
              <option>Other</option>
            </select>
          </div>
        </div>
      </div>

      {/* Table */}
      {isLoading ? (
        <div className="text-center py-12 text-gray-400">Loading tickets…</div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ticket #</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Priority</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Assigned</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {data?.items.map(t => (
                <tr key={t.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-mono text-xs text-blue-600">
                    <Link to={`/tickets/${t.id}`} className="hover:underline">{t.ticketNumber}</Link>
                  </td>
                  <td className="px-4 py-3 max-w-xs">
                    <Link to={`/tickets/${t.id}`} className="text-gray-900 hover:text-blue-600 font-medium text-sm line-clamp-1">
                      {t.title}
                    </Link>
                    <p className="text-xs text-gray-400">{t.category}</p>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600">{t.customerName}</td>
                  <td className="px-4 py-3"><StatusBadge status={t.status} /></td>
                  <td className="px-4 py-3"><PriorityBadge priority={t.priority} /></td>
                  <td className="px-4 py-3 text-sm text-gray-500">{t.assignedToName ?? <span className="text-gray-300">Unassigned</span>}</td>
                  <td className="px-4 py-3 text-xs text-gray-400">{format(new Date(t.createdAt), 'MMM d, HH:mm')}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination */}
          {(data?.totalPages ?? 0) > 1 && (
            <div className="px-4 py-3 flex items-center justify-between border-t bg-gray-50">
              <span className="text-xs text-gray-500">
                Page {filters.page} of {data?.totalPages}
              </span>
              <div className="flex gap-2">
                <button
                  disabled={(filters.page ?? 1) <= 1}
                  onClick={() => setFilters(f => ({ ...f, page: (f.page ?? 1) - 1 }))}
                  className="btn-secondary text-xs py-1 px-2"
                >← Prev</button>
                <button
                  disabled={(filters.page ?? 1) >= (data?.totalPages ?? 1)}
                  onClick={() => setFilters(f => ({ ...f, page: (f.page ?? 1) + 1 }))}
                  className="btn-secondary text-xs py-1 px-2"
                >Next →</button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
