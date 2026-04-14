from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Category

router = APIRouter(
    prefix="/categories",
    tags=["Categories"]
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/")
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).all()