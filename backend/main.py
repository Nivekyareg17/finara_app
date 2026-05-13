import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

import models
from database import engine
from routers import (
    auth_routes,
    category_routes,
    lecturas_routes,
    message_routes,
    stock_routes,
    transaction_routes,
    user_routes,
    video_routes,
    notes_routes, 
)
from routers.news_routes import news_router

app = FastAPI(
    title="Finara API",
    version="1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

os.makedirs("static/profile_pics", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

models.Base.metadata.create_all(bind=engine)

app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(transaction_routes.router)
app.include_router(video_routes.router)
app.include_router(lecturas_routes.router)
app.include_router(stock_routes.router)
app.include_router(category_routes.router)
app.include_router(message_routes.router)
app.include_router(news_router)
app.include_router(notes_routes.router) 


@app.get("/")
def read_root():
    return {"message": "Finara API is running"}