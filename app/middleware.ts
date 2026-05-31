import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const session = request.cookies.get('session');
  const isLogin = pathname === '/login';

  if (!session && !isLogin) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  if (session && isLogin) {
    return NextResponse.redirect(new URL('/analytics', request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
