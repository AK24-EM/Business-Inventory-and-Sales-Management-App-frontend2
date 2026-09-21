from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.supplier import Supplier, PurchaseOrder, DamagedProduct, PurchaseOrderStatus
from app.models.user import User, UserRole
from app.schemas.supplier import (
    SupplierCreate, SupplierResponse,
    CreatePurchaseOrderRequest, PurchaseOrderResponse,
    CreateDamagedProductRequest, DamagedProductResponse
)
from app.routes.auth import get_current_user, require_roles

router = APIRouter(prefix="/suppliers", tags=["Suppliers & Purchase Orders"])

@router.get("", response_model=List[SupplierResponse])
def get_suppliers(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Supplier).filter(Supplier.is_active == True).all()

@router.post("", response_model=SupplierResponse, status_code=status.HTTP_201_CREATED)
def create_supplier(
    sup_in: SupplierCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    supplier = Supplier(**sup_in.dict())
    db.add(supplier)
    db.commit()
    db.refresh(supplier)
    return supplier

@router.get("/purchase-orders/{store_id}", response_model=List[PurchaseOrderResponse])
def get_purchase_orders(store_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(PurchaseOrder).filter(PurchaseOrder.target_store_id == store_id).order_by(PurchaseOrder.created_at.desc()).all()

@router.post("/purchase-orders", response_model=PurchaseOrderResponse, status_code=status.HTTP_201_CREATED)
def create_purchase_order(
    po_in: CreatePurchaseOrderRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin]))
):
    po = PurchaseOrder(
        supplier_id=po_in.supplier_id,
        supplier_name=po_in.supplier_name,
        items=po_in.items,
        total_amount=po_in.total_amount,
        target_store_id=po_in.target_store_id,
        expected_delivery_date=po_in.expected_delivery_date,
        notes=po_in.notes,
        created_by_user_id=current_user.id,
        created_by_user_name=current_user.name
    )
    db.add(po)
    db.commit()
    db.refresh(po)
    return po

@router.get("/damaged/{store_id}", response_model=List[DamagedProductResponse])
def get_damaged_products(store_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(DamagedProduct).filter(DamagedProduct.store_id == store_id).order_by(DamagedProduct.reported_at.desc()).all()

@router.post("/damaged", response_model=DamagedProductResponse, status_code=status.HTTP_201_CREATED)
def report_damaged_product(
    req: CreateDamagedProductRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    dp = DamagedProduct(
        product_id=req.product_id,
        product_name=req.product_name,
        supplier_id=req.supplier_id,
        supplier_name=req.supplier_name,
        store_id=req.store_id,
        quantity=req.quantity,
        estimated_loss=req.estimated_loss,
        reason=req.reason,
        notes=req.notes,
        reported_by_user_id=current_user.id,
        reported_by_user_name=current_user.name
    )
    db.add(dp)
    db.commit()
    db.refresh(dp)
    return dp
