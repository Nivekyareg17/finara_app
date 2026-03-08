# Importaciones
from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from database import SessionLocal
from models import User
from auth import verify_token

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

    email = verify_token(token)    # Verificar el token creado en verify_token()

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
    
    email = verify_token(token)    # Verificar el token 

    user = db.query(User).filter(User.email == email).first()   # Buscar usuario en la base de datos

# Retorna nombre y email del usuario
    return {
        "name": user.name,
        "email": user.email
    }
