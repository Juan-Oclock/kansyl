#!/bin/bash

# Verification Script for Trial to Subscription Migration
# This script checks that all Trial references have been properly migrated

echo "🔍 Verifying Trial to Subscription migration..."
echo "================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for issues found
ISSUES_FOUND=0

# Function to check for patterns
check_pattern() {
    local pattern=$1
    local description=$2
    
    echo -n "Checking for $description... "
    
    # Search for the pattern, excluding comments and markdown files
    results=$(grep -r "$pattern" \
              --include="*.swift" \
              --exclude-dir=".git" \
              --exclude-dir="DerivedData" \
              --exclude-dir="build" \
              kansyl/ 2>/dev/null | \
              grep -v "//" | \
              grep -v "^\s*\*" || true)
    
    if [ -z "$results" ]; then
        echo -e "${GREEN}✓ Clean${NC}"
    else
        echo -e "${RED}✗ Found issues:${NC}"
        echo "$results" | head -5
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
}

# Check for various Trial-related patterns
echo "1. Checking for Trial type references..."
check_pattern "type 'Trial'" "Trial type references"

echo ""
echo "2. Checking for Trial class/struct definitions..."
check_pattern "class Trial\|struct Trial" "Trial definitions"

echo ""
echo "3. Checking for TrialStore references..."
check_pattern "TrialStore" "TrialStore usage"

echo ""
echo "4. Checking for Trial view files..."
check_pattern "TrialDetailView\|TrialsView\|AddTrialView\|ModernTrialDetailView\|ModernTrialsView\|BulkTrialManagementView" "Trial view references"

echo ""
echo "5. Checking for TrialStatus references..."
check_pattern "TrialStatus" "TrialStatus enum usage"

echo ""
echo "6. Checking file names..."
echo -n "Checking for Trial-named files... "
trial_files=$(find kansyl -name "*Trial*.swift" -type f 2>/dev/null)
if [ -z "$trial_files" ]; then
    echo -e "${GREEN}✓ Clean${NC}"
else
    echo -e "${RED}✗ Found files:${NC}"
    echo "$trial_files"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
echo "================================================"

# Summary
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Migration verified successfully!${NC}"
    echo "All Trial references have been properly migrated to Subscription."
else
    echo -e "${YELLOW}⚠️  Found $ISSUES_FOUND issue(s) that may need attention.${NC}"
    echo "Please review the items listed above."
fi

echo ""
echo "📝 Migration Summary:"
echo "  - Trial → Subscription (model)"
echo "  - TrialStore → SubscriptionStore"
echo "  - TrialStatus → SubscriptionStatus"
echo "  - All Trial views → Subscription views"

exit $ISSUES_FOUND