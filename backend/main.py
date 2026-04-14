# Importaciones
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Base, PasswordResetToken
from routers import auth_routes, user_routes, transaction_routes, video_routes, lecturas_routes, stock_routes, category_routes
from routers.news_routes import news_router

# from routers import ai_routes

# Crea la aplicación backend
app = FastAPI(
    title="Finara API",
    version="1.0"
)

# --- CONFIGURACIÓN DE CORS (PERMISOS) ---
# Esto permite que tu app de Flutter se conecte sin bloqueos
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite todas las conexiones
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear las tablas en la base de datos
Base.metadata.create_all(bind=engine)

# Agregar las rutas definidas
app.include_router(auth_routes.router)
app.include_router(user_routes.router)
# app.include_router(ai_routes.router)
app.include_router(transaction_routes.router)
app.include_router(news_router)
app.include_router(video_routes.router)
app.include_router(lecturas_routes.router)
app.include_router(stock_routes.stock_router)
app.include_router(category_routes.router)