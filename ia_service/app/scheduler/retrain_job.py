from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy import text
from datetime import date, timedelta
import logging
import os

logger = logging.getLogger(__name__)

CRON = os.getenv("MODEL_RETRAIN_CRON", "0 2 * * 1")  # Lunes 2AM
HORIZONTES = [7, 14, 30]


def retrain_all_models():
    """Cron job: re-entrena modelos para todos los productos activos."""
    logger.info("⏰ Iniciando re-entrenamiento semanal de modelos IA...")

    try:
        from app.database.connection import SessionLocal
        from app.services.forecasting_service import forecast_producto
    except Exception as e:
        logger.error(f"No se pudieron importar dependencias: {e}")
        return

    db = SessionLocal()
    try:
        productos = db.execute(text("""
            SELECT id, nombre, proveedor_id, stock_actual, stock_minimo
            FROM productos WHERE activo = true AND deleted_at IS NULL
        """)).fetchall()

        exitosos = 0
        errores = 0
        for prod in productos:
            pid = str(prod[0])
            try:
                resultado = forecast_producto(db, pid, HORIZONTES)

                for horizonte in HORIZONTES:
                    db.execute(text("""
                        INSERT INTO predicciones_ia
                            (producto_id, algoritmo, periodo_dias, unidades_predichas,
                             mae, mape, rmse, confianza, valido_hasta)
                        VALUES (:pid, :alg, :dias, :pred, :mae, :mape, :rmse, :conf, :valid)
                    """), {
                        "pid":   pid,
                        "alg":   resultado['algoritmo'],
                        "dias":  horizonte,
                        "pred":  resultado['predicciones'].get(f'{horizonte}_dias', 0),
                        "mae":   resultado['metricas']['mae'],
                        "mape":  resultado['metricas']['mape'],
                        "rmse":  resultado['metricas']['rmse'],
                        "conf":  resultado['confianza'],
                        "valid": date.today() + timedelta(days=7),
                    })

                db.commit()
                exitosos += 1
            except Exception as e:
                logger.error(f"Error en producto {prod[1]}: {e}")
                db.rollback()
                errores += 1

        logger.info(f"✅ Re-entrenamiento completado: {exitosos} exitosos, {errores} errores")
    except Exception as e:
        logger.error(f"Error general en re-entrenamiento: {e}")
    finally:
        db.close()


def setup_scheduler() -> BackgroundScheduler:
    """Configura el scheduler con el cron definido en env."""
    try:
        scheduler = BackgroundScheduler(timezone="America/La_Paz")
    except Exception:
        # Si la zona horaria no es válida, usar UTC
        scheduler = BackgroundScheduler(timezone="UTC")

    # Parsear cron: "0 2 * * 1" → minute hour day month day_of_week
    cron_parts = CRON.split()
    if len(cron_parts) == 5:
        minute, hour, day, month, day_of_week = cron_parts
        trigger = CronTrigger(
            minute=minute, hour=hour, day=day,
            month=month, day_of_week=day_of_week,
        )
    else:
        # Default: Lunes 2 AM
        trigger = CronTrigger(day_of_week="mon", hour=2, minute=0)

    scheduler.add_job(
        retrain_all_models,
        trigger=trigger,
        id="retrain_models",
        name="Reentrenamiento semanal de modelos IA",
        replace_existing=True,
        misfire_grace_time=3600,
    )
    return scheduler
