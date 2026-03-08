import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('roles')
export class Rol {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 50, unique: true })
  nombre!: string;

  @Column({ type: 'text', nullable: true })
  descripcion?: string;

  @Column({ default: true })
  activo!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
