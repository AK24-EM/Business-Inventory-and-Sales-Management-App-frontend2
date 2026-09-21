from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.customer import Customer, LoyaltyAccount, LoyaltyTransaction
from app.models.user import User
from app.schemas.customer import (
    CustomerCreate, CustomerResponse, LoyaltyAccountResponse, LoyaltyTransactionResponse
)
from app.routes.auth import get_current_user

router = APIRouter(prefix="/customers", tags=["Customers & Loyalty"])

@router.get("", response_model=List[CustomerResponse])
def get_customers(
    store_id: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Customer).filter(Customer.is_active == True)
    if store_id:
        query = query.filter(Customer.registered_store_id == store_id)
    if search:
        search_fmt = f"%{search.lower()}%"
        query = query.filter((Customer.name.ilike(search_fmt)) | (Customer.phone.ilike(search_fmt)))
    return query.order_by(Customer.name).all()

@router.get("/phone/{phone}", response_model=Optional[CustomerResponse])
def get_customer_by_phone(phone: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    customer = db.query(Customer).filter(Customer.phone == phone, Customer.is_active == True).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    return customer

@router.post("", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def register_customer(
    cust_in: CustomerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    existing = db.query(Customer).filter(Customer.phone == cust_in.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Customer with this phone number already exists")

    customer = Customer(
        name=cust_in.name,
        phone=cust_in.phone,
        email=cust_in.email,
        address=cust_in.address,
        registered_store_id=cust_in.registered_store_id,
        registered_by_user_id=current_user.id
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return customer

@router.get("/loyalty/{phone}", response_model=Optional[LoyaltyAccountResponse])
def get_loyalty_account(phone: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = db.query(LoyaltyAccount).filter(LoyaltyAccount.phone == phone).first()
    if not account:
        # Auto-create empty account if not exists
        customer = db.query(Customer).filter(Customer.phone == phone).first()
        account = LoyaltyAccount(
            id=phone,
            primary_customer_id=customer.id if customer else "unlinked",
            phone=phone,
            total_points=0,
            redeemed_points=0,
            available_points=0
        )
        db.add(account)
        db.commit()
        db.refresh(account)
    return account

@router.get("/loyalty/{phone}/transactions", response_model=List[LoyaltyTransactionResponse])
def get_loyalty_transactions(phone: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(LoyaltyTransaction).filter(LoyaltyTransaction.phone == phone).order_by(LoyaltyTransaction.timestamp.desc()).all()
