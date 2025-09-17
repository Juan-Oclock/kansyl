#!/bin/bash

# Setup script for DeepSeek API integration
# This script helps you configure your API key securely

echo "🚀 Setting up DeepSeek API integration for Kansyl..."
echo ""

# Check if Config.xcconfig exists
if [ ! -f "Config.xcconfig" ]; then
    echo "📝 Creating Config.xcconfig from template..."
    cp Config-Template.xcconfig Config.xcconfig
    echo "✅ Config.xcconfig created"
else
    echo "ℹ️  Config.xcconfig already exists"
fi

# Check if APIConfig.swift exists
if [ ! -f "kansyl/Config/APIConfig.swift" ]; then
    echo "📁 Creating Config directory..."
    mkdir -p kansyl/Config
fi

echo ""
echo "🔑 API Key Setup:"
echo "===================="
echo ""
echo "Choose your preferred method to add your DeepSeek API key:"
echo ""
echo "Option 1: Configuration File (Recommended for development)"
echo "  • Edit Config.xcconfig"
echo "  • Replace YOUR_DEEPSEEK_API_KEY_HERE with your actual API key"
echo ""
echo "Option 2: Swift Configuration"
echo "  • Edit kansyl/Config/APIConfig.swift"
echo "  • Replace YOUR_API_KEY_HERE with your actual API key"
echo ""
echo "Option 3: Runtime Configuration (Recommended for production)"
echo "  • Use the app's AI Settings screen"
echo "  • API key will be stored securely in iOS keychain"
echo ""
echo "🌐 Get your DeepSeek API key:"
echo "  1. Visit: https://platform.deepseek.com"
echo "  2. Sign up or log in"
echo "  3. Go to API Keys section"
echo "  4. Create new API key"
echo "  5. Copy the key to your chosen configuration method"
echo ""
echo "💰 DeepSeek Pricing (very affordable):"
echo "  • ~$0.001 per receipt scan"
echo "  • Much cheaper than OpenAI"
echo "  • No monthly subscription required"
echo ""
echo "🔒 Security Notes:"
echo "  • Config.xcconfig is already in .gitignore (won't be committed)"
echo "  • APIConfig.swift is already in .gitignore (won't be committed)"  
echo "  • Runtime configuration uses iOS keychain (most secure)"
echo ""

# Prompt user for API key if they want to set it now
read -p "Would you like to set your DeepSeek API key now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter your DeepSeek API key: " api_key
    
    if [ ! -z "$api_key" ]; then
        # Update Config.xcconfig
        sed -i.bak "s/YOUR_DEEPSEEK_API_KEY_HERE/$api_key/" Config.xcconfig
        rm Config.xcconfig.bak
        echo "✅ API key added to Config.xcconfig"
        
        # Update APIConfig.swift if it exists
        if [ -f "kansyl/Config/APIConfig.swift" ]; then
            sed -i.bak "s/YOUR_API_KEY_HERE/$api_key/" kansyl/Config/APIConfig.swift
            rm kansyl/Config/APIConfig.swift.bak
            echo "✅ API key added to APIConfig.swift"
        fi
        
        echo ""
        echo "🎉 Setup complete! Your DeepSeek API is configured and ready to use."
        echo ""
        echo "Next steps:"
        echo "1. Build and run your app"
        echo "2. Try the 'Scan Receipt with AI' feature"
        echo "3. Your API key is safely stored and won't be committed to git"
    else
        echo "❌ No API key provided. You can set it later in the configuration files."
    fi
else
    echo ""
    echo "ℹ️  No problem! You can set your API key later by:"
    echo "   • Editing Config.xcconfig, or"
    echo "   • Using the app's AI Settings screen"
fi

echo ""
echo "🔥 Features now available:"
echo "  • AI-powered receipt scanning"
echo "  • Automatic subscription detection"
echo "  • Smart service matching"
echo "  • Secure API key storage"
echo ""
echo "Happy scanning! 📸✨"