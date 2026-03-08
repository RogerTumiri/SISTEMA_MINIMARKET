import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '@config/jwt';
import { isBlacklisted } from '@config/redis';
import { AppError } from '@shared/utils/AppError';

export interface AuthRequest extends Request {
  user?: {
    id:       string;
    username: string;
    rol:      string;
  };
}

export async function authenticate(
  req: AuthRequest,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('TOKEN_REQUERIDO', 'Se requiere token de autenticación', 401);
    }

    const token = authHeader.split(' ')[1];

    // Verificar si el token está en blacklist (logout)
    const blacklisted = await isBlacklisted(token).catch(() => false);
    if (blacklisted) {
      throw new AppError('TOKEN_REVOCADO', 'El token ha sido revocado', 401);
    }

    const payload = verifyAccessToken(token);
    req.user = {
      id:       payload.sub,
      username: payload.username,
      rol:      payload.rol,
    };

    next();
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      next(new AppError('TOKEN_EXPIRADO', 'El token ha expirado', 401));
    } else if (err.name === 'JsonWebTokenError') {
      next(new AppError('TOKEN_INVALIDO', 'Token inválido', 401));
    } else {
      next(err);
    }
  }
}
