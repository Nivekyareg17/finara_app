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

# Editar categoria
@router.put("/categories/{category_id}")
def update_category(
    category_id: int,
    data: schemas.VideoCategoryCreate,
    db: Session = Depends(get_db)
):
    category = db.query(models.VideoCategory).filter(
        models.VideoCategory.id == category_id
    ).first()

    if not category:
        return {"error": "Categoría no encontrada"}

    category.title = data.title
    category.description = data.description

    db.commit()
    db.refresh(category)

    return category


# Eliminar categoria
@router.delete("/categories/{category_id}")
def delete_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(models.VideoCategory).filter(
        models.VideoCategory.id == category_id
    ).first()

    if not category:
        return {"error": "Categoría no encontrada"}

    db.delete(category)
    db.commit()

    return {"message": "Categoría eliminada"}


# Editar video
@router.put("/{video_id}")
def update_video(
    video_id: int,
    data: schemas.VideoCreate,
    db: Session = Depends(get_db)
):
    video = db.query(models.Video).filter(
        models.Video.id == video_id
    ).first()

    if not video:
        return {"error": "Video no encontrado"}

    video.title = data.title
    video.url = data.url
    video.category_id = data.category_id

    db.commit()
    db.refresh(video)

    return video


# Eliminar video
@router.delete("/{video_id}")
def delete_video(video_id: int, db: Session = Depends(get_db)):
    video = db.query(models.Video).filter(
        models.Video.id == video_id
    ).first()

    if not video:
        return {"error": "Video no encontrado"}

    db.delete(video)
    db.commit()

    return {"message": "Video eliminado"}