from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
import os
from pathlib import Path
from dotenv import load_dotenv

# Cargar .env desde la carpeta del ia_service
_env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(dotenv_path=_env_path)

# También intentar desde directorio de trabajo
load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:tumiri@localhost:5432/minimarket_db"
)


def get_engine():
    """Crea el engine de SQLAlchemy con manejo de errores."""
    try:
        engine = create_engine(
            DATABASE_URL,
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,     # Verifica conexiones antes de usarlas
            pool_recycle=3600,      # Recicla conexiones cada hora
            connect_args={"connect_timeout": 5},
        )
        return engine
    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Error creando engine de DB: {e}")
        raise


engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    """Dependency que provee una sesión de DB y la cierra al terminar."""
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
