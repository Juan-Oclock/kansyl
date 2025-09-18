# Secure Configuration Guide for Kansyl

## Overview
This guide explains how to securely configure API keys and credentials for the Kansyl app without exposing them in the source code.

## ⚠️ Security Best Practices
1. **NEVER commit API keys or credentials to Git**
2. **ALWAYS use xcconfig files for sensitive configuration**
3. **ENSURE Config.xcconfig is in .gitignore**
4. **USE environment-specific configurations for development vs production**

## Initial Setup

### Option 1: Simple Setup (Recommended for solo developers)
1. Copy the template: `cp Config-Template.xcconfig Config.xcconfig`
2. Edit `Config.xcconfig` and add your actual credentials
3. Use this single file for all your configuration

### Option 2: Two-File Setup (Better security)
1. Keep `Config.xcconfig` with placeholders (can be shared with team)
2. Create `Config.private.xcconfig` with your actual credentials:
```xcconfig
// Config.private.xcconfig
#include "Config.xcconfig"  // Import base config

// Override with your actual credentials
DEEPSEEK_API_KEY = sk-your-actual-deepseek-key-here
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJhbGc...your-anon-key-here
```
3. Configure Xcode to use `Config.private.xcconfig` instead of `Config.xcconfig`
4. Never commit `Config.private.xcconfig` (it's in .gitignore)

### 3. Verify Xcode Project Configuration
The Xcode project should already be configured to use the xcconfig file. To verify:
1. Open `kansyl.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "kansyl" target
4. Go to "Build Settings" tab
5. Search for "Configuration File"
6. Ensure it points to `Config.xcconfig`

## Getting Your API Keys

### DeepSeek API
1. Go to [https://platform.deepseek.com](https://platform.deepseek.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with `sk-`)

### Supabase Credentials
1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project
3. Navigate to Settings → API
4. Copy:
   - **Project URL**: Your Supabase project URL
   - **Anon/Public Key**: The anonymous key (safe for client-side use)
   - **Service Role Key**: DO NOT USE in mobile apps (server-side only)

## Configuration Files Structure

### Files That Should Exist (and be git-ignored):
- `Config.xcconfig` - Your actual configuration with real API keys
- `kansyl/Config/SupabaseConfig.swift` - Swift configuration manager (no hardcoded values)
- `kansyl/Config/APIConfig.swift` - API configuration (if using direct config)
- `kansyl/Config/Config.plist` - Property list configuration (if used)

### Files That ARE Tracked in Git:
- `Config-Template.xcconfig` - Template for team members
- `kansyl/Config/ProductionAIConfig.swift` - Production configuration loader
- `kansyl/Config/*.template` files - Safe templates without credentials

## How It Works

1. **xcconfig → Info.plist**: The xcconfig file values are injected into Info.plist at build time
2. **Info.plist → Swift Code**: Swift code reads values from Info.plist using `Bundle.main.object(forInfoDictionaryKey:)`
3. **Fallback Handling**: If credentials are missing, the app shows clear error messages

## Troubleshooting

### Error: "SUPABASE_URL not configured"
- Ensure `Config.xcconfig` exists and contains `SUPABASE_URL`
- Verify the Xcode project is using the correct xcconfig file
- Clean and rebuild the project

### Error: "Invalid DeepSeek API key"
- Check that your API key starts with `sk-`
- Ensure there are no extra spaces or quotes
- Verify the key hasn't expired

### Configuration Not Loading
1. Clean build folder: Cmd+Shift+K
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Restart Xcode
4. Rebuild the project

## Adding New Credentials

To add new API keys or credentials:

1. Add to `Config-Template.xcconfig`:
```xcconfig
NEW_SERVICE_API_KEY = YOUR_NEW_SERVICE_KEY_HERE
```

2. Add to your `Config.xcconfig`:
```xcconfig
NEW_SERVICE_API_KEY = actual-key-value
```

3. Access in Swift code:
```swift
let apiKey = Bundle.main.object(forInfoDictionaryKey: "NEW_SERVICE_API_KEY") as? String
```

## Security Checklist

- [ ] Config.xcconfig is in .gitignore
- [ ] No hardcoded API keys in Swift files
- [ ] No credentials in committed plist files
- [ ] Template files use clear placeholders
- [ ] Production uses secure credential management
- [ ] Service role keys are NEVER included in mobile apps

## For CI/CD

For automated builds, inject credentials as environment variables:
```bash
echo "DEEPSEEK_API_KEY = $DEEPSEEK_API_KEY" >> Config.xcconfig
echo "SUPABASE_URL = $SUPABASE_URL" >> Config.xcconfig
echo "SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY" >> Config.xcconfig
```

## Questions?

If you have questions about configuration or security, please:
1. Check this guide first
2. Review the template files
3. Never share actual API keys in issues or commits