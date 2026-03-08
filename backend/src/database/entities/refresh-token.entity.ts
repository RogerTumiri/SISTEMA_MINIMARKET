import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn
} from 'typeorm';
import { Usuario } from './usuario.entity';

@Entity('refresh_tokens')
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'usuario_id' })
  usuario_id!: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ length: 512, unique: true })
  token!: string;

  @Column({ type: 'timestamptz' })
  expira_en!: Date;

  @Column({ default: false })
  revocado!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
