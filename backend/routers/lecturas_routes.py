from fastapi import APIRouter, Depends
from requests import Session

from backend.database import SessionLocal
from backend.models import Lectura
from backend.schemas import LecturaCreate


router = APIRouter(
    prefix="/api/lecturas",
    tags="Lecturas"
)

#DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# POST
@router.post("/")
def crear_lectura(data: LecturaCreate, db: Session = Depends(get_db)):
    nueva = Lectura(**data.dict())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva

# GET
@router.get("/")
def obtener_lecturas(db: Session = Depends(get_db)):
    return db.__query(Lectura).all()