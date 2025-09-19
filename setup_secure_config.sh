#!/bin/bash

# Kansyl Secure Configuration Setup Script
# This script helps set up the configuration files securely

echo "🔒 Kansyl Secure Configuration Setup"
echo "===================================="
echo ""

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Setup Config.plist
echo "📋 Setting up Config.plist..."
if check_file "kansyl/Config/Config.plist"; then
    echo "   ⚠️  Config.plist already exists. Skipping..."
else
    if check_file "kansyl/Config/Config.plist.example"; then
        cp kansyl/Config/Config.plist.example kansyl/Config/Config.plist
        echo "   ✅ Created Config.plist from example"
        echo "   📝 Please edit kansyl/Config/Config.plist and add your DeepSeek API key"
    else
        echo "   ❌ Config.plist.example not found!"
    fi
fi

# Setup APIConfig.swift
echo ""
echo "📋 Setting up APIConfig.swift..."
if check_file "kansyl/Config/APIConfig.swift"; then
    echo "   ⚠️  APIConfig.swift already exists. Skipping..."
else
    if check_file "kansyl/Config/APIConfig.swift.template"; then
        cp kansyl/Config/APIConfig.swift.template kansyl/Config/APIConfig.swift
        echo "   ✅ Created APIConfig.swift from template"
        echo "   📝 Please edit kansyl/Config/APIConfig.swift and add your API keys"
    else
        echo "   ❌ APIConfig.swift.template not found!"
    fi
fi

# Setup .env file
echo ""
echo "📋 Setting up .env file..."
if check_file ".env"; then
    echo "   ⚠️  .env already exists. Skipping..."
else
    if check_file ".env.example"; then
        cp .env.example .env
        echo "   ✅ Created .env from example"
        echo "   📝 Please edit .env and add your environment variables"
    else
        echo "   ❌ .env.example not found!"
    fi
fi

# Verify gitignore
echo ""
echo "🔍 Verifying .gitignore configuration..."
if check_file ".gitignore"; then
    if grep -q "Config.plist" .gitignore && grep -q "APIConfig.swift" .gitignore; then
        echo "   ✅ .gitignore properly configured"
    else
        echo "   ⚠️  .gitignore may need updating"
    fi
else
    echo "   ❌ .gitignore not found!"
fi

echo ""
echo "===================================="
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit the configuration files with your actual API keys"
echo "2. Never commit files containing real API keys"
echo "3. Review SECURITY.md for security best practices"
echo ""
echo "Configuration files to edit:"
echo "  • kansyl/Config/Config.plist (for production)"
echo "  • kansyl/Config/APIConfig.swift (for development)"
echo "  • .env (for environment variables)"