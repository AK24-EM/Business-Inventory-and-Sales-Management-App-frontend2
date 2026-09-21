import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
    assert response.json()["cloud"] == "GCP"

def test_owner_login():
    response = client.post("/auth/login", json={
        "email": "owner@demo.com",
        "password": "demo123"
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["role"] == "owner"

def test_get_stores():
    # Login first
    login_res = client.post("/auth/login", json={
        "email": "owner@demo.com",
        "password": "demo123"
    })
    token = login_res.json()["access_token"]
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/stores", headers=headers)
    assert response.status_code == 200
    stores = response.json()
    assert len(stores) >= 2
    assert stores[0]["id"] == "store_01"

def test_get_products():
    login_res = client.post("/auth/login", json={
        "email": "owner@demo.com",
        "password": "demo123"
    })
    token = login_res.json()["access_token"]
    
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/products", headers=headers)
    assert response.status_code == 200
    products = response.json()
    assert len(products) >= 10
