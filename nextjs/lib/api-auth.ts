import { NextRequest, NextResponse } from 'next/server';
import { verifyToken, AuthUser } from './auth';

export async function requireAuth(
  req: NextRequest,
): Promise<{ user: AuthUser } | NextResponse> {
  const auth = req.headers.get('authorization');
  if (!auth?.startsWith('Bearer ')) {
    return NextResponse.json({ error: 'Missing token' }, { status: 401 });
  }
  try {
    const user = await verifyToken(auth.slice(7));
    return { user };
  } catch {
    return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
  }
}
