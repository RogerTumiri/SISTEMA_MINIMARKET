@echo off
REM ============================================================
REM   Iniciar el Servicio IA de MiniMarket
REM   Usa el venv local que ya tiene las dependencias instaladas
REM ============================================================
cd /d C:\Proyecto_Minimarcket\minimarket-system\ia_service

set VENV_PYTHON=venv\Scripts\python.exe
set VENV_PIP=venv\Scripts\pip.exe
set VENV_UVICORN=venv\Scripts\uvicorn.exe

REM Caso 1: El uvicorn ya está en el venv
if exist "%VENV_UVICORN%" (
    echo [OK] Iniciando con uvicorn del venv...
    "%VENV_UVICORN%" app.main:app --host 0.0.0.0 --port 8001 --reload
    goto :end
)

REM Caso 2: Python del venv existe pero no uvicorn - instalar
if exist "%VENV_PYTHON%" (
    echo Instalando dependencias en venv...
    "%VENV_PIP%" install --upgrade pip --quiet
    "%VENV_PIP%" install uvicorn[standard] fastapi sqlalchemy psycopg2-binary python-dotenv "pydantic>=2.0" pydantic-settings apscheduler numpy pandas scikit-learn statsmodels joblib httpx --quiet
    echo [OK] Dependencias instaladas. Iniciando servicio...
    "%VENV_UVICORN%" app.main:app --host 0.0.0.0 --port 8001 --reload
    goto :end
)

REM Caso 3: Usar Python del sistema
echo Venv no encontrado. Usando Python del sistema...
echo Esto puede requerir instalar dependencias: pip install uvicorn fastapi sqlalchemy psycopg2-binary python-dotenv pydantic apscheduler
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

:end
