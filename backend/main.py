from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from fastapi import UploadFile, File
import models  # IMPORTANTE para registrar modelos
import shutil
import os


# Carpeta donde se guardarán las fotos
UPLOAD_DIR = "static/profile_pics"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/users/upload-profile-picture")
async def upload_picture(
    file: UploadFile = File(...), 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    file_path = f"{UPLOAD_DIR}/{current_user.id}_{file.filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Guardamos la URL en la base de datos
    url = f"https://tu-api-en-render.com/{file_path}"
    current_user.profile_image_url = url
    db.commit()
    
    return {"url": url}

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
app.include_router(category_routes.router)
app.include_router(news_router)
app.include_router(video_routes.router)
app.include_router(lecturas_routes.router)
app.include_router(stock_routes.stock_router)

# Ruta raíz (para probar que funciona)
@app.get("/")
def read_root():
    return {"message": "Finara API is running"}