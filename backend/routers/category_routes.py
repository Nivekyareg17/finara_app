from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from auth import verify_token
from database import SessionLocal
from models import Category, User
import schemas

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
    db.query(Category).filter(Category.user_id == user.id).all()


@router.post("/")
def create_category(
    category: schemas.CategoryCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    new_category = Category(
        name=category.name,
        type=category.type,
        user_id=user.id
    )

    db.add(new_category)
    db.commit()
    db.refresh(new_category)

    return new_category