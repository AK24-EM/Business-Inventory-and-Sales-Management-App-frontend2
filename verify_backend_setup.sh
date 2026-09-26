#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# Backend Setup Verification Script
# Store Inventory Management System
# ══════════════════════════════════════════════════════════════════════════════

PROJECT_ID="store-inventory-sale-manage"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔍 Backend Setup Verification${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=0
PASSED=0

check_item() {
    TOTAL=$((TOTAL + 1))
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✅${NC} $1"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌${NC} $1"
    fi
}

# Check GCloud
gcloud --version &> /dev/null
check_item "GCloud CLI installed" $?

# Check Firebase CLI
firebase --version &> /dev/null
check_item "Firebase CLI installed" $?

# Check Node.js
node --version &> /dev/null
check_item "Node.js installed" $?

# Check Flutter
flutter --version &> /dev/null
check_item "Flutter SDK installed" $?

# Check GCP Project
gcloud projects describe $PROJECT_ID &> /dev/null
check_item "GCP Project exists ($PROJECT_ID)" $?

# Check Firestore Rules
[ -f "firestore.rules" ]
check_item "Firestore rules file exists" $?

# Check Firestore Indexes
[ -f "firestore.indexes.json" ]
check_item "Firestore indexes file exists" $?

# Check Firebase config
[ -f "firebase.json" ]
check_item "Firebase config file exists" $?

# Check Firebase options
[ -f "store_app/lib/firebase_options.dart" ]
check_item "Firebase options generated" $?

# Check Android config
[ -f "store_app/android/app/google-services.json" ]
check_item "Android google-services.json exists" $?

# Check iOS config
[ -f "store_app/ios/Runner/GoogleService-Info.plist" ]
check_item "iOS GoogleService-Info.plist exists" $?

# Check Service Account
[ -f "seed/store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json" ]
check_item "Service account key exists" $?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 Summary: $PASSED/$TOTAL checks passed${NC}"

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}🎉 All checks passed! Your backend is ready.${NC}"
    EXIT_CODE=0
else
    echo -e "${YELLOW}⚠️  Some checks failed. Please complete the setup.${NC}"
    EXIT_CODE=1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit $EXIT_CODE
