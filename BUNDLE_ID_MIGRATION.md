# Bundle ID Migration Plan

## Current Configuration (Temporary)

To avoid Apple's App ID creation limit, the app is currently using existing bundle IDs:

- **Main App**: `com.juan-oclock.safr.Safr`
- **Share Extension**: `com.juan-oclock.safr.Safr.ShareExtension`
- **Code Signing**: Manual (iOS Simulator only)

## Target Configuration (When App ID Limit Resets)

When the App ID limit resets (7 days from first hitting the limit), revert to:

- **Main App**: `com.juan-oclock.kansyl`
- **Share Extension**: `com.juan-oclock.kansyl.ShareExtension`
- **Code Signing**: Automatic (for device deployment)

## Migration Steps

### 1. Update Bundle Identifiers in Xcode Project
```bash
# In project.pbxproj, change:
# PRODUCT_BUNDLE_IDENTIFIER = com.juan-oclock.safr.Safr;
# To:
# PRODUCT_BUNDLE_IDENTIFIER = com.juan-oclock.kansyl;

# And change:
# PRODUCT_BUNDLE_IDENTIFIER = com.juan-oclock.safr.Safr.ShareExtension;
# To:
# PRODUCT_BUNDLE_IDENTIFIER = com.juan-oclock.kansyl.ShareExtension;
```

### 2. Update CloudKit Container (if needed)
```swift
// In CloudKitManager.swift and Persistence.swift
// Change containerIdentifier to: "iCloud.com.juan-oclock.kansyl"
```

### 3. Enable Automatic Code Signing (for Device Deployment)
```bash
# In project.pbxproj, change:
# CODE_SIGN_IDENTITY = "";
# CODE_SIGN_STYLE = Manual;
# To:
# CODE_SIGN_STYLE = Automatic;
```

### 4. Build with Provisioning Updates
```bash
xcodebuild -scheme kansyl -destination 'platform=iOS,name=Juan Oclock' -allowProvisioningUpdates build
```

## Current Status
- ✅ iOS Simulator builds work perfectly
- ✅ All Kansyl features functional
- ✅ Share extension working
- ⏳ Device deployment blocked by App ID limit (temporary)

## Notes
- This is a temporary workaround to continue development during the App ID limit period
- All functionality remains intact on iOS Simulator
- When migrating back, ensure CloudKit data compatibility if container IDs change