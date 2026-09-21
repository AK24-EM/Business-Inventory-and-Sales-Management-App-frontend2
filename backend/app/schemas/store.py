from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class StoreBase(BaseModel):
    name: str
    address: str
    city: str
    phone: str
    email: str
    manager_id: Optional[str] = None
    is_active: bool = True

class StoreCreate(StoreBase):
    pass

class StoreUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    manager_id: Optional[str] = None
    is_active: Optional[bool] = None

class StoreResponse(StoreBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
