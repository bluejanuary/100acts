import { supabase } from './supabase';

export type AuthUser = {
  id: string;
  email: string;
};

export async function verifyToken(token: string): Promise<AuthUser> {
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) throw new Error('Invalid token');
  return {
    id: data.user.id,
    email: data.user.email!,
  };
}
