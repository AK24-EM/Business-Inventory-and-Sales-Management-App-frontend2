from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.customer import LoyaltyTransactionType

class CustomerCreate(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None
    registered_store_id: str

class CustomerResponse(BaseModel):
    id: str
    name: str
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None
    registered_at: datetime
    registered_store_id: str
    registered_by_user_id: str
    is_active: bool

    class Config:
        from_attributes = True

class LoyaltyAccountResponse(BaseModel):
    id: str
    primary_customer_id: str
    phone: str
    total_points: int
    redeemed_points: int
    available_points: int
    created_at: datetime
    last_activity: datetime

    class Config:
        from_attributes = True

class LoyaltyTransactionResponse(BaseModel):
    id: str
    loyalty_account_id: str
    phone: str
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None
    type: LoyaltyTransactionType
    points: int
    sale_id: Optional[str] = None
    store_id: str
    store_name: str
    processed_by_user_id: str
    processed_by_user_name: str
    timestamp: datetime
    notes: Optional[str] = None

    class Config:
        from_attributes = True
