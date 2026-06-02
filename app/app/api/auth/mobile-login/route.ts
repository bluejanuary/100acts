import { NextRequest, NextResponse } from 'next/server';
import { supabaseAuth } from '@/lib/supabase';

// Mobile login — no admin role required
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

  return NextResponse.json({
    token: data.session.access_token,
    refreshToken: data.session.refresh_token,
    user: { id: data.user.id, email: data.user.email },
  });
}
