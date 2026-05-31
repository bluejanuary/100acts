# Next.js Migration

## Overview

The `api/` (Fastify) and `admin/` (Vue 3) services have been consolidated into a single Next.js 15 application located at `nextjs/`. Flutter mobile is unchanged.

---

## What Changed

| Before | After |
|---|---|
| `api/` — Fastify REST API on port 3100 | `nextjs/` — Next.js app on port 3100 |
| `admin/` — Vue 3 SPA on port 5173 | Admin UI built into Next.js (same origin as API) |
| 2 deployments, 2 processes | 1 deployment, 1 process |
| CORS required between admin and API | No CORS needed (same origin) |

Flutter mobile points to the same `API_URL` as before — no changes required.

---

## Directory Structure

```
nextjs/
├── prisma/
│   └── schema.prisma           # Same schema as api/prisma/
├── lib/
│   ├── auth.ts                 # JWT verification via Supabase
│   ├── prisma.ts               # PrismaClient singleton
│   ├── s3.ts                   # S3 presigned URL helper
│   ├── supabase.ts             # Supabase admin client
│   ├── api-auth.ts             # requireAuth() helper for route handlers
│   └── admin-api.ts            # Client-side fetch helpers for admin pages
├── app/
│   ├── layout.tsx              # Root HTML layout
│   ├── page.tsx                # Redirects / → /analytics
│   ├── globals.css
│   ├── login/
│   │   └── page.tsx            # Login page (public)
│   ├── (admin)/                # Route group — admin shell layout
│   │   ├── layout.tsx          # Sidebar + auth guard
│   │   ├── analytics/page.tsx
│   │   ├── acts/page.tsx
│   │   ├── users/page.tsx
│   │   └── categories/page.tsx
│   └── api/                    # REST API — same endpoints as Fastify
│       ├── health/route.ts
│       ├── auth/
│       │   ├── login/route.ts
│       │   ├── logout/route.ts
│       │   ├── signup/route.ts
│       │   ├── me/route.ts
│       │   └── refresh/route.ts
│       ├── config/route.ts
│       ├── acts/route.ts
│       ├── uploads/presign/route.ts
│       └── admin/
│           ├── users/route.ts
│           ├── users/[id]/route.ts
│           ├── categories/route.ts
│           └── analytics/route.ts
├── middleware.ts               # Protects admin routes via session cookie
├── next.config.ts
├── package.json
└── tsconfig.json
```

---

## API Endpoints

All endpoints are identical to the original Fastify API. No changes needed in Flutter.

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | — | Health check |
| POST | `/api/auth/signup` | — | Create user account |
| POST | `/api/auth/login` | — | Login, returns JWT + sets session cookie |
| POST | `/api/auth/logout` | — | Clears session cookie |
| GET | `/api/auth/me` | Bearer | Get current user |
| POST | `/api/auth/refresh` | — | Refresh access token |
| GET | `/api/config` | Bearer | System config (categories) for mobile |
| GET | `/api/acts` | Bearer | List all acts |
| POST | `/api/acts` | Bearer | Create act |
| POST | `/api/uploads/presign` | Bearer | Get S3 presigned upload URL |
| GET | `/api/admin/users` | Bearer | List users |
| POST | `/api/admin/users` | Bearer | Create user |
| DELETE | `/api/admin/users/:id` | Bearer | Delete user |
| GET | `/api/admin/analytics` | Bearer | Platform analytics |
| GET | `/api/admin/categories` | Bearer | List categories |
| POST | `/api/admin/categories` | Bearer | Create category |

---

## Auth Flow

### Mobile (Flutter)
Unchanged. Login returns a Bearer token stored in `flutter_secure_storage`. All requests include `Authorization: Bearer <token>`. Token refresh is handled automatically on 401.

### Admin (browser)
1. User submits the login form at `/login`
2. `POST /api/auth/login` verifies credentials via Supabase
3. Server sets an `httpOnly` session cookie and returns the token in the response body
4. Client stores the token in `localStorage` for use as a Bearer header on API calls
5. Next.js middleware reads the session cookie on every request — redirects unauthenticated users to `/login`
6. On logout, `POST /api/auth/logout` clears the session cookie and `localStorage` is cleared client-side
7. On any 401 API response, the client calls `/api/auth/logout` to clear the cookie, then redirects to `/login`

---

## Bugs Fixed During Migration

Five bugs were identified and fixed during the migration:

**1. Redirect loop on token expiry**
When an API call returned 401, the original code cleared `localStorage` and redirected to `/login`. But the `session` cookie remained set, causing middleware to redirect back to `/analytics` — an infinite loop. Fix: call `POST /api/auth/logout` to clear the cookie before redirecting.

**2. Prisma connection exhaustion in production**
The Prisma singleton was only cached in `globalThis` during development. In production serverless environments, warm containers reuse the same process, meaning every request created a new `PrismaClient` and burned through the database connection pool. Fix: always cache in `globalThis` regardless of environment.

**3. Admin shell flash on unauthenticated load**
The `useEffect` auth check in the admin layout ran after the first render, causing a brief flash of the full sidebar for unauthenticated users before the redirect fired. Fix: added a `ready` state — the layout renders `null` until the localStorage check completes.

**4. Malformed JSON crashes on POST routes**
All POST route handlers called `await req.json()` without a try/catch. A request with an empty or malformed body threw an unhandled exception, returning a 500 with a stack trace. Fix: wrapped `req.json()` in try/catch on all 7 POST routes, returning a clean 400 instead.

**5. Unhandled database errors in analytics route**
The analytics handler used `Promise.all` across 6 concurrent database and Supabase queries with no error handling. Any single failure caused an unhandled rejection. Fix: wrapped the entire block in try/catch, returning `{ error: 'Failed to load analytics' }` with status 500.

---

## Running Locally

```bash
# From the repo root
yarn install

# One-time: generate Prisma client
cd nextjs && npx prisma generate && cd ..

# Copy and fill in environment variables
cp nextjs/.env.example nextjs/.env

# Start the app (from root)
yarn nextjs
```

The app runs on `http://localhost:3100`.

---

## Environment Variables

All variables are server-side only (no `NEXT_PUBLIC_` needed — the admin UI and API share the same origin).

| Variable | Description |
|---|---|
| `DATABASE_URL` | Supabase Postgres connection string (pooled, port 6543) |
| `DIRECT_URL` | Supabase Postgres direct connection (port 5432, for migrations) |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-side only) |
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret |
| `AWS_REGION` | S3 bucket region |
| `S3_BUCKET_NAME` | S3 bucket name |

---

## Deployment Notes

- The `nextjs/` app can be deployed to Vercel, Railway, Render, or any Node.js host
- Run `npx prisma generate` as part of the build step
- The `api/` and `admin/` directories can be archived — they are superseded by `nextjs/`
- Flutter mobile only needs its `API_URL` env variable updated to point at the new deployment URL
