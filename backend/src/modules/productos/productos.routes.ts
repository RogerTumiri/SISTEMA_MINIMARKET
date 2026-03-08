import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { ProductosController } from './productos.controller';
import multer from 'multer';

const router = Router();
const ctrl   = new ProductosController();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

router.get('/',                authenticate,                             ctrl.listar);
router.post('/',               authenticate, authorize('ADMINISTRADOR'), ctrl.crear);
router.get('/barcode/:codigo', authenticate,                             ctrl.buscarBarcode);
router.get('/export',          authenticate, authorize('ADMINISTRADOR'), ctrl.exportar);
router.post('/import',         authenticate, authorize('ADMINISTRADOR'), upload.single('archivo'), ctrl.importar);
router.get('/:id',             authenticate,                             ctrl.obtener);
router.put('/:id',             authenticate, authorize('ADMINISTRADOR'), ctrl.actualizar);
router.delete('/:id',          authenticate, authorize('ADMINISTRADOR'), ctrl.eliminar);
router.get('/:id/kardex',      authenticate, authorize('ADMINISTRADOR'), ctrl.kardex);

export default router;
