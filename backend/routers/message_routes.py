from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Message, User
from auth import verify_token
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime
import schemas

router = APIRouter(prefix="/messages", tags=["Messages"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/")
def send_message(
    msg: schemas.MessageCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    sender = db.query(User).filter(User.email == data["sub"]).first()

    new_msg = Message(
        content=msg.content,
        sender_id=sender.id,
        receiver_id=msg.receiver_id,
        timestamp=datetime.utcnow(),
        is_read=False
    )

    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    return new_msg


@router.get("/{user_id}")
def get_messages(
    user_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    current_user = db.query(User).filter(User.email == data["sub"]).first()

    db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).update({"is_read": True})

    messages = db.query(Message).filter(
        ((Message.sender_id == current_user.id) & (Message.receiver_id == user_id)) |
        ((Message.sender_id == user_id) & (Message.receiver_id == current_user.id))
    ).order_by(Message.timestamp).all()

    return messages