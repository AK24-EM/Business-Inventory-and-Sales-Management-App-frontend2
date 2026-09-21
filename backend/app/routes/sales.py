from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.sale import Sale
from app.models.inventory import Inventory, StockMovementType
from app.models.customer import Customer, LoyaltyAccount, LoyaltyTransaction, LoyaltyTransactionType
from app.models.user import User
from app.schemas.sale import CreateSaleRequest, SaleResponse
from app.routes.auth import get_current_user
from app.routes.inventory import _record_movement

router = APIRouter(prefix="/sales", tags=["Sales & POS"])

@router.post("", response_model=SaleResponse, status_code=status.HTTP_201_CREATED)
def complete_sale(
    sale_in: CreateSaleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 1. Validate Stock Availability
    insufficient = []
    for item in sale_in.items:
        inv = db.query(Inventory).filter(Inventory.id == f"{sale_in.store_id}_{item.productId}").first()
        if not inv or inv.current_stock < item.quantity:
            insufficient.append(f"{item.productName} (Available: {inv.current_stock if inv else 0})")
    
    if insufficient:
        raise HTTPException(status_code=400, detail=f"Insufficient stock for: {', '.join(insufficient)}")

    # 2. Math Calculations
    subtotal = sum(item.totalPrice for item in sale_in.items)
    total_amount = max(0.0, subtotal - sale_in.discount_amount - sale_in.loyalty_points_redeemed)
    points_earned = int(total_amount * 1.0) if sale_in.customer_phone else 0

    # 3. Generate Invoice Number
    now = datetime.utcnow()
    prefix = sale_in.store_id[:3].upper()
    invoice_number = f"{prefix}-{now.strftime('%Y%m%d')}-{int(now.timestamp()) % 100000:05d}"

    # 4. Create Sale Record
    sale = Sale(
        store_id=sale_in.store_id,
        store_name=sale_in.store_name,
        items=[item.dict() for item in sale_in.items],
        subtotal=subtotal,
        discount_amount=sale_in.discount_amount,
        loyalty_points_redeemed=sale_in.loyalty_points_redeemed,
        total_amount=total_amount,
        payment_mode=sale_in.payment_mode,
        customer_id=sale_in.customer_id,
        customer_name=sale_in.customer_name,
        customer_phone=sale_in.customer_phone,
        loyalty_points_earned=points_earned,
        employee_id=current_user.id,
        employee_name=current_user.name,
        invoice_number=invoice_number,
        timestamp=now
    )
    db.add(sale)
    db.flush()

    # 5. Deduct Stock for each Item
    for item in sale_in.items:
        _record_movement(
            db=db,
            store_id=sale_in.store_id,
            product_id=item.productId,
            product_name=item.productName,
            m_type=StockMovementType.sale,
            quantity=item.quantity,
            user_id=current_user.id,
            user_name=current_user.name,
            reference_id=sale.id
        )

    # 6. Update Customer Loyalty Account
    if sale_in.customer_phone:
        account = db.query(LoyaltyAccount).filter(LoyaltyAccount.phone == sale_in.customer_phone).first()
        points_redeemed_count = int(sale_in.loyalty_points_redeemed / 0.10) if sale_in.loyalty_points_redeemed > 0 else 0
        
        if not account:
            account = LoyaltyAccount(
                id=sale_in.customer_phone,
                primary_customer_id=sale_in.customer_id or "unlinked",
                phone=sale_in.customer_phone,
                total_points=points_earned,
                redeemed_points=points_redeemed_count,
                available_points=points_earned - points_redeemed_count
            )
            db.add(account)
        else:
            account.total_points += points_earned
            account.redeemed_points += points_redeemed_count
            account.available_points = max(0, account.available_points + points_earned - points_redeemed_count)

        # Record Loyalty Transaction
        if points_earned > 0 or points_redeemed_count > 0:
            lt = LoyaltyTransaction(
                loyalty_account_id=sale_in.customer_phone,
                phone=sale_in.customer_phone,
                customer_id=sale_in.customer_id,
                customer_name=sale_in.customer_name,
                type=LoyaltyTransactionType.earn if points_earned > 0 else LoyaltyTransactionType.redeem,
                points=points_earned if points_earned > 0 else points_redeemed_count,
                sale_id=sale.id,
                store_id=sale_in.store_id,
                store_name=sale_in.store_name,
                processed_by_user_id=current_user.id,
                processed_by_user_name=current_user.name,
            )
            db.add(lt)

    db.commit()
    db.refresh(sale)
    return sale

@router.get("", response_model=List[SaleResponse])
def get_sales(
    store_id: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    customer_id: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Sale)
    if store_id:
        query = query.filter(Sale.store_id == store_id)
    if customer_id:
        query = query.filter(Sale.customer_id == customer_id)
    if from_date:
        query = query.filter(Sale.timestamp >= from_date)
    if to_date:
        query = query.filter(Sale.timestamp <= to_date)
    return query.order_by(Sale.timestamp.desc()).limit(limit).all()

@router.get("/today/{store_id}", response_model=List[SaleResponse])
def get_today_sales(store_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today_start = datetime.combine(date.today(), datetime.min.time())
    return db.query(Sale).filter(Sale.store_id == store_id, Sale.timestamp >= today_start).order_by(Sale.timestamp.desc()).all()
