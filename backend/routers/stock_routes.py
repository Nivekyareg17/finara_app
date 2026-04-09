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
    url = f"https://finnhub.io/api/v1/quote?symbol={symbol}&token={API_KEY}"
    
    response = requests.get(url)
    data = response.json()

    # simulamos histórico con variación
    price = data.get("c", 0)

    prices = [
        price * 0.95,
        price * 0.97,
        price * 0.96,
        price * 0.98,
        price * 1.00,
    ]

    return {
        "prices": prices
    }