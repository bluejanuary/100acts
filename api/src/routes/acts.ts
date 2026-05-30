import { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma';
import { ActCategory } from '@prisma/client';

const VALID_CATEGORIES = Object.values(ActCategory);

export async function actRoutes(app: FastifyInstance) {
  // GET /acts
  app.get('/acts', {
    preHandler: [app.authenticate],
  }, async () => {
    return prisma.act.findMany({
      select: { id: true, category: true, photoUrl: true, lat: true, long: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  });

  // POST /acts
  app.post('/acts', {
    preHandler: [app.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['category', 'photoUrl', 'lat', 'long'],
        properties: {
          category: { type: 'string', enum: VALID_CATEGORIES },
          photoUrl: { type: 'string' },
          lat: { type: 'number', minimum: -90, maximum: 90 },
          long: { type: 'number', minimum: -180, maximum: 180 },
          gpsAccuracy: { type: 'number' },
        },
      },
    },
  }, async (request, reply) => {
    const { category, photoUrl, lat, long, gpsAccuracy } = request.body as {
      category: ActCategory;
      photoUrl: string;
      lat: number;
      long: number;
      gpsAccuracy?: number;
    };

    const act = await prisma.act.create({
      data: { userId: request.user.id, category, photoUrl, lat, long, gpsAccuracy },
    });

    return reply.status(201).send(act);
  });
}
