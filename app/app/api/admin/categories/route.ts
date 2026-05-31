import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { prisma } from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const categories = await prisma.category.findMany({ orderBy: { createdAt: 'desc' } });
  return NextResponse.json(categories);
}

export async function POST(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  let name: string, slug: string, description: string | undefined;
  try {
    ({ name, slug, description } = await req.json());
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  if (!name || !slug) return NextResponse.json({ error: 'name and slug required' }, { status: 400 });

  const category = await prisma.category.create({ data: { name, slug, description } });
  return NextResponse.json(category, { status: 201 });
}
