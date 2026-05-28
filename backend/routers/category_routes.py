from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import func
from sqlalchemy.orm import Session

import models
import schemas
from auth import verify_token
from database import SessionLocal
from models import Category, User

router = APIRouter(
    prefix="/categories",
    tags=["Categories"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_user_from_token(token: str, db: Session) -> User:
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return user


DEFAULT_CATEGORIES = (
    {"name": "Salario", "type": "ingreso"},
    {"name": "Otros ingresos", "type": "ingreso"},
    {"name": "Comida", "type": "gasto"},
    {"name": "Transporte", "type": "gasto"},
)


def ensure_default_categories(user: User, db: Session) -> None:
    existing = db.query(Category).filter(Category.user_id == user.id).all()
    existing_keys = {
        (category.name.strip().lower(), category.type)
        for category in existing
    }

    created = False
    for category in DEFAULT_CATEGORIES:
        key = (category["name"].lower(), category["type"])
        if key in existing_keys:
            continue

        db.add(Category(
            name=category["name"],
            type=category["type"],
            user_id=user.id,
        ))
        created = True

    if created:
        db.commit()


@router.get("/")
def get_categories(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    user = get_user_from_token(token, db)
    ensure_default_categories(user, db)

    return db.query(Category).filter(
        Category.user_id == user.id
    ).all()


@router.post("/")
def create_category(
    category: schemas.CategoryCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    user = get_user_from_token(token, db)

    existing_category = db.query(Category).filter(
        Category.user_id == user.id,
        func.lower(Category.name) == category.name.strip().lower(),
        Category.type == category.type,
    ).first()

    if existing_category:
        raise HTTPException(
            status_code=400,
            detail="Ya existe una categoría con ese nombre y tipo",
        )

    new_category = Category(
        name=category.name.strip(),
        type=category.type,
        user_id=user.id,
    )

    db.add(new_category)
    db.commit()
    db.refresh(new_category)

    return new_category


@router.put("/{category_id}")
@router.put("/categories/{category_id}")
def update_category(
    category_id: int,
    category_data: schemas.CategoryCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    user = get_user_from_token(token, db)

    db_category = db.query(Category).filter(
        Category.id == category_id,
        Category.user_id == user.id,
    ).first()

    if not db_category:
        raise HTTPException(status_code=404, detail="Categoria no encontrada")

    duplicate_category = db.query(Category).filter(
        Category.user_id == user.id,
        Category.id != category_id,
        func.lower(Category.name) == category_data.name.strip().lower(),
        Category.type == category_data.type,
    ).first()

    if duplicate_category:
        raise HTTPException(
            status_code=400,
            detail="Ya existe una categoría con ese nombre y tipo",
        )

    db_category.name = category_data.name.strip()
    db_category.type = category_data.type

    db.commit()
    db.refresh(db_category)
    return db_category


@router.delete("/{category_id}")
@router.delete("/categories/{category_id}")
def delete_category(
    category_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    user = get_user_from_token(token, db)

    db_category = db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user.id,
    ).first()

    if not db_category:
        raise HTTPException(status_code=404, detail="Categoria no encontrada")

    db.delete(db_category)
    db.commit()
    return {"message": "Categoria eliminada"}
