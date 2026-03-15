import pandas as pd
import numpy as np
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date, timedelta
import logging
import warnings
warnings.filterwarnings('ignore')

logger = logging.getLogger(__name__)

# Verificar disponibilidad de librerías opcionales
PROPHET_AVAILABLE = False
STATSMODELS_AVAILABLE = False

try:
    from prophet import Prophet  # type: ignore
    PROPHET_AVAILABLE = True
    logger.info("✅ Prophet disponible")
except ImportError:
    logger.warning("⚠️  Prophet no disponible - se usará ARIMA/Naive como fallback")

try:
    from statsmodels.tsa.arima.model import ARIMA  # type: ignore
    STATSMODELS_AVAILABLE = True
    logger.info("✅ Statsmodels/ARIMA disponible")
except ImportError:
    logger.warning("⚠️  Statsmodels no disponible - se usará Naive como fallback")


def get_ventas_producto(db: Session, producto_id: str, dias: int = 365) -> pd.DataFrame:
    """Obtiene el historial de ventas diarias de un producto."""
    query = text(f"""
        SELECT 
            DATE(v.created_at) AS ds,
            SUM(vi.cantidad)   AS y
        FROM venta_items vi
        JOIN ventas v ON v.id = vi.venta_id
        WHERE vi.producto_id = :producto_id
          AND v.estado = 'COMPLETADA'
          AND v.created_at >= NOW() - INTERVAL '{dias} days'
        GROUP BY DATE(v.created_at)
        ORDER BY ds
    """)
    try:
        result = db.execute(query, {"producto_id": producto_id})
        rows = result.fetchall()
    except Exception as e:
        logger.error(f"Error consultando ventas para {producto_id}: {e}")
        return pd.DataFrame(columns=['ds', 'y'])

    if not rows:
        return pd.DataFrame(columns=['ds', 'y'])

    df = pd.DataFrame(rows, columns=['ds', 'y'])
    df['ds'] = pd.to_datetime(df['ds'])
    df['y'] = df['y'].astype(float)
    return df


def fill_missing_dates(df: pd.DataFrame) -> pd.DataFrame:
    """Rellena fechas sin ventas con 0."""
    if df.empty:
        return df
    idx = pd.date_range(df['ds'].min(), df['ds'].max())
    df = df.set_index('ds').reindex(idx, fill_value=0).reset_index()
    df.columns = ['ds', 'y']
    return df


def prophet_forecast(df: pd.DataFrame, horizons: list) -> dict:
    """Predicción con Prophet."""
    if not PROPHET_AVAILABLE:
        raise ImportError("Prophet no está instalado")

    model = Prophet(
        daily_seasonality=False,
        weekly_seasonality=True,
        yearly_seasonality=len(df) >= 180,
        changepoint_prior_scale=0.05,
        seasonality_prior_scale=10.0,
    )
    model.fit(df)

    max_horizon = max(horizons)
    future = model.make_future_dataframe(periods=max_horizon)
    forecast = model.predict(future)

    predicciones = {}
    for h in horizons:
        future_rows = forecast.tail(h)
        total = max(0, float(future_rows['yhat'].sum()))
        predicciones[f'{h}_dias'] = round(total, 2)

    # Calcular métricas en datos históricos
    hist_pred = forecast.head(len(df))['yhat'].values
    y_true = df['y'].values
    mae  = float(np.mean(np.abs(y_true - hist_pred)))
    mape = float(np.mean(np.abs((y_true - hist_pred) / (y_true + 1e-8))) * 100)
    rmse = float(np.sqrt(np.mean((y_true - hist_pred) ** 2)))
    confianza = max(0, min(100, 100 - mape))

    return {
        'algoritmo':    'Prophet',
        'predicciones': predicciones,
        'metricas':     {'mae': round(mae, 2), 'mape': round(mape, 2), 'rmse': round(rmse, 2)},
        'confianza':    round(confianza, 2),
    }


def arima_forecast(df: pd.DataFrame, horizons: list) -> dict:
    """Predicción con ARIMA como fallback."""
    if not STATSMODELS_AVAILABLE:
        raise ImportError("Statsmodels no está instalado")

    ts = df['y'].values.astype(float)
    model = ARIMA(ts, order=(1, 1, 1))
    result = model.fit()

    max_horizon = max(horizons)
    forecast = result.forecast(steps=max_horizon)

    predicciones = {}
    for h in horizons:
        total = max(0, float(np.sum(forecast[:h])))
        predicciones[f'{h}_dias'] = round(total, 2)

    # Métricas
    fitted = result.fittedvalues
    y_true = ts[1:]  # ARIMA diferenciado pierde primer punto
    mae  = float(np.mean(np.abs(y_true - fitted[1:])))
    mape = float(np.mean(np.abs((y_true - fitted[1:]) / (y_true + 1e-8))) * 100)
    rmse = float(np.sqrt(np.mean((y_true - fitted[1:]) ** 2)))
    confianza = max(0, min(100, 100 - mape))

    return {
        'algoritmo':    'ARIMA',
        'predicciones': predicciones,
        'metricas':     {'mae': round(mae, 2), 'mape': round(mape, 2), 'rmse': round(rmse, 2)},
        'confianza':    round(confianza, 2),
    }


def moving_average_forecast(df: pd.DataFrame, horizons: list) -> dict:
    """Predicción con media móvil ponderada (siempre disponible)."""
    if df.empty or len(df) < 2:
        recent = 0.0
    else:
        # Promedio ponderado: días más recientes tienen más peso
        n = min(30, len(df))
        recent_data = df['y'].tail(n).values
        weights = np.arange(1, n + 1, dtype=float)
        recent = float(np.average(recent_data, weights=weights))

    predicciones = {f'{h}_dias': round(float(recent * h), 2) for h in horizons}

    # Calcular métrica simple
    if len(df) >= 7:
        y_true = df['y'].tail(7).values
        y_pred = np.full(len(y_true), recent)
        mae = float(np.mean(np.abs(y_true - y_pred)))
        mape = float(np.mean(np.abs((y_true - y_pred) / (y_true + 1e-8))) * 100)
        rmse = float(np.sqrt(np.mean((y_true - y_pred) ** 2)))
    else:
        mae, mape, rmse = 0.0, 0.0, 0.0

    return {
        'algoritmo':    'MediaMovil',
        'predicciones': predicciones,
        'metricas':     {'mae': round(mae, 2), 'mape': round(mape, 2), 'rmse': round(rmse, 2)},
        'confianza':    max(20.0, min(60.0, 60.0 - mape)),
    }


def naive_forecast(df: pd.DataFrame, horizons: list) -> dict:
    """Predicción ingenua: promedio de últimos 7 días."""
    recent = df['y'].tail(7).mean() if not df.empty else 0
    predicciones = {f'{h}_dias': round(float(recent * h), 2) for h in horizons}
    return {
        'algoritmo':    'Naive',
        'predicciones': predicciones,
        'metricas':     {'mae': 0, 'mape': 0, 'rmse': 0},
        'confianza':    30.0,
    }


def forecast_producto(db: Session, producto_id: str, horizons: list = None) -> dict:
    """
    Obtiene predicciones para un producto.
    Cadena de fallback: Prophet → ARIMA → MediaMovil → Naive
    """
    if horizons is None:
        horizons = [7, 14, 30]

    df = get_ventas_producto(db, producto_id, dias=365)
    df = fill_missing_dates(df)

    MIN_DATOS = 14  # Mínimo 2 semanas de histórico

    if len(df) < MIN_DATOS:
        logger.warning(f"Producto {producto_id}: datos insuficientes ({len(df)} días), usando MediaMovil")
        return moving_average_forecast(df, horizons)

    # Intentar Prophet primero
    if PROPHET_AVAILABLE:
        try:
            result = prophet_forecast(df, horizons)
            # Comparar con ARIMA si está disponible
            if STATSMODELS_AVAILABLE:
                try:
                    arima_result = arima_forecast(df, horizons)
                    if arima_result['metricas']['mape'] < result['metricas']['mape']:
                        return arima_result
                except Exception:
                    pass
            return result
        except Exception as e_prophet:
            logger.warning(f"Prophet falló para {producto_id}: {e_prophet}")

    # Intentar ARIMA
    if STATSMODELS_AVAILABLE:
        try:
            return arima_forecast(df, horizons)
        except Exception as e_arima:
            logger.warning(f"ARIMA falló para {producto_id}: {e_arima}")

    # Fallback: Media Móvil ponderada
    logger.info(f"Usando MediaMovil para {producto_id}")
    return moving_average_forecast(df, horizons)
