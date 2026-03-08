# Importaciones
from fastapi import FastAPI    # Framework que ejecuta a fastAPI

from database import engine    # engine es el objeto que conecta SQLAlchemy con PostgreSQL.
from models import Base    # Base contiene la estructura de las tablas

from routers import auth_routes, user_routes    # Rutas

# Crea la aplicación backend
app = FastAPI(
    title="Finara API",
    version="1.0"
)

# Crear las tablas en la base de datos
Base.metadata.create_all(bind=engine)

# Agregar las rutas definidas
app.include_router(auth_routes.router)
app.include_router(user_routes.router)

