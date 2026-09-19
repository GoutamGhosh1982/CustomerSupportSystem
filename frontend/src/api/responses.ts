import api from './axios';
import type { Response } from '../types';

export const responseApi = {
  getByTicket: (ticketId: string)                      => api.get<Response[]>(`/responses/${ticketId}`).then(r => r.data),
  add:         (data: { ticketId: string; body: string; isInternal?: boolean }) =>
                 api.post<Response>('/responses', data).then(r => r.data),
  addAttachment: (responseId: string, file: File) => {
    const form = new FormData();
    form.append('file', file);
    return api.post(`/responses/${responseId}/attachments`, form, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }).then(r => r.data);
  }
};
