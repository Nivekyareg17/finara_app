from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import SessionLocal
from models import Lectura
from schemas import LecturaCreate

router = APIRouter(
    prefix="/api/lecturas",
    tags=["Lecturas"]
)

# DB
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
    return db.query(Lectura).all()

# PUT
@router.put("/{lectura_id}")
def actualizar_lectura(
    lectura_id: int,
    data: LecturaCreate,
    db: Session = Depends(get_db)
):
    lectura = db.query(Lectura).filter(Lectura.id == lectura_id).first()

    if not lectura:
        return {"error": "Lectura no encontrada"}

    lectura.titulo = data.titulo
    lectura.contenido = data.contenido
    lectura.tiempo_lectura = data.tiempo_lectura

    db.commit()
    db.refresh(lectura)

    return lectura

# DELETE
@router.delete("/{lectura_id}")
def eliminar_lectura(lectura_id: int, db: Session = Depends(get_db)):
    lectura = db.query(Lectura).filter(Lectura.id == lectura_id).first()

    if not lectura:
        return {"error": "Lectura no encontrada"}

    db.delete(lectura)
    db.commit()

    return {"message": "Lectura eliminada"}