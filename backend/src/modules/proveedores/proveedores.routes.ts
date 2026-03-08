import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Proveedor } from '@database/entities/proveedor.entity';
import { successResponse, AppError } from '@shared/utils/AppError';
import Joi from 'joi';
import { Request, Response, NextFunction } from 'express';
import { IsNull } from 'typeorm';

const router = Router();
const repo   = AppDataSource.getRepository(Proveedor);

const schema = Joi.object({
  nombre_empresa: Joi.string().max(150).required(),
  nit_ruc:        Joi.string().max(20).optional(),
  contacto:       Joi.string().max(100).optional(),
  telefono:       Joi.string().max(20).optional(),
  email:          Joi.string().email().optional(),
  direccion:      Joi.string().optional(),
  activo:         Joi.boolean().default(true),
});

router.get('/', authenticate, async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const provs = await repo.find({
      where: { activo: true, deleted_at: IsNull() as any },
      order: { nombre_empresa: 'ASC' },
    });
    return successResponse(res, provs);
  } catch (e) { next(e); }
});

router.post('/', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = schema.validate(req.body);
    if (error) throw new AppError('VALIDACION', error.message, 400);
    const prov = await repo.save(repo.create(value));
    return successResponse(res, prov, 'Proveedor creado', 201);
  } catch (e) { next(e); }
});

router.get('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const prov = await repo.findOne({ where: { id: req.params.id, deleted_at: IsNull() as any } });
    if (!prov) throw new AppError('NO_ENCONTRADO', 'Proveedor no encontrado', 404);
    return successResponse(res, prov);
  } catch (e) { next(e); }
});

router.put('/:id', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = schema.fork(['nombre_empresa'], s => s.optional()).validate(req.body);
    if (error) throw new AppError('VALIDACION', error.message, 400);
    await repo.update(req.params.id, { ...value, updated_at: new Date() });
    const updated = await repo.findOne({ where: { id: req.params.id } });
    return successResponse(res, updated, 'Proveedor actualizado');
  } catch (e) { next(e); }
});

router.delete('/:id', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    await repo.softDelete(req.params.id);
    return successResponse(res, null, 'Proveedor eliminado');
  } catch (e) { next(e); }
});

export default router;
