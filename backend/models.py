# Importaciones
from sqlalchemy import Column, ForeignKey, Integer, String, DateTime, Float  # Importa sqlalchemy para la creación de tablas
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

    transactions = relationship(
        "Transaction",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    reset_tokens = relationship(
        "PasswordResetToken",
        backref="user",
        cascade="all, delete-orphan"
    )

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float)
    type = Column(String)
    description = Column(String)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    user = relationship("User", back_populates="transactions")

    category_id = Column(Integer, ForeignKey("categories.id"))
    category = relationship("Category", back_populates="transactions")


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    type = Column(String)

    transactions = relationship("Transaction", back_populates="category")
    user_id = Column(Integer, ForeignKey("users.id"))
    user = relationship("User")

class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    token = Column(String, unique=True, index=True)
    expires_at = Column(DateTime)

class VideoCategory(Base):
    __tablename__ = "video_categories"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(String)

    videos = relationship("Video", back_populates="category", cascade="all, delete-orphan")


class Video(Base):
    __tablename__ = "videos"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    url = Column(String)

    category_id = Column(Integer, ForeignKey("video_categories.id", ondelete="CASCADE"))
    category = relationship("VideoCategory", back_populates="videos")


class Lectura(Base):
    __tablename__ = "lecturas"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String)
    contenido = Column(String)
    tiempo_lectura = Column(String)