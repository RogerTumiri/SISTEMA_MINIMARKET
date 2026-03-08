import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, OneToMany, JoinColumn
} from 'typeorm';
import { Usuario } from './usuario.entity';
import { Proveedor } from './proveedor.entity';
import { CompraItem } from './compra-item.entity';

@Entity('compras')
export class Compra {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'proveedor_id', nullable: true })
  proveedor_id?: string;

  @ManyToOne(() => Proveedor, { nullable: true })
  @JoinColumn({ name: 'proveedor_id' })
  proveedor?: Proveedor;

  @Column({ name: 'usuario_id' })
  usuario_id!: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ name: 'numero_factura', length: 50, nullable: true })
  numero_factura?: string;

  @Column({ name: 'fecha_compra', type: 'date', default: () => 'CURRENT_DATE' })
  fecha_compra!: string;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  subtotal!: number;

  @Column({ name: 'impuesto_monto', type: 'numeric', precision: 12, scale: 2, default: 0 })
  impuesto_monto!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  total!: number;

  @Column({ length: 20, default: 'CONFIRMADA', enum: ['BORRADOR', 'CONFIRMADA', 'ANULADA'] })
  estado!: string;

  @Column({ name: 'motivo_anulacion', type: 'text', nullable: true })
  motivo_anulacion?: string;

  @Column({ type: 'text', nullable: true })
  observaciones?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @OneToMany(() => CompraItem, (ci) => ci.compra, { cascade: true, eager: true })
  items!: CompraItem[];
}
