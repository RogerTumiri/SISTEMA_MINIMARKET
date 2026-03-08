import { Response, NextFunction } from 'express';
import { AuthRequest } from './authenticate.middleware';
import { AppError } from '@shared/utils/AppError';

export function authorize(...roles: string[]) {
  return (req: AuthRequest, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new AppError('NO_AUTENTICADO', 'Debe iniciar sesión', 401));
    }
    if (!roles.includes(req.user.rol)) {
      return next(new AppError(
        'SIN_PERMISOS',
        `Rol '${req.user.rol}' no tiene acceso a esta función`,
        403
      ));
    }
    next();
  };
}

export const onlyAdmin = authorize('ADMINISTRADOR');
export const authenticated = (_req: AuthRequest, _res: Response, next: NextFunction) => next();
