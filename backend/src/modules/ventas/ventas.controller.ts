import { Request, Response, NextFunction } from 'express';
import { VentasService } from './ventas.service';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import { successResponse, AppError } from '@shared/utils/AppError';
import Joi from 'joi';

const svc = new VentasService();

const ventaSchema = Joi.object({
  items: Joi.array().items(Joi.object({
    producto_id:   Joi.string().uuid().required(),
    variante_id:   Joi.string().uuid().optional(),
    cantidad:      Joi.number().positive().required(),
    descuento_item: Joi.number().min(0).default(0),
  })).min(1).required(),
  pagos: Joi.array().items(Joi.object({
    metodo_pago: Joi.string().valid('EFECTIVO','TARJETA_DEBITO','TARJETA_CREDITO','QR','OTRO').required(),
    monto:       Joi.number().positive().required(),
    referencia:  Joi.string().optional(),
  })).min(1).required(),
  descuento_global: Joi.number().min(0).max(100).default(0),
  observaciones:    Joi.string().optional(),
});

export class VentasController {
  crear = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = ventaSchema.validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const venta = await svc.crearVenta(
        value.items,
        value.pagos,
        req.user!.id,
        value.descuento_global,
        value.observaciones
      );

      // Emit WebSocket event
      const io = req.app.get('io');
      if (io) {
        io.emit('venta.nueva', {
          venta_id:   venta.id,
          total:      venta.total,
          vendedor:   req.user!.username,
          timestamp:  venta.created_at,
        });
      }

      return successResponse(res, venta, 'Venta registrada exitosamente', 201);
    } catch (err) { next(err); }
  };

  listar = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await svc.listar({
        page:       parseInt(req.query.page as string) || 1,
        limit:      Math.min(parseInt(req.query.limit as string) || 25, 100),
        vendedorId: req.query.vendedor_id as string,
        desde:      req.query.desde as string,
        hasta:      req.query.hasta as string,
      });
      return res.json({ success: true, ...result, timestamp: new Date().toISOString() });
    } catch (err) { next(err); }
  };

  obtener = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await svc.obtener(req.params.id);
      return successResponse(res, data);
    } catch (err) { next(err); }
  };

  anular = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({
        motivo: Joi.string().min(5).required(),
      }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);

      const result = await svc.anular(req.params.id, value.motivo, req.user!.id);
      return successResponse(res, result, 'Venta anulada');
    } catch (err) { next(err); }
  };

  recibo = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const venta = await svc.obtener(req.params.id);
      const format = req.query.format || 'json';

      if (format === 'json') {
        return successResponse(res, venta);
      }

      // PDF generation
      const PDFDocument = require('pdfkit');
      const doc = new PDFDocument({ size: [226, 700], margin: 10 }); // 80mm wide
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `inline; filename=recibo-${venta.numero_recibo}.pdf`);
      doc.pipe(res);

      doc.fontSize(10).font('Helvetica-Bold').text('MI MINIMARKET', { align: 'center' });
      doc.fontSize(8).font('Helvetica')
        .text('Av. Siempre Viva 742', { align: 'center' })
        .text(`Recibo: ${venta.numero_recibo}`, { align: 'center' })
        .text(`Fecha: ${new Date(venta.created_at).toLocaleString('es-BO')}`, { align: 'center' });

      doc.moveDown(0.5).dash(1, { space: 2 }).moveTo(doc.x, doc.y).lineTo(220, doc.y).stroke().undash();
      doc.fontSize(8).font('Helvetica');

      for (const item of venta.items) {
        doc.text(`${item.nombre_producto}`)
           .text(`  ${item.cantidad} x Bs.${Number(item.precio_unitario).toFixed(2)} = Bs.${Number(item.subtotal).toFixed(2)}`);
      }

      doc.moveDown(0.5).dash(1, { space: 2 }).moveTo(doc.x, doc.y).lineTo(220, doc.y).stroke().undash();
      doc.text(`Subtotal: Bs. ${Number(venta.subtotal).toFixed(2)}`);
      if (Number(venta.descuento_monto) > 0) {
        doc.text(`Descuento: -Bs. ${Number(venta.descuento_monto).toFixed(2)}`);
      }
      doc.text(`Impuesto: Bs. ${Number(venta.impuesto_monto).toFixed(2)}`);
      doc.font('Helvetica-Bold').text(`TOTAL: Bs. ${Number(venta.total).toFixed(2)}`);
      doc.font('Helvetica');
      for (const pago of venta.pagos) {
        doc.text(`${pago.metodo_pago}: Bs. ${Number(pago.monto).toFixed(2)}`);
      }
      doc.moveDown().text('¡Gracias por su compra!', { align: 'center' });
      doc.end();
    } catch (err) { next(err); }
  };
}
