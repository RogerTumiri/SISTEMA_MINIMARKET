import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, DeleteDateColumn
} from 'typeorm';

@Entity('proveedores')
export class Proveedor {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 150 })
  nombre_empresa!: string;

  @Column({ length: 20, nullable: true })
  nit_ruc?: string;

  @Column({ length: 100, nullable: true })
  contacto?: string;

  @Column({ length: 20, nullable: true })
  telefono?: string;

  @Column({ length: 150, nullable: true })
  email?: string;

  @Column({ type: 'text', nullable: true })
  direccion?: string;

  @Column({ default: true })
  activo!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;

  @DeleteDateColumn({ type: 'timestamptz' })
  deleted_at?: Date;
}
