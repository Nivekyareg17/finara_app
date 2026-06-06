from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
from models import Note, User
from pydantic import BaseModel
from auth import SECRET_KEY, ALGORITHM  # importa desde donde los defines

router = APIRouter(prefix="/notes", tags=["Notas"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    from jose import jwt, JWTError
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")  # ✅ el token guarda email en "sub"
        if email is None:
            raise HTTPException(status_code=401, detail="Token inválido")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

    user = db.query(User).filter(User.email == email).first()  # ✅ busca por email
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user  # ✅ retorna objeto User, no dict

class NoteSchema(BaseModel):
    title: str
    content: str
    category_name: str = "General"

@router.post("/")
async def create_note(data: NoteSchema, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    new_note = Note(
        title=data.title,
        content=data.content,
        category_name=data.category_name,
        user_id=current_user.id
    )
    db.add(new_note)
    db.commit()
    db.refresh(new_note)
    return new_note

@router.get("/")
async def get_notes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Note).filter(Note.user_id == current_user.id).all()

@router.put("/{note_id}/")
async def update_note(note_id: int, data: NoteSchema, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    note = db.query(Note).filter(Note.id == note_id, Note.user_id == current_user.id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Nota no encontrada")
    note.title = data.title
    note.content = data.content
    note.category_name = data.category_name
    db.commit()
    db.refresh(note)
    return note

@router.delete("/{note_id}/")
async def delete_note(note_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    note = db.query(Note).filter(Note.id == note_id, Note.user_id == current_user.id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Nota no encontrada")
    db.delete(note)
    db.commit()
    return {"status": "deleted", "id": note_id}