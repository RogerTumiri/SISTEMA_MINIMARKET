import { Router } from 'express';
import { authenticate } from '@shared/middleware/authenticate.middleware';
import { authorize } from '@shared/middleware/authorize.middleware';
import { AppDataSource } from '@database/data-source';
import { Usuario } from '@database/entities/usuario.entity';
import { Rol } from '@database/entities/rol.entity';
import { successResponse, AppError } from '@shared/utils/AppError';
import { AuthRequest } from '@shared/middleware/authenticate.middleware';
import Joi from 'joi';
import bcrypt from 'bcrypt';
import { IsNull } from 'typeorm';
import { Request, Response, NextFunction } from 'express';

const router  = Router();
const repo    = AppDataSource.getRepository(Usuario);
const rolRepo = AppDataSource.getRepository(Rol);

const SALT = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12');

const schema = Joi.object({
  nombre_completo: Joi.string().max(150).required(),
  email:           Joi.string().email().required(),
  username:        Joi.string().min(3).max(50).required(),
  password:        Joi.string().min(8).max(72).required(),
  rol:             Joi.string().valid('ADMINISTRADOR', 'VENDEDOR').required(),
  activo:          Joi.boolean().default(true),
});

// GET /usuarios
router.get('/', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const page  = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 25;
      const [data, total] = await repo.findAndCount({
        where: { deleted_at: IsNull() as any },
        relations: ['rol'],
        order: { created_at: 'DESC' },
        skip: (page - 1) * limit,
        take: limit,
      });
      const users = data.map(u => ({
        id: u.id, nombre_completo: u.nombre_completo, email: u.email,
        username: u.username, rol: u.rol?.nombre, activo: u.activo,
        ultimo_login: u.ultimo_login, created_at: u.created_at,
      }));
      return res.json({ success: true, data: users, meta: { total, page, limit }, timestamp: new Date().toISOString() });
    } catch (e) { next(e); }
  }
);

// POST /usuarios
router.post('/', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = schema.validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);
      const rol = await rolRepo.findOne({ where: { nombre: value.rol } });
      if (!rol) throw new AppError('ROL_NO_ENCONTRADO', 'Rol inválido', 400);
      const hash = await bcrypt.hash(value.password, SALT);
      const u = repo.create({ ...value, password_hash: hash, rol_id: rol.id });
      const saved = await repo.save(u);
      return successResponse(res, { id: saved.id, username: saved.username, rol: rol.nombre }, 'Usuario creado', 201);
    } catch (e) { next(e); }
  }
);

// GET /usuarios/:id
router.get('/:id', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const u = await repo.findOne({ where: { id: req.params.id, deleted_at: IsNull() as any }, relations: ['rol'] });
      if (!u) throw new AppError('NO_ENCONTRADO', 'Usuario no encontrado', 404);
      return successResponse(res, { id: u.id, nombre_completo: u.nombre_completo, email: u.email, username: u.username, rol: u.rol?.nombre, activo: u.activo, ultimo_login: u.ultimo_login });
    } catch (e) { next(e); }
  }
);

// PUT /usuarios/:id
router.put('/:id', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = schema.fork(['password'], s => s.optional()).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);
      const updates: any = { nombre_completo: value.nombre_completo, email: value.email, username: value.username, updated_at: new Date() };
      if (value.password) updates.password_hash = await bcrypt.hash(value.password, SALT);
      if (value.rol) {
        const rol = await rolRepo.findOne({ where: { nombre: value.rol } });
        if (rol) updates.rol_id = rol.id;
      }
      await repo.update(req.params.id, updates);
      return successResponse(res, null, 'Usuario actualizado');
    } catch (e) { next(e); }
  }
);

// PATCH /usuarios/:id/toggle-activo
router.patch('/:id/toggle-activo', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const u = await repo.findOne({ where: { id: req.params.id } });
      if (!u) throw new AppError('NO_ENCONTRADO', 'Usuario no encontrado', 404);
      await repo.update(req.params.id, { activo: !u.activo });
      return successResponse(res, { activo: !u.activo }, `Usuario ${!u.activo ? 'activado' : 'desactivado'}`);
    } catch (e) { next(e); }
  }
);

// POST /usuarios/:id/reset-password
router.post('/:id/reset-password', authenticate, authorize('ADMINISTRADOR'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { error, value } = Joi.object({ newPassword: Joi.string().min(8).required() }).validate(req.body);
      if (error) throw new AppError('VALIDACION', error.message, 400);
      const hash = await bcrypt.hash(value.newPassword, SALT);
      await repo.update(req.params.id, { password_hash: hash, intentos_fallidos: 0, bloqueado_hasta: undefined });
      return successResponse(res, null, 'Contraseña restablecida');
    } catch (e) { next(e); }
  }
);

export default router;
