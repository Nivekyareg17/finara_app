from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import schemas
from auth import verify_token
from database import SessionLocal
from models import BlockedUser, Message, User

router = APIRouter(prefix="/messages", tags=["Messages"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(token: str, db: Session) -> User:
    data = verify_token(token)
    user = db.query(User).filter(User.email == data["sub"]).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return user


def is_blocked_between(db: Session, user_a: int, user_b: int) -> bool:
    return db.query(BlockedUser).filter(
        ((BlockedUser.blocker_id == user_a) & (BlockedUser.blocked_id == user_b))
        | ((BlockedUser.blocker_id == user_b) & (BlockedUser.blocked_id == user_a))
    ).first() is not None


@router.get("/blocked/{user_id}")
def get_block_status(
    user_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)
    blocked_by_me = db.query(BlockedUser).filter(
        BlockedUser.blocker_id == current_user.id,
        BlockedUser.blocked_id == user_id,
    ).first()
    blocked_me = db.query(BlockedUser).filter(
        BlockedUser.blocker_id == user_id,
        BlockedUser.blocked_id == current_user.id,
    ).first()

    return {
        "blocked": blocked_by_me is not None or blocked_me is not None,
        "blocked_by_me": blocked_by_me is not None,
        "blocked_me": blocked_me is not None,
    }


@router.post("/block/{user_id}")
def block_user(
    user_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    if current_user.id == user_id:
        raise HTTPException(status_code=400, detail="No puedes bloquearte a ti mismo")

    existing = db.query(BlockedUser).filter(
        BlockedUser.blocker_id == current_user.id,
        BlockedUser.blocked_id == user_id,
    ).first()

    if not existing:
        try:
            db.add(BlockedUser(blocker_id=current_user.id, blocked_id=user_id))
            db.commit()
        except IntegrityError:
            db.rollback()

    return {"blocked": True}


@router.delete("/block/{user_id}")
def unblock_user(
    user_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    existing = db.query(BlockedUser).filter(
        BlockedUser.blocker_id == current_user.id,
        BlockedUser.blocked_id == user_id,
    ).first()

    if existing:
        db.delete(existing)
        db.commit()

    return {"blocked": False}


@router.post("/")
def send_message(
    msg: schemas.MessageCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    sender = get_current_user(token, db)

    if is_blocked_between(db, sender.id, msg.receiver_id):
        raise HTTPException(status_code=403, detail="Chat bloqueado")

    new_msg = Message(
        content=msg.content,
        sender_id=sender.id,
        receiver_id=msg.receiver_id,
        timestamp=datetime.utcnow(),
        is_read=False,
    )

    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    return new_msg


@router.get("/{user_id}")
def get_messages(
    user_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    if is_blocked_between(db, current_user.id, user_id):
        return []

    db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False,
    ).update({"is_read": True})

    messages = db.query(Message).filter(
        ((Message.sender_id == current_user.id) & (Message.receiver_id == user_id))
        | ((Message.sender_id == user_id) & (Message.receiver_id == current_user.id))
    ).order_by(Message.timestamp).all()

    return messages
