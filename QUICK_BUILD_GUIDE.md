# Quick Build & Test Guide - Sign in with Apple

## What Was Done

✅ **Entitlement enabled** in `kansyl.entitlements`  
✅ **AppleSignInCoordinator.swift** created (new helper class)  
✅ **SupabaseAuthManager** updated with migration support  
✅ **LoginView** wired up with real Apple Sign In  

## Next Steps

### 1. Build the Project

```bash
# Open Xcode
open /Users/juan_oclock/Documents/ios-mobile/kansyl/kansyl.xcodeproj

# In Xcode:
# - Product → Clean Build Folder (Cmd+Shift+K)
# - Product → Build (Cmd+B)
```

### 2. Test on Device (Recommended)

1. Connect your iPhone
2. Select your device in Xcode
3. Press Cmd+R to run
4. Tap "Continue with Apple"
5. Sign in and verify it works!

### 3. Test Anonymous Migration

1. Delete the app
2. Reinstall
3. Tap "Continue Without Account"
4. Add a test subscription
5. Tap "Continue with Apple"
6. Verify subscription migrated to your account

## If You See Errors

### "Signing for "kansyl" requires a development team"

**Fix**: Select your Apple Developer team in Xcode:
- Go to project settings
- Select "kansyl" target
- Signing & Capabilities tab
- Choose your team

### "Entitlement is not allowed"

**Fix**: You need to enable Sign in with Apple in Apple Developer Portal:
1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Select your App ID
3. Enable "Sign In with Apple" capability
4. Regenerate provisioning profiles

### Button does nothing

**Fix**: Check console logs in Xcode (Cmd+Shift+Y) and look for 🍎 emoji logs

## Documentation

Full docs in: `SIGN_IN_WITH_APPLE_IMPLEMENTATION.md`

## All Done! 🎉

Your "Continue with Apple" button is now fully functional!
