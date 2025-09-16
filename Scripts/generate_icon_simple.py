#!/usr/bin/env python3
"""
Simple app icon generator for Kansyl
Creates a temporary app icon using Python's Pillow library
"""

import os
import json
from pathlib import Path

# Check if Pillow is installed
try:
    from PIL import Image, ImageDraw, ImageFont
    print("✅ Pillow is installed")
except ImportError:
    print("❌ Pillow is not installed. Installing...")
    os.system("pip3 install Pillow")
    from PIL import Image, ImageDraw, ImageFont

def create_icon(size, output_path):
    """Create a simple app icon with the letter K"""
    # Create a new image with a blue gradient background
    img = Image.new('RGB', (size, size), color=(38, 89, 242))
    draw = ImageDraw.Draw(img)
    
    # Draw a slightly darker blue rectangle for depth
    draw.rectangle(
        [(0, 0), (size, size//2)],
        fill=(31, 71, 204)
    )
    
    # Draw the letter "K" in white
    font_size = int(size * 0.5)
    try:
        # Try to use a system font
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    text = "K"
    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - int(size * 0.05)
    
    # Draw text with shadow
    draw.text((x+2, y+2), text, fill=(0, 0, 0, 128), font=font)  # Shadow
    draw.text((x, y), text, fill='white', font=font)  # Main text
    
    # Add a small checkmark in the corner
    check_size = size // 5
    check_x = size - check_size - size // 10
    check_y = size // 10
    
    # Draw green circle for checkmark background
    draw.ellipse(
        [(check_x, check_y), (check_x + check_size, check_y + check_size)],
        fill=(76, 217, 100)
    )
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def main():
    """Generate all required icon sizes"""
    # Define the output directory
    base_dir = Path(__file__).parent.parent
    assets_dir = base_dir / "kansyl" / "Assets.xcassets" / "AppIcon.appiconset"
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Icon configurations
    icon_configs = [
        # iPhone icons
        {"size": 20, "scale": 2, "idiom": "iphone"},
        {"size": 20, "scale": 3, "idiom": "iphone"},
        {"size": 29, "scale": 2, "idiom": "iphone"},
        {"size": 29, "scale": 3, "idiom": "iphone"},
        {"size": 40, "scale": 2, "idiom": "iphone"},
        {"size": 40, "scale": 3, "idiom": "iphone"},
        {"size": 60, "scale": 2, "idiom": "iphone"},
        {"size": 60, "scale": 3, "idiom": "iphone"},
        # iPad icons
        {"size": 20, "scale": 1, "idiom": "ipad"},
        {"size": 20, "scale": 2, "idiom": "ipad"},
        {"size": 29, "scale": 1, "idiom": "ipad"},
        {"size": 29, "scale": 2, "idiom": "ipad"},
        {"size": 40, "scale": 1, "idiom": "ipad"},
        {"size": 40, "scale": 2, "idiom": "ipad"},
        {"size": 76, "scale": 1, "idiom": "ipad"},
        {"size": 76, "scale": 2, "idiom": "ipad"},
        {"size": 83.5, "scale": 2, "idiom": "ipad"},
        # App Store icon
        {"size": 1024, "scale": 1, "idiom": "ios-marketing"},
    ]
    
    # Generate Contents.json
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    print("🎨 Generating Kansyl app icons...")
    
    for config in icon_configs:
        size = config["size"]
        scale = config["scale"]
        idiom = config["idiom"]
        
        # Calculate actual pixel size
        actual_size = int(size * scale)
        
        # Generate filename
        if size == 83.5:
            filename = f"icon-83.5x83.5@{scale}x.png"
        else:
            filename = f"icon-{int(size)}x{int(size)}@{scale}x.png"
        
        # Create the icon
        output_path = assets_dir / filename
        create_icon(actual_size, output_path)
        
        # Add to Contents.json
        contents["images"].append({
            "filename": filename,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": f"{int(size) if size % 1 == 0 else size}x{int(size) if size % 1 == 0 else size}"
        })
    
    # Write Contents.json
    contents_path = assets_dir / "Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"✅ Successfully generated {len(icon_configs)} app icons!")
    print(f"📁 Icons saved to: {assets_dir}")
    print("\n🚀 Next steps:")
    print("1. Open your Xcode project")
    print("2. The icons should appear in Assets.xcassets")
    print("3. Build and run your app to see the new icon!")

if __name__ == "__main__":
    main()
