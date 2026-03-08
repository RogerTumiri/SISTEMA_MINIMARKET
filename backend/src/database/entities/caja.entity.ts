import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';
import { Usuario } from './usuario.entity';

@Entity('cajas')
export class Caja {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'usuario_id' })
  usuario_id!: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ name: 'monto_apertura', type: 'numeric', precision: 12, scale: 2, default: 0 })
  monto_apertura!: number;

  @Column({ name: 'monto_cierre', type: 'numeric', precision: 12, scale: 2, nullable: true })
  monto_cierre?: number;

  @Column({ name: 'monto_esperado', type: 'numeric', precision: 12, scale: 2, nullable: true })
  monto_esperado?: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, nullable: true })
  diferencia?: number;

  @Column({ name: 'hora_apertura', type: 'timestamptz', default: () => 'NOW()' })
  hora_apertura!: Date;

  @Column({ name: 'hora_cierre', type: 'timestamptz', nullable: true })
  hora_cierre?: Date;

  @Column({ length: 20, default: 'ABIERTA', enum: ['ABIERTA', 'CERRADA'] })
  estado!: string;

  @Column({ type: 'text', nullable: true })
  observaciones?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
