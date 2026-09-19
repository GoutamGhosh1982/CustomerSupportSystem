import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ticketApi } from '../api/tickets';
import type { CreateTicketRequest, UpdateStatusRequest, AssignTicketRequest, TicketFilters } from '../types';

export const useTickets = (filters: TicketFilters) =>
  useQuery({
    queryKey: ['tickets', filters],
    queryFn:  () => ticketApi.getAll(filters),
  });

export const useMyTickets = () =>
  useQuery({
    queryKey: ['my-tickets'],
    queryFn:  ticketApi.getMyTickets,
  });

export const useTicket = (id: string) =>
  useQuery({
    queryKey: ['ticket', id],
    queryFn:  () => ticketApi.getById(id),
    enabled:  !!id,
  });

export const useCreateTicket = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateTicketRequest) => ticketApi.create(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['my-tickets'] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    },
  });
};

export const useUpdateTicketStatus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateStatusRequest }) =>
      ticketApi.updateStatus(id, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    },
  });
};

export const useAssignTicket = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: AssignTicketRequest }) =>
      ticketApi.assign(id, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    },
  });
};
