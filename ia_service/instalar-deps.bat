@echo off
REM ============================================================
REM   Instalar dependencias del Servicio IA de MiniMarket
REM   Ejecutar como administrador si da permisos
REM ============================================================
echo Instalando dependencias del servicio IA...

REM Intentar con el venv primero
set VENV_PIP=C:\Proyecto_Minimarcket\minimarket-system\ia_service\venv\Scripts\pip.exe

if exist "%VENV_PIP%" (
    echo Usando pip del venv...
    "%VENV_PIP%" install --upgrade pip
    "%VENV_PIP%" install uvicorn[standard] fastapi sqlalchemy psycopg2-binary python-dotenv "pydantic>=2.0" pydantic-settings apscheduler numpy pandas scikit-learn statsmodels joblib httpx
) else (
    echo Venv no encontrado, usando pip del sistema...
    pip install uvicorn[standard] fastapi sqlalchemy psycopg2-binary python-dotenv "pydantic>=2.0" pydantic-settings apscheduler numpy pandas scikit-learn statsmodels joblib httpx
)

echo.
echo Instalacion completada. Verificando...

REM Verificar instalacion
set PYTHON=C:\Proyecto_Minimarcket\minimarket-system\ia_service\venv\Scripts\python.exe
if not exist "%PYTHON%" (
    set PYTHON=python
)

"%PYTHON%" -c "import uvicorn, fastapi, sqlalchemy; print('OK - uvicorn fastapi sqlalchemy instalados')"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo   OK - Todo instalado correctamente
) else (
    echo.
    echo   ERROR - Algunas dependencias no se instalaron correctamente
    echo   Intenta ejecutar manualmente:
    echo   pip install uvicorn fastapi sqlalchemy psycopg2-binary python-dotenv pydantic apscheduler numpy pandas scikit-learn statsmodels
)
pause
