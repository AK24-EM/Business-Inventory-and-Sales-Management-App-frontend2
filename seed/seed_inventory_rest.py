#!/usr/bin/env python3
"""
seed_inventory_rest.py

Seeds Firestore with inventory data using REST API (no Firebase Admin SDK needed).
Simpler alternative when Firebase Admin SDK has network issues.

Usage:
    python3 seed_inventory_rest.py
"""

import requests
import json
from datetime import datetime, timedelta

# Firebase project configuration
PROJECT_ID = "store-inventory-sale-manage"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# You'll need a Firebase Auth token
# Get it from: Firebase Console → Project Settings → Service Accounts → Generate new private key
# Or use Firebase Auth API to get an ID token

def get_timestamp():
    """Returns current timestamp in Firestore format"""
    return {
        "timestampValue": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    }

def days_ago(n):
    """Returns timestamp N days ago"""
    dt = datetime.utcnow() - timedelta(days=n)
    return {
        "timestampValue": dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    }

# Sample products data
products = [
    {
        "id": "p01",
        "name": "Tata Salt 1kg",
        "brand": "Tata",
        "category": "Groceries",
        "sellingPrice": 25.0,
        "stock": 150,
        "minStock": 20
    },
    {
        "id": "p02",
        "name": "Amul Butter 100g",
        "brand": "Amul",
        "category": "Dairy",
        "sellingPrice": 60.0,
        "stock": 80,
        "minStock": 20
    },
    {
        "id": "p03",
        "name": "Aashirvaad Atta 5kg",
        "brand": "Aashirvaad",
        "category": "Groceries",
        "sellingPrice": 285.0,
        "stock": 8,
        "minStock": 20
    },
    {
        "id": "p04",
        "name": "Britannia Good Day 100g",
        "brand": "Britannia",
        "category": "Snacks",
        "sellingPrice": 30.0,
        "stock": 65,
        "minStock": 25
    },
    {
        "id": "p05",
        "name": "Lays Classic 75g",
        "brand": "Lays",
        "category": "Snacks",
        "sellingPrice": 20.0,
        "stock": 5,
        "minStock": 25
    },
    {
        "id": "p06",
        "name": "Coca-Cola 2L",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "sellingPrice": 85.0,
        "stock": 120,
        "minStock": 30
    },
    {
        "id": "p07",
        "name": "Maggi Noodles 70g",
        "brand": "Maggi",
        "category": "Instant Food",
        "sellingPrice": 12.0,
        "stock": 200,
        "minStock": 50
    },
    {
        "id": "p08",
        "name": "Mother Dairy Milk 1L",
        "brand": "Mother Dairy",
        "category": "Dairy",
        "sellingPrice": 62.0,
        "stock": 3,
        "minStock": 20
    },
    {
        "id": "p09",
        "name": "Parle-G Biscuits 200g",
        "brand": "Parle",
        "category": "Snacks",
        "sellingPrice": 20.0,
        "stock": 0,
        "minStock": 30
    },
    {
        "id": "p10",
        "name": "Surf Excel 1kg",
        "brand": "Surf Excel",
        "category": "Household",
        "sellingPrice": 180.0,
        "stock": 45,
        "minStock": 15
    },
]

def print_manual_instructions():
    """Prints manual instructions for Firebase Console"""
    print("\n" + "="*80)
    print("  MANUAL SETUP INSTRUCTIONS (Copy to Firebase Console)")
    print("="*80)
    print("\n📍 Go to: https://console.firebase.google.com/")
    print("   → Select project: store-inventory-sale-manage")
    print("   → Firestore Database → Start Collection")
    print("\n")
    
    print("COLLECTION 1: products")
    print("-" * 80)
    for product in products:
        print(f"\nDocument ID: {product['id']}")
        print("Fields:")
        print(f"  name: (string) {product['name']}")
        print(f"  brand: (string) {product['brand']}")
        print(f"  category: (string) {product['category']}")
        print(f"  sellingPrice: (number) {product['sellingPrice']}")
        print(f"  mrp: (number) {product['sellingPrice'] + 5}")
        print(f"  barcode: (string) 89012345678{product['id'][-1]}")
        print(f"  sku: (string) {product['brand'][:4].upper()}-{product['id'].upper()}")
        print(f"  isActive: (boolean) true")
        print(f"  createdAt: (timestamp) [Click 'Set to current time']")
        print(f"  updatedAt: (timestamp) [Click 'Set to current time']")
    
    print("\n\n" + "="*80)
    print("COLLECTION 2: inventory")
    print("-" * 80)
    for product in products:
        doc_id = f"inv_store_01_{product['id']}"
        print(f"\nDocument ID: {doc_id}")
        print("Fields:")
        print(f"  storeId: (string) store_01")
        print(f"  productId: (string) {product['id']}")
        print(f"  productName: (string) {product['name']}")
        print(f"  category: (string) {product['category']}")
        print(f"  currentStock: (number) {product['stock']}")
        print(f"  minimumStockLevel: (number) {product['minStock']}")
        print(f"  maximumStockLevel: (number) 200")
        print(f"  imageUrl: (string) https://via.placeholder.com/200x200.png?text={product['name'].replace(' ', '+')}")
        print(f"  lastUpdated: (timestamp) [Click 'Set to current time']")
    
    print("\n\n" + "="*80)
    print("COLLECTION 3: stores")
    print("-" * 80)
    print("\nDocument ID: store_01")
    print("Fields:")
    print("  name: (string) Store 1: Downtown Central")
    print("  address: (string) 123 Main Street, Downtown")
    print("  city: (string) Mumbai")
    print("  state: (string) Maharashtra")
    print("  pincode: (string) 400001")
    print("  phone: (string) +91 22 1234 5678")
    print("  email: (string) downtown@store.com")
    print("  isActive: (boolean) true")
    print("  createdAt: (timestamp) [Click 'Set to current time']")
    print("  updatedAt: (timestamp) [Click 'Set to current time']")
    
    print("\n\n" + "="*80)
    print("\n✅ After adding this data:")
    print("   1. Refresh your app")
    print("   2. Stock should appear immediately!")
    print("   3. You should see:")
    print(f"      • {len([p for p in products if p['stock'] > p['minStock']])} items with normal stock")
    print(f"      • {len([p for p in products if 0 < p['stock'] <= p['minStock']])} items with low stock")
    print(f"      • {len([p for p in products if p['stock'] == 0])} items out of stock")
    print("\n" + "="*80 + "\n")

def print_json_export():
    """Prints JSON that can be imported"""
    print("\n" + "="*80)
    print("  JSON EXPORT (For bulk import tools)")
    print("="*80)
    
    print("\n// Products Collection")
    for product in products:
        doc = {
            "name": product['name'],
            "brand": product['brand'],
            "category": product['category'],
            "sellingPrice": product['sellingPrice'],
            "mrp": product['sellingPrice'] + 5,
            "barcode": f"89012345678{product['id'][-1]}",
            "sku": f"{product['brand'][:4].upper()}-{product['id'].upper()}",
            "isActive": True
        }
        print(f"// {product['id']}")
        print(json.dumps(doc, indent=2))
        print()
    
    print("\n// Inventory Collection")
    for product in products:
        doc_id = f"inv_store_01_{product['id']}"
        doc = {
            "storeId": "store_01",
            "productId": product['id'],
            "productName": product['name'],
            "category": product['category'],
            "currentStock": product['stock'],
            "minimumStockLevel": product['minStock'],
            "maximumStockLevel": 200,
            "imageUrl": f"https://via.placeholder.com/200x200.png?text={product['name'].replace(' ', '+')}"
        }
        print(f"// {doc_id}")
        print(json.dumps(doc, indent=2))
        print()

def main():
    print("\n🌱 Inventory Data Seeder")
    print("="*80)
    print("\n⚠️  REST API seeding requires authentication token")
    print("    For simplicity, use the manual instructions below:\n")
    
    choice = input("Choose option:\n  1. Print manual setup instructions\n  2. Export JSON\n\nEnter (1 or 2): ").strip()
    
    if choice == "1":
        print_manual_instructions()
    elif choice == "2":
        print_json_export()
    else:
        print("\n❌ Invalid choice. Run again.")
        return
    
    print("\n✅ Setup instructions generated!")
    print("\n💡 TIP: Copy-paste these instructions into Firebase Console")
    print("   It's faster than writing a REST API client with auth!\n")

if __name__ == "__main__":
    main()
