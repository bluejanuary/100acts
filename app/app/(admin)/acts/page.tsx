'use client';

import { useEffect, useState } from 'react';
import { getActs, type Act } from '@/lib/admin-api';
import Spinner from '@/components/Spinner';

const LABELS: Record<string, string> = {
  tree_mangrove: 'Tree / Mangrove', wildlife: 'Wildlife',
  recycling: 'Recycling', litter_cleanup: 'Litter Cleanup',
};

export default function ActsPage() {
  const [acts, setActs] = useState<Act[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    getActs().then(setActs).catch(e => setError(e.message)).finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="page-header">
        <h1>Acts</h1>
        {!loading && !error && <span className="count">{acts.length} total</span>}
      </div>

      {loading && <Spinner label="Loading acts…" />}
      {error && <p className="state error">{error}</p>}
      {!loading && !error && (
        <table>
          <thead>
            <tr><th>Photo</th><th>Category</th><th>Location</th><th>Date</th><th>User</th></tr>
          </thead>
          <tbody>
            {acts.map(act => (
              <tr key={act.id}>
                <td><img src={act.photoUrl} alt={act.category} className="thumb" /></td>
                <td><span className={`badge ${act.category}`}>{LABELS[act.category] ?? act.category}</span></td>
                <td className="mono">{act.lat.toFixed(5)}, {act.long.toFixed(5)}</td>
                <td>{new Date(act.createdAt).toLocaleString()}</td>
                <td className="mono">{act.userId?.slice(0, 8)}…</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <style jsx>{`
        .page-header { display: flex; align-items: baseline; gap: 12px; margin-bottom: 24px; }
        h1 { font-size: 24px; font-weight: 700; }
        .count { color: #888; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
        th { text-align: left; padding: 12px 16px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #888; background: #fafafa; border-bottom: 1px solid #eee; }
        td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        .thumb { width: 56px; height: 56px; object-fit: cover; border-radius: 6px; }
        .mono { font-family: monospace; font-size: 12px; color: #555; }
        .state { padding: 48px; text-align: center; color: #888; }
        .error { color: #dc2626; }
        .badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 600; }
        .badge.tree_mangrove { background: #dcfce7; color: #16a34a; }
        .badge.wildlife { background: #fef3c7; color: #d97706; }
        .badge.recycling { background: #dbeafe; color: #2563eb; }
        .badge.litter_cleanup { background: #fee2e2; color: #dc2626; }
      `}</style>
    </div>
  );
}
