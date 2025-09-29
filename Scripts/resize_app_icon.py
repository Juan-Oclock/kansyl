#!/usr/bin/env python3
"""
App icon resizer for Kansyl
Takes a source image and generates all required iOS app icon sizes
"""

import os
import json
import sys
from pathlib import Path

# Check if Pillow is installed
try:
    from PIL import Image
    print("✅ Pillow is installed")
except ImportError:
    print("❌ Pillow is not installed. Installing...")
    os.system("pip3 install Pillow")
    from PIL import Image

def resize_icon(source_image_path, size, output_path):
    """Resize the source image to the specified size"""
    try:
        # Open the source image
        img = Image.open(source_image_path)
        
        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Resize using high-quality Lanczos resampling
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # For the App Store icon (1024x1024), remove alpha channel
        if size == 1024:
            # Create a white background
            background = Image.new('RGB', (size, size), (255, 255, 255))
            # Paste the image on the white background
            if resized.mode == 'RGBA':
                background.paste(resized, (0, 0), resized)
                resized = background
            else:
                resized = resized.convert('RGB')
        
        # Save the resized image
        resized.save(output_path, 'PNG', optimize=True, quality=100)
        print(f"✓ Created: {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"✗ Error creating {output_path}: {str(e)}")
        return False

def main():
    """Generate all required icon sizes from source image"""
    
    # Check if source image path is provided
    if len(sys.argv) < 2:
        print("❌ Please provide the path to your source icon image")
        print("Usage: python3 resize_app_icon.py /path/to/your/icon.png")
        sys.exit(1)
    
    source_image_path = sys.argv[1]
    
    # Check if source image exists
    if not os.path.exists(source_image_path):
        print(f"❌ Source image not found: {source_image_path}")
        sys.exit(1)
    
    # Verify source image
    try:
        img = Image.open(source_image_path)
        width, height = img.size
        print(f"📱 Source image: {source_image_path}")
        print(f"   Size: {width}x{height}")
        
        # Recommend square image
        if width != height:
            print(f"⚠️  Warning: Source image is not square. It will be resized to square.")
        
        # Recommend minimum size
        if width < 1024 or height < 1024:
            print(f"⚠️  Warning: Source image is smaller than 1024x1024. Quality may be reduced.")
            response = input("Continue anyway? (y/n): ")
            if response.lower() != 'y':
                print("Exiting...")
                sys.exit(0)
    except Exception as e:
        print(f"❌ Error opening source image: {str(e)}")
        sys.exit(1)
    
    # Define the output directory
    base_dir = Path(__file__).parent.parent
    assets_dir = base_dir / "kansyl" / "Assets.xcassets" / "AppIcon.appiconset"
    
    # Create backup of existing icons
    backup_dir = base_dir / "kansyl" / "Assets.xcassets" / "AppIcon.appiconset.backup"
    if assets_dir.exists():
        print(f"\n📦 Creating backup of existing icons...")
        os.system(f"cp -r '{assets_dir}' '{backup_dir}'")
        print(f"   Backup saved to: {backup_dir}")
    
    # Create assets directory if it doesn't exist
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Icon configurations for iOS
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
    
    print(f"\n🎨 Generating iOS app icons from your image...")
    print(f"📁 Output directory: {assets_dir}\n")
    
    successful = 0
    failed = 0
    
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
        
        # Resize and save the icon
        output_path = assets_dir / filename
        success = resize_icon(source_image_path, actual_size, output_path)
        
        if success:
            successful += 1
        else:
            failed += 1
        
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
    
    print(f"\n📊 Results:")
    print(f"   ✅ Successfully generated: {successful} icons")
    if failed > 0:
        print(f"   ❌ Failed: {failed} icons")
    
    print(f"\n📁 All icons saved to: {assets_dir}")
    print(f"📄 Contents.json updated")
    
    print("\n🚀 Next steps:")
    print("1. Open your Xcode project")
    print("2. Clean build folder (Shift+Cmd+K)")
    print("3. Build and run your app to see the new icon!")
    
    if backup_dir.exists():
        print(f"\n💡 To restore previous icons:")
        print(f"   cp -r '{backup_dir}'/* '{assets_dir}/'")

if __name__ == "__main__":
    main()