import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { createPresignedUploadUrl } from '@/lib/s3';

const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

export async function POST(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  let filename: string, contentType: string;
  try {
    ({ filename, contentType } = await req.json());
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
  if (!filename || !contentType) {
    return NextResponse.json({ error: 'filename and contentType required' }, { status: 400 });
  }
  if (!ALLOWED_TYPES.has(contentType)) {
    return NextResponse.json({ error: 'Invalid content type' }, { status: 400 });
  }

  const key = `acts/${auth.user.id}/${Date.now()}-${filename}`;
  const { uploadUrl, publicUrl } = await createPresignedUploadUrl(key, contentType);
  return NextResponse.json({ uploadUrl, publicUrl });
}
