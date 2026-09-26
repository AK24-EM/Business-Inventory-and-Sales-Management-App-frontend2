#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# Firebase/GCP Backend Setup Script
# Store Inventory Management System
# ══════════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

PROJECT_ID="store-inventory-sale-manage"
REGION="asia-south1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ══════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ══════════════════════════════════════════════════════════════════════════════

print_step() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        return 1
    else
        print_success "$1 is installed"
        return 0
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Step 1: Check Prerequisites
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 1: Checking Prerequisites"

check_command "gcloud" || exit 1
check_command "firebase" || exit 1
check_command "node" || exit 1
check_command "npm" || exit 1
check_command "dart" || exit 1
check_command "flutter" || exit 1

print_success "All prerequisites are installed!"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 2: Authenticate with Google Cloud
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 2: Authenticating with Google Cloud"

echo "Opening browser for authentication..."
gcloud auth login

print_success "Authenticated with Google Cloud"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 3: Set GCP Project
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 3: Setting GCP Project"

gcloud config set project $PROJECT_ID
print_success "Project set to: $PROJECT_ID"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 4: Enable Required APIs
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 4: Enabling Required GCP APIs"

print_info "This may take a few minutes..."

APIs=(
    "firebase.googleapis.com"
    "firestore.googleapis.com"
    "identitytoolkit.googleapis.com"
    "firebasehosting.googleapis.com"
    "cloudfunctions.googleapis.com"
    "cloudscheduler.googleapis.com"
    "fcm.googleapis.com"
    "firebaseanalytics.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
)

for api in "${APIs[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --quiet
done

print_success "All APIs enabled!"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 5: Initialize Firebase
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 5: Initializing Firebase"

if [ ! -f "firebase.json" ]; then
    print_info "Initializing Firebase project..."
    firebase init firestore --project=$PROJECT_ID
else
    print_success "Firebase already initialized"
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 6: Deploy Firestore Security Rules
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 6: Deploying Firestore Security Rules"

if [ -f "firestore.rules" ]; then
    print_info "Deploying security rules..."
    firebase deploy --only firestore:rules --project=$PROJECT_ID
    print_success "Security rules deployed!"
else
    print_error "firestore.rules not found!"
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 7: Deploy Firestore Indexes
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 7: Deploying Firestore Indexes"

if [ -f "firestore.indexes.json" ]; then
    print_info "Deploying indexes..."
    firebase deploy --only firestore:indexes --project=$PROJECT_ID
    print_success "Indexes deployed!"
else
    print_error "firestore.indexes.json not found!"
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 8: Configure Flutter App
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 8: Configuring Flutter App"

print_info "Checking if flutterfire_cli is installed..."
if ! dart pub global list | grep -q "flutterfire_cli"; then
    print_info "Installing flutterfire_cli..."
    dart pub global activate flutterfire_cli
fi

cd store_app

print_info "Generating firebase_options.dart..."
flutterfire configure --project=$PROJECT_ID

print_success "Flutter app configured!"

cd ..
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 9: Install Node Dependencies
# ══════════════════════════════════════════════════════════════════════════════

print_step "Step 9: Installing Node Dependencies for Scripts"

if [ -d "seed" ]; then
    print_info "Installing dependencies for seed scripts..."
    cd seed
    if [ -f "package.json" ]; then
        npm install
        print_success "Seed dependencies installed!"
    else
        print_warning "No package.json found in seed directory"
    fi
    cd ..
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Step 10: Summary
# ══════════════════════════════════════════════════════════════════════════════

print_step "Setup Complete! 🎉"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Backend setup completed successfully!${NC}"
echo ""
echo "Next Steps:"
echo ""
echo "1. Verify your Firebase Console:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "2. Check Firestore Database:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""
echo "3. Seed initial data (optional):"
echo "   cd seed"
echo "   node seed_master_data.js"
echo ""
echo "4. Run your Flutter app:"
echo "   cd store_app"
echo "   flutter run"
echo ""
echo "5. Monitor logs:"
echo "   https://console.cloud.google.com/logs?project=$PROJECT_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_info "For detailed setup instructions, see: BACKEND_SETUP_PLAN.md"
echo ""
