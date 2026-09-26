#!/bin/bash

# Quick script to deploy Firestore rules
# Fixes permission issues for employees logging damage and transfers

set -e

echo "================================================"
echo "Deploying Firestore Security Rules"
echo "================================================"
echo ""

# Set the project
export FIREBASE_PROJECT="store-inventory-sale-manage"

echo "Project: $FIREBASE_PROJECT"
echo ""

# Check if user is authenticated
echo "Checking Firebase authentication..."
if firebase projects:list 2>&1 | grep -q "Authentication Error"; then
    echo "⚠️  Not authenticated. Running firebase login..."
    firebase login --reauth
fi

echo "✅ Authenticated"
echo ""

# Deploy rules
echo "Deploying rules..."
firebase deploy --only firestore:rules --project $FIREBASE_PROJECT

echo ""
echo "================================================"
echo "✅ Deployment Complete!"
echo "================================================"
echo ""
echo "Changes made:"
echo "  • Employees can now create damage reports"
echo "  • Employees can now initiate stock transfers"
echo "  • All staff can read damage reports and transfers"
echo "  • Managers can confirm/update transfers"
echo ""
echo "Test the fix:"
echo "  1. Sign in as an employee"
echo "  2. Navigate to Inventory screen"
echo "  3. Try 'Log Damage' - should work now ✅"
echo "  4. Try '+ Transfer' - should work now ✅"
echo ""
