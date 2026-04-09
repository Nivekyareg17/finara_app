from datetime import time
import os
import requests
from fastapi import APIRouter

stock_router = APIRouter(
    prefix="/api/stocks",
    tags=["Stocks API"]
)

API_KEY = os.getenv("FINNHUB_API_KEY")

SYMBOLS = [
    "AAPL",   # Apple
    "TSLA",   # Tesla
    "GOOGL",  # Google
    "AMZN",   # Amazon
    "MSFT",   # Microsoft
    "META",   # Facebook
    "NVDA",   # Nvidia
    "NFLX",   # Netflix
    "AMD",    # AMD
    "INTC"    # Intel
]

@stock_router.get("/")
def get_stocks():
    stocks = []

    for symbol in SYMBOLS:
        url = f"https://finnhub.io/api/v1/quote?symbol={symbol}&token={API_KEY}"
        response = requests.get(url)
        data = response.json()

        stocks.append({
            "symbol": symbol,
            "price": data.get("c"),
            "change": data.get("d"),
            "percent": data.get("dp")
        })

    return stocks

@stock_router.get("/history")
def get_stock_history(symbol: str):
    end = int(time.time())
    start = end - 60 * 60 * 24 * 7  # últimos 7 días

    url = f"https://finnhub.io/api/v1/stock/candle?symbol={symbol}&resolution=60&from={start}&to={end}&token={API_KEY}"
    
    response = requests.get(url)
    data = response.json()

    if data.get("s") != "ok":
        return {"error": "No data"}

    return {
        "prices": data.get("c", []),  # precios
        "timestamps": data.get("t", [])
    }