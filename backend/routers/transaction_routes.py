from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import SessionLocal, engine
from models import Transaction, User, Category
from auth import verify_token
from fastapi.security import OAuth2PasswordBearer
import schemas
from datetime import datetime

router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def ensure_transaction_date_column():
    try:
        with engine.begin() as connection:
            connection.execute(
                text(
                    "ALTER TABLE transactions "
                    "ADD COLUMN IF NOT EXISTS date TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                )
            )
    except Exception as exc:
        print(f"Could not ensure transactions.date column: {exc}")


def serialize_transaction_row(row):
    data = dict(row)
    if data.get("date") is None:
        data["date"] = datetime.utcnow()
    return data

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
    ensure_transaction_date_column()
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    category = db.query(Category).filter(
        Category.id == transaction.category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

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
        date=transaction.date or datetime.utcnow(),
        category_id=transaction.category_id,
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
    ensure_transaction_date_column()
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    try:
        transactions = db.query(Transaction).filter(
            Transaction.user_id == user.id
        ).order_by(Transaction.date.desc(), Transaction.id.desc()).all()

        return transactions
    except Exception as exc:
        print(f"ORM transactions query failed: {exc}")
        db.rollback()

    try:
        rows = db.execute(
            text(
                """
                SELECT id, amount, type, description, category_id, user_id,
                       COALESCE(date, CURRENT_TIMESTAMP) AS date
                FROM transactions
                WHERE user_id = :user_id
                ORDER BY COALESCE(date, CURRENT_TIMESTAMP) DESC, id DESC
                """
            ),
            {"user_id": user.id},
        ).mappings().all()

        return [serialize_transaction_row(row) for row in rows]
    except Exception as exc:
        print(f"Date fallback transactions query failed: {exc}")
        db.rollback()

    rows = db.execute(
        text(
            """
            SELECT id, amount, type, description, category_id, user_id,
                   CURRENT_TIMESTAMP AS date
            FROM transactions
            WHERE user_id = :user_id
            ORDER BY id DESC
            """
        ),
        {"user_id": user.id},
    ).mappings().all()

    return [serialize_transaction_row(row) for row in rows]


@router.put("/{id}")
def update_transaction(
    id: int,
    transaction: schemas.TransactionCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    ensure_transaction_date_column()
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    db_transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == user.id
    ).first()

    if not db_transaction:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")

    category = db.query(Category).filter(
        Category.id == transaction.category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

    existing = db.query(Transaction).filter(
        Transaction.user_id == user.id,
        Transaction.type == transaction.type,
        Transaction.amount == transaction.amount,
        Transaction.description == transaction.description,
        Transaction.id != id
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Transacción duplicada")

    db_transaction.amount = transaction.amount
    db_transaction.type = transaction.type
    db_transaction.description = transaction.description
    db_transaction.date = transaction.date or db_transaction.date
    db_transaction.category_id = transaction.category_id

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
