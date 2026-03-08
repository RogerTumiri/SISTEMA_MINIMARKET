import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import { successResponse } from '@shared/utils/AppError';
import { AppError } from '@shared/utils/AppError';
import Joi from 'joi';

const svc = new AuthService();

const passwordSchema = Joi.string().min(8).max(72)
  .pattern(/[A-Z]/, 'uppercase')
  .pattern(/[a-z]/, 'lowercase')
  .pattern(/[0-9]/, 'number')
  .required();

export class AuthController {
  login = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        username: Joi.string().required(),
        password: Joi.string().required(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const data = await svc.login(value.username, value.password);
      return successResponse(res, data, 'Sesión iniciada', 200);
    } catch (err) { next(err); }
  };

  logout = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const token = req.headers.authorization!.split(' ')[1];
      await svc.logout(token, req.user!.id);
      return successResponse(res, null, 'Sesión cerrada exitosamente');
    } catch (err) { next(err); }
  };

  refresh = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        refreshToken: Joi.string().required(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const data = await svc.refresh(value.refreshToken);
      return successResponse(res, data, 'Token renovado');
    } catch (err) { next(err); }
  };

  forgotPassword = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        email: Joi.string().email().required(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      await svc.forgotPassword(value.email);
      return successResponse(res, null, 'Si el email existe, recibirás instrucciones en minutos');
    } catch (err) { next(err); }
  };

  resetPassword = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        userId:      Joi.string().uuid().required(),
        token:       Joi.string().required(),
        newPassword: passwordSchema,
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      await svc.resetPassword(value.userId, value.token, value.newPassword);
      return successResponse(res, null, 'Contraseña actualizada exitosamente');
    } catch (err) { next(err); }
  };

  me = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const data = await svc.me(req.user!.id);
      return successResponse(res, data);
    } catch (err) { next(err); }
  };

  changePassword = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        currentPassword: Joi.string().required(),
        newPassword:     passwordSchema,
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      await svc.changePassword(req.user!.id, value.currentPassword, value.newPassword);
      return successResponse(res, null, 'Contraseña actualizada');
    } catch (err) { next(err); }
  };
}
