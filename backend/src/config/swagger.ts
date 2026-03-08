import { Application } from 'express';
import swaggerJSDoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'MiniMarket Pro API',
      version: '1.0.0',
      description: 'API REST para Sistema Inteligente de Gestión de Inventarios para Minimarkets',
      contact: { name: 'MiniMarket Pro', email: 'soporte@minimarket.com' },
    },
    servers: [
      { url: 'http://localhost:3001/api/v1', description: 'Desarrollo' },
      { url: 'https://api.minimarket.com/v1', description: 'Producción' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ['./src/modules/**/*.routes.ts', './src/modules/**/*.controller.ts'],
};

const swaggerSpec = swaggerJSDoc(options);

export function setupSwagger(app: Application): void {
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    explorer: true,
    customSiteTitle: 'MiniMarket Pro — API Docs',
    customCss: `
      .swagger-ui .topbar { background-color: #355872; }
      .swagger-ui .topbar-wrapper img { content: url("data:image/svg+xml,..."); }
    `,
  }));
  app.get('/api/docs.json', (_req, res) => res.json(swaggerSpec));
}
