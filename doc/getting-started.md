# Getting Started

## Prerequisites

- Node.js 20+
- npm 10+
- Terraform 1.5+
- AWS account with programmatic access
- Supabase account (free tier is fine)
- Expo Go app on your phone (for mobile testing)

---

## 1. Clone and install

```bash
# Fix npm cache permissions if needed (macOS)
sudo chown -R $(whoami) ~/.npm

npm install
```

---

## 2. Set up Supabase

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Once created, go to **Settings → API** and copy:
   - Project URL
   - `anon` public key
   - `service_role` key
   - JWT secret
3. Go to **Settings → Database** and copy the connection string (URI format)

---

## 3. Provision AWS infrastructure (Terraform)

```bash
cd infra

# Authenticate with AWS
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret

# Create a terraform.tfvars file
cat > terraform.tfvars <<EOF
aws_region  = "us-east-1"
environment = "dev"
bucket_name = "100acts-uploads"
EOF

terraform init
terraform apply
```

After apply, note the outputs — you'll need `bucket_name` and the IAM credentials for your `.env`.

---

## 4. Configure environment variables

```bash
cp .env.example .env
```

Fill in `.env` with values from Supabase and Terraform outputs:

```env
# From Supabase → Settings → Database
DATABASE_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres

# From Supabase → Settings → API
SUPABASE_JWT_SECRET=your-jwt-secret

# From Terraform outputs
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET_NAME=100acts-uploads-dev

# Mobile
EXPO_PUBLIC_SUPABASE_URL=https://your-ref.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
EXPO_PUBLIC_API_URL=http://localhost:3000

# Admin
VITE_SUPABASE_URL=https://your-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3000
```

---

## 5. Run database migrations

```bash
cd api

# Generate Prisma client
npx prisma generate

# Run migrations against Supabase
npx prisma migrate deploy
```

---

## 6. Start the API

```bash
cd api
npm run dev
```

API runs at `http://localhost:3000`. Test it:

```bash
curl http://localhost:3000/health
# → {"status":"ok"}
```

---

## 7. Start the admin dashboard

```bash
cd admin
npm run dev
```

Admin runs at `http://localhost:5173`.

---

## 8. Start the mobile app

```bash
cd mobile
npm start
```

Scan the QR code with **Expo Go** on your phone.

> **Note:** Your phone and computer must be on the same WiFi network for local development. For testing on a real device over the internet, update `EXPO_PUBLIC_API_URL` to point to a deployed API or use [ngrok](https://ngrok.com).

---

## Running everything at once

From the repo root:

```bash
# Terminal 1 – API
npm run api

# Terminal 2 – Admin
npm run admin

# Terminal 3 – Mobile
npm run mobile
```

---

## Useful commands

| Command | Description |
|---------|-------------|
| `npm run api` | Start API in dev mode (hot reload) |
| `npm run admin` | Start Vue admin dashboard |
| `npm run mobile` | Start Expo dev server |
| `cd api && npx prisma studio` | Browse database in browser |
| `cd api && npx prisma migrate dev` | Create and run a new migration |
| `cd infra && terraform plan` | Preview infrastructure changes |
| `cd infra && terraform apply` | Apply infrastructure changes |
