import os
import requests

from fastapi import APIRouter

news_router = APIRouter(
    prefix="/api/news",
    tags=["News API"]
)

API_KEY = os.getenv("GNEWS_API_KEY")

@news_router.get("/")
def get_news():
    url = f"https://gnews.io/api/v4/top-headlines?lang=es&topic=business&token={API_KEY}"

    response = requests.get(url)
    data = response.json()

    noticias = []

    for item in data["articles"][:10]:
        noticias.append({
            "titulo": item.get("title"),
            "categoria": "GENERAL",
            "imagen": item.get("image"),
            "fecha": item.get("publishedAt"),
            "fuente": item.get("source", {}).get("name"),
            "url": item.get("url")
        })

    return noticias