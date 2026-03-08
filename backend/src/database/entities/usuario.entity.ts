import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, DeleteDateColumn, ManyToOne, OneToMany, JoinColumn
} from 'typeorm';
import { Rol } from './rol.entity';

@Entity('usuarios')
export class Usuario {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'rol_id' })
  rol_id!: number;

  @ManyToOne(() => Rol, { eager: true })
  @JoinColumn({ name: 'rol_id' })
  rol!: Rol;

  @Column({ length: 150 })
  nombre_completo!: string;

  @Column({ length: 150, unique: true })
  email!: string;

  @Column({ length: 50, unique: true })
  username!: string;

  @Column({ length: 255 })
  password_hash!: string;

  @Column({ default: true })
  activo!: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  ultimo_login?: Date;

  @Column({ type: 'smallint', default: 0 })
  intentos_fallidos!: number;

  @Column({ type: 'timestamptz', nullable: true })
  bloqueado_hasta?: Date;

  @Column({ length: 255, nullable: true })
  reset_token?: string;

  @Column({ type: 'timestamptz', nullable: true })
  reset_token_expira?: Date;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;

  @DeleteDateColumn({ type: 'timestamptz' })
  deleted_at?: Date;
}
