from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from app.models.user import UserRole

class UserBase(BaseModel):
    name: str
    email: str
    phone: str
    role: UserRole
    assigned_store_id: Optional[str] = None
    is_active: bool = True

class UserCreate(BaseModel):
    name: str
    email: str
    phone: str
    password: str
    role: UserRole = UserRole.employee
    assigned_store_id: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(UserBase):
    id: str
    created_at: datetime
    last_login: Optional[datetime] = None
    fcm_token: Optional[str] = None

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
