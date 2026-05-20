import os

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

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
    version="1.0.1",
)

API_VERSION = "2026-05-19-movements-cors"

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


@app.middleware("http")
async def force_cors_headers(request: Request, call_next):
    if request.method == "OPTIONS":
        return JSONResponse(
            status_code=200,
            content={},
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "*",
            },
        )

    try:
        response = await call_next(request)
    except Exception as exc:
        print(f"Unhandled error on {request.url.path}: {exc}")
        response = JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"},
        )

    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response

os.makedirs("static/profile_pics", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

models.Base.metadata.create_all(bind=engine)


def apply_schema_updates():
    statements = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS description TEXT",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR",
        "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS date TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    ]

    with engine.begin() as connection:
        for statement in statements:
            connection.execute(text(statement))


try:
    apply_schema_updates()
except Exception as exc:
    print(f"Schema update skipped/failed: {exc}")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print(f"Unhandled error on {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        },
    )

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
    return {"message": "Finara API is running", "version": API_VERSION}


@app.get("/health")
def health_check():
    return {"status": "ok", "version": API_VERSION}
