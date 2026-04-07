from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
import models, schemas

router = APIRouter(prefix="/videos", tags=["Videos"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Crear categoría
@router.post("/categories", response_model=schemas.VideoCategoryResponse)
def create_category(category: schemas.VideoCategoryCreate, db: Session = Depends(get_db)):
    new_category = models.VideoCategory(**category.dict())
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category

# Obtener categorías
@router.get("/categories", response_model=list[schemas.VideoCategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(models.VideoCategory).all()

# Crear video
@router.post("/", response_model=schemas.VideoResponse)
def create_video(video: schemas.VideoCreate, db: Session = Depends(get_db)):
    new_video = models.Video(**video.dict())
    db.add(new_video)
    db.commit()
    db.refresh(new_video)
    return new_video

# Obtener videos por categoría
@router.get("/{category_id}", response_model=list[schemas.VideoResponse])
def get_videos(category_id: int, db: Session = Depends(get_db)):
    return db.query(models.Video).filter(models.Video.category_id == category_id).all()