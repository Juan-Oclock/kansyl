#!/bin/bash

# Test script for Core Data persistence

echo "🧪 Core Data Persistence Test"
echo "=============================="
echo ""

# Kill any existing simulator
echo "1. Stopping any existing simulator..."
xcrun simctl shutdown all 2>/dev/null

# Boot iPhone 15 Pro simulator
echo "2. Starting iPhone 15 Pro simulator..."
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 15 Pro" | head -1 | grep -o "[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}")
if [ -z "$DEVICE_ID" ]; then
    echo "❌ iPhone 15 Pro simulator not found. Creating one..."
    DEVICE_ID=$(xcrun simctl create "iPhone 15 Pro Test" "iPhone 15 Pro")
fi
xcrun simctl boot $DEVICE_ID 2>/dev/null || echo "Simulator already booted"

# Install the app
echo "3. Installing the app..."
xcrun simctl install $DEVICE_ID "/Users/juan_oclock/Library/Developer/Xcode/DerivedData/kansyl-cbyonjzaujidocgjcgmgcnhgjxoy/Build/Products/Debug-iphonesimulator/kansyl.app"

# Launch the app
echo "4. Launching the app..."
xcrun simctl launch --console $DEVICE_ID com.juan-oclock.kansyl.kansyl 2>&1 | grep -E "\[SubscriptionStore\]|\[CoreDataReset\]|\[PersistenceController\]|\[AppState\]" &

# Give app time to launch
sleep 5

echo ""
echo "5. Test Instructions:"
echo "   a. The app should now be running in the simulator"
echo "   b. Try adding a new subscription"
echo "   c. Close and reopen the app"
echo "   d. Check if the subscription persists"
echo ""
echo "6. Check the console output above for Core Data debug messages"
echo ""
echo "Press Ctrl+C when done testing"

# Keep script running to show console output
wait