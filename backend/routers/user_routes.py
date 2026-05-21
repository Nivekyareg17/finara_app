# Importaciones
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

import schemas
from security import hash_password
from database import SessionLocal
from models import User, Transaction, PasswordResetToken, EmailVerificationToken, Category, Message
from auth import verify_token, require_admin

from fastapi import UploadFile, File
import base64
import os

UPLOAD_DIR = "static/profile_pics"
os.makedirs(UPLOAD_DIR, exist_ok=True)

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

# Sirve para extraer automáticamente el token JWT del header Authorization cuando alguien llama a una ruta protegida en FastAPI.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# Entrega la sesión al endpoint que la necesite
def get_db():
    db = SessionLocal() # Abre una conexión temporal con PostgreSQL
    try:
        yield db
    finally:
        db.close()  # Cierra la conexión cuando termina la petición, evita problemas de rendimiento

# Endpoint de profile
# Verifica que el token sea válido
@router.get("/profile")    # Esto crea la ruta HTTP GET
def profile(token: str = Depends(oauth2_scheme)):   # Función que extrae el token JWT del header Authorization

    data = verify_token(token)
    email = data["sub"]
    role = data["role"]

# Si el token es válido se devuelve el mensaje de Acceso permitido y el email del usuario
    return {
        "message": "Acceso permitido",
        "user": email
    }
# Si el token no es válido, envía una respuesta 401



# Endpoint de me
# Sirve para obtener datos reales del usuario
@router.get("/me")    # Esto crea la ruta HTTP GET
def get_current_user(   # Función cuando alguien llame /me
    token: str = Depends(oauth2_scheme),    # Recibir el token
    db: Session = Depends(get_db)   # Abrir conexión con PostgreSQL
):
    
    data = verify_token(token)
    email = data["sub"]    # Verificar el token 

    user = db.query(User).filter(User.email == email).first()   # Buscar usuario en la base de datos

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

# Retorna nombre y email del usuario
    return {
        "name": user.name,
        "email": user.email,
        "role": data["role"],
        "profile_image_url": user.profile_image_url,
        "username": user.username,
        "age": user.age,
        "description": user.description,
        "phone": user.phone,
    }


@router.put("/profile-info")
def update_profile_info(
    profile: schemas.UserProfileUpdate,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    email = data["sub"]

    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.username = profile.username.strip() if profile.username else None
    user.age = profile.age
    user.description = profile.description.strip() if profile.description else None
    user.phone = profile.phone.strip() if profile.phone else None

    db.commit()
    db.refresh(user)

    return {
        "name": user.name,
        "email": user.email,
        "profile_image_url": user.profile_image_url,
        "username": user.username,
        "age": user.age,
        "description": user.description,
        "phone": user.phone,
    }

@router.get("/")
def get_users_public(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)

    users = db.query(User).all()

    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email
        } for u in users
    ]


@router.post("/create-admin")
def create_admin(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    data = Depends(require_admin)
):
    existing_user = db.query(User).filter(User.email == user.email).first()

    if existing_user:
        raise HTTPException(status_code=400, detail="Email ya existe")

    hashed_password = hash_password(user.password)

    new_admin = User(
        name=user.name,
        email=user.email,
        password=hashed_password,
        role_id=1  # admin
    )

    db.add(new_admin)
    db.commit()
    db.refresh(new_admin)

    return {"message": "Admin creado"}


# Listar usuarios
@router.get("/all")
def get_users(
    db: Session = Depends(get_db),
    data = Depends(require_admin)
):
    users = db.query(User).all()

    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "role": u.role.name
        } for u in users
    ]

# Eliminar usuario
@router.delete("/delete/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    data = Depends(require_admin)
):

    try:

        db.query(Category)\
            .filter(
                Category.user_id
                == user_id
            ).delete()

        db.query(Message)\
            .filter(
                (Message.sender_id == user_id)
                |
                (Message.receiver_id == user_id)
            ).delete(
                synchronize_session=False
            )
        
        user = db.query(User)\
            .filter(User.id == user_id)\
            .first()

        if not user:

            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado"
            )

        db.query(Transaction)\
            .filter(
                Transaction.user_id
                == user_id
            ).delete()

        db.query(PasswordResetToken)\
            .filter(
                PasswordResetToken.user_id
                == user_id
            ).delete()

        db.query(EmailVerificationToken)\
            .filter(
                EmailVerificationToken.user_id
                == user_id
            ).delete()

        db.delete(user)

        db.commit()

        return {
            "message":
            "Usuario eliminado"
        }

    except Exception as e:

        print(
            "ERROR DELETE:",
            str(e)
        )

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# Cambiar Rol (admin <-> user)
@router.put("/make-admin/{user_id}")
def make_admin(
    user_id: int,
    db: Session = Depends(get_db),
    data = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.role_id = 1
    db.commit()

    return {"message": "Ahora es admin"}


@router.put("/remove-admin/{user_id}")
def remove_admin(
    user_id: int,
    db: Session = Depends(get_db),
    data = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.role_id = 2
    db.commit()

    return {"message": "Ahora es usuario normal"}


@router.post("/upload-profile-picture")
async def upload_profile_picture(
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    data = verify_token(token)
    email = data["sub"]

    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    contents = await file.read()

    if not contents:
        raise HTTPException(status_code=400, detail="Archivo vacio")

    content_type = file.content_type or "image/jpeg"
    encoded_image = base64.b64encode(contents).decode("utf-8")
    url = f"data:{content_type};base64,{encoded_image}"

    user.profile_image_url = url
    db.commit()

    return {"url": url}
