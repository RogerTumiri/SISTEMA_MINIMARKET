from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.api import predicciones, sugerencias
import logging
import os

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger(__name__)


def try_setup_scheduler():
    """Intenta iniciar el scheduler; si falla (ej. no hay DB), continúa sin él."""
    try:
        from app.scheduler.retrain_job import setup_scheduler
        scheduler = setup_scheduler()
        scheduler.start()
        logger.info("⏰ Scheduler de reentrenamiento iniciado")
        return scheduler
    except Exception as e:
        logger.warning(f"⚠️  Scheduler no pudo iniciarse: {e}")
        return None


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🤖 Iniciando Microservicio IA — MiniMarket Pro")
    scheduler = try_setup_scheduler()
    yield
    if scheduler:
        try:
            scheduler.shutdown()
        except Exception:
            pass
    logger.info("🛑 Microservicio IA detenido")


app = FastAPI(
    title="MiniMarket IA Service",
    description="Microservicio de predicción de demanda y sugerencias de recompra",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predicciones.router, prefix="/predicciones", tags=["Predicciones"])
app.include_router(sugerencias.router, prefix="/sugerencias", tags=["Sugerencias"])


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "minimarket-ia",
        "version": "1.0.0",
        "database_url": "configured" if os.getenv("DATABASE_URL") else "missing"
    }
