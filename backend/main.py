from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
import models  # IMPORTANTE para registrar modelos

from routers import (
    auth_routes, 
    user_routes, 
    transaction_routes, 
    video_routes, 
    lecturas_routes, 
    stock_routes,
    category_routes
)

from routers.news_routes import news_router

# 1. Crear la aplicación backend
app = FastAPI(
    title="Finara API",
    version="1.0"
)

# 2. CONFIGURACIÓN DE CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Crear las tablas en la base de datos
models.Base.metadata.create_all(bind=engine)

# 4. Agregar rutas
app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(transaction_routes.router)
app.include_router(category_routes.router, prefix="/categories", tags=["Categories"])
app.include_router(news_router)
app.include_router(video_routes.router)
app.include_router(lecturas_routes.router)
app.include_router(stock_routes.stock_router)

# Ruta raíz (para probar que funciona)
@app.get("/")
def read_root():
    return {"message": "Finara API is running"}