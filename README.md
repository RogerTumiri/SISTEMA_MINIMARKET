# MiniMarket Pro — Sistema de Gestión de Minimarkets

Sistema integral para la gestión de un minimarket, desarrollado con **Flutter** (frontend), **Node.js + Express + TypeScript** (backend) y **PostgreSQL** (base de datos).

---

##  Descripción del Proyecto

MiniMarket Pro es un sistema diseñado para administrar las operaciones diarias de un minimarket: desde el registro de productos, la gestión de inventarios, hasta el punto de venta (POS) y la generación de reportes.

---

##  Funcionalidades Implementadas

###  Autenticación y Seguridad
- Inicio de sesión con usuario y contraseña
- Manejo de tokens JWT con refresh automático
- Protección de rutas según rol (Administrador / Vendedor)
- Bloqueo de cuenta tras intentos fallidos

###  Gestión de Productos
- Registro, edición y eliminación de productos
- Asignación de categorías, proveedores y unidades de medida
- Control de precios de compra y venta con margen de ganancia
- Código de barras para cada producto
- Manejo de impuestos por producto
- Stock mínimo y máximo configurable

###  Punto de Venta (POS)
- **Apertura y cierre de caja** con monto de apertura
- Búsqueda de productos por nombre o código de barras
- Carrito de compras con actualización de cantidades
- Cálculo automático de subtotal, impuestos y total
- Métodos de pago: Efectivo, Tarjeta Débito, Tarjeta Crédito, QR
- Cálculo de vuelto en pagos en efectivo
- Generación automática de número de recibo
- Arqueo de caja al cierre (monto esperado vs. real)

###  Dashboard
- Resumen de ventas del día
- Indicadores clave (KPIs): ventas totales, productos, ingresos
- Visualización rápida del estado del negocio

###  Historial de Ventas
- Listado de todas las ventas realizadas
- Filtros por fecha y vendedor
- Detalle de cada venta con sus ítems
- Anulación de ventas (solo administrador) con restauración de stock

###  Inventario
- Visualización del stock actual de todos los productos
- Registro de movimientos de inventario (entradas, salidas, ajustes)
- Alertas de stock bajo

###  Gestión de Usuarios (Admin)
- Crear, editar y desactivar usuarios
- Asignación de roles (Administrador, Vendedor)

###  Reportes
- Reporte de ventas por período
- Reportes básicos del sistema

###  Configuración
- Configuración de datos del negocio (nombre, dirección, NIT)

---

##  Funcionalidades en Desarrollo

| Módulo | Estado | Descripción |
|--------|--------|-------------|
| Gestión de Compras | 🔄 En proceso | Registro de compras a proveedores |
| Gestión de Proveedores | 🔄 En proceso | CRUD completo de proveedores |
| Reportes Avanzados | 🔄 En proceso | Exportación a PDF y Excel |
| Impresión de Recibos | 🔄 En proceso | Generación e impresión de tickets |
| Notificaciones en Tiempo Real | 🔄 En proceso | Alertas via WebSocket |
| Recuperación de Contraseña | 🔄 En proceso | Envío de email para reset |

---

##  Tecnologías Utilizadas

| Componente | Tecnología |
|------------|-----------|
| **Frontend** | Flutter 3.x (Dart) |
| **Backend** | Node.js + Express + TypeScript |
| **Base de Datos** | PostgreSQL 15 |
| **ORM** | TypeORM |
| **Autenticación** | JWT (JSON Web Tokens) |
| **State Management** | Riverpod |
| **Navegación** | GoRouter |
| **HTTP Client** | Dio |

---

##  Requisitos Previos

Antes de ejecutar el proyecto, asegúrese de tener instalado:

1. **Node.js** v18 o superior — [Descargar](https://nodejs.org/)
2. **PostgreSQL** 15 o superior — [Descargar](https://www.postgresql.org/download/)
3. **Flutter SDK** 3.3+ — [Descargar](https://docs.flutter.dev/get-started/install)
4. **Git** — [Descargar](https://git-scm.com/)
5. **Google Chrome** (para ejecutar Flutter Web)

---

##  Inicio Rápido

### Paso 1: Clonar el repositorio
```bash
git clone <URL_DEL_REPOSITORIO>
cd minimarket-system
```

### Paso 2: Configurar PostgreSQL
Asegúrese de que PostgreSQL esté corriendo en `localhost:5432` con el usuario `postgres`.

### Paso 3: Configurar variables de entorno
```bash
# Copiar el archivo de ejemplo
copy .env.example backend\.env
```
Edite `backend\.env` y configure la contraseña de su PostgreSQL en `DB_PASSWORD`.

### Paso 4: Ejecutar el script de inicio (Windows)
```bash
# Doble clic en iniciar-sistema.bat o ejecutar desde terminal:
iniciar-sistema.bat
```
Este script automáticamente:
- Instala las dependencias del backend (`npm install`)
- Crea la base de datos y aplica el esquema
- Crea el usuario administrador
- Inicia el servidor backend en el puerto 3001

### Paso 5: Iniciar el Frontend
En otra terminal:
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

###  Credenciales de Acceso
| Campo | Valor |
|-------|-------|
| **Usuario** | `admin` |
| **Contraseña** | `Admin123!` |
| **Email** | `admin@minimarket.com` |

---

##  Estructura del Proyecto

```
minimarket-system/
├── backend/                    # API REST (Node.js + TypeScript)
│   ├── src/
│   │   ├── config/            # Configuraciones (Redis, Swagger)
│   │   ├── database/          # Entidades, migraciones, data-source
│   │   ├── modules/           # Módulos del sistema
│   │   │   ├── auth/          # Autenticación
│   │   │   ├── productos/     # CRUD de productos
│   │   │   ├── categorias/    # Categorías de productos
│   │   │   ├── ventas/        # Registro de ventas
│   │   │   ├── cajas/         # Apertura/cierre de caja
│   │   │   ├── inventario/    # Control de inventario
│   │   │   ├── usuarios/      # Gestión de usuarios
│   │   │   ├── reportes/      # Reportes
│   │   │   └── ...
│   │   └── shared/            # Middleware, utilidades
│   ├── setup-database.js      # Script de configuración de BD
│   ├── package.json
│   └── tsconfig.json
├── frontend/                   # App Flutter
│   ├── lib/
│   │   ├── core/              # Tema, router, constantes, red
│   │   └── features/          # Módulos de la app
│   │       ├── auth/          # Login
│   │       ├── dashboard/     # Panel principal
│   │       ├── pos/           # Punto de Venta
│   │       ├── products/      # Productos
│   │       ├── inventory/     # Inventario
│   │       ├── sales/         # Historial de ventas
│   │       ├── users/         # Gestión de usuarios
│   │       ├── reports/       # Reportes
│   │       └── settings/      # Configuración
│   └── pubspec.yaml
├── .env.example               # Variables de entorno de ejemplo
├── docker-compose.yml         # Configuración Docker (opcional)
├── iniciar-sistema.bat        # Script de inicio para Windows
└── README.md                  # Este archivo
```

---

##  Endpoints Principales de la API

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/v1/auth/login` | Iniciar sesión |
| GET | `/api/v1/productos` | Listar productos |
| POST | `/api/v1/productos` | Crear producto |
| POST | `/api/v1/cajas/abrir` | Abrir caja |
| POST | `/api/v1/cajas/cerrar` | Cerrar caja |
| POST | `/api/v1/ventas` | Registrar venta |
| GET | `/api/v1/ventas` | Listar ventas |
| GET | `/api/v1/reportes` | Obtener reportes |

>  Documentación completa de la API disponible en: `http://localhost:3001/api/docs` (Swagger)

---

##  Autor

Proyecto académico Roger Tumiri Quispe — Sistema de Gestión de Minimarket.

---
