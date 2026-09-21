import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum
import enum
from app.database import Base

class UserRole(str, enum.Enum):
    owner = "owner"
    manager = "manager"
    employee = "employee"
    admin = "admin"

class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    firebase_uid = Column(String, unique=True, index=True, nullable=True)  # Firebase Auth UID
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.employee, nullable=False)
    assigned_store_id = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    fcm_token = Column(String, nullable=True)
