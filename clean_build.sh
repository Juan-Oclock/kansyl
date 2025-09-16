#!/bin/bash

# Clean Build Script for Kansyl
# This script cleans all Xcode caches and performs a fresh build

echo "🧹 Starting clean build process..."

# 1. Clean build folder
echo "📁 Cleaning build folder..."
xcodebuild clean -project kansyl.xcodeproj -scheme kansyl

# 2. Clean derived data
echo "🗑️  Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/kansyl-*

# 3. Clean module cache
echo "📦 Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# 4. Perform fresh build
echo "🔨 Building project..."
xcodebuild -project kansyl.xcodeproj \
           -scheme kansyl \
           -configuration Debug \
           -sdk iphonesimulator \
           -quiet \
           build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Clean build complete!"