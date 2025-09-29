#!/usr/bin/env python3
"""
Professional app icon generator for Kansyl
Creates a beautiful app icon with trial management theme
"""

import os
import json
import math
from pathlib import Path

# Check if Pillow is installed
try:
    from PIL import Image, ImageDraw, ImageFont
    print("✅ Pillow is installed")
except ImportError:
    print("❌ Pillow is not installed. Installing...")
    os.system("pip3 install Pillow")
    from PIL import Image, ImageDraw, ImageFont

def create_gradient_background(draw, size, colors):
    """Create a smooth gradient background"""
    for i in range(size):
        # Linear interpolation between colors
        ratio = i / size
        r = int(colors[0][0] * (1 - ratio) + colors[1][0] * ratio)
        g = int(colors[0][1] * (1 - ratio) + colors[1][1] * ratio)
        b = int(colors[0][2] * (1 - ratio) + colors[1][2] * ratio)
        draw.line([(0, i), (size, i)], fill=(r, g, b))

def create_professional_icon(size, output_path, style="gradient"):
    """Create a professional app icon for Kansyl"""
    
    # Create a new image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if style == "gradient":
        # Modern gradient background (blue to purple)
        create_gradient_background(draw, size, [
            (64, 134, 255),   # iOS blue
            (108, 99, 255)    # Purple accent
        ])
        
        # Add subtle corner radius effect
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        corner_radius = size // 8
        mask_draw.rounded_rectangle([0, 0, size, size], corner_radius, fill=255)
        
        # Apply mask
        img.putalpha(mask)
        
    elif style == "minimal":
        # Minimal flat design
        bg_color = (74, 144, 226)  # Modern blue
        draw.rounded_rectangle([0, 0, size, size], size//8, fill=bg_color)
    
    # Draw the main icon element - a stylized clock/calendar hybrid
    center_x, center_y = size // 2, size // 2
    icon_size = size * 0.6
    
    # Draw clock face background
    clock_radius = int(icon_size * 0.4)
    clock_bg_color = (255, 255, 255, 220)  # Semi-transparent white
    
    # Main clock circle
    draw.ellipse([
        center_x - clock_radius,
        center_y - clock_radius,
        center_x + clock_radius,
        center_y + clock_radius
    ], fill=clock_bg_color, outline=(255, 255, 255))
    
    # Draw clock hands pointing to "trial ending" position (11:59)
    # Hour hand (shorter, thicker)
    hour_angle = math.radians(-90 + (11 * 30))  # 11 o'clock position
    hour_length = clock_radius * 0.5
    hour_end_x = center_x + hour_length * math.cos(hour_angle)
    hour_end_y = center_y + hour_length * math.sin(hour_angle)
    draw.line([center_x, center_y, hour_end_x, hour_end_y], 
              fill=(255, 59, 48), width=max(2, size//150))  # Red for urgency
    
    # Minute hand (longer, thinner)
    minute_angle = math.radians(-90 + (59 * 6))  # 59 minutes
    minute_length = clock_radius * 0.7
    minute_end_x = center_x + minute_length * math.cos(minute_angle)
    minute_end_y = center_y + minute_length * math.sin(minute_angle)
    draw.line([center_x, center_y, minute_end_x, minute_end_y], 
              fill=(255, 59, 48), width=max(1, size//200))
    
    # Center dot
    center_dot_radius = max(2, size//100)
    draw.ellipse([
        center_x - center_dot_radius,
        center_y - center_dot_radius,
        center_x + center_dot_radius,
        center_y + center_dot_radius
    ], fill=(255, 59, 48))
    
    # Add "K" letter in the lower portion
    font_size = max(10, int(size * 0.25))
    try:
        # Try to use San Francisco font (iOS system font)
        font_paths = [
            "/System/Library/Fonts/SFNS.ttc",
            "/System/Library/Fonts/SF-Pro.ttc",
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
    
    text = "K"
    # Get text dimensions
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Position text in lower part of icon
    text_x = center_x - text_width // 2
    text_y = center_y + clock_radius // 2
    
    # Draw text with subtle shadow
    shadow_offset = max(1, size//200)
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text, 
              fill=(0, 0, 0, 100), font=font)
    draw.text((text_x, text_y), text, fill='white', font=font)
    
    # Add small notification badge in corner (optional)
    if size >= 60:  # Only for larger icons
        badge_size = size // 6
        badge_x = size - badge_size - size // 20
        badge_y = size // 20
        
        # Red notification badge
        draw.ellipse([
            badge_x, badge_y,
            badge_x + badge_size, badge_y + badge_size
        ], fill=(255, 59, 48))
        
        # Badge number (optional)
        badge_font_size = max(8, badge_size // 2)
        try:
            badge_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", badge_font_size)
        except:
            badge_font = ImageFont.load_default()
        
        badge_text = "!"
        badge_bbox = draw.textbbox((0, 0), badge_text, font=badge_font)
        badge_text_width = badge_bbox[2] - badge_bbox[0]
        badge_text_height = badge_bbox[3] - badge_bbox[1]
        
        badge_text_x = badge_x + (badge_size - badge_text_width) // 2
        badge_text_y = badge_y + (badge_size - badge_text_height) // 2
        
        draw.text((badge_text_x, badge_text_y), badge_text, fill='white', font=badge_font)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def main():
    """Generate all required icon sizes"""
    # Define the output directory
    base_dir = Path(__file__).parent.parent
    assets_dir = base_dir / "kansyl" / "Assets.xcassets" / "AppIcon.appiconset"
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Icon configurations (same as your existing script)
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
    
    print("🎨 Generating professional Kansyl app icons...")
    print("📱 Theme: Free trial management with time urgency")
    
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
        style = "gradient" if actual_size >= 40 else "minimal"
        create_professional_icon(actual_size, output_path, style)
        
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
    
    print(f"✅ Successfully generated {len(icon_configs)} professional app icons!")
    print(f"📁 Icons saved to: {assets_dir}")
    print("\n🎯 Design features:")
    print("• Gradient background (iOS blue to purple)")
    print("• Clock showing trial ending time (11:59)")
    print("• 'K' branding letter")
    print("• Red notification badge for urgency")
    print("• Rounded corners and modern design")
    print("\n🚀 Next steps:")
    print("1. Open your Xcode project")
    print("2. The icons should appear in Assets.xcassets")
    print("3. Build and run your app to see the new icon!")

if __name__ == "__main__":
    main()