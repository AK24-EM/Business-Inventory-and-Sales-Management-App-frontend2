import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Boolean, DateTime
from app.database import Base

class Product(Base):
    __tablename__ = "products"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, index=True, nullable=False)
    category = Column(String, index=True, nullable=False)
    description = Column(String, default="")
    purchase_price = Column(Float, nullable=False, default=0.0)
    selling_price = Column(Float, nullable=False, default=0.0)
    unit = Column(String, default="pcs")
    barcode = Column(String, unique=True, index=True, nullable=True)
    supplier_id = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
