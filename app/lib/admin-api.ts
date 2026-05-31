function authHeaders(): Record<string, string> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;
  if (!token) throw new Error('Not authenticated');
  return { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
}

async function request<T = unknown>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(path, options);
  if (res.status === 401) {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token');
      // Clear the session cookie so middleware doesn't redirect back after /login
      await fetch('/api/auth/logout', { method: 'POST' }).catch(() => {});
      window.location.href = '/login';
    }
    throw new Error('Session expired');
  }
  if (res.status === 204) return null as T;
  const body = await res.json();
  if (!res.ok) throw new Error(body.error ?? 'Request failed');
  return body as T;
}

export async function login(email: string, password: string) {
  const data = await request<{ token: string; refreshToken: string; user: { id: string; email: string } }>(
    '/api/auth/login',
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) },
  );
  localStorage.setItem('auth_token', data.token);
  return data;
}

export function getActs() {
  return request<Act[]>('/api/acts', { headers: authHeaders() });
}

export function getUsers() {
  return request<User[]>('/api/admin/users', { headers: authHeaders() });
}

export function createUser(body: { email: string; password: string }) {
  return request('/api/admin/users', {
    method: 'POST', headers: authHeaders(), body: JSON.stringify(body),
  });
}

export function deleteUser(id: string) {
  return request(`/api/admin/users/${id}`, { method: 'DELETE', headers: authHeaders() });
}

export function updateUserPassword(id: string, password: string) {
  return request(`/api/admin/users/${id}`, {
    method: 'PATCH', headers: authHeaders(), body: JSON.stringify({ password }),
  });
}

export function getAnalytics() {
  return request<Analytics>('/api/admin/analytics', { headers: authHeaders() });
}

export function getCategories() {
  return request<Category[]>('/api/admin/categories', { headers: authHeaders() });
}

export function createCategory(body: { name: string; slug: string; description?: string }) {
  return request('/api/admin/categories', {
    method: 'POST', headers: authHeaders(), body: JSON.stringify(body),
  });
}

export type Act = {
  id: string; userId: string; category: string;
  photoUrl: string; lat: number; long: number; createdAt: string;
};

export type User = {
  id: string; email: string; createdAt: string; lastSignIn: string | null;
};

export type Analytics = {
  totalActs: number; totalUsers: number; actsToday: number;
  actsThisWeek: number; actsThisMonth: number;
  byCategory: { category: string; count: number }[];
};

export type Category = {
  id: string; name: string; slug: string; description: string | null; createdAt: string;
};
