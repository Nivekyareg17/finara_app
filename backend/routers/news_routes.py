from fastapi import APIRouter

news_router = APIRouter()

@news_router.get("/news")
def get_news():
    return {"message": "Noticias funcionando 🚀"}