import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { CajasController } from './cajas.controller';

const router = Router();
const ctrl   = new CajasController();

router.post('/abrir',  authenticate,                             ctrl.abrir);
router.post('/cerrar', authenticate,                             ctrl.cerrar);
router.get('/activa',  authenticate,                             ctrl.activa);
router.get('/',        authenticate, authorize('ADMINISTRADOR'), ctrl.historial);

export default router;
