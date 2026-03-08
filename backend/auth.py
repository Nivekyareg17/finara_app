# Importaciones
from jose import JWTError, jwt  # Permite crear, decodificar y verificar tokens
from fastapi import HTTPException, status
from datetime import datetime, timedelta    # Manejo de fechas
from models import User

SECRET_KEY = "finara_secret_key"    # Clave que usa el servidor para firmar el token (datos del usuario + SECRET_KEY = token firmado), si se intenta modificar la firma no coincidirá
ALGORITHM = "HS256"    # Define algorítmo de la firma del JWT
ACCESS_TOKEN_EXPIRE_MINUTES = 120    # El token será valido por 120 minutos


# Función para generar tokens
def create_access_token(data: dict):    # La función recibe datos del usuario

    to_encode = data.copy()    # Se crea una copia del diccionario, esto evita modificar los dato originales

    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)    # Crea una fecha de expiración

    to_encode.update({"exp": expire})   # Agrega expiración al token

# Generación de JWT, se toman datos del usuario + fecha expiración + SECRET_KEY
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Retorna el token el cual se envía al cliente
    return encoded_jwt

def verify_token(token: str):

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")

        if email is None:
            raise HTTPException(status_code=401, detail="Token inválido")
        
        return email
    
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")