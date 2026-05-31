import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';
import { supabase } from '@/lib/supabase';

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  try {
    const [total, today, week, month, byCategory, usersRes] = await Promise.all([
      prisma.act.count(),
      prisma.act.count({ where: { createdAt: { gte: startOfToday } } }),
      prisma.act.count({ where: { createdAt: { gte: startOfWeek } } }),
      prisma.act.count({ where: { createdAt: { gte: startOfMonth } } }),
      prisma.act.groupBy({ by: ['category'], _count: { id: true } }),
      supabase.auth.admin.listUsers(),
    ]);

    return NextResponse.json({
      totalActs: total,
      actsToday: today,
      actsThisWeek: week,
      actsThisMonth: month,
      totalUsers: usersRes.data?.users.length ?? 0,
      byCategory: byCategory.map(row => ({ category: row.category, count: row._count.id })),
    });
  } catch {
    return NextResponse.json({ error: 'Failed to load analytics' }, { status: 500 });
  }
}
