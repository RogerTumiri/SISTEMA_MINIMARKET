import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { AppDataSource } from '@database/data-source';
import { UnidadMedida } from '@database/entities/unidad-medida.entity';
import { successResponse } from '@shared/utils/AppError';
import { Request, Response, NextFunction } from 'express';

const router = Router();
const repo   = AppDataSource.getRepository(UnidadMedida);

router.get('/', authenticate, async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await repo.find({ order: { nombre: 'ASC' } });
    return successResponse(res, data);
  } catch (e) { next(e); }
});

export default router;
