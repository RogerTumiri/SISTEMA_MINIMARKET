import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Venta } from '@database/entities/venta.entity';
import { Producto } from '@database/entities/producto.entity';
import { Compra } from '@database/entities/compra.entity';
import { successResponse } from '@shared/utils/AppError';

const router = Router();

// GET /reportes/ventas
router.get('/ventas', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const desde = req.query.desde as string || new Date(new Date().setHours(0,0,0,0)).toISOString();
      const hasta = req.query.hasta as string || new Date().toISOString();

      const ventas = await AppDataSource.getRepository(Venta).createQueryBuilder('v')
        .leftJoinAndSelect('v.items', 'i')
        .leftJoinAndSelect('v.pagos', 'p')
        .leftJoinAndSelect('v.usuario', 'u')
        .where('v.created_at BETWEEN :desde AND :hasta', { desde, hasta })
        .andWhere('v.estado = :estado', { estado: 'COMPLETADA' })
        .orderBy('v.created_at', 'DESC')
        .getMany();

      const total_ventas  = ventas.length;
      const monto_total   = ventas.reduce((s, v) => s + Number(v.total), 0);
      const ticket_prom   = total_ventas > 0 ? monto_total / total_ventas : 0;
      const total_imp     = ventas.reduce((s, v) => s + Number(v.impuesto_monto), 0);

      const por_metodo: Record<string, number> = {};
      ventas.flatMap(v => v.pagos || []).forEach(p => {
        por_metodo[p.metodo_pago] = (por_metodo[p.metodo_pago] || 0) + Number(p.monto);
      });

      // Top productos
      const topMap: Record<string, { nombre: string; cantidad: number; monto: number }> = {};
      ventas.flatMap(v => v.items || []).forEach(i => {
        if (!topMap[i.producto_id]) topMap[i.producto_id] = { nombre: i.nombre_producto, cantidad: 0, monto: 0 };
        topMap[i.producto_id].cantidad += Number(i.cantidad);
        topMap[i.producto_id].monto   += Number(i.subtotal);
      });
      const top_productos = Object.values(topMap).sort((a, b) => b.monto - a.monto).slice(0, 10);

      return successResponse(res, {
        resumen: { total_ventas, monto_total, ticket_promedio: ticket_prom, total_impuestos: total_imp, por_metodo_pago: por_metodo },
        top_productos,
        ventas: ventas.slice(0, 100),
      });
    } catch (e) { next(e); }
  }
);

// GET /reportes/inventario
router.get('/inventario', authenticate, authorize('ADMINISTRADOR'),
  async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const productos = await AppDataSource.getRepository(Producto).find({
        where: { activo: true },
        relations: ['categoria', 'unidad_medida'],
      });
      const valor_total = productos.reduce((s, p) =>
        s + Number(p.stock_actual) * Number(p.precio_compra), 0);
      const bajo_minimo = productos.filter(p => Number(p.stock_actual) <= Number(p.stock_minimo));
      const sin_stock   = productos.filter(p => Number(p.stock_actual) <= 0);
      return successResponse(res, {
        resumen: {
          total_productos: productos.length,
          valor_total_inventario: valor_total,
          productos_bajo_minimo:  bajo_minimo.length,
          productos_sin_stock:    sin_stock.length,
        },
        productos_criticos: bajo_minimo.map(p => ({
          id: p.id, nombre: p.nombre, stock_actual: p.stock_actual,
          stock_minimo: p.stock_minimo, estado: p.estado_stock,
        })),
        todos: productos,
      });
    } catch (e) { next(e); }
  }
);

// GET /reportes/productos-top
router.get('/productos-top', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const desde = req.query.desde as string || new Date(new Date().setDate(1)).toISOString();
      const hasta = req.query.hasta as string || new Date().toISOString();

      const result = await AppDataSource.query(`
        SELECT vi.producto_id, vi.nombre_producto,
               SUM(vi.cantidad)::numeric AS total_cantidad,
               SUM(vi.subtotal)::numeric AS total_monto
        FROM venta_items vi
        JOIN ventas v ON v.id = vi.venta_id
        WHERE v.created_at BETWEEN $1 AND $2 AND v.estado = 'COMPLETADA'
        GROUP BY vi.producto_id, vi.nombre_producto
        ORDER BY total_monto DESC
        LIMIT 20
      `, [desde, hasta]);

      return successResponse(res, result);
    } catch (e) { next(e); }
  }
);

// GET /reportes/ganancias
router.get('/ganancias', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const desde = req.query.desde as string || new Date(new Date().setDate(1)).toISOString();
      const hasta = req.query.hasta as string || new Date().toISOString();

      const result = await AppDataSource.query(`
        SELECT
          SUM(vi.subtotal)::numeric AS ventas_total,
          SUM(vi.precio_costo * vi.cantidad)::numeric AS costo_total,
          SUM(vi.subtotal - vi.precio_costo * vi.cantidad)::numeric AS ganancia_bruta,
          CASE WHEN SUM(vi.subtotal) > 0
               THEN ROUND(SUM(vi.subtotal - vi.precio_costo * vi.cantidad) / SUM(vi.subtotal) * 100, 2)
               ELSE 0 END AS margen_porcentaje
        FROM venta_items vi
        JOIN ventas v ON v.id = vi.venta_id
        WHERE v.created_at BETWEEN $1 AND $2 AND v.estado = 'COMPLETADA'
      `, [desde, hasta]);

      return successResponse(res, result[0]);
    } catch (e) { next(e); }
  }
);

// GET /reportes/caja-diaria
router.get('/caja-diaria', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const fecha = req.query.fecha as string || new Date().toISOString().split('T')[0];

      const result = await AppDataSource.query(`
        SELECT c.id, c.hora_apertura, c.hora_cierre, c.monto_apertura,
               c.monto_cierre, c.monto_esperado, c.diferencia, c.estado,
               u.nombre_completo as vendedor,
               COUNT(v.id) as total_ventas,
               COALESCE(SUM(v.total),0)::numeric as monto_total
        FROM cajas c
        JOIN usuarios u ON u.id = c.usuario_id
        LEFT JOIN ventas v ON v.caja_id = c.id AND v.estado = 'COMPLETADA'
        WHERE DATE(c.hora_apertura) = $1
        GROUP BY c.id, u.nombre_completo
        ORDER BY c.hora_apertura DESC
      `, [fecha]);

      return successResponse(res, result);
    } catch (e) { next(e); }
  }
);

export default router;
