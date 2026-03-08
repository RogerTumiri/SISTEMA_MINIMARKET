import { AppDataSource } from '@database/data-source';
import { Producto } from '@database/entities/producto.entity';
import { MovimientoInventario } from '@database/entities/movimiento-inventario.entity';
import { AppError } from '@shared/utils/AppError';
import { Like, IsNull, Not } from 'typeorm';

interface ProductoFilterParams {
  page?: number;
  limit?: number;
  search?: string;
  categoriaId?: number;
  proveedorId?: string;
  stockBajo?: boolean;
  activo?: boolean;
  orderBy?: string;
  order?: 'asc' | 'desc';
}

export class ProductosService {
  private repo = AppDataSource.getRepository(Producto);
  private movRepo = AppDataSource.getRepository(MovimientoInventario);

  async listar(params: ProductoFilterParams) {
    const {
      page = 1, limit = 25, search, categoriaId, proveedorId,
      stockBajo, activo = true, orderBy = 'nombre', order = 'asc',
    } = params;

    const qb = this.repo.createQueryBuilder('p')
      .leftJoinAndSelect('p.categoria', 'cat')
      .leftJoinAndSelect('p.proveedor', 'prov')
      .innerJoinAndSelect('p.unidad_medida', 'um')
      .where('p.deleted_at IS NULL')
      .andWhere('p.activo = :activo', { activo });

    if (search) {
      qb.andWhere('(p.nombre ILIKE :s OR p.codigo_barras ILIKE :s)', { s: `%${search}%` });
    }
    if (categoriaId) qb.andWhere('p.categoria_id = :categoriaId', { categoriaId });
    if (proveedorId)  qb.andWhere('p.proveedor_id = :proveedorId', { proveedorId });
    if (stockBajo)    qb.andWhere('p.stock_actual <= p.stock_minimo');

    const allowedOrder = ['nombre', 'precio_venta', 'stock_actual', 'created_at'];
    const safeOrder = allowedOrder.includes(orderBy) ? `p.${orderBy}` : 'p.nombre';
    qb.orderBy(safeOrder, order.toUpperCase() as 'ASC' | 'DESC');

    const total = await qb.getCount();
    const data = await qb.skip((page - 1) * limit).take(limit).getMany();

    return {
      data: data.map(p => this.toDto(p)),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page * limit < total,
        hasPrevPage: page > 1,
      },
    };
  }

  async buscarPorBarcode(codigo: string) {
    const p = await this.repo.findOne({
      where: { codigo_barras: codigo, activo: true, deleted_at: IsNull() as any },
    });
    if (!p) throw new AppError('PRODUCTO_NO_ENCONTRADO', `Código ${codigo} no registrado`, 404);
    return {
      id: p.id,
      nombre: p.nombre,
      codigo_barras: p.codigo_barras,
      precio_venta: Number(p.precio_venta),
      precio_costo: Number(p.precio_compra),
      stock_actual: Number(p.stock_actual),
      aplica_impuesto: p.aplica_impuesto,
      porcentaje_impuesto: Number(p.porcentaje_impuesto),
      unidad_medida: p.unidad_medida?.simbolo,
      imagen_url: p.imagen_url,
      estado_stock: p.estado_stock,
    };
  }

  async obtener(id: string) {
    const p = await this.repo.findOne({
      where: { id, deleted_at: IsNull() as any },
      relations: ['categoria', 'proveedor', 'unidad_medida'],
    });
    if (!p) throw new AppError('PRODUCTO_NO_ENCONTRADO', 'Producto no encontrado', 404);
    return this.toDto(p);
  }

  async crear(data: Partial<Producto>) {
    const p = this.repo.create(data);
    return this.toDto(await this.repo.save(p));
  }

  async actualizar(id: string, data: Partial<Producto>, usuarioId: string) {
    const p = await this.obtenerEntidad(id);
    Object.assign(p, data, { updated_at: new Date() });
    return this.toDto(await this.repo.save(p));
  }

  async eliminar(id: string) {
    const p = await this.obtenerEntidad(id);
    await this.repo.softDelete(id);
  }

  async kardex(productoId: string, page = 1, limit = 50) {
    const [data, total] = await this.movRepo.findAndCount({
      where: { producto_id: productoId },
      relations: ['usuario'],
      order: { created_at: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, meta: { total, page, limit } };
  }

  private async obtenerEntidad(id: string): Promise<Producto> {
    const p = await this.repo.findOne({ where: { id, deleted_at: IsNull() as any } });
    if (!p) throw new AppError('PRODUCTO_NO_ENCONTRADO', 'Producto no encontrado', 404);
    return p;
  }

  private toDto(p: Producto) {
    return {
      id:                   p.id,
      codigo_barras:        p.codigo_barras,
      nombre:               p.nombre,
      descripcion:          p.descripcion,
      categoria:            p.categoria ? { id: p.categoria.id, nombre: p.categoria.nombre } : null,
      proveedor:            p.proveedor ? { id: p.proveedor.id, nombre_empresa: p.proveedor.nombre_empresa } : null,
      unidad_medida:        p.unidad_medida,
      precio_compra:        Number(p.precio_compra),
      precio_venta:         Number(p.precio_venta),
      margen_ganancia:      Number(p.margen_ganancia || 0),
      stock_actual:         Number(p.stock_actual),
      stock_minimo:         Number(p.stock_minimo),
      stock_maximo:         p.stock_maximo ? Number(p.stock_maximo) : null,
      estado_stock:         p.estado_stock,
      aplica_impuesto:      p.aplica_impuesto,
      porcentaje_impuesto:  Number(p.porcentaje_impuesto),
      imagen_url:           p.imagen_url,
      activo:               p.activo,
      created_at:           p.created_at,
      updated_at:           p.updated_at,
    };
  }
}
