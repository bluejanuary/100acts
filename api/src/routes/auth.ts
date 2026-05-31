import { FastifyInstance } from 'fastify';
import { supabase } from '../lib/supabase';

export async function authRoutes(app: FastifyInstance) {
  // POST /auth/signup
  app.post('/auth/signup', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 8 },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password } = request.body as { email: string; password: string };

    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (error) {
      return reply.status(400).send({ error: error.message });
    }

    return reply.status(201).send({ id: data.user.id, email: data.user.email });
  });

  // GET /auth/me
  app.get('/auth/me', {
    preHandler: [app.authenticate],
  }, async (request) => {
    const { data, error } = await supabase.auth.admin.getUserById(request.user.id);
    if (error) throw error;
    return {
      id: data.user.id,
      email: data.user.email,
      createdAt: data.user.created_at,
    };
  });

  // POST /auth/refresh
  app.post('/auth/refresh', {
    schema: {
      body: {
        type: 'object',
        required: ['refreshToken'],
        properties: { refreshToken: { type: 'string' } },
      },
    },
  }, async (request, reply) => {
    const { refreshToken } = request.body as { refreshToken: string };
    const { data, error } = await supabase.auth.refreshSession({ refresh_token: refreshToken });
    if (error || !data.session) return reply.status(401).send({ error: 'Refresh failed' });
    return {
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
    };
  });

  // POST /auth/login
  app.post('/auth/login', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password } = request.body as { email: string; password: string };

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      return reply.status(401).send({ error: error.message });
    }

    return {
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      user: { id: data.user.id, email: data.user.email },
    };
  });
}
