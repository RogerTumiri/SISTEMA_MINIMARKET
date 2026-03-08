import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { ConfiguracionNegocio } from '@database/entities/configuracion-negocio.entity';
import { successResponse } from '@shared/utils/AppError';

const router = Router();
const repo   = AppDataSource.getRepository(ConfiguracionNegocio);

router.get('/', authenticate, async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const items = await repo.find();
    const config: Record<string, string> = {};
    items.forEach(i => { config[i.clave] = i.valor; });
    return successResponse(res, config);
  } catch (e) { next(e); }
});

router.put('/', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updates = req.body as Record<string, string>;
      for (const [clave, valor] of Object.entries(updates)) {
        await repo.upsert({ clave, valor, updated_at: new Date() }, ['clave']);
      }
      return successResponse(res, null, 'Configuración actualizada');
    } catch (e) { next(e); }
  }
);

export default router;
