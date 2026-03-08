import { Request, Response, NextFunction } from 'express';
import { CajasService } from './cajas.service';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import { successResponse, AppError } from '@shared/utils/AppError';
import Joi from 'joi';

const svc = new CajasService();

export class CajasController {
  abrir = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        monto_apertura: Joi.number().min(0).required(),
        observaciones:  Joi.string().optional(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const caja = await svc.abrir(req.user!.id, value.monto_apertura, value.observaciones);
      const io   = req.app.get('io');
      if (io) io.emit('caja.apertura', { caja_id: caja.id, vendedor: req.user!.username, monto_apertura: caja.monto_apertura, timestamp: caja.hora_apertura });
      return successResponse(res, caja, 'Caja abierta', 201);
    } catch (err) { next(err); }
  };

  cerrar = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        monto_cierre:  Joi.number().min(0).required(),
        observaciones: Joi.string().optional(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const result = await svc.cerrar(req.user!.id, value.monto_cierre, value.observaciones);
      const io = req.app.get('io');
      if (io) io.emit('caja.cierre', { caja_id: result.caja.id, vendedor: req.user!.username });
      return successResponse(res, result, 'Caja cerrada');
    } catch (err) { next(err); }
  };

  activa = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const caja = await svc.cajaActiva(req.user!.id);
      return successResponse(res, caja);
    } catch (err) { next(err); }
  };

  historial = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await svc.historial(
        parseInt(req.query.page as string) || 1,
        parseInt(req.query.limit as string) || 25,
      );
      return res.json({ success: true, ...result, timestamp: new Date().toISOString() });
    } catch (err) { next(err); }
  };
}
