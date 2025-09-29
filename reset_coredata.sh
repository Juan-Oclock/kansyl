#!/bin/bash

echo "🗑️ Core Data Store Reset Script"
echo "================================="
echo ""

# Get the app's bundle ID
BUNDLE_ID="com.juan-oclock.kansyl.kansyl"

# Get the active device ID
DEVICE_ID=$(xcrun simctl list devices | grep "Booted" | grep -o "[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}" | head -1)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No booted simulator found. Please start a simulator first."
    exit 1
fi

echo "📱 Found booted simulator: $DEVICE_ID"
echo ""

# Get the app container path
APP_CONTAINER=$(xcrun simctl get_app_container $DEVICE_ID $BUNDLE_ID data 2>/dev/null)

if [ -z "$APP_CONTAINER" ]; then
    echo "❌ App not installed or container not found"
    echo "Make sure the app is installed on the simulator"
    exit 1
fi

echo "📂 App container: $APP_CONTAINER"
echo ""

# Find and delete all Core Data stores
echo "🔍 Looking for Core Data stores..."
STORES_PATH="$APP_CONTAINER/Library/Application Support"

if [ -d "$STORES_PATH" ]; then
    echo "Found Application Support directory"
    
    # List all .sqlite files
    echo ""
    echo "Core Data files found:"
    find "$STORES_PATH" -name "*.sqlite*" -o -name "*.db" | while read file; do
        echo "  - $(basename "$file")"
    done
    
    echo ""
    echo "🗑️ Deleting Core Data stores..."
    
    # Delete all Core Data related files
    find "$STORES_PATH" -name "*.sqlite*" -delete
    find "$STORES_PATH" -name "*.db" -delete
    
    # Also check for CloudKit stores
    find "$APP_CONTAINER" -path "*/CloudKit/*" -name "*.sqlite*" -delete 2>/dev/null
    
    echo "✅ Core Data stores deleted"
else
    echo "⚠️ No Application Support directory found"
fi

# Also clear the Caches directory
CACHES_PATH="$APP_CONTAINER/Library/Caches"
if [ -d "$CACHES_PATH" ]; then
    echo ""
    echo "🗑️ Clearing caches..."
    rm -rf "$CACHES_PATH"/*
    echo "✅ Caches cleared"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Force quit the app in the simulator (if running)"
echo "2. Relaunch the app"
echo "3. The Core Data store will be recreated with the new model"
echo ""
echo "✨ Done!"