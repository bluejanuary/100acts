import { NextRequest, NextResponse } from 'next/server';
import { supabaseAuth } from '@/lib/supabase';

// Open endpoint for mobile app user registration
export async function POST(req: NextRequest) {
  let email: string, password: string;
  try {
    ({ email, password } = await req.json());
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  if (!email || !password || password.length < 8) {
    return NextResponse.json({ error: 'Valid email and password (min 8 chars) required' }, { status: 400 });
  }

  const { data, error } = await supabaseAuth.auth.signUp({ email, password });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  return NextResponse.json({ id: data.user?.id, email: data.user?.email }, { status: 201 });
}
