# Importaciones
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

import schemas
from security import hash_password
from database import SessionLocal
from models import User
from auth import verify_token, require_admin

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

# Retorna nombre y email del usuario
    return {
        "name": user.name,
        "email": user.email,
        "role": data["role"]
    }


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