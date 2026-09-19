import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { useForm } from 'react-hook-form';
import toast from 'react-hot-toast';
import { useTicket, useUpdateTicketStatus } from '../../hooks/useTickets';
import { useResponses, useAddResponse } from '../../hooks/useResponses';
import { useSignalR } from '../../hooks/useSignalR';
import { useAuthStore } from '../../store/authStore';
import { StatusBadge, PriorityBadge } from '../../components/StatusBadge';
import type { TicketStatus } from '../../types';

const STATUSES: TicketStatus[] = ['Open', 'InProgress', 'Escalated', 'Closed'];

export default function TicketDetailPage() {
  const { id }         = useParams<{ id: string }>();
  const navigate       = useNavigate();
  const { user }       = useAuthStore();
  const isAgent        = user?.role !== 'Customer';

  const { data: ticket, isLoading } = useTicket(id!);
  const { data: responses }         = useResponses(id!);
  const updateStatus                = useUpdateTicketStatus();
  const addResponse                 = useAddResponse(id!);
  useSignalR(id);

  const { register, handleSubmit, reset } = useForm<{ body: string; isInternal: boolean }>();

  const onSendResponse = async (data: { body: string; isInternal: boolean }) => {
    try {
      await addResponse.mutateAsync({ ticketId: id!, body: data.body, isInternal: data.isInternal });
      reset();
      toast.success('Response sent.');
    } catch {
      toast.error('Failed to send response.');
    }
  };

  const onStatusChange = async (newStatus: TicketStatus) => {
    try {
      await updateStatus.mutateAsync({ id: id!, data: { status: newStatus } });
      toast.success(`Status updated to ${newStatus}.`);
    } catch {
      toast.error('Failed to update status.');
    }
  };

  if (isLoading) return <div className="text-center py-12 text-gray-500">Loading…</div>;
  if (!ticket)   return <div className="text-center py-12 text-red-500">Ticket not found.</div>;

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="card">
        <div className="flex items-start justify-between mb-4">
          <div>
            <span className="font-mono text-sm text-blue-600">{ticket.ticketNumber}</span>
            <h1 className="text-xl font-bold text-gray-900 mt-1">{ticket.title}</h1>
          </div>
          <div className="flex gap-2">
            <StatusBadge status={ticket.status} />
            <PriorityBadge priority={ticket.priority} />
          </div>
        </div>
        <p className="text-gray-700 bg-gray-50 rounded p-3 text-sm">{ticket.description}</p>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4 text-xs text-gray-500">
          <div><span className="font-medium block text-gray-700">Category</span>{ticket.category}</div>
          <div><span className="font-medium block text-gray-700">Customer</span>{ticket.customerName}</div>
          <div><span className="font-medium block text-gray-700">Assigned To</span>{ticket.assignedToName ?? '—'}</div>
          <div><span className="font-medium block text-gray-700">SLA Deadline</span>
            {ticket.slaDeadline ? format(new Date(ticket.slaDeadline), 'MMM d, HH:mm') : '—'}</div>
        </div>

        {/* Agent status controls */}
        {isAgent && ticket.status !== 'Closed' && (
          <div className="mt-4 flex gap-2 flex-wrap border-t pt-4">
            {STATUSES.filter(s => s !== ticket.status).map(s => (
              <button
                key={s}
                onClick={() => onStatusChange(s)}
                disabled={updateStatus.isPending}
                className="btn-secondary text-xs py-1 px-3"
              >
                Mark as {s === 'InProgress' ? 'In Progress' : s}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Conversation Thread */}
      <div className="card">
        <h2 className="font-semibold text-gray-900 mb-4">Conversation</h2>
        <div className="space-y-4">
          {!responses?.length && (
            <p className="text-sm text-gray-400 text-center py-4">No responses yet.</p>
          )}
          {responses?.map(r => (
            <div key={r.id} className={`flex gap-3 ${r.authorType === 'Agent' ? 'flex-row-reverse' : ''}`}>
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0 ${r.authorType === 'Agent' ? 'bg-blue-600' : 'bg-gray-400'}`}>
                {r.authorName[0].toUpperCase()}
              </div>
              <div className={`max-w-xl ${r.isInternal ? 'opacity-75' : ''}`}>
                <div className={`rounded-lg p-3 text-sm ${r.authorType === 'Agent' ? 'bg-blue-50 text-blue-900' : 'bg-gray-100 text-gray-900'}`}>
                  {r.isInternal && <span className="text-xs font-semibold text-orange-500 block mb-1">🔒 Internal Note</span>}
                  {r.body}
                </div>
                <p className="text-xs text-gray-400 mt-1 px-1">
                  {r.authorName} · {format(new Date(r.createdAt), 'MMM d, HH:mm')}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Reply Box */}
        {ticket.status !== 'Closed' && (
          <form onSubmit={handleSubmit(onSendResponse)} className="mt-6 border-t pt-4 space-y-3">
            <textarea
              {...register('body', { required: true })}
              className="input"
              rows={4}
              placeholder="Write your reply…"
            />
            <div className="flex items-center justify-between">
              {isAgent && (
                <label className="flex items-center gap-2 text-sm text-gray-600 cursor-pointer">
                  <input {...register('isInternal')} type="checkbox" className="rounded" />
                  Internal note (not visible to customer)
                </label>
              )}
              <button type="submit" disabled={addResponse.isPending} className="btn-primary ml-auto">
                {addResponse.isPending ? 'Sending…' : 'Send Reply'}
              </button>
            </div>
          </form>
        )}

        {ticket.status === 'Closed' && (
          <div className="mt-4 text-center text-sm text-gray-400 border-t pt-4">
            This ticket is closed. <button onClick={() => navigate(-1)} className="text-blue-500 hover:underline">Go back</button>
          </div>
        )}
      </div>
    </div>
  );
}
