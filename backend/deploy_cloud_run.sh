#!/bin/bash
set -e

PROJECT_ID="store-inventory-sale-manage"
REGION="asia-south1"
SERVICE_NAME="storeiq-api"

echo "=========================================================="
echo "🚀 Deploying StoreIQ Backend to Google Cloud Run (Source Deploy)"
echo "Project:  ${PROJECT_ID}"
echo "Region:   ${REGION}"
echo "Service:  ${SERVICE_NAME}"
echo "=========================================================="

# 1. Enable required GCP APIs
echo "📦 Enabling required APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="${PROJECT_ID}"

# 2. Deploy directly from source to Cloud Run non-interactively
echo "🚀 Building container and deploying service to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
    --source . \
    --platform=managed \
    --region="${REGION}" \
    --allow-unauthenticated \
    --project="${PROJECT_ID}" \
    --memory=512Mi \
    --cpu=1 \
    --min-instances=0 \
    --max-instances=5 \
    --quiet

# 3. Print Cloud Run URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --platform=managed --region="${REGION}" --project="${PROJECT_ID}" --format='value(status.url)')

echo "=========================================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "Cloud Run Service URL: ${SERVICE_URL}"
echo "Interactive Swagger Docs: ${SERVICE_URL}/docs"
echo "=========================================================="
