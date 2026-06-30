import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(req.url);
  const swLat = parseFloat(searchParams.get('swLat') ?? '');
  const swLng = parseFloat(searchParams.get('swLng') ?? '');
  const neLat = parseFloat(searchParams.get('neLat') ?? '');
  const neLng = parseFloat(searchParams.get('neLng') ?? '');

  if ([swLat, swLng, neLat, neLng].some(isNaN)) {
    return NextResponse.json(
      { error: 'swLat, swLng, neLat, neLng query params are required' },
      { status: 400 },
    );
  }

  const acts = await prisma.act.findMany({
    where: {
      lat: { gte: swLat, lte: neLat },
      long: { gte: swLng, lte: neLng },
    },
    select: { id: true, lat: true, long: true, category: true },
    orderBy: { createdAt: 'desc' },
  });

  return NextResponse.json(acts);
}
