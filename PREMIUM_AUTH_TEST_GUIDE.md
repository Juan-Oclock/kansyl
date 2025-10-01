# Premium Purchase Authentication Flow - Test Guide

## Overview
This guide helps you test the premium purchase authentication flow that was just implemented.

## What Was Fixed

### Problem
You were seeing "Unable to load premium products. Please check your internet connection" error when trying to upgrade to premium. This happened because:

1. The app was checking for products BEFORE checking if it's running on simulator
2. StoreKit can't load products on simulator (no App Store Connect connection)
3. The authentication check wasn't in place yet

### Solution
1. **Added authentication requirement** - Users must sign in before purchasing
2. **Fixed simulator check order** - Now checks simulator status FIRST, before product loading
3. **Improved error messages** - Shows appropriate messages for simulator vs real device
4. **Updated both premium views**:
   - `PremiumFeaturesView.swift` (accessed from Settings)
   - `PremiumFeatureView.swift` (accessed when hitting subscription limit)

## Test Scenarios

### Scenario 1: Anonymous User Hits Subscription Limit (Primary Flow)

**Current State**: You have 5 active subscriptions in anonymous mode ✅

**Steps**:
1. **Try to add a 6th subscription**:
   - Tap the `+` button in the tab bar
   - Select any subscription method
   - Try to add a new subscription

2. **Expected Result**:
   - ❌ App blocks the addition
   - 📱 "Subscription Limit Reached" screen appears
   - 👀 Shows "5 of 5 subscriptions used" message
   - 💎 "Upgrade to Premium" button visible

3. **Tap "Upgrade to Premium"**:
   - ⚠️ **Alert appears**: "Sign In Required"
   - 📝 Message: "You need to sign in or create an account before purchasing premium features..."
   - ✅ Buttons: "Cancel" or "Sign In"

4. **Tap "Sign In"**:
   - 📱 LoginView sheet appears
   - ✏️ Can create account or sign in
   - ✅ After authentication, returns to premium screen

5. **Try purchase again** (after signing in):
   - 🔄 Button shows "Processing..." with spinner
   - Console log: `⚠️ [PremiumManager] Simulator detected, cannot proceed with purchase`
   - ⚠️ **Alert appears**: "Purchase Error"
   - 📝 Message: "In-app purchases are not supported on the iOS Simulator. Please test on a real device or use the DEBUG button below..."

### Scenario 2: Access Premium via Settings

**Steps**:
1. **Go to Settings** (gear icon in tab bar)
2. **Scroll to "Premium Features" section**
3. **Tap "Unlock Premium"**
4. **PremiumFeaturesView appears**
5. **Select a plan** (Monthly or Yearly)
6. **Tap "Start Premium"**

**Expected Result** (if in anonymous mode):
- Same authentication flow as Scenario 1
- Alert: "Sign In Required"
- After sign-in: Shows simulator error

**Expected Result** (if already authenticated):
- Directly shows simulator error

### Scenario 3: Using DEBUG Toggle (Workaround)

**Purpose**: Enable premium features for testing without actual purchase

**Steps**:
1. **Go to Settings**
2. **Scroll down to "🐛 DEBUG (Simulator Only)" section**
3. **Toggle ON "Enable Test Premium"**
4. **Result**: Instantly get premium features!
5. **Try adding more subscriptions**: Should work now ✅

**Note**: This toggle only appears in DEBUG builds and only on simulator.

## Console Logs to Watch For

### Successful Authentication Check
```
🛒 [PremiumFeatureView] Purchase button tapped
🔐 [PremiumFeatureView] isAuthenticated: true
👤 [PremiumFeatureView] isAnonymousMode: false
✅ [PremiumFeatureView] User authenticated, initiating purchase
```

### Anonymous User Blocked
```
🛒 [PremiumFeatureView] Purchase button tapped
🔐 [PremiumFeatureView] isAuthenticated: false
👤 [PremiumFeatureView] isAnonymousMode: true
⚠️ [PremiumFeatureView] User not authenticated, showing sign-in prompt
```

### Simulator Detection
```
⚠️ [PremiumManager] Simulator detected, cannot proceed with purchase
```

## Expected User Experience

### For Anonymous Users:
1. ✅ Can add up to 5 subscriptions freely
2. ⚠️ Blocked at 6th subscription
3. 💎 Prompted to upgrade to premium
4. 🔐 Required to sign in before purchasing
5. 🚫 Informed that simulator doesn't support IAP
6. 🐛 Can use DEBUG toggle instead

### For Authenticated Users:
1. ✅ Can add up to 5 subscriptions freely
2. ⚠️ Blocked at 6th subscription  
3. 💎 Prompted to upgrade to premium
4. ✅ Already authenticated, proceeds to purchase
5. 🚫 Informed that simulator doesn't support IAP
6. 🐛 Can use DEBUG toggle instead

### For Premium Users:
1. ✅ Unlimited subscriptions
2. 🎉 No limits or prompts

## Testing on Real Device

To test the actual purchase flow:

1. **Build and install on real device** (not simulator)
2. **Ensure you have a test Apple ID** for sandbox testing
3. **Follow Scenario 1 or 2**
4. **Expected**: StoreKit payment sheet appears with actual pricing
5. **Can test purchase** using sandbox Apple ID

## Files Modified

1. `kansyl/Managers/PremiumManager.swift`
   - Moved simulator check before product check
   - Added product reload logic
   - Made `PremiumError` equatable

2. `kansyl/Views/PremiumFeatureView.swift` 
   - Added authentication requirement
   - Added sign-in flow
   - Improved error handling

3. `kansyl/Views/PremiumFeaturesView.swift`
   - Added authentication requirement
   - Added sign-in flow
   - Improved error handling

4. `kansyl/Views/SettingsView.swift`
   - Added DEBUG toggle for test premium
   - Passed authManager to premium view

5. `kansyl/Views/AddSubscriptionView.swift`
   - Passed authManager to premium view

6. `kansyl/Views/AddSubscriptionMethodSelector.swift`
   - Passed authManager to premium view

7. `kansyl/Views/ModernSubscriptionsView.swift`
   - Passed authManager to premium view

## Quick Test Checklist

- [ ] Can add 5 subscriptions in anonymous mode
- [ ] Blocked at 6th subscription
- [ ] "Upgrade to Premium" appears
- [ ] Shows "Sign In Required" alert when tapping upgrade
- [ ] Can tap "Sign In" to see LoginView
- [ ] After sign-in, purchase shows simulator error
- [ ] DEBUG toggle in Settings enables premium
- [ ] After enabling test premium, can add unlimited subscriptions
- [ ] Same flow works from Settings > "Unlock Premium"

## Success Criteria

✅ **Authentication Required**: Anonymous users cannot purchase premium
✅ **Sign-In Flow**: Users are guided to sign in/sign up
✅ **Simulator Handled**: Appropriate error for simulator testing
✅ **DEBUG Bypass**: Test toggle available for development
✅ **Proper Errors**: Clear, helpful error messages
✅ **User-Friendly**: Smooth flow with clear guidance

## Next Steps

1. **Test on simulator** following scenarios above
2. **Verify console logs** match expected output
3. **Test DEBUG toggle** works correctly
4. **Test on real device** for actual IAP flow (optional)
5. **Configure StoreKit testing** if needed (optional)
