# Importaciones
from sqlalchemy import create_engine    # Conexión entre Python y la base de dtos
from sqlalchemy.orm import sessionmaker, declarative_base   # Herramientas ORM de SQLAlchemy, sessionmaker crea sesiones de base de datos

DATABASE_URL = "postgresql://postgres:2805@localhost:5432/finara_db"    # URL de la base de datos

engine = create_engine(DATABASE_URL)    # Abre y administra conexiones, ejecuta consultas SQL

# Se define como se crearán las sesiones de base de datos
SessionLocal = sessionmaker(
    autocommit=False,   # Los cambios no se guardan automáticamente
    autoflush=False,    # Evita que SQLAlchemy envíe cambios automaticamente a la db sin que uno decida
    bind=engine     # Conecta las sesiones con el engine que se creó antes
)

Base = declarative_base()   # Crea la clase base para todos los modelos de la base de datos