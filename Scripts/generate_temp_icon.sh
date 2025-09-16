#!/bin/bash

# Generate temporary app icon for Kansyl using SF Symbols
# This creates a simple icon that can be used during development

echo "🎨 Generating temporary app icon for Kansyl..."

# Create Assets directory if it doesn't exist
ASSETS_PATH="kansyl/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ASSETS_PATH"

# Function to create icon using ImageMagick or sips
create_icon_with_sips() {
    local size=$1
    local output_name=$2
    
    # Create a temporary PNG with solid color
    # Using sips (built into macOS)
    
    # First create a base image
    echo "Creating ${output_name}..."
    
    # Create a solid color PNG using Swift
    swift - <<EOF
import Cocoa
import AppKit

let size = CGSize(width: $size, height: $size)
let image = NSImage(size: size)
image.lockFocus()

// Background gradient
let gradient = NSGradient(colors: [
    NSColor(red: 0.15, green: 0.35, blue: 0.95, alpha: 1.0),
    NSColor(red: 0.1, green: 0.25, blue: 0.80, alpha: 1.0)
])
gradient?.draw(in: NSRect(origin: .zero, size: size), angle: -45)

// Draw "K" letter
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: CGFloat($size) * 0.5, weight: .bold),
    .foregroundColor: NSColor.white
]
let text = "K"
let textSize = text.size(withAttributes: attributes)
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

// Save to file
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)
let data = bitmap?.representation(using: .png, properties: [:])
try? data?.write(to: URL(fileURLWithPath: "$ASSETS_PATH/$output_name"))
EOF
}

# Required icon sizes for iOS
# Format: size@scale
declare -a ICON_SIZES=(
    "20:2:40:iphone"
    "20:3:60:iphone"
    "29:2:58:iphone"
    "29:3:87:iphone"
    "40:2:80:iphone"
    "40:3:120:iphone"
    "60:2:120:iphone"
    "60:3:180:iphone"
    "20:1:20:ipad"
    "20:2:40:ipad"
    "29:1:29:ipad"
    "29:2:58:ipad"
    "40:1:40:ipad"
    "40:2:80:ipad"
    "76:1:76:ipad"
    "76:2:152:ipad"
    "83.5:2:167:ipad"
    "1024:1:1024:ios-marketing"
)

# Generate each icon size
for size_config in "${ICON_SIZES[@]}"; do
    IFS=':' read -r base scale pixels idiom <<< "$size_config"
    filename="icon-${base}x${base}@${scale}x.png"
    create_icon_with_sips $pixels $filename
done

# Create Contents.json
cat > "$ASSETS_PATH/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "icon-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "icon-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Temporary app icon generated successfully!"
echo "📁 Icons saved to: $ASSETS_PATH"
echo ""
echo "To use the icon:"
echo "1. Open your Xcode project"
echo "2. The icon should automatically appear in Assets.xcassets"
echo "3. Build and run your app"
echo ""
echo "💡 Tip: You can also use the AppIconGenerator.swift file in Xcode"
echo "   to preview and customize the icon design"
