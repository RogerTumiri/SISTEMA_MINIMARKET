import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { AuthController } from './auth.controller';
import { authenticate } from '@shared/middleware/authenticate.middleware';

const router = Router();
const ctrl   = new AuthController();

// Rate limiting: 10 intentos por minuto por IP en login
const loginLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: {
    success: false,
    error: {
      code:    'DEMASIADAS_PETICIONES',
      message: 'Demasiados intentos. Espere un minuto.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Iniciar sesión
 *     tags: [Auth]
 */
router.post('/login',           loginLimiter,   ctrl.login);
router.post('/logout',          authenticate,   ctrl.logout);
router.post('/refresh',                         ctrl.refresh);
router.post('/forgot-password',                 ctrl.forgotPassword);
router.post('/reset-password',                  ctrl.resetPassword);
router.get('/me',               authenticate,   ctrl.me);
router.patch('/change-password', authenticate,  ctrl.changePassword);

export default router;
