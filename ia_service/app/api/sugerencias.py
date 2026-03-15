from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError
from app.database.connection import get_db
from pydantic import BaseModel, Field
from typing import Optional
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


class AprobarBody(BaseModel):
    cantidad_aprobada: float = Field(gt=0, description="Cantidad aprobada para la recompra")
    observaciones: Optional[str] = None


class RechazarBody(BaseModel):
    motivo: Optional[str] = None


@router.get("/")
async def listar_sugerencias(
    estado: str = "PENDIENTE",
    db: Session = Depends(get_db)
):
    """Lista sugerencias de recompra filtradas por estado (PENDIENTE, APROBADA, RECHAZADA)."""
    if estado not in ("PENDIENTE", "APROBADA", "RECHAZADA", "CONVERTIDA"):
        raise HTTPException(status_code=400, detail="Estado inválido")

    try:
        rows = db.execute(text("""
            SELECT sr.id, sr.producto_id, p.nombre as producto_nombre,
                   sr.proveedor_id, pv.nombre_empresa as proveedor_nombre,
                   sr.cantidad_sugerida, sr.fecha_limite_pedido, sr.estado,
                   sr.cantidad_aprobada, sr.created_at
            FROM sugerencias_recompra sr
            JOIN productos p ON p.id = sr.producto_id
            LEFT JOIN proveedores pv ON pv.id = sr.proveedor_id
            WHERE sr.estado = :estado
            ORDER BY sr.fecha_limite_pedido ASC NULLS LAST, sr.created_at DESC
        """), {"estado": estado}).fetchall()
    except OperationalError:
        raise HTTPException(status_code=503, detail="Base de datos no disponible")

    data = [
        {
            "id":                  str(r[0]),
            "producto_id":         str(r[1]),
            "producto_nombre":     r[2],
            "proveedor_id":        str(r[3]) if r[3] else None,
            "proveedor_nombre":    r[4],
            "cantidad_sugerida":   float(r[5]),
            "fecha_limite_pedido": str(r[6]) if r[6] else None,
            "estado":              r[7],
            "cantidad_aprobada":   float(r[8]) if r[8] else None,
            "created_at":          str(r[9]),
        }
        for r in rows
    ]
    return {"success": True, "data": data, "total": len(data)}


@router.get("/resumen")
async def resumen_sugerencias(db: Session = Depends(get_db)):
    """Resumen rápido del estado de sugerencias."""
    try:
        rows = db.execute(text("""
            SELECT estado, COUNT(*) as total
            FROM sugerencias_recompra
            GROUP BY estado
        """)).fetchall()
        resumen = {r[0]: int(r[1]) for r in rows}
        return {"success": True, "data": resumen}
    except OperationalError:
        raise HTTPException(status_code=503, detail="Base de datos no disponible")


@router.patch("/{id}/aprobar")
async def aprobar_sugerencia(
    id: str,
    body: AprobarBody,
    db: Session = Depends(get_db)
):
    """Aprueba una sugerencia de recompra."""
    try:
        result = db.execute(text("""
            UPDATE sugerencias_recompra
            SET estado = 'APROBADA',
                cantidad_aprobada = :cantidad
            WHERE id = :id AND estado = 'PENDIENTE'
            RETURNING id
        """), {"id": id, "cantidad": body.cantidad_aprobada})
        db.commit()

        if not result.fetchone():
            raise HTTPException(status_code=404, detail="Sugerencia no encontrada o ya procesada")

        return {"success": True, "message": "Sugerencia aprobada"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error aprobando sugerencia {id}: {e}")
        raise HTTPException(status_code=500, detail="Error al aprobar sugerencia")


@router.patch("/{id}/rechazar")
async def rechazar_sugerencia(
    id: str,
    body: RechazarBody,
    db: Session = Depends(get_db)
):
    """Rechaza una sugerencia de recompra."""
    try:
        result = db.execute(text("""
            UPDATE sugerencias_recompra
            SET estado = 'RECHAZADA'
            WHERE id = :id AND estado = 'PENDIENTE'
            RETURNING id
        """), {"id": id})
        db.commit()

        if not result.fetchone():
            raise HTTPException(status_code=404, detail="Sugerencia no encontrada o ya procesada")

        return {"success": True, "message": "Sugerencia rechazada"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error rechazando sugerencia {id}: {e}")
        raise HTTPException(status_code=500, detail="Error al rechazar sugerencia")
