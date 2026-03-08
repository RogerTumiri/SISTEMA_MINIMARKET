import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';
import { Venta } from './venta.entity';

@Entity('pagos')
export class Pago {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'venta_id' })
  venta_id!: string;

  @ManyToOne(() => Venta, (v) => v.pagos)
  @JoinColumn({ name: 'venta_id' })
  venta!: Venta;

  @Column({
    name: 'metodo_pago',
    length: 30,
    enum: ['EFECTIVO', 'TARJETA_DEBITO', 'TARJETA_CREDITO', 'QR', 'OTRO'],
  })
  metodo_pago!: string;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  monto!: number;

  @Column({ length: 100, nullable: true })
  referencia?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
