import nodemailer from 'nodemailer';
import { logger } from '@shared/utils/logger';

const transporter = nodemailer.createTransport({
  host:   process.env.SMTP_HOST || 'smtp.gmail.com',
  port:   parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export async function sendPasswordResetEmail(
  to: string,
  resetUrl: string,
  nombre: string
): Promise<void> {
  const html = `
    <!DOCTYPE html>
    <html lang="es">
    <head><meta charset="UTF-8"></head>
    <body style="font-family: Arial, sans-serif; background:#F7F8F0; padding: 40px;">
      <div style="max-width: 480px; margin: auto; background: #fff; border-radius: 12px;
                  padding: 32px; box-shadow: 0 2px 12px rgba(53,88,114,0.12);">
        <div style="text-align:center; margin-bottom: 24px;">
          <h1 style="color:#355872; margin:0; font-size:24px;">🏪 MiniMarket Pro</h1>
        </div>
        <h2 style="color:#1A202C;">Recuperar Contraseña</h2>
        <p style="color:#4A5568;">Hola <strong>${nombre}</strong>,</p>
        <p style="color:#4A5568;">Recibimos una solicitud para restablecer tu contraseña.
           Haz clic en el botón de abajo para continuar. El enlace expira en 30 minutos.</p>
        <div style="text-align:center; margin: 32px 0;">
          <a href="${resetUrl}" style="background:#355872; color:#fff; padding:14px 32px;
             border-radius:8px; text-decoration:none; font-weight:bold; display:inline-block;">
            Restablecer Contraseña
          </a>
        </div>
        <p style="color:#A0AEC0; font-size:13px;">
          Si no solicitaste esto, puedes ignorar este email.<br>
          El enlace expirará en 30 minutos.
        </p>
        <hr style="border-color:#E2E8F0; margin: 24px 0;">
        <p style="color:#A0AEC0; font-size: 12px; text-align: center;">© 2025 MiniMarket Pro</p>
      </div>
    </body>
    </html>
  `;

  try {
    await transporter.sendMail({
      from: `"MiniMarket Pro" <${process.env.SMTP_USER}>`,
      to,
      subject: 'Recuperar contraseña — MiniMarket Pro',
      html,
    });
    logger.info(`Email de reset enviado a ${to}`);
  } catch (err) {
    logger.error(`Error enviando email a ${to}`, err);
    throw new Error('No se pudo enviar el email de recuperación');
  }
}
