from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import datetime
from app.models.supplier import PurchaseOrderStatus

class SupplierBase(BaseModel):
    name: str
    contact_person: str
    phone: str
    email: Optional[str] = None
    address: str
    product_ids: List[str] = []
    is_active: bool = True

class SupplierCreate(SupplierBase):
    pass

class SupplierResponse(SupplierBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True

class CreatePurchaseOrderRequest(BaseModel):
    supplier_id: str
    supplier_name: str
    items: List[Any]
    total_amount: float
    target_store_id: str
    expected_delivery_date: Optional[datetime] = None
    notes: Optional[str] = None

class PurchaseOrderResponse(BaseModel):
    id: str
    supplier_id: str
    supplier_name: str
    items: List[Any]
    total_amount: float
    status: PurchaseOrderStatus
    created_by_user_id: str
    created_by_user_name: str
    created_at: datetime
    expected_delivery_date: Optional[datetime] = None
    notes: Optional[str] = None
    target_store_id: str

    class Config:
        from_attributes = True

class CreateDamagedProductRequest(BaseModel):
    product_id: str
    product_name: str
    supplier_id: str
    supplier_name: str
    store_id: str
    quantity: int
    estimated_loss: float
    reason: str
    notes: Optional[str] = None

class DamagedProductResponse(BaseModel):
    id: str
    product_id: str
    product_name: str
    supplier_id: str
    supplier_name: str
    store_id: str
    quantity: int
    estimated_loss: float
    reason: str
    reported_at: datetime
    reported_by_user_id: str
    reported_by_user_name: str
    notes: Optional[str] = None

    class Config:
        from_attributes = True
