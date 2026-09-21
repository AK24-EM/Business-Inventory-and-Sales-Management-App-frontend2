from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.inventory import StockMovementType, AdjustmentReason, TransferStatus

class InventoryResponse(BaseModel):
    id: str
    store_id: str
    product_id: str
    product_name: str
    category: str
    current_stock: int
    minimum_stock_level: int
    last_updated: datetime

    class Config:
        from_attributes = True

class ReceiveStockRequest(BaseModel):
    store_id: str
    product_id: str
    product_name: str
    quantity: int
    purchase_order_id: Optional[str] = None
    notes: Optional[str] = None

class AdjustStockRequest(BaseModel):
    store_id: str
    product_id: str
    product_name: str
    quantity_change: int  # positive (increase) or negative (decrease)
    reason: AdjustmentReason
    notes: Optional[str] = None

class InitiateTransferRequest(BaseModel):
    source_store_id: str
    destination_store_id: str
    product_id: str
    product_name: str
    quantity: int
    notes: Optional[str] = None

class StockMovementResponse(BaseModel):
    id: str
    store_id: str
    product_id: str
    product_name: str
    type: StockMovementType
    quantity: int
    stock_before: int
    stock_after: int
    reason: Optional[str] = None
    adjustment_reason: Optional[AdjustmentReason] = None
    reference_id: Optional[str] = None
    user_id: str
    user_name: str
    timestamp: datetime

    class Config:
        from_attributes = True

class StockTransferResponse(BaseModel):
    id: str
    source_store_id: str
    destination_store_id: str
    product_id: str
    product_name: str
    quantity: int
    initiated_by_user_id: str
    initiated_by_user_name: str
    initiated_at: datetime
    confirmed_by_user_id: Optional[str] = None
    confirmed_by_user_name: Optional[str] = None
    confirmed_at: Optional[datetime] = None
    status: TransferStatus
    notes: Optional[str] = None

    class Config:
        from_attributes = True
