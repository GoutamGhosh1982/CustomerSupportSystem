import api from './axios';
import type { User } from '../types';

interface LoginRequest    { email: string; password: string; }
interface RegisterRequest { fullName: string; email: string; password: string; role?: string; }

export const authApi = {
  login:    (data: LoginRequest)    => api.post<User>('/auth/login', data).then(r => r.data),
  register: (data: RegisterRequest) => api.post<User>('/auth/register', data).then(r => r.data),
};
