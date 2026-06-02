import { NextRequest, NextResponse } from 'next/server';
import { supabase, supabaseAuth } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  let email: string, password: string;
  try {
    ({ email, password } = await req.json());
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  if (!email || !password) {
    return NextResponse.json({ error: 'email and password required' }, { status: 400 });
  }

  const { data, error } = await supabaseAuth.auth.signInWithPassword({ email, password });
  if (error || !data.session) {
    return NextResponse.json({ error: error?.message ?? 'Login failed' }, { status: 401 });
  }

  // Only admin users can access the portal
  const { data: userData } = await supabase.auth.admin.getUserById(data.user.id);
  if (userData?.user?.app_metadata?.role !== 'admin') {
    return NextResponse.json({ error: 'Access denied' }, { status: 403 });
  }

  const res = NextResponse.json({
    token: data.session.access_token,
    refreshToken: data.session.refresh_token,
    user: { id: data.user.id, email: data.user.email },
  });

  res.cookies.set('session', data.session.access_token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7,
    path: '/',
  });

  return res;
}
