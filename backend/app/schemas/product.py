from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ProductBase(BaseModel):
    name: str
    category: str
    description: Optional[str] = ""
    purchase_price: float
    selling_price: float
    unit: str = "pcs"
    barcode: Optional[str] = None
    supplier_id: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    purchase_price: Optional[float] = None
    selling_price: Optional[float] = None
    unit: Optional[str] = None
    barcode: Optional[str] = None
    supplier_id: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None

class ProductResponse(ProductBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
