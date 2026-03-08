import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, OneToMany, JoinColumn
} from 'typeorm';
import { Usuario } from './usuario.entity';
import { VentaItem } from './venta-item.entity';
import { Pago } from './pago.entity';
import { Caja } from './caja.entity';

@Entity('ventas')
export class Venta {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'caja_id' })
  caja_id!: string;

  @ManyToOne(() => Caja)
  @JoinColumn({ name: 'caja_id' })
  caja!: Caja;

  @Column({ name: 'usuario_id' })
  usuario_id!: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ name: 'numero_recibo', length: 30, unique: true })
  numero_recibo!: string;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  subtotal!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  descuento_monto!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  impuesto_monto!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  total!: number;

  @Column({
    length: 20,
    default: 'COMPLETADA',
    enum: ['COMPLETADA', 'ANULADA'],
  })
  estado!: string;

  @Column({ type: 'text', nullable: true })
  motivo_anulacion?: string;

  @Column({ name: 'anulada_por', nullable: true })
  anulada_por?: string;

  @Column({ name: 'anulada_en', type: 'timestamptz', nullable: true })
  anulada_en?: Date;

  @Column({ type: 'text', nullable: true })
  observaciones?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @OneToMany(() => VentaItem, (item) => item.venta, { cascade: true, eager: true })
  items!: VentaItem[];

  @OneToMany(() => Pago, (p) => p.venta, { cascade: true, eager: true })
  pagos!: Pago[];
}
