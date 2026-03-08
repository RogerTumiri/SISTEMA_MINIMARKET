import { AppDataSource } from '@database/data-source';
import { Venta } from '@database/entities/venta.entity';
import { VentaItem } from '@database/entities/venta-item.entity';
import { Pago } from '@database/entities/pago.entity';
import { Producto } from '@database/entities/producto.entity';
import { MovimientoInventario } from '@database/entities/movimiento-inventario.entity';
import { Caja } from '@database/entities/caja.entity';
import { ConfiguracionNegocio } from '@database/entities/configuracion-negocio.entity';
import { AppError } from '@shared/utils/AppError';
import { IsNull } from 'typeorm';

interface ItemCarrito {
  producto_id: string;
  variante_id?: string;
  cantidad: number;
  descuento_item?: number;
}

interface PagoInput {
  metodo_pago: string;
  monto: number;
  referencia?: string;
}

export class VentasService {
  private ventaRepo = AppDataSource.getRepository(Venta);
  private productoRepo = AppDataSource.getRepository(Producto);
  private cajaRepo = AppDataSource.getRepository(Caja);
  private configRepo = AppDataSource.getRepository(ConfiguracionNegocio);

  async crearVenta(
    items: ItemCarrito[],
    pagos: PagoInput[],
    userId: string,
    descuentoGlobal = 0,
    observaciones?: string
  ) {
    // Verificar caja abierta del usuario
    const caja = await this.cajaRepo.findOne({
      where: { usuario_id: userId, estado: 'ABIERTA' },
    });
    if (!caja) {
      throw new AppError('CAJA_CERRADA', 'Debe abrir la caja antes de registrar ventas', 400);
    }

    // Leer %IVA de configuración
    const configIva = await this.configRepo.findOne({ where: { clave: 'porcentaje_iva' } });
    const pctIva = parseFloat(configIva?.valor || '0');

    return AppDataSource.transaction(async (manager) => {
      let subtotalVenta = 0;
      let impuestoVenta = 0;
      const ventaItems: VentaItem[] = [];

      for (const item of items) {
        const producto = await manager.findOne(Producto, {
          where: { id: item.producto_id, activo: true, deleted_at: IsNull() as any },
        });
        if (!producto) {
          throw new AppError('PRODUCTO_NO_ENCONTRADO', `Producto ${item.producto_id} no encontrado`, 404);
        }
        if (Number(producto.stock_actual) < item.cantidad) {
          throw new AppError(
            'STOCK_INSUFICIENTE',
            `Stock insuficiente para ${producto.nombre}. Disponible: ${producto.stock_actual}`,
            400
          );
        }

        const descItem     = item.descuento_item || 0;
        const precioFinal  = Number(producto.precio_venta) - descItem;
        const subtotalItem = precioFinal * item.cantidad;
        const impuestoItem = producto.aplica_impuesto
          ? subtotalItem * (Number(producto.porcentaje_impuesto) / 100)
          : subtotalItem * (pctIva / 100);

        subtotalVenta += subtotalItem;
        impuestoVenta += impuestoItem;

        // Descontar stock
        const stockAnterior = Number(producto.stock_actual);
        await manager.update(Producto, producto.id, {
          stock_actual: stockAnterior - item.cantidad,
        });

        // Registrar movimiento kardex
        const mov = manager.create(MovimientoInventario, {
          producto_id:     producto.id,
          usuario_id:      userId,
          tipo_movimiento: 'VENTA',
          cantidad_cambio: -item.cantidad,
          stock_anterior:  stockAnterior,
          stock_resultante: stockAnterior - item.cantidad,
          precio_costo:    Number(producto.precio_compra),
          observacion:     'Venta POS',
        });
        await manager.save(MovimientoInventario, mov);

        const ventaItem = manager.create(VentaItem, {
          producto_id:     producto.id,
          variante_id:     item.variante_id,
          nombre_producto: producto.nombre,
          codigo_barras:   producto.codigo_barras,
          cantidad:        item.cantidad,
          precio_unitario: Number(producto.precio_venta),
          precio_costo:    Number(producto.precio_compra),
          descuento_item:  descItem,
          subtotal:        subtotalItem,
          impuesto_item:   impuestoItem,
        });
        ventaItems.push(ventaItem);
      }

      const descuentoMonto = descuentoGlobal > 0 ? subtotalVenta * (descuentoGlobal / 100) : 0;
      const totalVenta = subtotalVenta - descuentoMonto + impuestoVenta;

      // Generar número de recibo
      const count = await manager.count(Venta);
      const numeroRecibo = `REC-${new Date().getFullYear()}-${String(count + 1).padStart(5, '0')}`;

      const venta = manager.create(Venta, {
        caja_id:         caja.id,
        usuario_id:      userId,
        numero_recibo:   numeroRecibo,
        subtotal:        subtotalVenta,
        descuento_monto: descuentoMonto,
        impuesto_monto:  impuestoVenta,
        total:           totalVenta,
        observaciones,
        items: ventaItems,
        pagos: pagos.map(p => ({
          metodo_pago: p.metodo_pago,
          monto:       p.monto,
          referencia:  p.referencia,
        })) as Pago[],
      });

      const saved = await manager.save(Venta, venta);

      // Calcular vuelto (efectivo)
      const pagoEfectivo = pagos.find(p => p.metodo_pago === 'EFECTIVO');
      const vuelto = pagoEfectivo ? Math.max(0, pagoEfectivo.monto - totalVenta) : 0;

      return { ...saved, vuelto };
    });
  }

  async listar(params: { page: number; limit: number; vendedorId?: string; desde?: string; hasta?: string }) {
    const { page = 1, limit = 25, vendedorId, desde, hasta } = params;
    const qb = this.ventaRepo.createQueryBuilder('v')
      .leftJoinAndSelect('v.usuario', 'u')
      .leftJoinAndSelect('v.items', 'i')
      .orderBy('v.created_at', 'DESC');

    if (vendedorId) qb.andWhere('v.usuario_id = :vendedorId', { vendedorId });
    if (desde)      qb.andWhere('v.created_at >= :desde', { desde });
    if (hasta)      qb.andWhere('v.created_at <= :hasta', { hasta });

    const total = await qb.getCount();
    const data  = await qb.skip((page - 1) * limit).take(limit).getMany();
    return { data, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async obtener(id: string) {
    const v = await this.ventaRepo.findOne({
      where: { id },
      relations: ['usuario', 'caja', 'items', 'pagos'],
    });
    if (!v) throw new AppError('VENTA_NO_ENCONTRADA', 'Venta no encontrada', 404);
    return v;
  }

  async anular(id: string, motivo: string, adminId: string) {
    const venta = await this.obtener(id);
    if (venta.estado === 'ANULADA') {
      throw new AppError('VENTA_YA_ANULADA', 'La venta ya está anulada', 400);
    }

    return AppDataSource.transaction(async (manager) => {
      // Restaurar stock de cada ítem
      for (const item of venta.items) {
        const producto = await manager.findOne(Producto, { where: { id: item.producto_id } });
        if (producto) {
          const stockAnterior = Number(producto.stock_actual);
          await manager.update(Producto, producto.id, {
            stock_actual: stockAnterior + Number(item.cantidad),
          });
          await manager.save(MovimientoInventario, manager.create(MovimientoInventario, {
            producto_id:      producto.id,
            usuario_id:       adminId,
            tipo_movimiento:  'DEVOLUCION',
            referencia_id:    venta.id,
            referencia_tipo:  'VENTA',
            cantidad_cambio:  Number(item.cantidad),
            stock_anterior:   stockAnterior,
            stock_resultante: stockAnterior + Number(item.cantidad),
            observacion:      `Anulación venta ${venta.numero_recibo}`,
          }));
        }
      }

      await manager.update(Venta, id, {
        estado:           'ANULADA',
        motivo_anulacion: motivo,
        anulada_por:      adminId,
        anulada_en:       new Date(),
      });

      return { message: 'Venta anulada exitosamente' };
    });
  }
}
