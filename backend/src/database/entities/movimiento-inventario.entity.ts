import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';
import { Producto } from './producto.entity';
import { Usuario } from './usuario.entity';

@Entity('movimientos_inventario')
export class MovimientoInventario {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'producto_id' })
  producto_id!: string;

  @ManyToOne(() => Producto)
  @JoinColumn({ name: 'producto_id' })
  producto!: Producto;

  @Column({ name: 'variante_id', nullable: true })
  variante_id?: string;

  @Column({ name: 'usuario_id' })
  usuario_id!: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({
    name: 'tipo_movimiento',
    length: 30,
    enum: ['VENTA', 'COMPRA', 'AJUSTE_ENTRADA', 'AJUSTE_SALIDA', 'MERMA', 'DEVOLUCION'],
  })
  tipo_movimiento!: string;

  @Column({ name: 'referencia_id', nullable: true })
  referencia_id?: string;

  @Column({ name: 'referencia_tipo', length: 20, nullable: true })
  referencia_tipo?: string;

  @Column({ name: 'cantidad_cambio', type: 'numeric', precision: 12, scale: 3 })
  cantidad_cambio!: number;

  @Column({ name: 'stock_anterior', type: 'numeric', precision: 12, scale: 3 })
  stock_anterior!: number;

  @Column({ name: 'stock_resultante', type: 'numeric', precision: 12, scale: 3 })
  stock_resultante!: number;

  @Column({ name: 'precio_costo', type: 'numeric', precision: 12, scale: 2, nullable: true })
  precio_costo?: number;

  @Column({ type: 'text', nullable: true })
  observacion?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
