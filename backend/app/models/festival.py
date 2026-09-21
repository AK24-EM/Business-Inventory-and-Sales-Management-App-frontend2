import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime
from app.database import Base

class Festival(Base):
    __tablename__ = "festivals"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    advance_order_days = Column(Integer, default=14)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(String, default="info")  # lowStock, festival, transfer, alert
    target_store_id = Column(String, index=True, nullable=True)
    target_role = Column(String, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
