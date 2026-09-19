import api from './axios';
import type {
  Ticket, CreateTicketRequest, UpdateStatusRequest,
  AssignTicketRequest, PagedResult, TicketFilters
} from '../types';

export const ticketApi = {
  create:       (data: CreateTicketRequest)          => api.post<Ticket>('/tickets', data).then(r => r.data),
  getAll:       (filters: TicketFilters)             => api.get<PagedResult<Ticket>>('/tickets', { params: filters }).then(r => r.data),
  getById:      (id: string)                         => api.get<Ticket>(`/tickets/${id}`).then(r => r.data),
  getMyTickets: ()                                   => api.get<Ticket[]>('/tickets/my').then(r => r.data),
  updateStatus: (id: string, data: UpdateStatusRequest) => api.patch<Ticket>(`/tickets/${id}/status`, data).then(r => r.data),
  assign:       (id: string, data: AssignTicketRequest) => api.patch<Ticket>(`/tickets/${id}/assign`, data).then(r => r.data),
};
