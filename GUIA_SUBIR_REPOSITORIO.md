# 📦 Guía para Subir al Repositorio de GitHub

Esta guía detalla exactamente qué archivos subir al repositorio para que cualquier persona pueda **clonar y ejecutar** el proyecto sin problemas.

---

## 🔧 Configuración Inicial del Repositorio

### 1. Crear repositorio en GitHub
1. Ir a [github.com/new](https://github.com/new)
2. Nombre del repositorio: `minimarket-system`
3. Dejarlo como **Public** o **Private** según prefiera
4. **NO** inicializar con README (ya tenemos uno)
5. Click en **Create repository**

### 2. Inicializar Git en el proyecto (si aún no lo tiene)

Abra una terminal en la carpeta `minimarket-system/`:

```bash
cd minimarket-system
git init
git remote add origin https://github.com/SU_USUARIO/minimarket-system.git
```

---

## 📋 Archivos que SÍ deben subirse

### Raíz del proyecto (`minimarket-system/`)
```
✅ README.md                        # Documentación del proyecto
✅ GUIA_SUBIR_REPOSITORIO.md        # Esta guía
✅ .gitignore                        # Reglas de exclusión
✅ .env.example                      # Ejemplo de variables de entorno
✅ docker-compose.yml                # Configuración Docker (referencia)
✅ iniciar-sistema.bat               # Script de inicio Windows
```

### Backend (`backend/`)
```
✅ backend/package.json              # Dependencias Node.js
✅ backend/package-lock.json         # Lock de dependencias (IMPORTANTE)
✅ backend/tsconfig.json             # Configuración TypeScript
✅ backend/Dockerfile                # Dockerfile del backend
✅ backend/setup-database.js         # Script de configuración de BD
✅ backend/src/                      # TODO el código fuente
✅ backend/src/main.ts               # Punto de entrada
✅ backend/src/config/               # Toda la carpeta config
✅ backend/src/database/             # Toda la carpeta database
✅ backend/src/database/entities/    # Todas las entidades
✅ backend/src/database/migrations/  # Todas las migraciones SQL
✅ backend/src/database/data-source.ts
✅ backend/src/modules/              # Todos los módulos
✅ backend/src/modules/auth/
✅ backend/src/modules/productos/
✅ backend/src/modules/categorias/
✅ backend/src/modules/proveedores/
✅ backend/src/modules/ventas/
✅ backend/src/modules/cajas/
✅ backend/src/modules/compras/
✅ backend/src/modules/inventario/
✅ backend/src/modules/reportes/
✅ backend/src/modules/configuracion/
✅ backend/src/modules/unidades/
✅ backend/src/modules/usuarios/
✅ backend/src/shared/               # Toda la carpeta shared
✅ backend/src/shared/middleware/
✅ backend/src/shared/utils/
✅ backend/src/shared/websocket/
```

### Frontend (`frontend/`)
```
✅ frontend/pubspec.yaml             # Dependencias Flutter
✅ frontend/pubspec.lock             # Lock de dependencias
✅ frontend/analysis_options.yaml    # Configuración de análisis
✅ frontend/lib/                     # TODO el código fuente
✅ frontend/lib/main.dart            # Punto de entrada
✅ frontend/lib/core/                # Toda la carpeta core
✅ frontend/lib/core/constants/
✅ frontend/lib/core/layout/
✅ frontend/lib/core/network/
✅ frontend/lib/core/router/
✅ frontend/lib/core/theme/
✅ frontend/lib/features/            # Todas las features
✅ frontend/lib/features/auth/
✅ frontend/lib/features/dashboard/
✅ frontend/lib/features/pos/
✅ frontend/lib/features/products/
✅ frontend/lib/features/inventory/
✅ frontend/lib/features/sales/
✅ frontend/lib/features/users/
✅ frontend/lib/features/reports/
✅ frontend/lib/features/settings/
✅ frontend/lib/features/ai/
✅ frontend/web/                     # Archivos web de Flutter
✅ frontend/android/                 # Configuración Android
✅ frontend/windows/                 # Configuración Windows
✅ frontend/linux/                   # Configuración Linux
✅ frontend/macos/                   # Configuración macOS
✅ frontend/ios/                     # Configuración iOS
✅ frontend/test/                    # Tests
✅ frontend/.metadata                # Metadata de Flutter
```

### Nginx (opcional)
```
✅ nginx/                            # Configuración nginx si existe
```

---

## 🚫 Archivos que NO deben subirse

El archivo `.gitignore` ya está configurado para excluir estos, pero verifique:

```
❌ backend/node_modules/             # Dependencias instaladas (se regeneran con npm install)
❌ backend/.env                      # Contiene credenciales reales
❌ backend/*.txt                     # Archivos de log/debug temporales
❌ backend/err.log
❌ backend/fix-admin.js              # Scripts de debug temporales
❌ backend/fix-result.txt
❌ backend/hash-result.txt
❌ backend/test-login.js
❌ backend/verify-hash.js
❌ backend/login-test-result.txt
❌ backend/backend-log.txt
❌ backend/compile_errors.txt
❌ backend/db-check.txt
❌ backend/db-result.txt
❌ backend/pwd-fix.txt
❌ backend/srv-err.txt
❌ backend/srv-out.txt
❌ backend/setup-db.js               # Script duplicado/debug

❌ frontend/.dart_tool/              # Cache de Dart
❌ frontend/build/                   # Build compilado
❌ frontend/.flutter-plugins
❌ frontend/.flutter-plugins-dependencies
❌ frontend/.idea/                   # Configuración IDE

❌ ia_service/venv/                  # Entorno virtual Python
❌ ia_service/__pycache__/
❌ ia_service/.env

❌ *.log                             # Archivos de log
❌ *.txt                             # Archivos temporales de debug
❌ .vscode/                          # Configuración IDE personal
❌ .idea/                            # Configuración IntelliJ
```

---

## ✏️ Actualizar el .gitignore

Asegúrese de que el `.gitignore` en la raíz de `minimarket-system/` tenga este contenido:

```gitignore
# BACKEND (Node)
backend/node_modules/
backend/.env
backend/*.txt
backend/err.log
backend/fix-admin.js
backend/fix-result.txt
backend/hash-result.txt
backend/test-login.js
backend/verify-hash.js
backend/login-test-result.txt
backend/backend-log.txt
backend/compile_errors.txt
backend/db-check.txt
backend/db-result.txt
backend/pwd-fix.txt
backend/srv-err.txt
backend/srv-out.txt
backend/setup-db.js

# FRONTEND (Flutter)
frontend/.dart_tool/
frontend/build/
frontend/.flutter-plugins
frontend/.flutter-plugins-dependencies
frontend/.idea/

# IA (Python)
ia_service/venv/
ia_service/__pycache__/
ia_service/.env

# GENERAL
.env
*.log

# Archivos temporales de raíz
*.txt
!README.md
!GUIA_SUBIR_REPOSITORIO.md

# IDE
.vscode/
.idea/
```

---

## 🚀 Comandos para Subir al Repositorio

Ejecute estos comandos en orden desde la carpeta `minimarket-system/`:

```bash
# 1. Verificar el estado (ver qué archivos se van a subir)
git status

# 2. Agregar todos los archivos (respetando .gitignore)
git add .

# 3. Verificar que NO se estén subiendo archivos sensibles
git status
#    Asegúrese de que NO aparezcan: node_modules, .env, *.txt de debug

# 4. Hacer el commit
git commit -m "Avance del proyecto: POS, productos, dashboard, autenticación"

# 5. Subir al repositorio
git branch -M main
git push -u origin main
```

---

## 🧑‍🏫 Instrucciones para el Tutor (Clonar y Ejecutar)

El tutor debe seguir estos pasos para ejecutar el proyecto:

### Requisitos previos
1. **Node.js** v18+ instalado
2. **PostgreSQL** 15+ instalado y corriendo
3. **Flutter SDK** 3.3+ instalado
4. **Google Chrome** instalado

### Pasos
```bash
# 1. Clonar el repositorio
git clone https://github.com/SU_USUARIO/minimarket-system.git
cd minimarket-system

# 2. Configurar variables de entorno
copy .env.example backend\.env
# Editar backend\.env y poner la contraseña de PostgreSQL en DB_PASSWORD

# 3. Ejecutar el script de inicio (esto instala deps + configura BD + inicia backend)
iniciar-sistema.bat

# 4. En otra terminal, iniciar el frontend
cd frontend
flutter pub get
flutter run -d chrome
```

### Acceder al sistema
- Abrir el navegador en la URL que Flutter indique
- **Usuario:** `admin`
- **Contraseña:** `Admin123!`

### Flujo de uso del POS
1. Iniciar sesión → ir a **POS** en el menú lateral
2. **Abrir Caja** → ingresar monto de apertura → click en "Abrir Caja"
3. Buscar productos por nombre o escanear código de barras
4. Agregar al carrito → seleccionar método de pago → click en "Cobrar"
5. Al finalizar el turno → click en "Cerrar Caja" → ingresar monto en caja

---

## ⚠️ Solución de Problemas Comunes

| Problema | Solución |
|----------|----------|
| `pg_isready` no reconocido | Agregar PostgreSQL al PATH del sistema |
| Error de conexión a la BD | Verificar que PostgreSQL esté corriendo y la contraseña en `.env` sea correcta |
| `npm: command not found` | Instalar Node.js desde [nodejs.org](https://nodejs.org/) |
| `flutter: command not found` | Instalar Flutter SDK y agregarlo al PATH |
| CORS error en el frontend | Verificar que el backend esté corriendo en el puerto 3001 |
| "Debe abrir la caja" | En el POS, primero debe abrir la caja antes de hacer ventas |

---
