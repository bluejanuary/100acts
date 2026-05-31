'use client';

import { useEffect, useState } from 'react';
import { getAnalytics, type Analytics } from '@/lib/admin-api';

const LABELS: Record<string, string> = {
  tree_mangrove: 'Tree / Mangrove', wildlife: 'Wildlife',
  recycling: 'Recycling', litter_cleanup: 'Litter Cleanup',
};
const BAR_COLORS: Record<string, string> = {
  tree_mangrove: '#16a34a', wildlife: '#d97706',
  recycling: '#2563eb', litter_cleanup: '#dc2626',
};
const STAT_CARDS = [
  { key: 'totalActs', label: 'Total Acts', color: '#22c55e' },
  { key: 'totalUsers', label: 'Total Users', color: '#3b82f6' },
  { key: 'actsToday', label: 'Acts Today', color: '#14b8a6' },
  { key: 'actsThisWeek', label: 'This Week', color: '#8b5cf6' },
  { key: 'actsThisMonth', label: 'This Month', color: '#f97316' },
] as const;

export default function AnalyticsPage() {
  const [data, setData] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    getAnalytics().then(setData).catch(e => setError(e.message)).finally(() => setLoading(false));
  }, []);

  if (loading) return <p className="state">Loading...</p>;
  if (error) return <p className="state error">{error}</p>;
  if (!data) return null;

  const maxCount = Math.max(...data.byCategory.map(c => c.count), 1);

  return (
    <div>
      <h1>Analytics</h1>

      <h2>Platform</h2>
      <div className="stats">
        {STAT_CARDS.map(({ key, label, color }) => (
          <div key={key} className="stat-card" style={{ borderTopColor: color }}>
            <span className="stat-value">{data[key]}</span>
            <span className="stat-label">{label}</span>
          </div>
        ))}
      </div>

      <h2>Acts by category</h2>
      <div className="categories">
        {data.byCategory.length === 0 && <p className="empty">No acts recorded yet</p>}
        {data.byCategory.map(item => (
          <div key={item.category} className="cat-row">
            <div className="cat-info">
              <span className={`badge ${item.category}`}>{LABELS[item.category] ?? item.category}</span>
              <span className="cat-count">{item.count} acts</span>
            </div>
            <div className="bar-wrap">
              <div className="bar" style={{ width: `${Math.round((item.count / maxCount) * 100)}%`, background: BAR_COLORS[item.category] ?? '#22c55e' }} />
            </div>
          </div>
        ))}
      </div>

      <style jsx>{`
        h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
        h2 { font-size: 14px; font-weight: 600; color: #888; text-transform: uppercase; letter-spacing: 0.5px; margin: 28px 0 14px; }
        .state { padding: 48px; text-align: center; color: #888; }
        .error { color: #dc2626; }
        .stats { display: flex; flex-wrap: wrap; gap: 14px; }
        .stat-card { background: #fff; border-radius: 12px; padding: 24px 28px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); display: flex; flex-direction: column; gap: 6px; min-width: 140px; border-top: 3px solid transparent; }
        .stat-value { font-size: 36px; font-weight: 800; color: #1a1a1a; }
        .stat-label { font-size: 12px; color: #888; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
        .categories { background: #fff; border-radius: 12px; padding: 20px 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); display: flex; flex-direction: column; gap: 16px; }
        .cat-row { display: flex; flex-direction: column; gap: 8px; }
        .cat-info { display: flex; align-items: center; justify-content: space-between; }
        .cat-count { font-size: 13px; font-weight: 600; color: #555; }
        .bar-wrap { height: 8px; background: #f0f0f0; border-radius: 99px; overflow: hidden; }
        .bar { height: 100%; border-radius: 99px; transition: width 0.4s ease; }
        .badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 600; }
        .badge.tree_mangrove { background: #dcfce7; color: #16a34a; }
        .badge.wildlife { background: #fef3c7; color: #d97706; }
        .badge.recycling { background: #dbeafe; color: #2563eb; }
        .badge.litter_cleanup { background: #fee2e2; color: #dc2626; }
        .empty { color: #aaa; text-align: center; padding: 16px; }
      `}</style>
    </div>
  );
}
