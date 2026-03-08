# Importaciones
from sqlalchemy import Column, Integer, String  # Importa sqlalchemy para la creación de tablas
from database import Base

#Creación de tabla de usuarios
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)