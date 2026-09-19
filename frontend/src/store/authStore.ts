import { create } from 'zustand';
import type { User } from '../types';

interface AuthState {
  user:     User | null;
  setUser:  (user: User | null) => void;
  logout:   () => void;
  isAuthenticated: boolean;
}

const storedUser = localStorage.getItem('user');

export const useAuthStore = create<AuthState>((set) => ({
  user:            storedUser ? JSON.parse(storedUser) : null,
  isAuthenticated: !!storedUser,

  setUser: (user) => {
    if (user) {
      localStorage.setItem('user',  JSON.stringify(user));
      localStorage.setItem('token', user.token);
    }
    set({ user, isAuthenticated: !!user });
  },

  logout: () => {
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    set({ user: null, isAuthenticated: false });
  },
}));
