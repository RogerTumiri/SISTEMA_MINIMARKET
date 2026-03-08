import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Categoria } from '@database/entities/categoria.entity';
import { successResponse, AppError } from '@shared/utils/AppError';
import Joi from 'joi';
import { Request, Response, NextFunction } from 'express';

const router = Router();
const repo   = AppDataSource.getRepository(Categoria);

const schema = Joi.object({
  nombre:      Joi.string().max(100).required(),
  descripcion: Joi.string().optional(),
  parent_id:   Joi.number().integer().optional(),
  icono:       Joi.string().max(100).optional(),
  color_hex:   Joi.string().length(7).optional(),
  activo:      Joi.boolean().default(true),
});

router.get('/', authenticate, async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const cats = await repo.find({ order: { nombre: 'ASC' } });
    return successResponse(res, cats);
  } catch (e) { next(e); }
});

router.post('/', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = schema.validate(req.body);
    if (error) throw new AppError('VALIDACION', error.message, 400);
    const cat = await repo.save(repo.create(value));
    return successResponse(res, cat, 'Categoría creada', 201);
  } catch (e) { next(e); }
});

router.put('/:id', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = schema.fork(['nombre'], s => s.optional()).validate(req.body);
    if (error) throw new AppError('VALIDACION', error.message, 400);
    await repo.update(parseInt(req.params.id), { ...value, updated_at: new Date() });
    const updated = await repo.findOne({ where: { id: parseInt(req.params.id) } });
    return successResponse(res, updated, 'Categoría actualizada');
  } catch (e) { next(e); }
});

router.delete('/:id', authenticate, authorize('ADMINISTRADOR'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    await repo.update(parseInt(req.params.id), { activo: false });
    return successResponse(res, null, 'Categoría desactivada');
  } catch (e) { next(e); }
});

export default router;
