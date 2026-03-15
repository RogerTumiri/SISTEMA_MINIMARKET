from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from app.database.connection import get_db
from app.services.forecasting_service import forecast_producto
from datetime import date, timedelta
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

HORIZONTES = [7, 14, 30]


def get_all_productos(db: Session) -> list:
    """Obtiene todos los productos activos."""
    try:
        rows = db.execute(text("""
            SELECT p.id, p.nombre, p.proveedor_id, p.stock_actual, p.stock_minimo
            FROM productos p
            WHERE p.activo = true AND p.deleted_at IS NULL
        """)).fetchall()
        return [
            {
                "id": str(r[0]),
                "nombre": r[1],
                "proveedor_id": str(r[2]) if r[2] else None,
                "stock_actual": float(r[3]),
                "stock_minimo": float(r[4])
            }
            for r in rows
        ]
    except OperationalError as e:
        logger.error(f"Error de conexión a DB: {e}")
        raise HTTPException(status_code=503, detail="Base de datos no disponible")


def guardar_prediccion(db: Session, producto_id: str, resultado: dict):
    """Guarda predicción en la base de datos."""
    for horizonte in HORIZONTES:
        pred_valor = resultado['predicciones'].get(f'{horizonte}_dias', 0)
        db.execute(text("""
            INSERT INTO predicciones_ia
                (producto_id, algoritmo, periodo_dias, unidades_predichas,
                 mae, mape, rmse, confianza, valido_hasta)
            VALUES
                (:pid, :alg, :dias, :pred, :mae, :mape, :rmse, :conf, :valid)
        """), {
            "pid":   producto_id,
            "alg":   resultado['algoritmo'],
            "dias":  horizonte,
            "pred":  pred_valor,
            "mae":   resultado['metricas']['mae'],
            "mape":  resultado['metricas']['mape'],
            "rmse":  resultado['metricas']['rmse'],
            "conf":  resultado['confianza'],
            "valid": date.today() + timedelta(days=7),
        })
    db.commit()


def generar_sugerencias(db: Session, producto: dict, resultado: dict):
    """Genera sugerencias de recompra basadas en predicción."""
    pred_30  = resultado['predicciones'].get('30_dias', 0)
    pred_14  = resultado['predicciones'].get('14_dias', 0)
    stock    = producto['stock_actual']
    stock_min = producto['stock_minimo']

    # Si el stock no alcanza para 14 días o está bajo el mínimo
    if stock < pred_14 * 0.8 or stock <= stock_min:
        cantidad_sugerida = max(pred_30 - stock, stock_min * 2)
        if cantidad_sugerida <= 0:
            return

        dias_restantes = int(stock / (pred_14 / 14)) if pred_14 > 0 else 0
        fecha_limite = date.today() + timedelta(days=max(1, dias_restantes))

        # Evitar duplicados de sugerencias pendientes
        existing = db.execute(text("""
            SELECT id FROM sugerencias_recompra
            WHERE producto_id = :pid AND estado = 'PENDIENTE'
        """), {"pid": producto['id']}).fetchone()

        if not existing:
            db.execute(text("""
                INSERT INTO sugerencias_recompra
                    (producto_id, proveedor_id, cantidad_sugerida, fecha_limite_pedido)
                VALUES (:pid, :prov, :cant, :fecha)
            """), {
                "pid":   producto['id'],
                "prov":  producto.get('proveedor_id'),
                "cant":  round(cantidad_sugerida, 2),
                "fecha": fecha_limite,
            })
        db.commit()


async def ejecutar_predicciones_bg(db: Session):
    """Tarea en background: ejecuta predicciones para todos los productos."""
    try:
        productos = get_all_productos(db)
    except HTTPException:
        logger.error("No se pudieron obtener productos (DB no disponible)")
        return {"exitosos": 0, "errores": 0, "error": "DB no disponible"}

    logger.info(f"Ejecutando predicciones para {len(productos)} productos...")

    exitosos = 0
    errores = 0
    for prod in productos:
        try:
            resultado = forecast_producto(db, prod['id'], HORIZONTES)
            guardar_prediccion(db, prod['id'], resultado)
            generar_sugerencias(db, prod, resultado)
            exitosos += 1
        except Exception as e:
            logger.error(f"Error predicción para {prod['nombre']}: {e}")
            errores += 1

    logger.info(f"Predicciones completadas: {exitosos} exitosas, {errores} errores")
    return {"exitosos": exitosos, "errores": errores}


@router.get("/")
async def listar_predicciones(db: Session = Depends(get_db)):
    """Lista las predicciones más recientes por producto."""
    try:
        rows = db.execute(text("""
            SELECT DISTINCT ON (pia.producto_id, pia.periodo_dias)
                pia.id, pia.producto_id, p.nombre as nombre_producto,
                pia.algoritmo, pia.periodo_dias, pia.unidades_predichas,
                pia.mae, pia.mape, pia.rmse, pia.confianza,
                pia.fecha_prediccion, pia.valido_hasta
            FROM predicciones_ia pia
            JOIN productos p ON p.id = pia.producto_id
            WHERE pia.valido_hasta >= CURRENT_DATE
            ORDER BY pia.producto_id, pia.periodo_dias, pia.fecha_prediccion DESC
            LIMIT 500
        """)).fetchall()
    except OperationalError:
        raise HTTPException(status_code=503, detail="Base de datos no disponible")

    # Agrupar por producto
    productos_map: dict = {}
    for r in rows:
        pid = str(r[1])
        if pid not in productos_map:
            productos_map[pid] = {
                "producto_id":      pid,
                "nombre_producto":  r[2],
                "algoritmo":        r[3],
                "predicciones":     {},
                "metricas":         {"mae": float(r[6] or 0), "mape": float(r[7] or 0), "rmse": float(r[8] or 0)},
                "confianza":        float(r[9] or 0),
                "valido_hasta":     str(r[11]),
            }
        productos_map[pid]["predicciones"][f"{r[4]}_dias"] = float(r[5])

    return {"success": True, "data": list(productos_map.values())}


@router.post("/ejecutar")
async def ejecutar_manual(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Ejecuta el re-entrenamiento de modelos manualmente."""
    background_tasks.add_task(ejecutar_predicciones_bg, db)
    return {
        "success": True,
        "message": "Predicciones ejecutándose en background. Resultados disponibles en minutos.",
    }


@router.get("/producto/{producto_id}")
async def prediccion_producto(producto_id: str, db: Session = Depends(get_db)):
    """Obtiene predicción para un producto específico en tiempo real."""
    try:
        resultado = forecast_producto(db, producto_id, HORIZONTES)
        return {"success": True, "data": resultado}
    except Exception as e:
        logger.error(f"Error en predicción para {producto_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
