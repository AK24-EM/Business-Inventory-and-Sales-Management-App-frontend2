#!/bin/bash

# Script to fix transfers permission errors
# This script will deploy updated Firestore rules and guide you through fixing user permissions

set -e

echo "=========================================="
echo "Transfers Permission Fix Script"
echo "=========================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed."
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI found"
echo ""

# Step 1: Check Firebase authentication
echo "Step 1: Checking Firebase authentication..."
if firebase projects:list &> /dev/null; then
    echo "✅ Already authenticated with Firebase"
else
    echo "⚠️  Not authenticated. Running firebase login..."
    firebase login --reauth
fi
echo ""

# Step 2: Set the project
echo "Step 2: Setting Firebase project..."
firebase use store-inventory-sale-manage
echo "✅ Project set to: store-inventory-sale-manage"
echo ""

# Step 3: Deploy Firestore rules
echo "Step 3: Deploying updated Firestore security rules..."
firebase deploy --only firestore:rules
echo "✅ Firestore rules deployed successfully"
echo ""

# Step 4: Instructions for setting user claims
echo "=========================================="
echo "Next Steps: Set User Custom Claims"
echo "=========================================="
echo ""
echo "To access the transfers screen, users must have the 'manager' role."
echo ""
echo "Option A: Use the Node.js script"
echo "  1. Run: node set_custom_claims.js"
echo "  2. Follow the prompts to set user roles"
echo ""
echo "Option B: Use Firebase Console"
echo "  1. Go to: https://console.firebase.google.com/project/store-inventory-sale-manage/authentication/users"
echo "  2. Click on a user"
echo "  3. Scroll to 'Custom claims'"
echo "  4. Add: {\"role\": \"manager\", \"assignedStoreId\": \"STORE_ID_HERE\"}"
echo ""
echo "Option C: Use Firebase CLI"
echo "  Run: firebase auth:set-custom-claims <USER_UID> '{ \"role\": \"manager\", \"assignedStoreId\": \"STORE_ID\" }'"
echo ""
echo "=========================================="
echo "Testing"
echo "=========================================="
echo ""
echo "After setting claims:"
echo "  1. Sign out and sign in again in the app"
echo "  2. Navigate to /manager/transfers"
echo "  3. The permission error should be resolved"
echo ""
echo "If you still see errors, check TRANSFERS_PERMISSION_FIX.md for more details."
echo ""
echo "✅ Rules deployment complete!"
