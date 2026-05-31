import { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma';

export async function configRoutes(app: FastifyInstance) {
  // GET /config — returns system config for the mobile app
  app.get('/config', {
    preHandler: [app.authenticate],
  }, async (request, reply) => {
    try {
      const categories = await prisma.category.findMany({
        select: { id: true, name: true, slug: true },
        orderBy: { createdAt: 'asc' },
      });
      app.log.info({ categories }, '[config] returning system config');
      return { categories };
    } catch (err) {
      app.log.error({ err }, '[config] failed to fetch categories');
      return reply.status(500).send({ error: 'Failed to load config' });
    }
  });
}
