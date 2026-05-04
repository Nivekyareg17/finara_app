from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from fastapi.staticfiles import StaticFiles
from routers.news_routes import news_router
import models

from routers import (
    auth_routes, 
    user_routes, 
    transaction_routes, 
    video_routes, 
    lecturas_routes, 
    stock_routes,
    category_routes,
    message_routes
)

# 1. Crear la aplicación backend
app = FastAPI(
    title="Finara API",
    version="1.0"
)

app.mount("/static", StaticFiles(directory="static"), name="static")

# 2. CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. DB
models.Base.metadata.create_all(bind=engine)

# 4. Routers
app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(transaction_routes.router)
app.include_router(category_routes.router)
app.include_router(news_router)
app.include_router(video_routes.router)
app.include_router(lecturas_routes.router)
app.include_router(stock_routes.stock_router)
app.include_router(message_routes.router)

@app.get("/")
def read_root():
    return {"message": "Finara API is running"}