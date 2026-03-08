import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Producto } from '@database/entities/producto.entity';
import { MovimientoInventario } from '@database/entities/movimiento-inventario.entity';
import { successResponse, AppError } from '@shared/utils/AppError';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import Joi from 'joi';

const router      = Router();
const productoRepo = AppDataSource.getRepository(Producto);
const movRepo      = AppDataSource.getRepository(MovimientoInventario);

// POST /inventario/egreso — Merma/Egreso
router.post('/egreso', authenticate, authorize('ADMINISTRADOR'),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        producto_id: Joi.string().uuid().required(),
        cantidad:    Joi.number().positive().required(),
        motivo:      Joi.string().required(),
        observacion: Joi.string().optional(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const producto = await productoRepo.findOne({ where: { id: value.producto_id } });
      if (!producto) throw new AppError('PRODUCTO_NO_ENCONTRADO', 'Producto no encontrado', 404);
      if (Number(producto.stock_actual) < value.cantidad) {
        throw new AppError('STOCK_INSUFICIENTE', 'Stock insuficiente', 400);
      }

      const stockAnterior = Number(producto.stock_actual);
      await productoRepo.update(value.producto_id, { stock_actual: stockAnterior - value.cantidad });

      const mov = movRepo.create({
        producto_id:      value.producto_id,
        usuario_id:       req.user!.id,
        tipo_movimiento:  'MERMA',
        cantidad_cambio:  -value.cantidad,
        stock_anterior:   stockAnterior,
        stock_resultante: stockAnterior - value.cantidad,
        observacion:      `${value.motivo}${value.observacion ? ': ' + value.observacion : ''}`,
      });
      await movRepo.save(mov);

      return successResponse(res, mov, 'Egreso registrado', 201);
    } catch (e) { next(e); }
  }
);

// POST /inventario/ajuste — Ajuste de inventario
router.post('/ajuste', authenticate, authorize('ADMINISTRADOR'),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        producto_id:  Joi.string().uuid().required(),
        stock_fisico: Joi.number().min(0).required(),
        motivo:       Joi.string().required(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const producto = await productoRepo.findOne({ where: { id: value.producto_id } });
      if (!producto) throw new AppError('PRODUCTO_NO_ENCONTRADO', 'Producto no encontrado', 404);

      const stockSistema  = Number(producto.stock_actual);
      const diferencia    = value.stock_fisico - stockSistema;
      const tipoMovimiento = diferencia >= 0 ? 'AJUSTE_ENTRADA' : 'AJUSTE_SALIDA';

      await productoRepo.update(value.producto_id, { stock_actual: value.stock_fisico });

      const mov = movRepo.create({
        producto_id:      value.producto_id,
        usuario_id:       req.user!.id,
        tipo_movimiento:  tipoMovimiento,
        cantidad_cambio:  diferencia,
        stock_anterior:   stockSistema,
        stock_resultante: value.stock_fisico,
        observacion:      `Ajuste: ${value.motivo}`,
      });
      await movRepo.save(mov);

      return successResponse(res, {
        stock_sistema:  stockSistema,
        stock_fisico:   value.stock_fisico,
        diferencia,
        movimiento:     mov,
      }, 'Ajuste registrado', 201);
    } catch (e) { next(e); }
  }
);

// GET /inventario/movimientos/:productoId — Kardex
router.get('/movimientos/:productoId', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const page  = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 50;
      const [data, total] = await movRepo.findAndCount({
        where: { producto_id: req.params.productoId },
        relations: ['usuario'],
        order: { created_at: 'DESC' },
        skip: (page - 1) * limit,
        take: limit,
      });
      return res.json({ success: true, data, meta: { total, page, limit }, timestamp: new Date().toISOString() });
    } catch (e) { next(e); }
  }
);

export default router;
