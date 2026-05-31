import { createClient } from '@supabase/supabase-js';

// Admin client — service role, for admin operations (listUsers, deleteUser, etc.)
export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

// Auth client — anon key, required for signInWithPassword and refreshSession
export const supabaseAuth = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
);
