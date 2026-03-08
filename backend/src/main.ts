import 'reflect-metadata';
import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';

import { AppDataSource } from '@database/data-source';
import { redisClient } from '@config/redis';
import { logger } from '@shared/utils/logger';
import { errorHandler } from '@shared/middleware/errorHandler.middleware';
import { setupSwagger } from '@config/swagger';

// Routes
import authRoutes from '@modules/auth/auth.routes';
import usuariosRoutes from '@modules/usuarios/usuarios.routes';
import productosRoutes from '@modules/productos/productos.routes';
import categoriasRoutes from '@modules/categorias/categorias.routes';
import proveedoresRoutes from '@modules/proveedores/proveedores.routes';
import ventasRoutes from '@modules/ventas/ventas.routes';
import cajasRoutes from '@modules/cajas/cajas.routes';
import comprasRoutes from '@modules/compras/compras.routes';
import inventarioRoutes from '@modules/inventario/inventario.routes';
import reportesRoutes from '@modules/reportes/reportes.routes';
import configuracionRoutes from '@modules/configuracion/configuracion.routes';
import unidadesRoutes from '@modules/unidades/unidades.routes';
import { setupWebSocket } from '@shared/websocket/socket.server';

const PORT = process.env.PORT || 3001;

async function bootstrap(): Promise<void> {
  // ─── Inicializar Base de Datos ────────────────────────────
  try {
    await AppDataSource.initialize();
    logger.info('✅ Conexión a PostgreSQL establecida');
  } catch (err) {
    logger.error('❌ Error conectando a PostgreSQL', err);
    process.exit(1);
  }

  // ─── Inicializar Redis ────────────────────────────────────
  try {
    await redisClient.ping();
    logger.info('✅ Conexión a Redis establecida');
  } catch (err) {
    logger.warn('⚠️ Redis no disponible, tokens blacklist deshabilitado', err);
  }

  // ─── App Express ─────────────────────────────────────────
  const app: Application = express();
  const httpServer = createServer(app);

  // Seguridad
  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }));

  // CORS
  const allowedOrigins = (process.env.FRONTEND_URL || 'http://localhost').split(',').map(s => s.trim());
  app.use(cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (curl, mobile apps, Postman)
      if (!origin) return callback(null, true);
      // In development, allow all localhost origins (Flutter web uses random ports)
      if (process.env.NODE_ENV === 'development' && /^https?:\/\/localhost(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      callback(new Error(`CORS bloqueado para origen: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  }));

  app.use(compression() as any);
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan('combined', {
    stream: { write: (message) => logger.http(message.trim()) },
  }));

  // ─── WebSocket ────────────────────────────────────────────
  const io = new SocketIOServer(httpServer, {
    cors: { origin: allowedOrigins, credentials: true },
  });
  setupWebSocket(io);
  app.set('io', io);

  // ─── Health Check ─────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'minimarket-api',
      version: '1.0.0',
    });
  });

  // ─── Rutas API ────────────────────────────────────────────
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/usuarios', usuariosRoutes);
  app.use('/api/v1/productos', productosRoutes);
  app.use('/api/v1/categorias', categoriasRoutes);
  app.use('/api/v1/proveedores', proveedoresRoutes);
  app.use('/api/v1/ventas', ventasRoutes);
  app.use('/api/v1/cajas', cajasRoutes);
  app.use('/api/v1/compras', comprasRoutes);
  app.use('/api/v1/inventario', inventarioRoutes);
  app.use('/api/v1/reportes', reportesRoutes);
  app.use('/api/v1/configuracion', configuracionRoutes);
  app.use('/api/v1/unidades-medida', unidadesRoutes);

  // ─── Swagger ──────────────────────────────────────────────
  setupSwagger(app);

  // ─── Error Handler ────────────────────────────────────────
  app.use(errorHandler);

  // ─── Iniciar servidor ─────────────────────────────────────
  httpServer.listen(PORT, () => {
    logger.info(`🚀 API MiniMarket corriendo en http://localhost:${PORT}`);
    logger.info(`📚 Swagger disponible en http://localhost:${PORT}/api/docs`);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('🛑 Cerrando servidor...');
    await AppDataSource.destroy();
    await redisClient.quit();
    process.exit(0);
  });
}

bootstrap().catch((err) => {
  logger.error('Error crítico al iniciar la aplicación', err);
  process.exit(1);
});
