import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn
} from 'typeorm';

@Entity('configuracion_negocio')
export class ConfiguracionNegocio {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 100, unique: true })
  clave!: string;

  @Column({ type: 'text' })
  valor!: string;

  @Column({ type: 'text', nullable: true })
  descripcion?: string;

  @Column({ name: 'updated_at', type: 'timestamptz', default: () => 'NOW()' })
  updated_at!: Date;
}
