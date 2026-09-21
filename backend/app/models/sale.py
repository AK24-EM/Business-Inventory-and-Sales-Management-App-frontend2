import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, JSON
import enum
from app.database import Base

class PaymentMode(str, enum.Enum):
    cash = "cash"
    upi = "upi"
    card = "card"

class Sale(Base):
    __tablename__ = "sales"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String, index=True, nullable=False)
    store_name = Column(String, nullable=False)
    items = Column(JSON, nullable=False)  # List of {productId, productName, category, quantity, unitPrice, totalPrice}
    subtotal = Column(Float, nullable=False)
    discount_amount = Column(Float, default=0.0)
    loyalty_points_redeemed = Column(Float, default=0.0)
    total_amount = Column(Float, nullable=False)
    payment_mode = Column(Enum(PaymentMode), nullable=False)
    customer_id = Column(String, index=True, nullable=True)
    customer_name = Column(String, nullable=True)
    customer_phone = Column(String, index=True, nullable=True)
    loyalty_points_earned = Column(Integer, default=0)
    employee_id = Column(String, nullable=False)
    employee_name = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    invoice_number = Column(String, unique=True, index=True, nullable=False)
    is_returned = Column(Boolean, default=False)
