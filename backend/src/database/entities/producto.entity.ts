import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, DeleteDateColumn,
  ManyToOne, JoinColumn
} from 'typeorm';
import { Categoria } from './categoria.entity';
import { Proveedor } from './proveedor.entity';
import { UnidadMedida } from './unidad-medida.entity';

@Entity('productos')
export class Producto {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'categoria_id', nullable: true })
  categoria_id?: number;

  @ManyToOne(() => Categoria, { nullable: true, eager: false })
  @JoinColumn({ name: 'categoria_id' })
  categoria?: Categoria;

  @Column({ name: 'proveedor_id', nullable: true })
  proveedor_id?: string;

  @ManyToOne(() => Proveedor, { nullable: true, eager: false })
  @JoinColumn({ name: 'proveedor_id' })
  proveedor?: Proveedor;

  @Column({ name: 'unidad_medida_id' })
  unidad_medida_id!: number;

  @ManyToOne(() => UnidadMedida, { eager: true })
  @JoinColumn({ name: 'unidad_medida_id' })
  unidad_medida!: UnidadMedida;

  @Column({ length: 50, unique: true, nullable: true })
  codigo_barras?: string;

  @Column({ length: 200 })
  nombre!: string;

  @Column({ type: 'text', nullable: true })
  descripcion?: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  precio_compra!: number;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  precio_venta!: number;

  // margen_ganancia es columna generada, la leemos pero no escribimos
  @Column({ type: 'numeric', precision: 5, scale: 2, insert: false, update: false, nullable: true })
  margen_ganancia?: number;

  @Column({ type: 'numeric', precision: 12, scale: 3, default: 0 })
  stock_actual!: number;

  @Column({ type: 'numeric', precision: 12, scale: 3, default: 5 })
  stock_minimo!: number;

  @Column({ type: 'numeric', precision: 12, scale: 3, nullable: true })
  stock_maximo?: number;

  @Column({ length: 500, nullable: true })
  imagen_url?: string;

  @Column({ default: false })
  aplica_impuesto!: boolean;

  @Column({ type: 'numeric', precision: 5, scale: 2, default: 0 })
  porcentaje_impuesto!: number;

  @Column({ default: true })
  activo!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;

  @DeleteDateColumn({ type: 'timestamptz' })
  deleted_at?: Date;

  // Virtual: calculado en app
  get estado_stock(): string {
    if (this.stock_actual <= 0) return 'SIN_STOCK';
    if (this.stock_actual <= this.stock_minimo) return 'CRITICO';
    if (this.stock_actual <= 2 * this.stock_minimo) return 'BAJO';
    return 'NORMAL';
  }
}
