# Premium Purchase Authentication Flow

## Overview
This document describes the implementation of the authentication requirement for premium purchases.

## Problem
The app needed to ensure that users are authenticated before they can purchase premium features, preventing anonymous users from making purchases that wouldn't be linked to an account.

## Solution Implemented

### 1. Updated `PremiumFeaturesView.swift`

#### Added Environment Objects and State
```swift
@EnvironmentObject private var authManager: SupabaseAuthManager
@ObservedObject private var userStateManager = UserStateManager.shared
@ObservedObject private var premiumManager = PremiumManager.shared
@State private var showingSignInRequired = false
@State private var showingSignInSheet = false
@State private var isPurchasing = false
@State private var purchaseErrorMessage = ""
```

#### Added Authentication Check Handler
```swift
private func handlePurchase() {
    // Check if user is authenticated
    if !authManager.isAuthenticated || userStateManager.isAnonymousMode {
        // Show sign-in required alert
        showingSignInRequired = true
        return
    }
    
    // Proceed with purchase
    isPurchasing = true
    Task {
        let isYearly = selectedPlan == .yearly
        await premiumManager.purchase(yearly: isYearly)
        
        await MainActor.run {
            isPurchasing = false
            
            switch premiumManager.purchaseState {
            case .purchased:
                presentationMode.wrappedValue.dismiss()
            case .failed(let error):
                // Show appropriate error message
                if let premiumError = error as? PremiumError, premiumError == .simulatorNotSupported {
                    purchaseErrorMessage = "In-app purchases are not supported on the iOS Simulator..."
                } else {
                    purchaseErrorMessage = error.localizedDescription
                }
                showingPurchaseAlert = true
            case .idle:
                // Purchase cancelled or pending
                break
            default:
                break
            }
        }
    }
}
```

#### Added Alerts
1. **Sign-In Required Alert**: Prompts user to sign in when they attempt to purchase while anonymous
2. **Purchase Error Alert**: Shows appropriate error messages, including simulator-specific message

#### Added Sign-In Sheet
```swift
.sheet(isPresented: $showingSignInSheet) {
    LoginView()
        .environmentObject(authManager)
        .environmentObject(userStateManager)
}
```

### 2. Updated `PremiumManager.swift`
Made `PremiumError` conform to `Equatable` to allow error comparison:
```swift
enum PremiumError: LocalizedError, Equatable {
    case productNotFound
    case unverifiedTransaction
    case simulatorNotSupported
}
```

### 3. Updated `SettingsView.swift`
Passed `authManager` to `PremiumFeaturesView`:
```swift
.sheet(isPresented: $showingPremiumFeatures) {
    PremiumFeaturesView()
        .environmentObject(authManager)
}
```

## User Flow

### Anonymous User Attempting Purchase
1. User taps "Unlock Premium" in Settings
2. `PremiumFeaturesView` opens
3. User selects a plan and taps "Start Premium"
4. App checks: `!authManager.isAuthenticated || userStateManager.isAnonymousMode`
5. **Alert appears**: "Sign In Required"
   - Message: "You need to sign in or create an account before purchasing premium features. This ensures your purchase is linked to your account."
   - Buttons: "Cancel" or "Sign In"
6. If user taps "Sign In", `LoginView` sheet appears
7. User can create account or sign in
8. After authentication, user can return and complete purchase

### Authenticated User Attempting Purchase
1. User taps "Unlock Premium" in Settings
2. `PremiumFeaturesView` opens
3. User selects a plan and taps "Start Premium"
4. App checks: user is authenticated ✅
5. Purchase process begins:
   - Button shows "Processing..." with spinner
   - `premiumManager.purchase()` is called
   - On simulator: Shows error about simulator not supporting IAP
   - On real device: Would proceed with actual StoreKit purchase

## Testing

### On Simulator
1. **Anonymous Mode Testing**:
   - Start app in anonymous mode
   - Add 5 subscriptions (hit the limit)
   - Try to upgrade to premium
   - **Expected**: "Sign In Required" alert appears
   - Tap "Sign In" → LoginView appears
   - After sign-in, can try purchase again
   - **Expected**: "Purchase Error" alert (simulator not supported)

2. **Authenticated User Testing**:
   - Sign in to the app
   - Try to upgrade to premium
   - **Expected**: "Purchase Error" alert (simulator not supported)
   - Use DEBUG toggle in Settings to enable test premium instead

### On Real Device
1. **Anonymous Mode Testing**:
   - Same flow as simulator, but purchase would actually process
   - StoreKit would handle the transaction

2. **Authenticated User Testing**:
   - Purchase would process through StoreKit
   - User would see Apple's payment sheet

## Debug Features

In `SettingsView`, there's a DEBUG section (only visible in DEBUG builds):
- **Enable Test Premium**: Toggle to bypass purchase and enable premium features for testing
- Only works on simulator
- Won't appear in release builds

## Benefits

1. **Data Safety**: Ensures purchases are always linked to an account
2. **Better UX**: Clear messaging about why authentication is needed
3. **Prevents Orphaned Purchases**: Anonymous purchases can't be recovered if device is lost
4. **Clear Flow**: Users understand the requirement before attempting purchase
5. **Logging**: All steps are logged for debugging

## Files Modified
- `kansyl/Views/PremiumFeaturesView.swift`
- `kansyl/Managers/PremiumManager.swift`
- `kansyl/Views/SettingsView.swift`

## Related Issues Fixed
- Anonymous user subscription addition (separate issue)
- Static `currentUserID` implementation in `SubscriptionStore`
