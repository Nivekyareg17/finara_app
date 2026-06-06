from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
from models import Note, User
from pydantic import BaseModel
from routers.user_routes import get_current_user  # ✅ reutiliza el mismo que funciona en /users/me

router = APIRouter(prefix="/notes", tags=["Notas"])

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