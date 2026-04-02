# Importar CryptContext que genera hashes de contraseñas
from passlib.context import CryptContext

import uuid
from datetime import datetime, timedelta

# Aquí se configura como se van a configurar las contraseñas
# bcrypt es un algoritmo que permite proteger contra ataques de fuerza bruta
# deprecated="auto" permite que si el algoritmo se vuelve viejo lo marque como obsoleto de forma automática
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Función para encriptar contraseña
def hash_password(password: str):   # Espera una contraseña en texto
    return pwd_context.hash(password)   # Aquí se toma la contraseña y se encripta

# Función para verificar contraseña
# Esta función sirve para el login
def verify_password(plain_password, hashed_password):   # Recibe plain_password(contraseña que escribe el usuario) y hashed_password(contraseña guardad en la base)
    return pwd_context.verify(plain_password, hashed_password)  # Verifica si la contraseña es correcta

# Genera token unico
def create_reset_token():
    return str(uuid.uuid4())

# Expiracion de token (15 minutos)
def get_expiration():
    return datetime.utcnow() + timedelta(minutes=15)