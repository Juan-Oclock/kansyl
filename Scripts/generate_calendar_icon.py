#!/usr/bin/env python3
"""
Alternative app icon generator for Kansyl - Calendar design
Creates an app icon with a calendar/cancel theme
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

def create_calendar_icon(size, output_path):
    """Create a calendar-themed icon for Kansyl"""
    
    # Create a new image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background - soft gradient
    for i in range(size):
        ratio = i / size
        r = int(107 * (1 - ratio) + 142 * ratio)  # Green to teal gradient
        g = int(198 * (1 - ratio) + 211 * ratio)
        b = int(114 * (1 - ratio) + 157 * ratio)
        draw.line([(0, i), (size, i)], fill=(r, g, b))
    
    # Calendar base
    calendar_margin = size * 0.15
    calendar_width = size - (calendar_margin * 2)
    calendar_height = calendar_width * 0.9
    calendar_x = calendar_margin
    calendar_y = (size - calendar_height) / 2
    
    # Calendar background
    draw.rounded_rectangle(
        [calendar_x, calendar_y, calendar_x + calendar_width, calendar_y + calendar_height],
        radius=size // 20,
        fill=(255, 255, 255, 240),
        outline=(255, 255, 255)
    )
    
    # Calendar header (red for urgency)
    header_height = calendar_height * 0.2
    draw.rounded_rectangle(
        [calendar_x, calendar_y, calendar_x + calendar_width, calendar_y + header_height],
        radius=size // 20,
        fill=(255, 59, 48)
    )
    
    # Draw calendar grid lines
    grid_start_y = calendar_y + header_height + (calendar_height * 0.1)
    grid_height = calendar_height * 0.6
    
    # Vertical lines
    for i in range(1, 7):
        x_pos = calendar_x + (calendar_width * i / 7)
        draw.line(
            [(x_pos, grid_start_y), (x_pos, grid_start_y + grid_height)],
            fill=(200, 200, 200),
            width=max(1, size // 300)
        )
    
    # Horizontal lines
    for i in range(1, 5):
        y_pos = grid_start_y + (grid_height * i / 5)
        draw.line(
            [(calendar_x + calendar_width * 0.05, y_pos), 
             (calendar_x + calendar_width * 0.95, y_pos)],
            fill=(200, 200, 200),
            width=max(1, size // 300)
        )
    
    # Add a circled date (trial end date)
    circle_x = calendar_x + calendar_width * 0.72
    circle_y = grid_start_y + grid_height * 0.3
    circle_radius = calendar_width * 0.08
    
    # Red circle around the date
    draw.ellipse(
        [circle_x - circle_radius, circle_y - circle_radius,
         circle_x + circle_radius, circle_y + circle_radius],
        outline=(255, 59, 48),
        width=max(2, size // 100)
    )
    
    # Add X mark over the circled date
    x_size = circle_radius * 0.6
    draw.line(
        [(circle_x - x_size, circle_y - x_size), 
         (circle_x + x_size, circle_y + x_size)],
        fill=(255, 59, 48),
        width=max(2, size // 100)
    )
    draw.line(
        [(circle_x - x_size, circle_y + x_size), 
         (circle_x + x_size, circle_y - x_size)],
        fill=(255, 59, 48),
        width=max(2, size // 100)
    )
    
    # Add "K" branding at the bottom
    font_size = max(12, int(calendar_height * 0.15))
    try:
        font_paths = [
            "/System/Library/Fonts/SFNS.ttc",
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/Arial.ttf"
        ]
        font = None
        for font_path in font_paths:
            try:
                font = ImageFont.truetype(font_path, font_size)
                break
            except:
                continue
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    text = "KANSYL"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = calendar_y + calendar_height + (calendar_margin * 0.3)
    
    # Text shadow
    draw.text((text_x + 1, text_y + 1), text, fill=(0, 0, 0, 100), font=font)
    draw.text((text_x, text_y), text, fill='white', font=font)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def main():
    """Generate all required icon sizes"""
    # Define the output directory
    base_dir = Path(__file__).parent.parent
    # Create a different directory for this variant
    assets_dir = base_dir / "kansyl" / "Assets.xcassets" / "AppIcon-Calendar.appiconset"
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
    
    print("📅 Generating calendar-themed Kansyl app icons...")
    print("✨ Theme: Calendar with cancel mark")
    
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
        create_calendar_icon(actual_size, output_path)
        
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
    
    print(f"✅ Successfully generated {len(icon_configs)} calendar-themed icons!")
    print(f"📁 Icons saved to: {assets_dir}")
    print("\n🎯 Design features:")
    print("• Calendar with marked cancellation date")
    print("• Green to teal gradient background")
    print("• Red X mark over trial end date")
    print("• Clean, minimal design")
    print("\n💡 To use this variant:")
    print("1. Copy the contents from AppIcon-Calendar.appiconset")
    print("2. Replace the files in AppIcon.appiconset")
    print("3. Rebuild your app in Xcode")

if __name__ == "__main__":
    main()