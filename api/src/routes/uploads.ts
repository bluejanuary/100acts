import { FastifyInstance } from 'fastify';
import { createPresignedUploadUrl } from '../lib/s3';

export async function uploadRoutes(app: FastifyInstance) {
  app.post('/uploads/presign', {
    preHandler: [app.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['filename', 'contentType'],
        properties: {
          filename: { type: 'string' },
          contentType: { type: 'string', enum: ['image/jpeg', 'image/png', 'image/webp'] },
        },
      },
    },
  }, async (request) => {
    const { filename, contentType } = request.body as { filename: string; contentType: string };
    const user = request.user;

    const key = `acts/${user.id}/${Date.now()}-${filename}`;
    const { uploadUrl, publicUrl } = await createPresignedUploadUrl(key, contentType);

    return { uploadUrl, publicUrl };
  });
}
