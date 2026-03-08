import {
  Entity, PrimaryGeneratedColumn, Column,
  ManyToOne, JoinColumn
} from 'typeorm';
import { Compra } from './compra.entity';
import { Producto } from './producto.entity';

@Entity('compra_items')
export class CompraItem {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'compra_id' })
  compra_id!: string;

  @ManyToOne(() => Compra, (c) => c.items)
  @JoinColumn({ name: 'compra_id' })
  compra!: Compra;

  @Column({ name: 'producto_id' })
  producto_id!: string;

  @ManyToOne(() => Producto)
  @JoinColumn({ name: 'producto_id' })
  producto!: Producto;

  @Column({ name: 'variante_id', nullable: true })
  variante_id?: string;

  @Column({ type: 'numeric', precision: 12, scale: 3 })
  cantidad!: number;

  @Column({ name: 'precio_unitario', type: 'numeric', precision: 12, scale: 2 })
  precio_unitario!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  subtotal!: number;
}
