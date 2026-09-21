from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base
from app.models import *  # Load all models into metadata
from app.routes import auth, stores, products, inventory, sales, customers, suppliers, analytics

# Create database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Enterprise Store & Inventory Management REST API running on Google Cloud Platform (Cloud Run)",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enable CORS for Flutter Web and Mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routers
app.include_router(auth.router)
app.include_router(stores.router)
app.include_router(products.router)
app.include_router(inventory.router)
app.include_router(sales.router)
app.include_router(customers.router)
app.include_router(suppliers.router)
app.include_router(analytics.router)

@app.get("/")
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "platform": "Google Cloud Platform (GCP Cloud Run)",
        "docs": "/docs",
        "health": "OK"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "cloud": "GCP", "region": settings.GCP_REGION}
