import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import toast from 'react-hot-toast';
import { useCreateTicket } from '../../hooks/useTickets';

const CATEGORIES = ['Authentication', 'Billing', 'Technical Support', 'Account', 'Feature Request', 'Other'];
const PRIORITIES = ['Low', 'Medium', 'High', 'Critical'] as const;

const schema = z.object({
  title:       z.string().min(5, 'Title must be at least 5 characters'),
  description: z.string().min(20, 'Please describe the issue in at least 20 characters'),
  category:    z.string().min(1, 'Please select a category'),
  priority:    z.enum(['Low', 'Medium', 'High', 'Critical']),
});
type FormData = z.infer<typeof schema>;

export default function SubmitTicketPage() {
  const navigate     = useNavigate();
  const createTicket = useCreateTicket();

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { priority: 'Medium' }
  });

  const onSubmit = async (data: FormData) => {
    try {
      const ticket = await createTicket.mutateAsync(data);
      toast.success(`Ticket ${ticket.ticketNumber} created successfully!`);
      navigate(`/tickets/${ticket.id}`);
    } catch {
      toast.error('Failed to create ticket. Please try again.');
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Submit a Support Ticket</h1>
        <p className="text-gray-500 text-sm mt-1">Describe your issue and we'll get back to you as soon as possible.</p>
      </div>

      <div className="card">
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          <div>
            <label className="label">Title <span className="text-red-500">*</span></label>
            <input {...register('title')} className="input" placeholder="Brief summary of your issue" />
            {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Category <span className="text-red-500">*</span></label>
              <select {...register('category')} className="input">
                <option value="">Select a category…</option>
                {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
              {errors.category && <p className="text-red-500 text-xs mt-1">{errors.category.message}</p>}
            </div>
            <div>
              <label className="label">Priority</label>
              <select {...register('priority')} className="input">
                {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="label">Description <span className="text-red-500">*</span></label>
            <textarea
              {...register('description')}
              className="input"
              rows={6}
              placeholder="Please describe your issue in detail…"
            />
            {errors.description && <p className="text-red-500 text-xs mt-1">{errors.description.message}</p>}
          </div>

          <div className="flex gap-3 justify-end">
            <button type="button" onClick={() => navigate(-1)} className="btn-secondary">Cancel</button>
            <button type="submit" disabled={createTicket.isPending} className="btn-primary">
              {createTicket.isPending ? 'Submitting…' : 'Submit Ticket'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
