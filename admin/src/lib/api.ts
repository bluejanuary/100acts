const API_URL = import.meta.env.VITE_API_URL as string;

function authHeaders() {
  const token = localStorage.getItem('auth_token');
  if (!token) throw new Error('Not authenticated');
  return { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
}

async function request(path: string, options: RequestInit = {}) {
  const res = await fetch(`${API_URL}${path}`, options);
  if (res.status === 401) {
    localStorage.removeItem('auth_token');
    window.location.href = '/login';
    throw new Error('Session expired');
  }
  const body = await res.json();
  if (!res.ok) throw new Error(body.error ?? 'Request failed');
  return body;
}

export async function login(email: string, password: string) {
  const data = await request('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  localStorage.setItem('auth_token', data.token);
  return data;
}

export function getActs() {
  return request('/acts', { headers: authHeaders() });
}

export function getUsers() {
  return request('/admin/users', { headers: authHeaders() });
}

export function createUser(body: { email: string; password: string }) {
  return request('/admin/users', {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify(body),
  });
}

export function deleteUser(id: string) {
  return request(`/admin/users/${id}`, {
    method: 'DELETE',
    headers: authHeaders(),
  });
}

export function getAnalytics() {
  return request('/admin/analytics', { headers: authHeaders() });
}

export function getCategories() {
  return request('/admin/categories', { headers: authHeaders() });
}

export function createCategory(body: { name: string; slug: string; description?: string }) {
  return request('/admin/categories', {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify(body),
  });
}
