from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import schemas
from auth import verify_token
from database import SessionLocal
from models import BlockedUser, Message, MessageRequest, User

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


@router.post("/request")
def send_request(
    request: schemas.MessageRequestCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    if current_user.id == request.receiver_id:
        raise HTTPException(
            status_code=400,
            detail="No puedes enviarte solicitud a ti mismo"
        )

    existing = db.query(MessageRequest).filter(
        (
            (MessageRequest.sender_id == current_user.id) &
            (MessageRequest.receiver_id == request.receiver_id)
        ) |
        (
            (MessageRequest.sender_id == request.receiver_id) &
            (MessageRequest.receiver_id == current_user.id)
        )
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Ya existe una solicitud o conversacion"
        )

    new_request = MessageRequest(
        sender_id=current_user.id,
        receiver_id=request.receiver_id,
        status="pending"
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return new_request


@router.get("/requests")
def get_requests(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    requests = db.query(MessageRequest).filter(
        MessageRequest.receiver_id == current_user.id,
        MessageRequest.status == "pending"
    ).all()

    result = []

    for req in requests:

        sender = db.query(User).filter(
            User.id == req.sender_id
        ).first()

        result.append({
            "id": req.id,
            "sender_id": req.sender_id,
            "sender_name": sender.name,
            "sender_email": sender.email,
            "status": req.status,
        })

    return result


@router.post("/request/{request_id}/accept")
def accept_request(
    request_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    request = db.query(MessageRequest).filter(
        MessageRequest.id == request_id,
        MessageRequest.receiver_id == current_user.id
    ).first()

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Solicitud no encontrada"
        )

    request.status = "accepted"

    db.commit()
    db.refresh(request)

    return request


@router.post("/request/{request_id}/reject")
def reject_request(
    request_id: int,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    request = db.query(MessageRequest).filter(
        MessageRequest.id == request_id,
        MessageRequest.receiver_id == current_user.id
    ).first()

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Solicitud no encontrada"
        )

    request.status = "rejected"

    db.commit()
    db.refresh(request)

    return request


@router.post("/")
def send_message(
    msg: schemas.MessageCreate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    sender = get_current_user(token, db)

    allowed_chat = db.query(MessageRequest).filter(
        (
            (MessageRequest.sender_id == sender.id) &
            (MessageRequest.receiver_id == msg.receiver_id)
        ) |
        (
            (MessageRequest.sender_id == msg.receiver_id) &
            (MessageRequest.receiver_id == sender.id)
        ),
        MessageRequest.status == "accepted"
    ).first()

    if not allowed_chat:
        raise HTTPException(
            status_code=403,
            detail="Debes tener una solicitud aceptada para chatear"
        )

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


@router.get("/search")
def search_user(
    email: str,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    user = db.query(User).filter(
        User.email == email,
        User.id != current_user.id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado"
        )

    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
    }

@router.get("/chats")
def get_chats(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    current_user = get_current_user(token, db)

    requests = db.query(MessageRequest).filter(
        (
            (MessageRequest.sender_id == current_user.id)
            |
            (MessageRequest.receiver_id == current_user.id)
        ),
        MessageRequest.status == "accepted"
    ).all()

    chats = []

    for req in requests:

        other_id = (
            req.receiver_id
            if req.sender_id == current_user.id
            else req.sender_id
        )

        user = db.query(User).filter(
            User.id == other_id
        ).first()

        if user:
            last_message = db.query(Message).filter(
                (
                    (Message.sender_id == current_user.id) &
                    (Message.receiver_id == other_id)
                )
                |
                (
                    (Message.sender_id == other_id) &
                    (Message.receiver_id == current_user.id)
                )
            ).order_by(
                Message.timestamp.desc()
            ).first()

            chats.append({
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "profile_image_url": user.profile_image_url,
                "username": user.username,
                "description": user.description,
                "last_message":
                    last_message.content
                    if last_message
                    else "Sin mensajes",
                "last_time":
                    last_message.timestamp.isoformat()
                    if last_message
                    else None,
            })

    return chats


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


