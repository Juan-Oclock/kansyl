#!/usr/bin/env python3
"""
Download the app icon image
"""

import urllib.request
import os
from pathlib import Path

def download_icon():
    # The URL of the icon image
    url = "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/remind-me-byjwh5/assets/t06jm8bq9xol/app_icon.png"
    
    # Define where to save the icon
    base_dir = Path(__file__).parent.parent
    icon_dir = base_dir / "Resources"
    icon_dir.mkdir(exist_ok=True)
    
    output_path = icon_dir / "new_app_icon.png"
    
    try:
        print("📥 Downloading app icon...")
        print(f"   From: {url}")
        print(f"   To: {output_path}")
        
        # Download the image
        urllib.request.urlretrieve(url, output_path)
        
        print(f"✅ Icon successfully downloaded!")
        print(f"📁 Saved to: {output_path}")
        
        # Check file size
        file_size = os.path.getsize(output_path)
        print(f"📊 File size: {file_size:,} bytes")
        
        return str(output_path)
        
    except Exception as e:
        print(f"❌ Error downloading icon: {str(e)}")
        return None

if __name__ == "__main__":
    icon_path = download_icon()
    
    if icon_path:
        print("\n🎯 Next step:")
        print(f"   python3 Scripts/resize_app_icon.py '{icon_path}'")