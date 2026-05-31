'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';

const NAV = [
  { href: '/analytics', label: 'Analytics', icon: '📊' },
  { href: '/users', label: 'Users', icon: '👥' },
  { href: '/acts', label: 'Acts', icon: '🌿' },
  { href: '/categories', label: 'Categories', icon: '🏷️' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (!localStorage.getItem('auth_token')) router.replace('/login');
  }, [router]);

  async function logout() {
    localStorage.removeItem('auth_token');
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/login');
  }

  return (
    <div id="shell">
      <aside className="sidebar">
        <div className="brand">100acts</div>
        <nav>
          {NAV.map(({ href, label, icon }) => (
            <Link key={href} href={href} className={pathname === href ? 'active' : ''}>
              <span className="icon">{icon}</span> {label}
            </Link>
          ))}
        </nav>
        <button className="logout" onClick={logout}>Log out</button>
      </aside>
      <main>{children}</main>
      <style jsx>{`
        #shell { display: flex; min-height: 100vh; }
        .sidebar { width: 220px; background: #fff; border-right: 1px solid #e5e5e5; display: flex; flex-direction: column; padding: 24px 16px; gap: 4px; position: fixed; top: 0; left: 0; bottom: 0; }
        .brand { font-size: 20px; font-weight: 800; color: #22c55e; padding: 0 8px 24px; }
        nav { display: flex; flex-direction: column; gap: 4px; flex: 1; }
        nav :global(a) { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 8px; text-decoration: none; color: #555; font-size: 14px; font-weight: 500; }
        nav :global(a:hover) { background: #f5f5f5; }
        nav :global(a.active) { background: #f0fdf4; color: #16a34a; font-weight: 600; }
        .icon { font-size: 16px; }
        .logout { background: none; border: 1px solid #e5e5e5; border-radius: 8px; padding: 10px 12px; cursor: pointer; color: #dc2626; font-size: 14px; font-weight: 500; text-align: left; }
        .logout:hover { background: #fee2e2; }
        main { margin-left: 220px; flex: 1; padding: 32px; }
      `}</style>
    </div>
  );
}
