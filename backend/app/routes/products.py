from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.product import Product
from app.models.user import User, UserRole
from app.schemas.product import ProductCreate, ProductUpdate, ProductResponse
from app.routes.auth import get_current_user, require_roles

router = APIRouter(prefix="/products", tags=["Products"])

@router.get("", response_model=List[ProductResponse])
def get_products(
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Product).filter(Product.is_active == True)
    if category and category != "All":
        query = query.filter(Product.category == category)
    if search:
        search_fmt = f"%{search.lower()}%"
        query = query.filter(
            (Product.name.ilike(search_fmt)) |
            (Product.category.ilike(search_fmt)) |
            (Product.barcode.ilike(search_fmt))
        )
    return query.order_by(Product.name).all()

@router.get("/barcode/{barcode}", response_model=ProductResponse)
def get_product_by_barcode(barcode: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    product = db.query(Product).filter(Product.barcode == barcode, Product.is_active == True).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found with barcode")
    return product

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    prod_in: ProductCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    if prod_in.barcode:
        existing = db.query(Product).filter(Product.barcode == prod_in.barcode).first()
        if existing:
            raise HTTPException(status_code=400, detail="Barcode already assigned to another product")
    
    product = Product(**prod_in.dict())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.patch("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: str,
    prod_in: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin, UserRole.manager]))
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    for field, value in prod_in.dict(exclude_unset=True).items():
        setattr(product, field, value)
    
    db.commit()
    db.refresh(product)
    return product

@router.delete("/{product_id}")
def delete_product(
    product_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin]))
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    product.is_active = False
    db.commit()
    return {"message": "Product deactivated successfully"}
