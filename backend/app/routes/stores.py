from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.store import Store
from app.models.user import User, UserRole
from app.schemas.store import StoreCreate, StoreUpdate, StoreResponse
from app.routes.auth import get_current_user, require_roles

router = APIRouter(prefix="/stores", tags=["Stores"])

@router.get("", response_model=List[StoreResponse])
def get_stores(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Store).filter(Store.is_active == True).all()

@router.get("/{store_id}", response_model=StoreResponse)
def get_store(store_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    return store

@router.post("", response_model=StoreResponse, status_code=status.HTTP_201_CREATED)
def create_store(
    store_in: StoreCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin]))
):
    store = Store(**store_in.dict())
    db.add(store)
    db.commit()
    db.refresh(store)
    return store

@router.patch("/{store_id}", response_model=StoreResponse)
def update_store(
    store_id: str,
    store_in: StoreUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.owner, UserRole.admin]))
):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    
    for field, value in store_in.dict(exclude_unset=True).items():
        setattr(store, field, value)
    
    db.commit()
    db.refresh(store)
    return store
