from datetime import datetime, timedelta
from app.database import SessionLocal, engine, Base
from app.models import (
    User, UserRole, Store, Product, Inventory, Customer, LoyaltyAccount,
    Supplier, Sale, PaymentMode
)
from app.routes.auth import get_password_hash

def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Check if data exists
    if db.query(User).count() > 0:
        print("Database already populated.")
        db.close()
        return

    print("Seeding initial GCP demo database...")

    # 1. Users
    users = [
        User(
            id="uid_owner",
            name="Rahul Sharma",
            email="owner@demo.com",
            phone="9876543210",
            hashed_password=get_password_hash("demo123"),
            role=UserRole.owner,
            is_active=True,
        ),
        User(
            id="uid_manager",
            name="Priya Patel",
            email="manager@demo.com",
            phone="9876543211",
            hashed_password=get_password_hash("demo123"),
            role=UserRole.manager,
            assigned_store_id="store_01",
            is_active=True,
        ),
        User(
            id="uid_employee",
            name="Amit Kumar",
            email="employee@demo.com",
            phone="9876543212",
            hashed_password=get_password_hash("demo123"),
            role=UserRole.employee,
            assigned_store_id="store_01",
            is_active=True,
        ),
    ]
    db.add_all(users)
    db.commit()

    # 2. Stores
    stores = [
        Store(
            id="store_01",
            name="StoreIQ - Andheri Branch",
            address="42, Lokhandwala Complex, Andheri West",
            city="Mumbai",
            phone="022-26300100",
            email="andheri@storeiq.in",
            manager_id="uid_manager",
            is_active=True,
        ),
        Store(
            id="store_02",
            name="StoreIQ - Bandra Branch",
            address="15, Hill Road, Bandra West",
            city="Mumbai",
            phone="022-26400200",
            email="bandra@storeiq.in",
            manager_id="uid_employee",
            is_active=True,
        ),
    ]
    db.add_all(stores)
    db.commit()

    # 3. Products
    products_data = [
        ("p01", "Amul Butter 500g", "Dairy", 225.0, 260.0, "pcs", "8901234560001"),
        ("p02", "Tata Salt 1kg", "Grocery", 20.0, 26.0, "pcs", "8901234560002"),
        ("p03", "Aashirvaad Atta 5kg", "Grocery", 245.0, 280.0, "pcs", "8901234560003"),
        ("p04", "Coca-Cola 2L", "Beverages", 70.0, 90.0, "bottle", "8901234560004"),
        ("p05", "Lays Classic 75g", "Snacks", 18.0, 25.0, "pack", "8901234560005"),
        ("p06", "Dove Soap 100g", "Personal Care", 42.0, 55.0, "pcs", "8901234560006"),
        ("p07", "Maggi Noodles 70g", "Snacks", 12.0, 16.0, "pack", "8901234560007"),
        ("p08", "Mother Dairy Milk 1L", "Dairy", 58.0, 68.0, "litre", "8901234560008"),
        ("p09", "Fortune Sunflower Oil 1L", "Grocery", 148.0, 175.0, "litre", "8901234560009"),
        ("p10", "Dettol Handwash 250ml", "Personal Care", 78.0, 98.0, "bottle", "8901234560010"),
    ]
    
    for pid, name, cat, p_price, s_price, unit, barcode in products_data:
        db.add(Product(
            id=pid, name=name, category=cat, purchase_price=p_price,
            selling_price=s_price, unit=unit, barcode=barcode, is_active=True
        ))
    db.commit()

    # 4. Inventory for Store 1
    inventory_stock = {
        "p01": (45, 15), "p02": (120, 30), "p03": (8, 20), "p04": (60, 20),
        "p05": (5, 25), "p06": (80, 20), "p07": (200, 50), "p08": (3, 20),
        "p09": (35, 15), "p10": (40, 15),
    }
    for pid, name, cat, _, _, _, _ in products_data:
        stock, min_lvl = inventory_stock.get(pid, (20, 10))
        db.add(Inventory(
            id=f"store_01_{pid}",
            store_id="store_01",
            product_id=pid,
            product_name=name,
            category=cat,
            current_stock=stock,
            minimum_stock_level=min_lvl
        ))
    db.commit()

    # 5. Customers & Loyalty
    custs = [
        ("cust_01", "Neha Verma", "9900000001", "neha@example.com", 650),
        ("cust_02", "Ravi Gupta", "9900000002", "ravi@example.com", 340),
        ("cust_03", "Suman Das", "9900000003", None, 700),
    ]
    for cid, name, phone, email, pts in custs:
        db.add(Customer(
            id=cid, name=name, phone=phone, email=email,
            registered_store_id="store_01", registered_by_user_id="uid_employee"
        ))
        db.add(LoyaltyAccount(
            id=phone, primary_customer_id=cid, phone=phone,
            total_points=pts + 200, redeemed_points=200, available_points=pts
        ))
    db.commit()

    # 6. Sample Recent Sales
    now = datetime.utcnow()
    sales = [
        Sale(
            id="s001", store_id="store_01", store_name="StoreIQ - Andheri Branch",
            items=[{"productId": "p01", "productName": "Amul Butter 500g", "category": "Dairy", "quantity": 2, "unitPrice": 260.0, "totalPrice": 520.0}],
            subtotal=520.0, total_amount=520.0, payment_mode=PaymentMode.upi,
            employee_id="uid_employee", employee_name="Amit Kumar",
            timestamp=now - timedelta(hours=2), invoice_number="ANH-20260901-00001"
        ),
        Sale(
            id="s002", store_id="store_01", store_name="StoreIQ - Andheri Branch",
            items=[{"productId": "p03", "productName": "Aashirvaad Atta 5kg", "category": "Grocery", "quantity": 1, "unitPrice": 280.0, "totalPrice": 280.0}],
            subtotal=280.0, total_amount=280.0, payment_mode=PaymentMode.cash,
            employee_id="uid_employee", employee_name="Amit Kumar",
            timestamp=now - timedelta(hours=4), invoice_number="ANH-20260901-00002"
        ),
    ]
    db.add_all(sales)
    db.commit()
    db.close()
    print("GCP database seeded successfully!")

if __name__ == "__main__":
    seed()
