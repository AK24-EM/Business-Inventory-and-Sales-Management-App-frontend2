from datetime import datetime, timedelta, date
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.sale import Sale
from app.models.inventory import Inventory
from app.models.product import Product
from app.models.user import User, UserRole
from app.routes.auth import get_current_user, require_roles

router = APIRouter(prefix="/analytics", tags=["Analytics & AI Insights"])

@router.get("/summary")
def get_analytics_summary(
    store_id: Optional[str] = None,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from_date = datetime.utcnow() - timedelta(days=days)
    
    query = db.query(Sale).filter(Sale.timestamp >= from_date)
    if store_id:
        query = query.filter(Sale.store_id == store_id)
    
    sales = query.all()
    total_revenue = sum(s.total_amount for s in sales)
    total_transactions = len(sales)
    avg_ticket_size = (total_revenue / total_transactions) if total_transactions > 0 else 0.0
    
    revenue_by_store: Dict[str, float] = {}
    revenue_by_category: Dict[str, float] = {}
    revenue_by_payment: Dict[str, float] = {}
    
    for s in sales:
        revenue_by_store[s.store_name] = revenue_by_store.get(s.store_name, 0.0) + s.total_amount
        revenue_by_payment[s.payment_mode.value] = revenue_by_payment.get(s.payment_mode.value, 0.0) + s.total_amount
        
        if s.items:
            for item in s.items:
                cat = item.get("category", "Other")
                revenue_by_category[cat] = revenue_by_category.get(cat, 0.0) + item.get("totalPrice", 0.0)

    # Low stock count
    inv_query = db.query(Inventory)
    if store_id:
        inv_query = inv_query.filter(Inventory.store_id == store_id)
    low_stock_count = inv_query.filter(Inventory.current_stock <= Inventory.minimum_stock_level).count()

    return {
        "total_revenue": round(total_revenue, 2),
        "total_transactions": total_transactions,
        "average_transaction_value": round(avg_ticket_size, 2),
        "low_stock_alerts": low_stock_count,
        "revenue_by_store": revenue_by_store,
        "revenue_by_category": revenue_by_category,
        "revenue_by_payment_mode": revenue_by_payment,
        "period_start": from_date.isoformat(),
        "period_end": datetime.utcnow().isoformat()
    }

@router.get("/restocking-suggestions")
def get_restocking_suggestions(
    store_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    query = db.query(Inventory).filter(Inventory.current_stock <= Inventory.minimum_stock_level)
    if store_id:
        query = query.filter(Inventory.store_id == store_id)
    
    low_items = query.all()
    suggestions = []
    
    for item in low_items:
        prod = db.query(Product).filter(Product.id == item.product_id).first()
        rec_qty = (item.minimum_stock_level * 2) - item.current_stock
        purchase_price = prod.purchase_price if prod else 50.0
        
        suggestions.append({
            "product_id": item.product_id,
            "product_name": item.product_name,
            "category": item.category,
            "store_id": item.store_id,
            "current_stock": item.current_stock,
            "minimum_stock_level": item.minimum_stock_level,
            "recommended_order_quantity": max(10, rec_qty),
            "purchase_price": purchase_price,
            "estimated_cost": round(max(10, rec_qty) * purchase_price, 2)
        })
        
    return suggestions
