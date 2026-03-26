from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Transaction, User
from auth import verify_token
from fastapi.security import OAuth2PasswordBearer
import schemas

router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/")
def create_transaction(
    transaction: schemas.TransactionCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    existing = db.query(Transaction).filter(
        Transaction.user_id == user.id,
        Transaction.type == transaction.type,
        Transaction.amount == transaction.amount,
        Transaction.description == transaction.description
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Transacción duplicada")

    new_transaction = Transaction(
        amount=transaction.amount,
        type=transaction.type,
        description=transaction.description,
        user_id=user.id
    )

    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)

    return new_transaction


@router.get("/")
def get_transactions(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    transactions = db.query(Transaction).filter(
        Transaction.user_id == user.id
    ).all()

    return transactions


@router.put("/{id}")
def update_transaction(
    id: int,
    transaction: schemas.TransactionCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    db_transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == user.id
    ).first()

    if not db_transaction:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    existing = db.query(Transaction).filter(
        Transaction.user_id == user.id,
        Transaction.type == transaction.type,
        Transaction.amount == transaction.amount,
        Transaction.description == transaction.description,
        Transaction.id != id  # 🔥 CLAVE
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Transacción duplicada")

    db_transaction.amount = transaction.amount
    db_transaction.type = transaction.type
    db_transaction.description = transaction.description

    db.commit()
    db.refresh(db_transaction)

    return db_transaction


@router.delete("/{id}")
def delete_transaction(
    id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == user.id
    ).first()

    if not transaction:
        raise HTTPException(status_code=404, detail="No encontrada")

    db.delete(transaction)
    db.commit()

    return {"message": "Eliminada"}