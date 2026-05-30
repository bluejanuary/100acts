import { FastifyInstance } from 'fastify';
import { supabase } from '../lib/supabase';
import { prisma } from '../lib/prisma';

export async function adminRoutes(app: FastifyInstance) {
  // GET /admin/users
  app.get('/admin/users', {
    preHandler: [app.authenticate],
  }, async (request, reply) => {
    const { data, error } = await supabase.auth.admin.listUsers();
    if (error) return reply.status(500).send({ error: error.message });
    return data.users.map((u) => ({
      id: u.id,
      email: u.email,
      createdAt: u.created_at,
      lastSignIn: u.last_sign_in_at,
    }));
  });

  // POST /admin/users
  app.post('/admin/users', {
    preHandler: [app.authenticate],
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
    const { data, error } = await supabase.auth.admin.createUser({ email, password, email_confirm: true });
    if (error) return reply.status(400).send({ error: error.message });
    return reply.status(201).send({ id: data.user.id, email: data.user.email });
  });

  // DELETE /admin/users/:id
  app.delete('/admin/users/:id', {
    preHandler: [app.authenticate],
  }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const { error } = await supabase.auth.admin.deleteUser(id);
    if (error) return reply.status(400).send({ error: error.message });
    return reply.status(204).send();
  });

  // GET /admin/analytics
  app.get('/admin/analytics', {
    preHandler: [app.authenticate],
  }, async (request, reply) => {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [total, today, week, month, byCategory, usersRes] = await Promise.all([
      prisma.act.count(),
      prisma.act.count({ where: { createdAt: { gte: startOfToday } } }),
      prisma.act.count({ where: { createdAt: { gte: startOfWeek } } }),
      prisma.act.count({ where: { createdAt: { gte: startOfMonth } } }),
      prisma.act.groupBy({ by: ['category'], _count: { id: true } }),
      supabase.auth.admin.listUsers(),
    ]);

    return {
      totalActs: total,
      actsToday: today,
      actsThisWeek: week,
      actsThisMonth: month,
      totalUsers: usersRes.data?.users.length ?? 0,
      byCategory: byCategory.map((row) => ({ category: row.category, count: row._count.id })),
    };
  });

  // GET /admin/categories
  app.get('/admin/categories', {
    preHandler: [app.authenticate],
  }, async (request, reply) => {
    return prisma.category.findMany({ orderBy: { createdAt: 'desc' } });
  });

  // POST /admin/categories
  app.post('/admin/categories', {
    preHandler: [app.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['name', 'slug'],
        properties: {
          name: { type: 'string' },
          slug: { type: 'string' },
          description: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { name, slug, description } = request.body as { name: string; slug: string; description?: string };
    const category = await prisma.category.create({ data: { name, slug, description } });
    return reply.status(201).send(category);
  });
}
