from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.inventory import (
    Inventory, StockMovement, StockTransfer,
    StockMovementType, TransferStatus
)
from app.models.user import User, UserRole
from app.models.product import Product
from app.schemas.inventory import (
    InventoryResponse, ReceiveStockRequest, AdjustStockRequest,
    InitiateTransferRequest, StockMovementResponse, StockTransferResponse
)
from app.routes.auth import get_current_user, require_roles

router = APIRouter(prefix="/inventory", tags=["Inventory"])

@router.get("/{store_id}", response_model=List[InventoryResponse])
def get_store_inventory(
    store_id: str,
    low_stock_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Inventory).filter(Inventory.store_id == store_id)
    if low_stock_only:
        query = query.filter(Inventory.current_stock <= Inventory.minimum_stock_level)
    return query.all()

@router.get("/{store_id}/{product_id}", response_model=InventoryResponse)
def get_inventory_item(
    store_id: str,
    product_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    inv_id = f"{store_id}_{product_id}"
    inv = db.query(Inventory).filter(Inventory.id == inv_id).first()
    if not inv:
        # Fetch product to initialize 0 stock
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        inv = Inventory(
            id=inv_id,
            store_id=store_id,
            product_id=product_id,
            product_name=product.name,
            category=product.category,
            current_stock=0,
            minimum_stock_level=10,
        )
        db.add(inv)
        db.commit()
        db.refresh(inv)
    return inv

def _record_movement(
    db: Session,
    store_id: str,
    product_id: str,
    product_name: str,
    m_type: StockMovementType,
    quantity: int,
    user_id: str,
    user_name: str,
    reason: Optional[str] = None,
    adjustment_reason = None,
    reference_id: Optional[str] = None
):
    inv_id = f"{store_id}_{product_id}"
    inv = db.query(Inventory).filter(Inventory.id == inv_id).first()
    
    if not inv:
        product = db.query(Product).filter(Product.id == product_id).first()
        inv = Inventory(
            id=inv_id,
            store_id=store_id,
            product_id=product_id,
            product_name=product_name if not product else product.name,
            category="General" if not product else product.category,
            current_stock=0,
            minimum_stock_level=10
        )
        db.add(inv)
        db.flush()

    stock_before = inv.current_stock
    delta = quantity if m_type in [StockMovementType.receipt, StockMovementType.transferIn] else -quantity
    stock_after = max(0, stock_before + delta)
    inv.current_stock = stock_after
    inv.last_updated = datetime.utcnow()

    movement = StockMovement(
        store_id=store_id,
        product_id=product_id,
        product_name=product_name,
        type=m_type,
        quantity=quantity,
        stock_before=stock_before,
        stock_after=stock_after,
        reason=reason,
        adjustment_reason=adjustment_reason,
        reference_id=reference_id,
        user_id=user_id,
        user_name=user_name,
    )
    db.add(movement)
    return stock_after

@router.post("/receive", status_code=status.HTTP_200_OK)
def receive_stock(
    req: ReceiveStockRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    new_stock = _record_movement(
        db=db,
        store_id=req.store_id,
        product_id=req.product_id,
        product_name=req.product_name,
        m_type=StockMovementType.receipt,
        quantity=req.quantity,
        user_id=current_user.id,
        user_name=current_user.name,
        reason=req.notes,
        reference_id=req.purchase_order_id
    )
    db.commit()
    return {"message": "Stock received successfully", "new_stock": new_stock}

@router.post("/adjust", status_code=status.HTTP_200_OK)
def adjust_stock(
    req: AdjustStockRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    m_type = StockMovementType.receipt if req.quantity_change >= 0 else StockMovementType.adjustment
    new_stock = _record_movement(
        db=db,
        store_id=req.store_id,
        product_id=req.product_id,
        product_name=req.product_name,
        m_type=m_type,
        quantity=abs(req.quantity_change),
        user_id=current_user.id,
        user_name=current_user.name,
        reason=req.notes,
        adjustment_reason=req.reason
    )
    db.commit()
    return {"message": "Stock adjusted successfully", "new_stock": new_stock}

@router.post("/transfers", response_model=StockTransferResponse)
def initiate_transfer(
    req: InitiateTransferRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    source_inv = db.query(Inventory).filter(Inventory.id == f"{req.source_store_id}_{req.product_id}").first()
    if not source_inv or source_inv.current_stock < req.quantity:
        raise HTTPException(status_code=400, detail="Insufficient stock at source store")

    transfer = StockTransfer(
        source_store_id=req.source_store_id,
        destination_store_id=req.destination_store_id,
        product_id=req.product_id,
        product_name=req.product_name,
        quantity=req.quantity,
        initiated_by_user_id=current_user.id,
        initiated_by_user_name=current_user.name,
        notes=req.notes
    )
    db.add(transfer)
    db.flush()

    # Deduct from source store
    _record_movement(
        db=db,
        store_id=req.source_store_id,
        product_id=req.product_id,
        product_name=req.product_name,
        m_type=StockMovementType.transferOut,
        quantity=req.quantity,
        user_id=current_user.id,
        user_name=current_user.name,
        reference_id=transfer.id
    )

    db.commit()
    db.refresh(transfer)
    return transfer

@router.post("/transfers/{transfer_id}/confirm")
def confirm_transfer(
    transfer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    transfer = db.query(StockTransfer).filter(StockTransfer.id == transfer_id).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
    if transfer.status != TransferStatus.pending:
        raise HTTPException(status_code=400, detail="Transfer is not in pending state")
    
    transfer.status = TransferStatus.confirmed
    transfer.confirmed_by_user_id = current_user.id
    transfer.confirmed_by_user_name = current_user.name
    transfer.confirmed_at = datetime.utcnow()

    # Add to destination store
    _record_movement(
        db=db,
        store_id=transfer.destination_store_id,
        product_id=transfer.product_id,
        product_name=transfer.product_name,
        m_type=StockMovementType.transferIn,
        quantity=transfer.quantity,
        user_id=current_user.id,
        user_name=current_user.name,
        reference_id=transfer.id
    )

    db.commit()
    return {"message": "Transfer confirmed successfully"}

@router.get("/movements/{store_id}", response_model=List[StockMovementResponse])
def get_movements(
    store_id: str,
    product_id: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(StockMovement).filter(StockMovement.store_id == store_id)
    if product_id:
        query = query.filter(StockMovement.product_id == product_id)
    return query.order_by(StockMovement.timestamp.desc()).limit(limit).all()

@router.get("/transfers/pending/{store_id}", response_model=List[StockTransferResponse])
def get_pending_transfers(
    store_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(StockTransfer).filter(
        StockTransfer.destination_store_id == store_id,
        StockTransfer.status == TransferStatus.pending
    ).all()
