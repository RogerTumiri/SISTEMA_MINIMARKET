import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('unidades_medida')
export class UnidadMedida {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 50 })
  nombre!: string;

  @Column({ length: 10 })
  simbolo!: string;
}
