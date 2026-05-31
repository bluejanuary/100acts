'use client';

import { useEffect, useState, useMemo } from 'react';
import { getUsers, createUser, deleteUser, updateUserPassword, type User } from '@/lib/admin-api';
import Spinner from '@/components/Spinner';

type SortDir = 'asc' | 'desc';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [listError, setListError] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState('');
  const [form, setForm] = useState({ email: '', password: '' });

  // Search + sort
  const [search, setSearch] = useState('');
  const [sortDir, setSortDir] = useState<SortDir>('desc');

  // Edit modal
  const [editUser, setEditUser] = useState<User | null>(null);
  const [editForm, setEditForm] = useState({ password: '', confirm: '' });
  const [editError, setEditError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => { fetchUsers(); }, []);

  async function fetchUsers() {
    try {
      setUsers(await getUsers());
    } catch (e: unknown) {
      setListError(e instanceof Error ? e.message : 'Failed to load users');
    } finally {
      setLoading(false);
    }
  }

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    const result = q
      ? users.filter(u => u.email.toLowerCase().includes(q) || u.id.toLowerCase().includes(q))
      : [...users];
    result.sort((a, b) => {
      const diff = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      return sortDir === 'asc' ? diff : -diff;
    });
    return result;
  }, [users, search, sortDir]);

  async function create(e: React.FormEvent) {
    e.preventDefault();
    setCreating(true);
    setCreateError('');
    try {
      await createUser(form);
      setForm({ email: '', password: '' });
      await fetchUsers();
    } catch (e: unknown) {
      setCreateError(e instanceof Error ? e.message : 'Failed to create user');
    } finally {
      setCreating(false);
    }
  }

  async function remove(id: string, email: string) {
    if (!confirm(`Delete user ${email}? This cannot be undone.`)) return;
    try {
      await deleteUser(id);
      setUsers(u => u.filter(x => x.id !== id));
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed to delete user');
    }
  }

  function openEdit(user: User) {
    setEditUser(user);
    setEditForm({ password: '', confirm: '' });
    setEditError('');
  }

  function closeEdit() {
    setEditUser(null);
    setEditError('');
  }

  async function savePassword(e: React.FormEvent) {
    e.preventDefault();
    if (editForm.password.length < 8) { setEditError('Password must be at least 8 characters'); return; }
    if (editForm.password !== editForm.confirm) { setEditError('Passwords do not match'); return; }
    setSaving(true);
    setEditError('');
    try {
      await updateUserPassword(editUser!.id, editForm.password);
      closeEdit();
    } catch (e: unknown) {
      setEditError(e instanceof Error ? e.message : 'Failed to update password');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <h1>Users</h1>

      <div className="panel">
        <h2>Add user</h2>
        <form onSubmit={create}>
          <div className="fields">
            <div className="field">
              <label>Email</label>
              <input value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} type="email" placeholder="user@example.com" required />
            </div>
            <div className="field">
              <label>Password</label>
              <input value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} type="password" placeholder="Min 8 characters" required minLength={8} />
            </div>
          </div>
          {createError && <p className="error">{createError}</p>}
          <button type="submit" disabled={creating}>{creating ? 'Creating...' : 'Create user'}</button>
        </form>
      </div>

      {/* Table header with search + sort */}
      <div className="table-header">
        <div className="page-header">
          <h2>All users</h2>
          <span className="count">{filtered.length} of {users.length}</span>
        </div>
        <div className="controls">
          <input
            className="search"
            type="search"
            placeholder="Search by email or ID…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          <button
            className="sort-btn"
            onClick={() => setSortDir(d => d === 'asc' ? 'desc' : 'asc')}
            title="Toggle sort order"
          >
            Joined {sortDir === 'asc' ? '↑' : '↓'}
          </button>
        </div>
      </div>

      {loading && <Spinner label="Loading users…" />}
      {listError && <p className="state error">{listError}</p>}
      {!loading && !listError && (
        <table>
          <thead>
            <tr><th>Email</th><th>Joined</th><th>Last sign in</th><th>ID</th><th></th></tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={5} className="empty">No users match your search</td></tr>
            )}
            {filtered.map(user => (
              <tr key={user.id}>
                <td className="email">{user.email}</td>
                <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                <td>{user.lastSignIn ? new Date(user.lastSignIn).toLocaleDateString() : '—'}</td>
                <td className="mono">{user.id.slice(0, 8)}…</td>
                <td className="actions">
                  <button className="edit" onClick={() => openEdit(user)}>Edit</button>
                  <button className="delete" onClick={() => remove(user.id, user.email)}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {/* Edit password modal */}
      {editUser && (
        <div className="overlay" onClick={closeEdit}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>Change password</h2>
            <p className="modal-email">{editUser.email}</p>
            <form onSubmit={savePassword}>
              <div className="field">
                <label>New password</label>
                <input type="password" placeholder="Min 8 characters" value={editForm.password} onChange={e => setEditForm(f => ({ ...f, password: e.target.value }))} required minLength={8} autoFocus />
              </div>
              <div className="field" style={{ marginTop: 12 }}>
                <label>Confirm password</label>
                <input type="password" placeholder="Retype password" value={editForm.confirm} onChange={e => setEditForm(f => ({ ...f, confirm: e.target.value }))} required />
              </div>
              {editError && <p className="error">{editError}</p>}
              <div className="modal-actions">
                <button type="button" className="cancel" onClick={closeEdit}>Cancel</button>
                <button type="submit" disabled={saving}>{saving ? 'Saving...' : 'Save password'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style jsx>{`
        h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
        h2 { font-size: 16px; font-weight: 700; margin-bottom: 0; }
        .panel { background: #fff; border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin-bottom: 28px; }
        .fields { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; }
        .field { display: flex; flex-direction: column; gap: 6px; flex: 1; min-width: 200px; }
        label { font-size: 12px; font-weight: 600; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }
        input { padding: 10px 12px; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 14px; outline: none; width: 100%; box-sizing: border-box; }
        input:focus { border-color: #22c55e; }
        button { padding: 10px 20px; background: #22c55e; color: #fff; border: none; border-radius: 8px; font-size: 14px; font-weight: 700; cursor: pointer; }
        button:disabled { opacity: 0.6; cursor: not-allowed; }
        .error { color: #dc2626; font-size: 13px; margin: 8px 0; }
        /* Table toolbar */
        .table-header { display: flex; align-items: center; justify-content: space-between; margin: 28px 0 16px; flex-wrap: wrap; gap: 12px; }
        .page-header { display: flex; align-items: baseline; gap: 12px; }
        .count { color: #888; font-size: 14px; }
        .controls { display: flex; align-items: center; gap: 10px; }
        .search { width: 240px; padding: 8px 12px; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 14px; outline: none; }
        .search:focus { border-color: #22c55e; }
        .sort-btn { padding: 8px 14px; background: #fff; color: #555; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; white-space: nowrap; }
        .sort-btn:hover { background: #f5f5f5; }
        /* Table */
        table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
        th { text-align: left; padding: 12px 16px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #888; background: #fafafa; border-bottom: 1px solid #eee; }
        td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        .email { font-weight: 500; }
        .mono { font-family: monospace; font-size: 12px; color: #999; }
        .actions { display: flex; gap: 8px; }
        .edit { padding: 5px 12px; background: #fff; color: #2563eb; border: 1px solid #2563eb; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; }
        .edit:hover { background: #eff6ff; }
        .delete { padding: 5px 12px; background: #fff; color: #dc2626; border: 1px solid #dc2626; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; }
        .delete:hover { background: #fee2e2; }
        .empty { text-align: center; color: #aaa; padding: 32px; }
        .state { padding: 48px; text-align: center; color: #888; }
        /* Modal */
        .overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; z-index: 50; }
        .modal { background: #fff; border-radius: 14px; padding: 28px; width: 100%; max-width: 420px; box-shadow: 0 8px 32px rgba(0,0,0,0.18); }
        .modal h2 { margin-bottom: 4px; }
        .modal-email { color: #888; font-size: 13px; margin-bottom: 20px; }
        .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }
        .cancel { background: #fff; color: #555; border: 1.5px solid #e5e5e5; }
        .cancel:hover { background: #f5f5f5; }
      `}</style>
    </div>
  );
}
