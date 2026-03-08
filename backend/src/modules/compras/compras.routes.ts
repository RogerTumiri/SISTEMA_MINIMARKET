import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Compra } from '@database/entities/compra.entity';
import { CompraItem } from '@database/entities/compra-item.entity';
import { Producto } from '@database/entities/producto.entity';
import { MovimientoInventario } from '@database/entities/movimiento-inventario.entity';
import { successResponse, AppError } from '@shared/utils/AppError';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import Joi from 'joi';

const router = Router();

const schema = Joi.object({
  proveedor_id:    Joi.string().uuid().optional(),
  numero_factura:  Joi.string().optional(),
  fecha_compra:    Joi.string().optional(),
  observaciones:   Joi.string().optional(),
  items: Joi.array().items(Joi.object({
    producto_id:    Joi.string().uuid().required(),
    variante_id:    Joi.string().uuid().optional(),
    cantidad:       Joi.number().positive().required(),
    precio_unitario: Joi.number().positive().required(),
  })).min(1).required(),
});

// POST /compras
router.post('/', authenticate, authorize('ADMINISTRADOR'),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = schema.validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const result = await AppDataSource.transaction(async (manager) => {
        let subtotal = 0;
        const compraItems: Partial<CompraItem>[] = [];

        for (const item of value.items) {
          const producto = await manager.findOne(Producto, { where: { id: item.producto_id } });
          if (!producto) throw new AppError('PRODUCTO_NO_ENCONTRADO', `Producto ${item.producto_id} no encontrado`, 404);

          const itemSubtotal = item.cantidad * item.precio_unitario;
          subtotal += itemSubtotal;

          // Actualizar stock y precio de costo (promedio ponderado)
          const stockActual = Number(producto.stock_actual);
          const nuevoStock  = stockActual + item.cantidad;
          const precioPromedio = stockActual > 0
            ? (stockActual * Number(producto.precio_compra) + item.cantidad * item.precio_unitario) / nuevoStock
            : item.precio_unitario;

          await manager.update(Producto, item.producto_id, {
            stock_actual:  nuevoStock,
            precio_compra: precioPromedio,
          });

          await manager.save(MovimientoInventario, manager.create(MovimientoInventario, {
            producto_id:      item.producto_id,
            usuario_id:       req.user!.id,
            tipo_movimiento:  'COMPRA',
            cantidad_cambio:  item.cantidad,
            stock_anterior:   stockActual,
            stock_resultante: nuevoStock,
            precio_costo:     item.precio_unitario,
            observacion:      `Compra: ${value.numero_factura || 'sin factura'}`,
          }));

          compraItems.push({ ...item, subtotal: itemSubtotal });
        }

        const compra = manager.create(Compra, {
          proveedor_id:   value.proveedor_id,
          usuario_id:     req.user!.id,
          numero_factura: value.numero_factura,
          fecha_compra:   value.fecha_compra,
          observaciones:  value.observaciones,
          subtotal,
          impuesto_monto: 0,
          total:          subtotal,
          estado:         'CONFIRMADA',
          items:          compraItems as CompraItem[],
        });
        return manager.save(Compra, compra);
      });

      return successResponse(res, result, 'Compra registrada', 201);
    } catch (e) { next(e); }
  }
);

// GET /compras
router.get('/', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const page  = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 25;
      const compraRepo = AppDataSource.getRepository(Compra);
      const [data, total] = await compraRepo.findAndCount({
        relations: ['proveedor', 'usuario'],
        order: { created_at: 'DESC' },
        skip: (page - 1) * limit,
        take: limit,
      });
      return res.json({ success: true, data, meta: { total, page, limit }, timestamp: new Date().toISOString() });
    } catch (e) { next(e); }
  }
);

export default router;
