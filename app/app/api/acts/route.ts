import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const acts = await prisma.act.findMany({
    where: { userId: auth.user.id },
    select: { id: true, userId: true, category: true, description: true, photoUrl: true, photoUrls: true, lat: true, long: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
  });
  return NextResponse.json(acts);
}

export async function POST(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  let body: { category?: string; description?: string; photoUrls?: string[]; lat?: number; long?: number; gpsAccuracy?: number };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  const { category, description, photoUrls, lat, long, gpsAccuracy } = body;

  if (!category || !description || !photoUrls?.length || lat == null || long == null) {
    return NextResponse.json({ error: 'category, description, photoUrls, lat, long are required' }, { status: 400 });
  }
  if (photoUrls.length > 5) {
    return NextResponse.json({ error: 'Maximum 5 photos allowed' }, { status: 400 });
  }
  if (typeof lat !== 'number' || typeof long !== 'number' || lat < -90 || lat > 90 || long < -180 || long > 180) {
    return NextResponse.json({ error: 'Invalid coordinates' }, { status: 400 });
  }

  // Validate category against DB
  const validCategory = await prisma.category.findUnique({ where: { slug: category } });
  if (!validCategory) {
    return NextResponse.json({ error: 'Invalid category' }, { status: 400 });
  }

  const act = await prisma.act.create({
    data: { userId: auth.user.id, category, description, photoUrl: photoUrls[0], photoUrls, lat, long, gpsAccuracy },
  });
  return NextResponse.json(act, { status: 201 });
}
