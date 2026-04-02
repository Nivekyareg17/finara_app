# Importaciones
from sqlalchemy import Column, ForeignKey, Integer, String, DateTime  # Importa sqlalchemy para la creación de tablas
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

    transactions = relationship("Transaction", back_populates="user")

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Integer)
    type = Column(String)
    description = Column(String)

    user_id = Column(Integer, ForeignKey("users.id"))
    user = relationship("User", back_populates="transactions")

class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    token = Column(String, unique=True, index=True)
    expires_at = Column(DateTime)