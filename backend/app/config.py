import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "StoreIQ Cloud API"
    VERSION: str = "1.0.0"
    GCP_PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "store-inventory-sale-manage")
    GCP_REGION: str = os.getenv("GCP_REGION", "asia-south1")
    
    # Database configuration (Defaults to SQLite for instant local dev, or Cloud SQL Postgres in GCP)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./storeiq.db")
    
    # JWT Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "storeiq-gcp-enterprise-jwt-secret-key-2026-supersecure")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Cloud Storage bucket for product images / export reports
    GCS_BUCKET_NAME: str = os.getenv("GCS_BUCKET_NAME", "storeiq-media-bucket")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()
