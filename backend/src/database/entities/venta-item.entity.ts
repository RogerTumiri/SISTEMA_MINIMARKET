import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';
import { Venta } from './venta.entity';
import { Producto } from './producto.entity';

@Entity('venta_items')
export class VentaItem {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'venta_id' })
  venta_id!: string;

  @ManyToOne(() => Venta, (v) => v.items)
  @JoinColumn({ name: 'venta_id' })
  venta!: Venta;

  @Column({ name: 'producto_id' })
  producto_id!: string;

  @ManyToOne(() => Producto)
  @JoinColumn({ name: 'producto_id' })
  producto!: Producto;

  @Column({ name: 'variante_id', nullable: true })
  variante_id?: string;

  @Column({ name: 'nombre_producto', length: 200 })
  nombre_producto!: string;

  @Column({ name: 'codigo_barras', length: 50, nullable: true })
  codigo_barras?: string;

  @Column({ type: 'numeric', precision: 12, scale: 3 })
  cantidad!: number;

  @Column({ name: 'precio_unitario', type: 'numeric', precision: 12, scale: 2 })
  precio_unitario!: number;

  @Column({ name: 'precio_costo', type: 'numeric', precision: 12, scale: 2 })
  precio_costo!: number;

  @Column({ name: 'descuento_item', type: 'numeric', precision: 12, scale: 2, default: 0 })
  descuento_item!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  subtotal!: number;

  @Column({ name: 'impuesto_item', type: 'numeric', precision: 12, scale: 2, default: 0 })
  impuesto_item!: number;
}
