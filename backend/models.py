# Importaciones
from sqlalchemy import Column, ForeignKey, Integer, String  # Importa sqlalchemy para la creación de tablas
from sqlalchemy.orm import relationship  # Permite conectar tablas user - role
from database import Base  # DB donde salen los modelos (SQLAlchemy)

# Creación de tabla de roles
class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True)

    users = relationship("User", back_populates="role")    # Un rol tiene muchos usuarios

#Creación de tabla de usuarios
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)

    role_id = Column(Integer, ForeignKey("roles.id"))   # Guarda el ID del rol - conecta con roles.id
    role = relationship("Role", back_populates="users")