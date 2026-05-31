import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';
import { ActCategory } from '@prisma/client';

const VALID_CATEGORIES = new Set(Object.values(ActCategory));

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const acts = await prisma.act.findMany({
    select: { id: true, userId: true, category: true, photoUrl: true, lat: true, long: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
  });
  return NextResponse.json(acts);
}

export async function POST(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const body = await req.json();
  const { category, photoUrl, lat, long, gpsAccuracy } = body;

  if (!category || !photoUrl || lat == null || long == null) {
    return NextResponse.json({ error: 'category, photoUrl, lat, long are required' }, { status: 400 });
  }
  if (!VALID_CATEGORIES.has(category)) {
    return NextResponse.json({ error: 'Invalid category' }, { status: 400 });
  }
  if (lat < -90 || lat > 90 || long < -180 || long > 180) {
    return NextResponse.json({ error: 'Invalid coordinates' }, { status: 400 });
  }

  const act = await prisma.act.create({
    data: { userId: auth.user.id, category, photoUrl, lat, long, gpsAccuracy },
  });
  return NextResponse.json(act, { status: 201 });
}
