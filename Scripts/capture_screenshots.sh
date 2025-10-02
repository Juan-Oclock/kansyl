#!/bin/bash

# Kansyl - Automated App Store Screenshot Capture Script
# This script captures screenshots for all required device sizes
# Usage: ./capture_screenshots.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOTS_DIR="$PROJECT_DIR/Screenshots"
SCHEME="kansyl"
WORKSPACE="$PROJECT_DIR/kansyl.xcworkspace"

# Device configurations for App Store screenshots
# Format: "Device Name|Width x Height|Scale|Directory Name"
declare -a DEVICES=(
    "iPhone 15 Pro Max|1290x2796|3x|6.7-inch"
    "iPhone 15 Plus|1290x2796|3x|6.7-inch"
    "iPhone 11 Pro Max|1242x2688|3x|6.5-inch"
    "iPhone 8 Plus|1242x2208|3x|5.5-inch"
    "iPad Pro (12.9-inch) (6th generation)|2048x2732|2x|12.9-inch-iPad"
)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Kansyl Screenshot Capture Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Check if workspace exists
if [ ! -f "$WORKSPACE" ]; then
    echo -e "${RED}Error: Workspace not found at $WORKSPACE${NC}"
    exit 1
fi

# Create screenshots directory
echo -e "${YELLOW}Creating screenshots directory...${NC}"
mkdir -p "$SCREENSHOTS_DIR"

# Function to capture screenshots for a specific device
capture_for_device() {
    local device_name="$1"
    local resolution="$2"
    local scale="$3"
    local dir_name="$4"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Capturing screenshots for: $device_name${NC}"
    echo -e "${YELLOW}Resolution: $resolution @ $scale${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Create device-specific directory
    local device_dir="$SCREENSHOTS_DIR/$dir_name"
    mkdir -p "$device_dir"
    
    # Build and run UI tests
    echo -e "${YELLOW}Building and running UI tests...${NC}"
    
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$device_name" \
        -derivedDataPath "$PROJECT_DIR/DerivedData" \
        -only-testing:"kansylUITests/ScreenshotTests" \
        SCREENSHOTS_PATH="$device_dir" \
        2>&1 | grep -E "Test Case|passed|failed|Screenshot" || true
    
    # Check if screenshots were created
    if [ "$(ls -A $device_dir)" ]; then
        echo -e "${GREEN}✓ Screenshots captured successfully for $device_name${NC}"
        echo -e "${YELLOW}  Location: $device_dir${NC}"
        ls -1 "$device_dir" | sed 's/^/    - /'
    else
        echo -e "${RED}✗ No screenshots found for $device_name${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}Starting screenshot capture for ${#DEVICES[@]} device configurations...${NC}"
echo ""

# Capture screenshots for each device
for device_config in "${DEVICES[@]}"; do
    IFS='|' read -r device_name resolution scale dir_name <<< "$device_config"
    capture_for_device "$device_name" "$resolution" "$scale" "$dir_name"
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Screenshot capture complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Screenshots saved to: $SCREENSHOTS_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review screenshots in: $SCREENSHOTS_DIR"
echo "  2. Edit/enhance screenshots if needed"
echo "  3. Upload to App Store Connect"
echo ""
echo -e "${GREEN}Done! 🎉${NC}"
