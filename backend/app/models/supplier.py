import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, JSON
import enum
from app.database import Base

class PurchaseOrderStatus(str, enum.Enum):
    draft = "draft"
    sent = "sent"
    received = "received"
    partiallyReceived = "partiallyReceived"
    cancelled = "cancelled"

class Supplier(Base):
    __tablename__ = "suppliers"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    contact_person = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    email = Column(String, nullable=True)
    address = Column(String, nullable=False)
    product_ids = Column(JSON, default=list)  # list of product string IDs
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    supplier_id = Column(String, index=True, nullable=False)
    supplier_name = Column(String, nullable=False)
    items = Column(JSON, nullable=False)
    total_amount = Column(Float, nullable=False)
    status = Column(Enum(PurchaseOrderStatus), default=PurchaseOrderStatus.draft)
    created_by_user_id = Column(String, nullable=False)
    created_by_user_name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expected_delivery_date = Column(DateTime, nullable=True)
    notes = Column(String, nullable=True)
    target_store_id = Column(String, index=True, nullable=False)

class DamagedProduct(Base):
    __tablename__ = "damaged_products"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    product_id = Column(String, index=True, nullable=False)
    product_name = Column(String, nullable=False)
    supplier_id = Column(String, index=True, nullable=False)
    supplier_name = Column(String, nullable=False)
    store_id = Column(String, index=True, nullable=False)
    quantity = Column(Integer, nullable=False)
    estimated_loss = Column(Float, nullable=False)
    reason = Column(String, nullable=False)
    reported_at = Column(DateTime, default=datetime.utcnow, index=True)
    reported_by_user_id = Column(String, nullable=False)
    reported_by_user_name = Column(String, nullable=False)
    notes = Column(String, nullable=True)
