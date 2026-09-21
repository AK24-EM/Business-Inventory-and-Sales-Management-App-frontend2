from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import datetime
from app.models.sale import PaymentMode

class SaleItemSchema(BaseModel):
    productId: str
    productName: str
    category: str
    quantity: int
    unitPrice: float
    totalPrice: float

class CreateSaleRequest(BaseModel):
    store_id: str
    store_name: str
    items: List[SaleItemSchema]
    payment_mode: PaymentMode
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    discount_amount: float = 0.0
    loyalty_points_redeemed: float = 0.0

class SaleResponse(BaseModel):
    id: str
    store_id: str
    store_name: str
    items: List[Any]
    subtotal: float
    discount_amount: float
    loyalty_points_redeemed: float
    total_amount: float
    payment_mode: PaymentMode
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    loyalty_points_earned: int
    employee_id: str
    employee_name: str
    timestamp: datetime
    invoice_number: str
    is_returned: bool

    class Config:
        from_attributes = True
