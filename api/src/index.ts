import Fastify from 'fastify';
import cors from '@fastify/cors';
import { verifyToken, AuthUser } from './lib/auth';
import { actRoutes } from './routes/acts';
import { uploadRoutes } from './routes/uploads';
import { authRoutes } from './routes/auth';
import { adminRoutes } from './routes/admin';
import { configRoutes } from './routes/config';

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
  interface FastifyRequest {
    user: AuthUser;
  }
}

const app = Fastify({ logger: true });

app.register(cors, { origin: true });

// Auth decorator
app.decorate('authenticate', async (request: any, reply: any) => {
  const auth = request.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    return reply.status(401).send({ error: 'Missing token' });
  }

  try {
    request.user = await verifyToken(auth.slice(7));
  } catch {
    return reply.status(401).send({ error: 'Invalid token' });
  }
});

app.register(authRoutes);
app.register(adminRoutes);
app.register(actRoutes);
app.register(uploadRoutes);
app.register(configRoutes);

app.get('/health', async () => ({ status: 'ok' }));

app.listen({ port: 3100, host: '0.0.0.0' }, (err) => {
  if (err) {
    app.log.error(err);
    process.exit(1);
  }
});
