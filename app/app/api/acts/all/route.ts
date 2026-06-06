import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const acts = await prisma.act.findMany({
    select: { id: true, userId: true, category: true, description: true, photoUrl: true, photoUrls: true, lat: true, long: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
  });
  return NextResponse.json(acts);
}
