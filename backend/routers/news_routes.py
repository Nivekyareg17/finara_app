import os
import requests

from fastapi import APIRouter

news_router = APIRouter(
    prefix="/api",
    tags=["News API"]
)

API_KEY = os.getenv("FINNHUB_API_KEY")

@news_router.get("/")
def get_news():
    url = f"https://finnhub.io/api/v1/news?category=general&token={API_KEY}"

    response = requests.get(url)
    data = response.json()

    noticias = []

    for item in data[:10]:
        noticias.append({
            "titulo": item.get("headline"),
            "categoria": item.get("category"),
            "imagen": item.get("image"),
            "fecha": item.get("datetime"),
            "fuente": item.get("source"),
            "url": item.get("url")
        })

    return noticias