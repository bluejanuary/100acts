import { NextRequest, NextResponse } from 'next/server';
import { supabaseAuth } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  let refreshToken: string;
  try {
    ({ refreshToken } = await req.json());
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  if (!refreshToken) return NextResponse.json({ error: 'refreshToken required' }, { status: 400 });

  const { data, error } = await supabaseAuth.auth.refreshSession({ refresh_token: refreshToken });
  if (error || !data.session) {
    return NextResponse.json({ error: 'Refresh failed' }, { status: 401 });
  }

  return NextResponse.json({
    token: data.session.access_token,
    refreshToken: data.session.refresh_token,
  });
}
