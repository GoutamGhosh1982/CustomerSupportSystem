import api from './axios';
import type { User } from '../types';

export const userApi = {
  getAll:     ()              => api.get<User[]>('/users').then(r => r.data),
  getById:    (id: string)    => api.get<User>(`/users/${id}`).then(r => r.data),
  updateRole: (id: string, role: string) => api.patch(`/users/${id}/role`, { role }).then(r => r.data),
  deactivate: (id: string)    => api.patch(`/users/${id}/deactivate`).then(r => r.data),
};
