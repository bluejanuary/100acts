import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET(_req: NextRequest) {
  try {
    const categories = await prisma.category.findMany({
      select: { id: true, name: true, slug: true },
      orderBy: { createdAt: 'asc' },
    });
    return NextResponse.json({ categories });
  } catch {
    return NextResponse.json({ error: 'Failed to load config' }, { status: 500 });
  }
}
