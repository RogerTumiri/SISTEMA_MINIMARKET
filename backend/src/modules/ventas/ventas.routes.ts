import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { VentasController } from './ventas.controller';

const router = Router();
const ctrl   = new VentasController();

router.post('/',           authenticate,                             ctrl.crear);
router.get('/',            authenticate, authorize('ADMINISTRADOR'), ctrl.listar);
router.get('/:id',         authenticate,                             ctrl.obtener);
router.post('/:id/anular', authenticate, authorize('ADMINISTRADOR'), ctrl.anular);
router.get('/:id/recibo',  authenticate,                             ctrl.recibo);

export default router;
