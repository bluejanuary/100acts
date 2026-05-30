-- Enable PostGIS for geo queries
create extension if not exists postgis;

-- Acts table
create table public.acts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users(id) on delete cascade not null,
  category      text not null check (category in ('tree_mangrove', 'wildlife', 'recycling', 'litter_cleanup')),
  photo_url     text not null,
  lat           double precision not null,
  long          double precision not null,
  gps_accuracy  double precision,
  location      geometry(Point, 4326) generated always as (st_setsrid(st_makepoint(long, lat), 4326)) stored,
  created_at    timestamptz default now() not null
);

-- Index for geo queries (map view)
create index acts_location_idx on public.acts using gist(location);
create index acts_user_id_idx on public.acts(user_id);
create index acts_category_idx on public.acts(category);

-- Row Level Security
alter table public.acts enable row level security;

-- Users can insert their own acts
create policy "users can insert own acts"
  on public.acts for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Users can read their own acts
create policy "users can read own acts"
  on public.acts for select
  to authenticated
  using (auth.uid() = user_id);

-- Anyone authenticated can read all acts for map view
create policy "authenticated users can read all acts for map"
  on public.acts for select
  to authenticated
  using (true);
