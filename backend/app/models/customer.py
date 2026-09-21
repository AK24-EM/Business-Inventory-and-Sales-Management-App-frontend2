import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Enum
import enum
from app.database import Base

class LoyaltyTransactionType(str, enum.Enum):
    earn = "earn"
    redeem = "redeem"
    adjust = "adjust"
    expire = "expire"

class Customer(Base):
    __tablename__ = "customers"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    phone = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, nullable=True)
    address = Column(String, nullable=True)
    registered_at = Column(DateTime, default=datetime.utcnow)
    registered_store_id = Column(String, index=True, nullable=False)
    registered_by_user_id = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)

class LoyaltyAccount(Base):
    __tablename__ = "loyalty_accounts"
    
    id = Column(String, primary_key=True)  # phone number
    primary_customer_id = Column(String, nullable=False)
    phone = Column(String, unique=True, index=True, nullable=False)
    total_points = Column(Integer, default=0)
    redeemed_points = Column(Integer, default=0)
    available_points = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_activity = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class LoyaltyTransaction(Base):
    __tablename__ = "loyalty_transactions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    loyalty_account_id = Column(String, index=True, nullable=False)
    phone = Column(String, index=True, nullable=False)
    customer_id = Column(String, nullable=True)
    customer_name = Column(String, nullable=True)
    type = Column(Enum(LoyaltyTransactionType), nullable=False)
    points = Column(Integer, nullable=False)
    sale_id = Column(String, nullable=True)
    store_id = Column(String, nullable=False)
    store_name = Column(String, nullable=False)
    processed_by_user_id = Column(String, nullable=False)
    processed_by_user_name = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    notes = Column(String, nullable=True)
