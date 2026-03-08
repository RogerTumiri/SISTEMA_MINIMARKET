import { AppDataSource } from '@database/data-source';
import { Caja } from '@database/entities/caja.entity';
import { Venta } from '@database/entities/venta.entity';
import { AppError } from '@shared/utils/AppError';

export class CajasService {
  private cajaRepo  = AppDataSource.getRepository(Caja);
  private ventaRepo = AppDataSource.getRepository(Venta);

  async abrir(userId: string, montoApertura: number, observaciones?: string) {
    const yaAbierta = await this.cajaRepo.findOne({
      where: { usuario_id: userId, estado: 'ABIERTA' },
    });
    if (yaAbierta) throw new AppError('CAJA_ABIERTA', 'Ya tienes una caja abierta', 400);

    const caja = this.cajaRepo.create({
      usuario_id:     userId,
      monto_apertura: montoApertura,
      observaciones,
    });
    return this.cajaRepo.save(caja);
  }

  async cerrar(userId: string, montoCierre: number, observaciones?: string) {
    const caja = await this.cajaRepo.findOne({
      where: { usuario_id: userId, estado: 'ABIERTA' },
    });
    if (!caja) throw new AppError('CAJA_CERRADA', 'No tienes una caja abierta', 400);

    // Calcular totales del turno
    const ventas = await this.ventaRepo.find({
      where: { caja_id: caja.id, estado: 'COMPLETADA' },
    });
    const totalVentas          = ventas.reduce((s, v) => s + Number(v.total), 0);
    const ventasEfectivo       = ventas
      .flatMap(v => v.pagos || [])
      .filter(p => p.metodo_pago === 'EFECTIVO')
      .reduce((s, p) => s + Number(p.monto), 0);
    const montoEsperado = Number(caja.monto_apertura) + ventasEfectivo;
    const diferencia    = montoCierre - montoEsperado;

    Object.assign(caja, {
      estado:        'CERRADA',
      hora_cierre:   new Date(),
      monto_cierre:  montoCierre,
      monto_esperado: montoEsperado,
      diferencia,
      observaciones: observaciones || caja.observaciones,
    });

    await this.cajaRepo.save(caja);
    return {
      caja,
      resumen: {
        total_ventas:          ventas.length,
        monto_total_ventas:    totalVentas,
        monto_apertura:        caja.monto_apertura,
        ventas_en_efectivo:    ventasEfectivo,
        monto_esperado:        montoEsperado,
        monto_cierre:          montoCierre,
        diferencia,
        estado_cuadre:         diferencia === 0 ? 'CORRECTO' : diferencia > 0 ? 'SOBRANTE' : 'FALTANTE',
      },
    };
  }

  async cajaActiva(userId: string) {
    return this.cajaRepo.findOne({ where: { usuario_id: userId, estado: 'ABIERTA' } });
  }

  async historial(page = 1, limit = 25) {
    const [data, total] = await this.cajaRepo.findAndCount({
      relations: ['usuario'],
      order: { created_at: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, meta: { total, page, limit } };
  }
}
