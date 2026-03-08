import { Request, Response, NextFunction } from 'express';
import { AppError } from '@shared/utils/AppError';
import { logger } from '@shared/utils/logger';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const requestId = req.headers['x-request-id'] as string;

  if (err instanceof AppError) {
    logger.warn(`[${err.code}] ${err.message}`, {
      path: req.path,
      method: req.method,
      requestId,
    });

    res.status(err.statusCode).json({
      success: false,
      error: {
        code:    err.code,
        message: err.message,
        ...(err.details && { details: err.details }),
        ...(err.field   && { field: err.field }),
      },
      timestamp: new Date().toISOString(),
      requestId,
    });
    return;
  }

  // Error de validación de TypeORM / DB
  if (err.code === '23505') {
    res.status(409).json({
      success: false,
      error: {
        code:    'DUPLICADO',
        message: 'Ya existe un registro con esos datos únicos',
      },
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Error desconocido
  logger.error('Error interno del servidor', { err, path: req.path, requestId });
  res.status(500).json({
    success: false,
    error: {
      code:    'ERROR_INTERNO',
      message: 'Error interno del servidor',
    },
    timestamp: new Date().toISOString(),
    requestId,
  });
}
