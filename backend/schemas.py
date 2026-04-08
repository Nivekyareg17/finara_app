from pydantic import BaseModel, EmailStr, Field, validator
from typing import Literal
import re

# Creación de tablas
# Validaciones de datos para los registros
class UserCreate(BaseModel):
    name: str = Field(..., min_length=6, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)

# Aquí se valida la contraseña para que sea más fuerte
    @validator("password")
    def password_strength(cls, value):
        if not re.search(r"[A-Za-z]", value):   # Verifica que haya al menos una letra
            raise ValueError("La contraseña debe tener al menos una letra")
        
        if not re.search(r"[0-9]", value):    # Valida que  haya al menos un número
            raise ValueError("La contraseña debe tener al menos un número")
        
        return value

class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)

class TransactionCreate(BaseModel):
    amount: float = Field(..., gt=0)
    type: Literal["ingreso", "gasto"]
    description: str = Field(..., min_length=1, max_length=100)


class TransactionResponse(BaseModel):
    id: int
    amount: int
    type: str
    description: str

    class Config:
        orm_mode = True


# VIDEO CATEGORY
class VideoCategoryCreate(BaseModel):
    title: str
    description: str

class VideoCategoryResponse(BaseModel):
    id: int
    title: str
    description: str

    class Config:
        orm_mode = True


class VideoCreate(BaseModel):
    title: str
    url: str
    category_id: int

class VideoResponse(BaseModel):
    id: int
    title: str
    url: str
    category_id: int

    class Config:
        orm_mode = True


class LecturaCreate(BaseModel):
    titulo: str
    contenido: str
    tiempo_lectura: str

class LecturaResponse(BaseModel):
    id: int
    titulo: str
    contenido: str
    tiempo_lectura: str

    class Config:
        orm_mode = True