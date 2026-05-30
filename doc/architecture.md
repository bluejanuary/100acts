# 100 Acts – Architecture Overview

## What We Built

A monorepo containing three applications and infrastructure-as-code for the 100 Acts environmental movement app.

---

## Monorepo Structure

```
100acts/
├── mobile/           # Expo (React Native) – user-facing mobile app
├── admin/            # Vue.js – internal admin dashboard
├── api/              # Fastify + Prisma – backend REST API
├── infra/  # Terraform – AWS infrastructure
├── supabase/         # Database migrations
└── doc/              # Documentation
```

---

## Applications

### Mobile (Expo / React Native)
The user-facing app. Users log environmental acts by selecting a category, taking a photo, and submitting with their GPS location.

**Two screens:**
- **Upload** – select category, take photo, capture GPS, submit act
- **Map** – view all submitted acts as pins on a world map

**Auth:** Supabase (email/password). The Supabase JWT is passed as a Bearer token to the API on every request.

---

### API (Fastify + Prisma + TypeScript)
The backend REST API. All business logic lives here. Neither the mobile app nor the admin dashboard talk directly to the database or S3.

**Endpoints:**
| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/uploads/presign` | Get a pre-signed S3 URL for photo upload |
| GET | `/acts` | Fetch all acts (map view) |
| POST | `/acts` | Create a new act record |

**Auth:** Verifies Supabase JWTs on every protected route using the `SUPABASE_JWT_SECRET`.

---

### Admin (Vue.js + Vite)
Internal dashboard for managing and reviewing submitted acts.

**Views:**
- **Acts** – table of all submitted acts with photo thumbnails, category badges, coordinates, and timestamps

---

## Infrastructure

### Database – Supabase (Postgres)
- Managed Postgres hosted on Supabase Cloud
- PostGIS extension enabled for geo queries
- Prisma manages the schema and runs migrations
- Row Level Security (RLS) enabled on the `acts` table

**Schema – `acts` table:**
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | References auth.users |
| category | Enum | tree_mangrove, wildlife, recycling, litter_cleanup |
| photo_url | Text | Public S3 URL of the uploaded photo |
| lat | Float | Latitude |
| long | Float | Longitude |
| gps_accuracy | Float | GPS accuracy in metres |
| location | Geometry | PostGIS point (auto-generated from lat/long) |
| created_at | Timestamptz | Server timestamp |

### Storage – AWS S3
- All photos are uploaded directly from the mobile app to S3 via pre-signed URLs
- The API generates a pre-signed PUT URL (valid for 5 minutes)
- The mobile app uploads the photo blob directly to S3 — the API never handles the file
- Bucket is private; objects are accessed via their public URL after upload
- CORS configured to allow uploads from any origin (tighten to your domain in production)

### Terraform (infra/)
Provisions all AWS resources:
- S3 bucket with versioning, CORS, and lifecycle rules
- IAM user with scoped S3 permissions
- Outputs bucket name, ARN, and IAM credentials

---

## Data Flow

### Submitting an Act
```
Mobile
  1. → POST /uploads/presign        (get pre-signed S3 URL)
  2. → PUT {presigned-url}          (upload photo directly to S3)
  3. → POST /acts                   (save act record with S3 photo URL)
API
  4. → Prisma → Postgres (Supabase)
```

### Viewing the Map
```
Mobile
  1. → GET /acts
API
  2. → Prisma → Postgres
  3. ← returns [ { id, category, lat, long, createdAt } ]
Mobile
  4. renders pins on MapView
```

---

## Environment Variables

See `.env.example` for a full list. Key variables:

| Variable | Used by | Purpose |
|----------|---------|---------|
| `DATABASE_URL` | API | Prisma connection string (Supabase Postgres) |
| `SUPABASE_JWT_SECRET` | API | Verify Supabase auth tokens |
| `AWS_ACCESS_KEY_ID` | API | S3 access |
| `AWS_SECRET_ACCESS_KEY` | API | S3 access |
| `S3_BUCKET_NAME` | API | Target bucket for uploads |
| `EXPO_PUBLIC_SUPABASE_URL` | Mobile | Supabase auth |
| `EXPO_PUBLIC_API_URL` | Mobile | API base URL |
| `VITE_SUPABASE_URL` | Admin | Supabase auth |
| `VITE_API_URL` | Admin | API base URL |
