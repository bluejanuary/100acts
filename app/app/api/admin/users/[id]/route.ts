import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabase } from '@/lib/supabase';

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const { error } = await supabase.auth.admin.deleteUser(id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  return new NextResponse(null, { status: 204 });
}

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  let body: { password?: string; role?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }

  const { id } = await params;

  if (body.password !== undefined) {
    if (body.password.length < 8) {
      return NextResponse.json({ error: 'Password must be at least 8 characters' }, { status: 400 });
    }
    const { error } = await supabase.auth.admin.updateUserById(id, { password: body.password });
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  }

  if (body.role !== undefined) {
    if (body.role !== 'admin' && body.role !== 'user') {
      return NextResponse.json({ error: 'Role must be admin or user' }, { status: 400 });
    }
    const { error } = await supabase.auth.admin.updateUserById(id, {
      app_metadata: { role: body.role },
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ success: true });
}
