from sqlalchemy import Column, ForeignKey, Integer, String, DateTime, Float
from sqlalchemy.orm import relationship
from database import Base

# 1. TABLA DE CATEGORÍAS
class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    type = Column(String)

    user_id = Column(Integer, ForeignKey("users.id"))
    user = relationship("User")

    transactions = relationship("Transaction", back_populates="category")


# 2. TABLA DE ROLES
class Role(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True)
    users = relationship("User", back_populates="role")


# 3. TABLA DE USUARIOS
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)

    role_id = Column(Integer, ForeignKey("roles.id"))
    role = relationship("Role", back_populates="users")

    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    reset_tokens = relationship("PasswordResetToken", backref="user", cascade="all, delete-orphan")


# 4. TABLA DE TRANSACCIONES
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


# 5. RESET TOKEN
class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String, unique=True, index=True)
    expires_at = Column(DateTime)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))