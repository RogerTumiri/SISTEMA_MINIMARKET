import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';

@Entity('categorias')
export class Categoria {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 100 })
  nombre!: string;

  @Column({ type: 'text', nullable: true })
  descripcion?: string;

  @Column({ nullable: true })
  parent_id?: number;

  @ManyToOne(() => Categoria, { nullable: true })
  @JoinColumn({ name: 'parent_id' })
  padre?: Categoria;

  @Column({ length: 100, nullable: true })
  icono?: string;

  @Column({ length: 7, nullable: true })
  color_hex?: string;

  @Column({ default: true })
  activo!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
