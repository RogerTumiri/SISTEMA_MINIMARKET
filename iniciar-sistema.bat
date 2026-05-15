@echo off
REM ============================================================
REM   MINIMARKET SYSTEM - Script de inicio completo
REM   Doble clic para iniciar todo el sistema
REM ============================================================

echo.
echo ================================================================
echo   MINIMARKET PRO - Sistema de Gestion de Minimarkets
echo ================================================================
echo.

REM Guardar directorio del script como raiz del proyecto
set "SCRIPT_DIR=%~dp0"

REM ─────────────────────────────────────────────────────────────
REM 1) Verificar que existan las carpetas necesarias
REM ─────────────────────────────────────────────────────────────
if not exist "%SCRIPT_DIR%backend" (
    echo   [ERROR] No se encontro la carpeta backend\
    echo   Asegurese de ejecutar este script desde la raiz de minimarket-system
    pause
    exit /b 1
)

REM ─────────────────────────────────────────────────────────────
REM 2) Liberar puertos si hay procesos previos
REM ─────────────────────────────────────────────────────────────
echo [0/3] Liberando puertos anteriores...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3001 " ^| findstr "LISTENING"') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo   [OK] Puertos verificados

REM ─────────────────────────────────────────────────────────────
REM 3) Verificar PostgreSQL
REM ─────────────────────────────────────────────────────────────
echo.
echo [1/3] Verificando PostgreSQL...
pg_isready -h localhost -p 5432 -U postgres >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo   [AVISO] pg_isready no disponible o PostgreSQL no responde.
    echo   Intentando continuar... Asegurese de que PostgreSQL este activo.
    echo   Para iniciarlo: services.msc -^> buscar "postgresql" -^> Iniciar
    echo.
) ELSE (
    echo   [OK] PostgreSQL activo
)

REM ─────────────────────────────────────────────────────────────
REM 4) Verificar node_modules del backend
REM ─────────────────────────────────────────────────────────────
if not exist "%SCRIPT_DIR%backend\node_modules" (
    echo.
    echo [*] Instalando dependencias del backend...
    cd /d "%SCRIPT_DIR%backend"
    call npm install
    echo   [OK] Dependencias instaladas
)

REM ─────────────────────────────────────────────────────────────
REM 5) Verificar archivo .env del backend
REM ─────────────────────────────────────────────────────────────
if not exist "%SCRIPT_DIR%backend\.env" (
    echo.
    echo [AVISO] No se encontro backend\.env
    echo   Copiando desde .env.example...
    if exist "%SCRIPT_DIR%.env.example" (
        copy "%SCRIPT_DIR%.env.example" "%SCRIPT_DIR%backend\.env" >nul
        echo   [OK] Archivo .env creado. Revise y configure las credenciales.
    ) else (
        echo   [ERROR] No se encontro .env.example tampoco.
        echo   Cree el archivo backend\.env manualmente.
    )
)

REM ─────────────────────────────────────────────────────────────
REM 6) Configurar base de datos (crear BD + tablas + admin)
REM ─────────────────────────────────────────────────────────────
echo.
echo [2/3] Configurando base de datos...
cd /d "%SCRIPT_DIR%backend"
node setup-database.js
IF %ERRORLEVEL% NEQ 0 (
    echo   [AVISO] Hubo un problema configurando la BD.
    echo   Verifique que PostgreSQL este corriendo y las credenciales en backend\.env
)

REM ─────────────────────────────────────────────────────────────
REM 7) Backend Node.js (puerto 3001)
REM ─────────────────────────────────────────────────────────────
echo.
echo [3/3] Iniciando Backend API (puerto 3001)...
start "MiniMarket - Backend API" cmd /k "cd /d "%SCRIPT_DIR%backend" && npm run dev"
timeout /t 5 /nobreak >nul
echo   [OK] Backend iniciando...

echo.
echo ================================================================
echo   SISTEMA INICIADO CORRECTAMENTE
echo ================================================================
echo.
echo   Backend API:    http://localhost:3001
echo   Swagger Docs:   http://localhost:3001/api/docs
echo   Health Check:   http://localhost:3001/health
echo.
echo ================================================================
echo   CREDENCIALES DE ACCESO
echo ================================================================
echo   Usuario:   admin
echo   Password:  Admin123!
echo   Email:     admin@minimarket.com
echo ================================================================
echo.
echo   SIGUIENTE PASO - Iniciar el Frontend Flutter:
echo   1. Abra otra terminal
echo   2. cd "%SCRIPT_DIR%frontend"
echo   3. flutter pub get
echo   4. flutter run -d chrome
echo.
pause
