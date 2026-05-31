'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login } from '@/lib/admin-api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await login(email, password);
      router.push('/analytics');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f5f5f5' }}>
      <div className="card">
        <h1>100acts Admin</h1>
        <p className="sub">Sign in to continue</p>
        <form onSubmit={submit}>
          <input value={email} onChange={e => setEmail(e.target.value)} type="email" placeholder="Email" required />
          <input value={password} onChange={e => setPassword(e.target.value)} type="password" placeholder="Password" required />
          {error && <p className="error">{error}</p>}
          <button type="submit" disabled={loading}>{loading ? 'Signing in...' : 'Sign in'}</button>
        </form>
      </div>
      <style jsx>{`
        .card { background: #fff; padding: 40px; border-radius: 16px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); width: 100%; max-width: 380px; }
        h1 { font-size: 24px; font-weight: 800; color: #22c55e; margin-bottom: 4px; }
        .sub { color: #888; font-size: 14px; margin-bottom: 28px; }
        form { display: flex; flex-direction: column; gap: 14px; }
        input { padding: 12px 14px; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 15px; outline: none; }
        input:focus { border-color: #22c55e; }
        button { padding: 13px; background: #22c55e; color: #fff; border: none; border-radius: 8px; font-size: 15px; font-weight: 700; cursor: pointer; }
        button:disabled { opacity: 0.6; cursor: not-allowed; }
        .error { color: #dc2626; font-size: 13px; }
      `}</style>
    </div>
  );
}
