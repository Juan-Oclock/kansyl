# Simulator Testing Bypass for Premium Features

## Overview
iOS Simulator does not support real In-App Purchases through StoreKit. To enable testing of premium features on the simulator, we've added a development-only bypass that allows you to enable "test premium" mode.

## The Problem

When testing on iOS Simulator:
- ❌ StoreKit IAP doesn't work
- ❌ "Upgrade to Premium" button shows error
- ❌ Can't test premium features (unlimited subscriptions)
- ❌ Error: "Unable to load premium products. Please check your internet connection and try again."

This is **expected behavior** - Apple's StoreKit only works on real devices.

## The Solution

### Simulator Detection
Automatically detects when running on simulator:
```swift
private var isSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}
```

### Better Error Message
When purchase attempted on simulator:
```
"In-App Purchases are not supported on iOS Simulator. 
Please test on a real device or use the development bypass option."
```

### Development Bypass Button
**Only visible in DEBUG builds on Simulator:**
- Orange button: "Enable Test Premium (Simulator Only)"
- Bypasses purchase flow
- Immediately grants premium status
- Allows testing unlimited subscriptions

## How to Use

### Testing on Simulator

#### Step 1: Hit Subscription Limit
1. Open app in iOS Simulator (from Xcode)
2. Add 5 subscriptions (free limit)
3. Try to add 6th subscription
4. Paywall appears

#### Step 2: Enable Test Premium
1. On paywall, scroll to bottom
2. See orange button: **"Enable Test Premium (Simulator Only)"**
3. Tap the button
4. ✅ Premium enabled instantly
5. Modal dismisses
6. You can now add unlimited subscriptions!

#### Step 3: Test Premium Features
- Add more than 5 subscriptions ✅
- Test unlimited subscription flow ✅
- Verify premium UI elements ✅
- Test premium-only features ✅

#### Step 4: Disable Test Premium (Optional)
In DEBUG builds, you can disable test premium programmatically:
```swift
await PremiumManager.shared.disableTestPremium()
```

### Testing on Real Device

#### Sandbox Testing
1. Build on real device (iPhone/iPad)
2. Configure Sandbox Test User in App Store Connect
3. Sign out of App Store on device
4. Tap "Upgrade to Premium"
5. Use Sandbox Test User credentials
6. Complete real purchase flow (no charge)

#### Production Testing
1. Submit to TestFlight or App Store
2. Real Apple ID required
3. Real payment charged
4. Can request refund within 90 days

## UI Differences

### Simulator (DEBUG Build)
```
┌─────────────────────────────────┐
│ Premium Features View           │
│                                 │
│ [Monthly Plan] [Yearly Plan]   │
│                                 │
│ [Upgrade to Premium Button]    │
│                                 │
│ ┌───────────────────────────┐ │
│ │ 🔧 Enable Test Premium    │ │
│ │ (Simulator Only)           │ │
│ │ Bypass purchase for testing│ │
│ └───────────────────────────┘ │
│                                 │
│ Restore | Terms | Privacy      │
└─────────────────────────────────┘
```

### Real Device (DEBUG Build)
```
┌─────────────────────────────────┐
│ Premium Features View           │
│                                 │
│ [Monthly Plan] [Yearly Plan]   │
│                                 │
│ [Upgrade to Premium Button]    │
│                                 │
│ Testing in sandbox mode         │
│ - use your Apple ID             │
│                                 │
│ Restore | Terms | Privacy      │
└─────────────────────────────────┘
```

### Production (RELEASE Build)
```
┌─────────────────────────────────┐
│ Premium Features View           │
│                                 │
│ [Monthly Plan] [Yearly Plan]   │
│                                 │
│ [Upgrade to Premium Button]    │
│                                 │
│ Cancel anytime. No hidden fees. │
│                                 │
│ Restore | Terms | Privacy      │
└─────────────────────────────────┘
```

## Code Implementation

### PremiumManager.swift

#### Simulator Detection
```swift
private var isSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}
```

#### Purchase Blocking
```swift
@MainActor
func purchase(yearly: Bool = false) async {
    purchaseState = .loading
    
    // Check if running on simulator
    if isSimulator {
        purchaseState = .failed(PremiumError.simulatorNotSupported)
        return
    }
    
    // Continue with real purchase...
}
```

#### Test Premium Methods (DEBUG only)
```swift
#if DEBUG
@MainActor
func enableTestPremium() {
    isPremium = true
    purchaseState = .purchased
    print("[PremiumManager] Test premium enabled for development")
}

@MainActor
func disableTestPremium() {
    isPremium = false
    purchaseState = .idle
    print("[PremiumManager] Test premium disabled")
}
#endif
```

### PremiumFeatureView.swift

#### Bypass Button (Simulator + DEBUG only)
```swift
#if DEBUG
#if targetEnvironment(simulator)
Button(action: {
    Task {
        await premiumManager.enableTestPremium()
        dismiss()
    }
}) {
    VStack(spacing: 4) {
        HStack(spacing: 6) {
            Image(systemName: "wrench.and.screwdriver.fill")
            Text("Enable Test Premium (Simulator Only)")
        }
        Text("Bypass purchase for testing - this only works on simulator")
    }
}
#endif
#endif
```

## Security Notes

### ✅ Safe for Production
- Test bypass only available in **DEBUG builds**
- Automatically removed in **RELEASE builds**
- Requires `#if DEBUG` compiler flag
- Only works on **Simulator**, not real devices
- No way for users to exploit in production

### Build Configuration
- **DEBUG**: Xcode default, local testing
- **RELEASE**: App Store, TestFlight, production

### Verification
Check build configuration:
1. Xcode → Product → Scheme → Edit Scheme
2. Run → Build Configuration
3. Should be "Debug" for local testing
4. Should be "Release" for distribution

## Testing Workflows

### Workflow 1: Quick Feature Testing
```
1. Open Xcode
2. Run on Simulator (⌘R)
3. Add 5 subscriptions
4. Hit paywall
5. Tap "Enable Test Premium"
6. ✅ Test unlimited subscriptions
```

### Workflow 2: Real Purchase Flow Testing
```
1. Connect iPhone/iPad
2. Build to device (⌘R)
3. Set up Sandbox Test User
4. Tap "Upgrade to Premium"
5. Complete sandbox purchase
6. ✅ Test real purchase flow
```

### Workflow 3: Production Testing
```
1. Archive app (Product → Archive)
2. Upload to TestFlight
3. Install via TestFlight
4. Use real Apple ID
5. Complete real purchase
6. ✅ Verify production flow
```

## Troubleshooting

### Button Not Visible
**Problem**: Can't see "Enable Test Premium" button

**Solutions**:
1. Make sure running in **Simulator** (not device)
2. Verify **DEBUG build** (not RELEASE)
3. Check scheme: Xcode → Product → Scheme → Edit Scheme
4. Rebuild project (⌘⇧K then ⌘B)

### Button Doesn't Work
**Problem**: Button tapped but nothing happens

**Solutions**:
1. Check Xcode console for log: "[PremiumManager] Test premium enabled"
2. Restart app
3. Clean build folder (⌘⇧K)
4. Check `isPremium` state in debugger

### Still Shows Limit After Enable
**Problem**: Enabled test premium but still hit 5 subscription limit

**Solutions**:
1. Close and reopen add subscription sheet
2. Verify `isPremium = true` in debugger
3. Restart app completely
4. Check subscription count calculation

## Console Logs

### Enable Test Premium
```
[PremiumManager] Test premium enabled for development
```

### Disable Test Premium
```
[PremiumManager] Test premium disabled
```

### Simulator Purchase Attempt
```
Purchase Error: In-App Purchases are not supported on iOS Simulator. 
Please test on a real device or use the development bypass option.
```

## Related Files
- `kansyl/Managers/PremiumManager.swift` - Core logic
- `kansyl/Views/PremiumFeatureView.swift` - Bypass button UI
- `kansyl/docs/PREMIUM_PURCHASE_ERROR_HANDLING.md` - Error handling

## Best Practices

### DO ✅
- Use simulator bypass for quick feature testing
- Test real purchase flow on device before release
- Disable test premium when testing free tier
- Verify build configuration before distribution
- Test on multiple devices and iOS versions

### DON'T ❌
- Don't ship DEBUG builds to users
- Don't rely only on simulator testing
- Don't skip real device testing
- Don't test production purchases without refund plan
- Don't forget to test purchase error scenarios

---

**Implementation Date**: 2025-09-30  
**Status**: ✅ Complete and Ready for Testing  
**Build Required**: DEBUG on Simulator