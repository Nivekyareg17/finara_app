# Importaciones
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal
from models import User
from security import hash_password, verify_password
from auth import create_access_token
import schemas


router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


# Entrega la sesión al endpoint que la necesite
def get_db():
    db = SessionLocal() # Abre una conexión temporal con PostgreSQL
    try:
        yield db
    finally:
        db.close()  # Cierra la conexión cuando termina la petición, evita problemas de rendimiento



# Endpoint de registro
@router.post("/register")  # Esto crea la ruta HTTP POST

# Aquí se trae a schemas.UserCreate que valida los datos con Pydantic desde schemas
# db: Session = Depends(get_db) dice a fastAPI "obtén una conexión a la base de datos usando get_db" 
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(User.email == user.email).first()

    if existing_user:
        return {"error": "El email ya está registrado"}

    # Contraseña encriptada
    hashed_password = hash_password(user.password)

# Creación de objeto usuario(User) usando los datos recibidos
    new_user = User(
        name=user.name,
        email=user.email,
        password=hashed_password
    )

    db.add(new_user)    # Agrega el usuario a la sesión
    db.commit() # Guarda los datos en PostgreSQL
    db.refresh(new_user)    # Actualiza el objeto con los datos finales guardados

    return {"message": "Usuario creado"}    # Respuesta del backend



# Endpoint de login
@router.post("/login") # Esto crea la ruta HTTP POST

# user: schemas.UserLogin significa que fastAPI espera un JSON con esa estructura creada en schemas
# db: Session = Depends(get_db) crea una conexión a la base de datos usando la función get_db
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):

# Aquí ocurre una consulta a PostgreSQL(db.query(User))
# Aquí se filtra el email por uno específico (.filter(User.email == user.email))
# Aquí devuelve el primer resultado encontrado (.first())
    db_user = db.query(User).filter(User.email == user.email).first()

# Verificar si existe usuario
    if not db_user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    
# Verificar si la contraseña es correcta (contraseña ingresada vs contraseña hash en db)
    if not verify_password(user.password, db_user.password):
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")
    
# Crear el token JWT
    access_token = create_access_token(
        data={"sub": db_user.email}
    )

# Si todo está bien retorna el mensaje exitoso
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
