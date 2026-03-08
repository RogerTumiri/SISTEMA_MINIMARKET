import { AppDataSource } from '@database/data-source';
import { Usuario } from '@database/entities/usuario.entity';
import { RefreshToken } from '@database/entities/refresh-token.entity';
import {
  signAccessToken, signRefreshToken,
  verifyRefreshToken, getTokenExpirationSeconds
} from '@config/jwt';
import {
  addToBlacklist, isBlacklisted,
  storeRefreshToken, deleteRefreshToken
} from '@config/redis';
import { sendPasswordResetEmail } from '@config/mailer';
import { AppError } from '@shared/utils/AppError';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

const SALT_ROUNDS   = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12');
const MAX_INTENTOS  = 5;
const BLOQUEO_MIN   = 15;

export class AuthService {
  private userRepo  = AppDataSource.getRepository(Usuario);
  private tokenRepo = AppDataSource.getRepository(RefreshToken);

  // ─── Login ────────────────────────────────────────────────
  async login(username: string, password: string) {
    const user = await this.userRepo.findOne({
      where: [{ username }, { email: username }],
      relations: ['rol'],
    });

    if (!user) {
      throw new AppError('CREDENCIALES_INVALIDAS', 'Usuario o contraseña incorrectos', 401);
    }

    // Verificar bloqueo
    if (user.bloqueado_hasta && user.bloqueado_hasta > new Date()) {
      const segsRestantes = Math.ceil(
        (user.bloqueado_hasta.getTime() - Date.now()) / 1000
      );
      throw new AppError(
        'CUENTA_BLOQUEADA',
        `Cuenta bloqueada. Intente en ${Math.ceil(segsRestantes / 60)} minutos.`,
        423,
        { bloqueado_por_segundos: segsRestantes }
      );
    }

    if (!user.activo) {
      throw new AppError('CUENTA_INACTIVA', 'La cuenta está desactivada', 403);
    }

    const passwordOk = await bcrypt.compare(password, user.password_hash);
    if (!passwordOk) {
      // Incrementar intentos fallidos
      user.intentos_fallidos += 1;
      if (user.intentos_fallidos >= MAX_INTENTOS) {
        user.bloqueado_hasta = new Date(Date.now() + BLOQUEO_MIN * 60 * 1000);
        user.intentos_fallidos = 0;
      }
      await this.userRepo.save(user);
      throw new AppError('CREDENCIALES_INVALIDAS', 'Usuario o contraseña incorrectos', 401);
    }

    // Reset intentos fallidos + actualizar ultimo_login
    user.intentos_fallidos = 0;
    user.bloqueado_hasta   = undefined as any;
    user.ultimo_login      = new Date();
    await this.userRepo.save(user);

    // Generar tokens
    const payload = { sub: user.id, username: user.username, rol: user.rol.nombre };
    const accessToken  = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    // Guardar refresh token en DB y Redis
    const rt = this.tokenRepo.create({
      usuario_id: user.id,
      token:      refreshToken,
      expira_en:  new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });
    await this.tokenRepo.save(rt);
    await storeRefreshToken(user.id, refreshToken, 7 * 24 * 3600);

    return {
      accessToken,
      refreshToken,
      expiresIn: 28800,
      usuario: {
        id:             user.id,
        nombre_completo: user.nombre_completo,
        username:        user.username,
        email:           user.email,
        rol:             user.rol.nombre,
      },
    };
  }

  // ─── Refresh Token ────────────────────────────────────────
  async refresh(refreshToken: string) {
    let payload: any;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw new AppError('TOKEN_INVALIDO', 'Refresh token inválido o expirado', 401);
    }

    // Verificar en DB
    const rt = await this.tokenRepo.findOne({
      where: { token: refreshToken, revocado: false },
    });
    if (!rt) throw new AppError('TOKEN_INVALIDO', 'Refresh token no encontrado', 401);

    const user = await this.userRepo.findOne({
      where: { id: payload.sub },
      relations: ['rol'],
    });
    if (!user || !user.activo) {
      throw new AppError('CUENTA_INACTIVA', 'Cuenta inactiva', 403);
    }

    // Rotar tokens
    rt.revocado = true;
    await this.tokenRepo.save(rt);

    const newPayload = { sub: user.id, username: user.username, rol: user.rol.nombre };
    const newAccess  = signAccessToken(newPayload);
    const newRefresh = signRefreshToken(newPayload);

    const newRt = this.tokenRepo.create({
      usuario_id: user.id,
      token:      newRefresh,
      expira_en:  new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });
    await this.tokenRepo.save(newRt);
    await storeRefreshToken(user.id, newRefresh, 7 * 24 * 3600);

    return { accessToken: newAccess, refreshToken: newRefresh, expiresIn: 28800 };
  }

  // ─── Logout ───────────────────────────────────────────────
  async logout(accessToken: string, userId: string) {
    const ttl = getTokenExpirationSeconds(accessToken);
    if (ttl > 0) await addToBlacklist(accessToken, ttl);

    await this.tokenRepo.update({ usuario_id: userId, revocado: false }, { revocado: true });
    await deleteRefreshToken(userId);
  }

  // ─── Forgot Password ──────────────────────────────────────
  async forgotPassword(email: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    // No revelar si el email existe (previene user enumeration)
    if (!user) return;

    const token = uuidv4();
    user.reset_token        = await bcrypt.hash(token, 10);
    user.reset_token_expira = new Date(Date.now() + 30 * 60 * 1000);
    await this.userRepo.save(user);

    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}&id=${user.id}`;
    await sendPasswordResetEmail(user.email, resetUrl, user.nombre_completo).catch(() => {});
  }

  // ─── Reset Password ───────────────────────────────────────
  async resetPassword(userId: string, token: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user?.reset_token || !user.reset_token_expira) {
      throw new AppError('TOKEN_INVALIDO', 'Token inválido o expirado', 400);
    }
    if (user.reset_token_expira < new Date()) {
      throw new AppError('TOKEN_EXPIRADO', 'El token ha expirado', 400);
    }

    const tokenOk = await bcrypt.compare(token, user.reset_token);
    if (!tokenOk) throw new AppError('TOKEN_INVALIDO', 'Token inválido', 400);

    user.password_hash       = await bcrypt.hash(newPassword, SALT_ROUNDS);
    user.reset_token         = undefined as any;
    user.reset_token_expira  = undefined as any;
    user.intentos_fallidos   = 0;
    user.bloqueado_hasta     = undefined as any;
    user.updated_at          = new Date();
    await this.userRepo.save(user);
  }

  // ─── Change Password ──────────────────────────────────────
  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new AppError('NO_ENCONTRADO', 'Usuario no encontrado', 404);

    const ok = await bcrypt.compare(currentPassword, user.password_hash);
    if (!ok) throw new AppError('CREDENCIALES_INVALIDAS', 'Contraseña actual incorrecta', 400);

    user.password_hash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    user.updated_at    = new Date();
    await this.userRepo.save(user);
  }

  // ─── Me ───────────────────────────────────────────────────
  async me(userId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['rol'],
    });
    if (!user) throw new AppError('NO_ENCONTRADO', 'Usuario no encontrado', 404);

    return {
      id:             user.id,
      nombre_completo: user.nombre_completo,
      username:        user.username,
      email:           user.email,
      rol:             user.rol.nombre,
      ultimo_login:    user.ultimo_login,
      created_at:      user.created_at,
    };
  }
}
