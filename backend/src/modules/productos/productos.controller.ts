import { Request, Response, NextFunction } from 'express';
import { ProductosService } from './productos.service';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import { successResponse, AppError } from '@shared/utils/AppError';
import Joi from 'joi';

const svc = new ProductosService();

const productoSchema = Joi.object({
  codigo_barras:       Joi.string().max(50).optional(),
  nombre:              Joi.string().max(200).required(),
  descripcion:         Joi.string().optional(),
  categoria_id:        Joi.number().integer().optional(),
  proveedor_id:        Joi.string().uuid().optional(),
  unidad_medida_id:    Joi.number().integer().required(),
  precio_compra:       Joi.number().min(0).required(),
  precio_venta:        Joi.number().min(0).required(),
  stock_actual:        Joi.number().min(0).default(0),
  stock_minimo:        Joi.number().min(0).default(5),
  stock_maximo:        Joi.number().min(0).optional(),
  aplica_impuesto:     Joi.boolean().default(false),
  porcentaje_impuesto: Joi.number().min(0).max(100).default(0),
  activo:              Joi.boolean().default(true),
});

export class ProductosController {
  listar = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await svc.listar({
        page:        parseInt(req.query.page as string) || 1,
        limit:       Math.min(parseInt(req.query.limit as string) || 25, 100),
        search:      req.query.search as string,
        categoriaId: req.query.categoriaId ? parseInt(req.query.categoriaId as string) : undefined,
        proveedorId: req.query.proveedorId as string,
        stockBajo:   req.query.stockBajo === 'true',
        activo:      req.query.activo !== 'false',
        orderBy:     req.query.orderBy as string,
        order:       (req.query.order as 'asc' | 'desc') || 'asc',
      });
      return res.json({ success: true, ...result, timestamp: new Date().toISOString() });
    } catch (err) { next(err); }
  };

  buscarBarcode = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await svc.buscarPorBarcode(req.params.codigo);
      return successResponse(res, data);
    } catch (err) { next(err); }
  };

  obtener = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await svc.obtener(req.params.id);
      return successResponse(res, data);
    } catch (err) { next(err); }
  };

  crear = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = productoSchema.validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);
      const data = await svc.crear(value);
      return successResponse(res, data, 'Producto creado', 201);
    } catch (err) { next(err); }
  };

  actualizar = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = productoSchema.fork(
        ['nombre', 'unidad_medida_id', 'precio_compra', 'precio_venta'],
        (s) => s.optional()
      ).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);
      const data = await svc.actualizar(req.params.id, value, req.user!.id);
      return successResponse(res, data, 'Producto actualizado');
    } catch (err) { next(err); }
  };

  eliminar = async (req: Request, res: Response, next: NextFunction) => {
    try {
      await svc.eliminar(req.params.id);
      return successResponse(res, null, 'Producto eliminado');
    } catch (err) { next(err); }
  };

  kardex = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await svc.kardex(
        req.params.id,
        parseInt(req.query.page as string) || 1,
        parseInt(req.query.limit as string) || 50,
      );
      return res.json({ success: true, ...result, timestamp: new Date().toISOString() });
    } catch (err) { next(err); }
  };

  exportar = async (_req: Request, res: Response, next: NextFunction) => {
    try {
      // TODO: Implement Excel export with exceljs
      res.status(501).json({ success: false, error: { code: 'NOT_IMPLEMENTED', message: 'Exportación aún no implementada' } });
    } catch (err) { next(err); }
  };

  importar = async (_req: Request, res: Response, next: NextFunction) => {
    try {
      // TODO: Implement CSV/Excel import
      res.status(501).json({ success: false, error: { code: 'NOT_IMPLEMENTED', message: 'Importación aún no implementada' } });
    } catch (err) { next(err); }
  };
}
