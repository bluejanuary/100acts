import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';

const ACT_SELECT = {
  id: true,
  userId: true,
  category: true,
  description: true,
  photoUrl: true,
  photoUrls: true,
  lat: true,
  long: true,
  createdAt: true,
} as const;

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;

  const act = await prisma.act.findUnique({
    where: { id },
    select: ACT_SELECT,
  });

  if (!act) {
    return NextResponse.json({ error: 'Act not found' }, { status: 404 });
  }

  return NextResponse.json(act);
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;

  const existing = await prisma.act.findUnique({ where: { id }, select: { userId: true } });
  if (!existing) {
    return NextResponse.json({ error: 'Act not found' }, { status: 404 });
  }
  if (existing.userId !== auth.user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  let body: { category?: string; description?: string; photoUrls?: string[] };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }

  const { category, description, photoUrls } = body;

  if (!category || !description || !photoUrls?.length) {
    return NextResponse.json(
      { error: 'category, description, and photoUrls are required' },
      { status: 400 },
    );
  }
  if (photoUrls.length > 5) {
    return NextResponse.json({ error: 'Maximum 5 photos allowed' }, { status: 400 });
  }

  const validCategory = await prisma.category.findUnique({ where: { slug: category } });
  if (!validCategory) {
    return NextResponse.json({ error: 'Invalid category' }, { status: 400 });
  }

  const act = await prisma.act.update({
    where: { id },
    data: {
      category,
      description,
      photoUrl: photoUrls[0],
      photoUrls,
    },
    select: ACT_SELECT,
  });

  return NextResponse.json(act);
}
