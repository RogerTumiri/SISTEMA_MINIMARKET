import { Server as SocketIOServer, Socket } from 'socket.io';
import { verifyAccessToken } from '@config/jwt';
import { logger } from '@shared/utils/logger';

export function setupWebSocket(io: SocketIOServer): void {
  // Auth middleware for WebSocket
  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('No token provided'));
    try {
      const payload = verifyAccessToken(token as string);
      (socket as any).user = payload;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = (socket as any).user;
    logger.info(`[WS] Cliente conectado: ${user?.username} (${socket.id})`);

    // Unirse a sala según rol
    if (user?.rol === 'ADMINISTRADOR') {
      socket.join('admins');
    }
    socket.join('all');

    socket.on('disconnect', () => {
      logger.info(`[WS] Cliente desconectado: ${user?.username}`);
    });

    socket.on('ping', () => {
      socket.emit('pong', { timestamp: new Date().toISOString() });
    });
  });

  // Emitir alertas de stock (llamado desde otros servicios)
  io.emitStockAlerta = (data: any) => {
    io.to('all').emit('stock.alerta', data);
  };
}

// Extender tipo de Socket.IO para evitar errores ts
declare module 'socket.io' {
  interface Server {
    emitStockAlerta?: (data: any) => void;
  }
}
