'use client';

import { useEffect, useState } from 'react';
import { getCategories, createCategory, type Category } from '@/lib/admin-api';

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [listError, setListError] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState('');
  const [form, setForm] = useState({ name: '', slug: '', description: '' });

  useEffect(() => { fetchCategories(); }, []);

  async function fetchCategories() {
    try {
      setCategories(await getCategories());
    } catch (e: unknown) {
      setListError(e instanceof Error ? e.message : 'Failed to load categories');
    } finally {
      setLoading(false);
    }
  }

  async function create(e: React.FormEvent) {
    e.preventDefault();
    setCreating(true);
    setCreateError('');
    try {
      await createCategory(form);
      setForm({ name: '', slug: '', description: '' });
      await fetchCategories();
    } catch (e: unknown) {
      setCreateError(e instanceof Error ? e.message : 'Failed to create category');
    } finally {
      setCreating(false);
    }
  }

  return (
    <div>
      <h1>Categories</h1>

      <div className="panel">
        <h2>Create category</h2>
        <form onSubmit={create}>
          <div className="fields">
            <div className="field">
              <label>Name</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="e.g. Ocean Cleanup" required />
            </div>
            <div className="field">
              <label>Slug</label>
              <input value={form.slug} onChange={e => setForm(f => ({ ...f, slug: e.target.value }))} placeholder="e.g. ocean_cleanup" required />
            </div>
            <div className="field full">
              <label>Description</label>
              <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} placeholder="Short description (optional)" />
            </div>
          </div>
          {createError && <p className="error">{createError}</p>}
          <button type="submit" disabled={creating}>{creating ? 'Creating...' : 'Create category'}</button>
        </form>
      </div>

      <div className="page-header"><h2>Existing categories</h2></div>

      {loading && <p className="state">Loading...</p>}
      {listError && <p className="state error">{listError}</p>}
      {!loading && !listError && (
        <table>
          <thead>
            <tr><th>Name</th><th>Slug</th><th>Description</th><th>Created</th></tr>
          </thead>
          <tbody>
            {categories.length === 0 && (
              <tr><td colSpan={4} className="empty">No categories yet</td></tr>
            )}
            {categories.map(cat => (
              <tr key={cat.id}>
                <td className="bold">{cat.name}</td>
                <td className="mono">{cat.slug}</td>
                <td>{cat.description ?? '—'}</td>
                <td>{new Date(cat.createdAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <style jsx>{`
        h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
        h2 { font-size: 16px; font-weight: 700; margin-bottom: 16px; }
        .page-header { margin: 28px 0 16px; }
        .panel { background: #fff; border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin-bottom: 28px; }
        .fields { display: flex; flex-wrap: wrap; gap: 14px; margin-bottom: 16px; }
        .field { display: flex; flex-direction: column; gap: 6px; flex: 1; min-width: 180px; }
        .field.full { flex-basis: 100%; }
        label { font-size: 12px; font-weight: 600; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }
        input { padding: 10px 12px; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 14px; outline: none; }
        input:focus { border-color: #22c55e; }
        button { padding: 10px 20px; background: #22c55e; color: #fff; border: none; border-radius: 8px; font-size: 14px; font-weight: 700; cursor: pointer; }
        button:disabled { opacity: 0.6; cursor: not-allowed; }
        .error { color: #dc2626; font-size: 13px; margin-bottom: 12px; }
        table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
        th { text-align: left; padding: 12px 16px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #888; background: #fafafa; border-bottom: 1px solid #eee; }
        td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; }
        tr:last-child td { border-bottom: none; }
        .bold { font-weight: 600; }
        .mono { font-family: monospace; font-size: 12px; color: #555; }
        .empty { text-align: center; color: #aaa; padding: 32px; }
        .state { padding: 48px; text-align: center; color: #888; }
      `}</style>
    </div>
  );
}
