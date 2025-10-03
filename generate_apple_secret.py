#!/usr/bin/env python3
"""
Generate Apple Sign In with Apple Secret (JWT) for Supabase

Requirements:
    pip install pyjwt cryptography

Usage:
    python3 generate_apple_secret.py
"""

import jwt
import time
from datetime import datetime, timedelta

def generate_apple_secret(team_id, client_id, key_id, private_key_path):
    """
    Generate JWT secret for Apple Sign In
    
    Args:
        team_id: Your Apple Team ID (e.g., 'YXXWV4ZNFS')
        client_id: Your Services ID (same as bundle ID)
        key_id: Your Apple Key ID (10 characters)
        private_key_path: Path to your .p8 key file
    
    Returns:
        JWT token string (valid for 6 months)
    """
    
    # Read the private key
    with open(private_key_path, 'r') as f:
        private_key = f.read()
    
    # JWT expires in 6 months (maximum allowed by Apple)
    expiration_time = datetime.now() + timedelta(days=180)
    
    # Create the JWT headers
    headers = {
        'kid': key_id,
        'alg': 'ES256'
    }
    
    # Create the JWT payload
    payload = {
        'iss': team_id,
        'iat': int(time.time()),
        'exp': int(expiration_time.timestamp()),
        'aud': 'https://appleid.apple.com',
        'sub': client_id
    }
    
    # Generate the JWT
    token = jwt.encode(
        payload,
        private_key,
        algorithm='ES256',
        headers=headers
    )
    
    return token


def main():
    """Interactive script to generate Apple secret"""
    
    print("=" * 60)
    print("Apple Sign In with Apple - JWT Secret Generator")
    print("=" * 60)
    print()
    
    # Get inputs
    print("Enter the following information from your Apple Developer Account:")
    print()
    
    team_id = input("Team ID (e.g., YXXWV4ZNFS): ").strip()
    if not team_id:
        team_id = "YXXWV4ZNFS"  # Default
        print(f"Using default: {team_id}")
    
    client_id = input("Services ID / Bundle ID (e.g., com.juan-oclock.kansyl.kansyl): ").strip()
    if not client_id:
        client_id = "com.juan-oclock.kansyl.kansyl"  # Default
        print(f"Using default: {client_id}")
    
    key_id = input("Key ID (10 characters from Apple): ").strip()
    if not key_id:
        print("❌ Key ID is required!")
        return
    
    private_key_path = input("Path to .p8 key file (e.g., ./AuthKey_ABC123.p8): ").strip()
    if not private_key_path:
        print("❌ Private key file path is required!")
        return
    
    print()
    print("Generating JWT secret...")
    print()
    
    try:
        # Generate the secret
        secret = generate_apple_secret(team_id, client_id, key_id, private_key_path)
        
        print("✅ Success! Here's your Apple Sign In configuration:")
        print()
        print("-" * 60)
        print("📋 Copy these values to Supabase:")
        print("-" * 60)
        print()
        print("Client ID:")
        print(f"  {client_id}")
        print()
        print("Secret Key (for OAuth):")
        print(f"  {secret}")
        print()
        print("⚠️  Important:")
        print("  - This secret expires in 6 months")
        print("  - Generate a new one before expiration")
        print("  - Keep this secret secure!")
        print()
        print("-" * 60)
        
    except FileNotFoundError:
        print(f"❌ Error: Could not find private key file: {private_key_path}")
        print("   Make sure you've downloaded the .p8 key from Apple Developer Portal")
    except Exception as e:
        print(f"❌ Error generating secret: {e}")
        print("   Make sure you have installed: pip install pyjwt cryptography")


if __name__ == "__main__":
    main()
