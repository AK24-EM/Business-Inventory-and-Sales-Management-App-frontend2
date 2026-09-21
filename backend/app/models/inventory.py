import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Enum, Index
import enum
from app.database import Base

class StockMovementType(str, enum.Enum):
    receipt = "receipt"
    sale = "sale"
    adjustment = "adjustment"
    transferOut = "transferOut"
    transferIn = "transferIn"
    damaged = "damaged"

class AdjustmentReason(str, enum.Enum):
    damage = "damage"
    expiry = "expiry"
    countCorrection = "countCorrection"
    other = "other"

class TransferStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    cancelled = "cancelled"

class Inventory(Base):
    __tablename__ = "inventory"
    
    id = Column(String, primary_key=True)  # store_id + "_" + product_id
    store_id = Column(String, index=True, nullable=False)
    product_id = Column(String, index=True, nullable=False)
    product_name = Column(String, nullable=False)
    category = Column(String, nullable=False)
    current_stock = Column(Integer, default=0, nullable=False)
    minimum_stock_level = Column(Integer, default=10, nullable=False)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        Index('idx_store_product', 'store_id', 'product_id'),
    )

class StockMovement(Base):
    __tablename__ = "stock_movements"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String, index=True, nullable=False)
    product_id = Column(String, index=True, nullable=False)
    product_name = Column(String, nullable=False)
    type = Column(Enum(StockMovementType), nullable=False)
    quantity = Column(Integer, nullable=False)
    stock_before = Column(Integer, nullable=False)
    stock_after = Column(Integer, nullable=False)
    reason = Column(String, nullable=True)
    adjustment_reason = Column(Enum(AdjustmentReason), nullable=True)
    reference_id = Column(String, nullable=True)
    user_id = Column(String, nullable=False)
    user_name = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

class StockTransfer(Base):
    __tablename__ = "stock_transfers"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    source_store_id = Column(String, index=True, nullable=False)
    destination_store_id = Column(String, index=True, nullable=False)
    product_id = Column(String, nullable=False)
    product_name = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False)
    initiated_by_user_id = Column(String, nullable=False)
    initiated_by_user_name = Column(String, nullable=False)
    initiated_at = Column(DateTime, default=datetime.utcnow)
    confirmed_by_user_id = Column(String, nullable=True)
    confirmed_by_user_name = Column(String, nullable=True)
    confirmed_at = Column(DateTime, nullable=True)
    status = Column(Enum(TransferStatus), default=TransferStatus.pending)
    notes = Column(String, nullable=True)
