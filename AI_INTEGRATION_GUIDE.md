# 🤖 AI Receipt Scanning Integration Guide

## Overview
Your Kansyl app now includes AI-powered receipt scanning using DeepSeek API. Users can photograph receipts and automatically detect subscription services, prices, and billing information.

## 🚀 Quick Setup

### 1. Get DeepSeek API Key
- Visit [https://platform.deepseek.com](https://platform.deepseek.com)
- Sign up or log in
- Navigate to API Keys section
- Create new API key
- Copy the API key

### 2. Configure API Key (Choose One Method)

#### Option A: Automated Setup (Recommended)
```bash
./setup_deepseek.sh
```

#### Option B: Manual Configuration File
```bash
# Edit Config.xcconfig
DEEPSEEK_API_KEY = your_actual_api_key_here
```

#### Option C: Swift Configuration
```swift
// Edit kansyl/Config/APIConfig.swift
static let deepSeekAPIKey = "your_actual_api_key_here"
```

#### Option D: Runtime Configuration (Most Secure)
- Use the app's AI Settings screen
- API key stored in iOS keychain
- Best for production/distribution

## 💰 Cost Information

DeepSeek is very affordable:
- **~$0.001 per receipt scan** (less than a penny!)
- **No monthly subscription required**
- **Pay only for what you use**
- **10x cheaper than OpenAI**

Typical usage:
- 100 receipt scans = ~$0.10
- 1000 receipt scans = ~$1.00

## 🔒 Security Features

### Development
- API keys stored in files that are **automatically ignored by git**
- `Config.xcconfig` and `APIConfig.swift` are in `.gitignore`
- No risk of accidentally committing API keys

### Production  
- API keys stored in **iOS keychain** (most secure)
- **Local image processing** with iOS Vision framework
- **Only text content** sent to AI service, never images
- **No data retention** by DeepSeek for API calls

## 🎯 Features

### Smart Detection
- **Service Recognition**: Automatically identifies subscription services
- **Price Extraction**: Detects monthly/yearly pricing
- **Date Parsing**: Finds start dates and billing cycles
- **Confidence Scoring**: Shows how confident the AI is about detection

### Enhanced Matching
- **Fuzzy Matching**: Handles service name variations (Netflix vs "net flix")
- **Template Integration**: Matches with your existing service templates
- **Price Validation**: Cross-references detected prices with known service costs
- **Logo Assignment**: Automatically assigns appropriate service logos

### User Experience
- **Camera Integration**: Take photos directly in the app
- **Photo Library**: Select existing receipt images
- **Real-time Processing**: Shows progress during AI analysis
- **Review & Confirm**: Users can review and edit detected information
- **Seamless Integration**: Works with existing subscription management flow

## 🛠️ Technical Details

### Components Added
```
ReceiptScanner.swift       - Main AI scanning engine
AIConfigManager.swift     - Secure configuration management
ReceiptScanView.swift      - Complete scanning UI
AISettingsView.swift      - User configuration interface
ServiceTemplateManager+AI - Enhanced service matching
```

### API Integration
```swift
// Uses DeepSeek Chat API
URL: https://api.deepseek.com/v1/chat/completions
Model: deepseek-chat
Temperature: 0.1 (for consistent results)
Max Tokens: 500 (sufficient for receipt analysis)
```

### Image Processing Pipeline
1. **Capture** → Camera or photo library
2. **OCR** → iOS Vision framework (local processing)
3. **AI Analysis** → DeepSeek API (text only)
4. **Service Matching** → Enhanced fuzzy matching
5. **User Review** → Confirmation and editing
6. **Integration** → Add to subscription tracking

## 📱 Usage Instructions

### For Users
1. Open Kansyl app
2. Tap "Add Subscription" 
3. Tap "Scan Receipt with AI"
4. Take photo or select from library
5. Review detected information
6. Confirm and add to subscriptions

### For Developers
1. Configure API key (see setup options above)
2. Build and run the app
3. Test with various receipt types
4. Monitor API usage in DeepSeek dashboard

## 🎛️ Configuration Options

### AI Settings Screen
Access through app settings to:
- Configure DeepSeek API key
- Test API connection
- View privacy information
- Enable/disable AI features

### Environment Variables
```bash
# For CI/CD or advanced setups
export DEEPSEEK_API_KEY="your_key_here"
```

## 🐛 Troubleshooting

### Common Issues

**"API key not configured"**
- Solution: Set API key using one of the methods above

**"AI service unavailable"**
- Check internet connection
- Verify API key is valid
- Check DeepSeek service status

**"No text found in image"**
- Ensure receipt image is clear and well-lit
- Try a different image or retake photo

**"Low confidence detection"**
- Receipt might not be for a subscription service
- Try manual entry for non-subscription items

### Debug Information
Enable debug logging in `APIConfig.swift`:
```swift
static let enableLogging = true
```

## 🚀 Future Enhancements

Potential improvements:
- Support for additional AI providers
- Offline text recognition
- Receipt history and management
- Bulk receipt processing
- Integration with email receipt parsing

## 📊 Analytics

Track AI usage:
- Number of scans performed
- Success rate of detections
- Most commonly detected services
- User satisfaction with AI accuracy

## 🤝 Contributing

When contributing to AI features:
1. Never commit actual API keys
2. Test with various receipt formats
3. Update AI prompts for better accuracy
4. Maintain privacy and security standards

## 📄 License

This AI integration maintains the same license as the main Kansyl project.

---

**Happy scanning!** 📸✨

The AI integration transforms manual subscription entry into an effortless, camera-powered experience.