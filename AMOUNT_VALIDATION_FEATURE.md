# Amount Validation Feature

## Overview
This feature adds validation to ensure users enter a non-zero amount when creating or editing subscriptions with **Premium** (Paid) or **Promo** (Promotional) subscription types.

## Problem
Users could create or edit subscriptions with Premium or Promo types but leave the amount at $0, which doesn't make sense for paid subscriptions or promotional offers.

## Solution
Added conditional validation that checks:
- If subscription type is **Premium** (`paid`) OR **Promotional** (`promotional`)
- AND the amount is ≤ $0

Then:
1. Display a visual error on the amount field (red border)
2. Show an alert modal with a clear message
3. Play error haptic feedback
4. Focus the amount field so user can correct it
5. Prevent saving until a valid amount is entered

## Implementation Details

### Files Modified

#### 1. `AddSubscriptionView.swift`
- Added state variables:
  - `@State private var showingAmountWarning = false` - Controls alert display
  - `@State private var isAmountInvalid = false` - Controls visual error state

- Updated price field (lines ~596-613):
  - Added `onChange` handler to clear error state when user types
  - Added red border overlay when `isAmountInvalid` is true

- Updated `saveSubscription()` function (lines ~704-709):
  ```swift
  // Validate amount for Premium and Promo types
  if (subscriptionType == .paid || subscriptionType == .promotional) && customPrice <= 0 {
      isAmountInvalid = true
      showingAmountWarning = true
      HapticManager.shared.playError()
      return
  }
  ```

- Added alert modal (lines ~185-191):
  ```swift
  .alert("Amount Required", isPresented: $showingAmountWarning) {
      Button("OK", role: .cancel) {
          isPriceFocused = true
      }
  } message: {
      Text("Please enter an amount greater than \(userPreferences.currencySymbol)0 for \(subscriptionType.displayName) subscriptions.")
  }
  ```

#### 2. `EditSubscriptionView.swift`
- Added same state variables and validation logic
- Updated price field with onChange handler and error styling
- Updated `saveChanges()` function with same validation check
- Added same alert modal

### User Experience

1. **Creating a Subscription**:
   - User selects "Premium" or "Promo" type
   - Leaves amount at $0.00
   - Taps "Add Subscription"
   - ❌ Amount field gets red border
   - 📱 Alert appears: "Amount Required"
   - 💬 Message explains they need to enter amount > $0
   - ⌨️ When they tap "OK", keyboard focuses on amount field
   - ✅ User enters valid amount and can save

2. **Editing a Subscription**:
   - User changes type from "Trial" to "Premium" or "Promo"
   - Amount is $0.00
   - Taps "Save Changes"
   - Same validation flow as above

3. **Visual Feedback**:
   - Red border appears around amount field
   - Border disappears when user starts typing
   - Error haptic plays when validation fails

### Edge Cases Handled

✅ **Trial subscriptions with $0** - Allowed (trials can be free)
✅ **Changing type back to Trial** - Error clears automatically
✅ **Typing in amount field** - Error state clears on change
✅ **Currency symbol** - Alert uses user's preferred currency
✅ **Focus management** - Keyboard appears on amount field after alert

### Subscription Types

| Type | Display Name | Icon | Can be $0? |
|------|-------------|------|------------|
| Trial | Free Trial | clock.badge.checkmark | ✅ Yes |
| Paid | Premium | star.fill | ❌ No |
| Promotional | Promo | gift | ❌ No |

## Testing Checklist

- [ ] Create new subscription with Premium type and $0 amount
- [ ] Create new subscription with Promo type and $0 amount  
- [ ] Create new subscription with Trial type and $0 amount (should work)
- [ ] Edit subscription, change from Trial to Premium with $0 amount
- [ ] Edit subscription, change from Trial to Promo with $0 amount
- [ ] Verify alert message shows correct currency symbol
- [ ] Verify red border appears on amount field
- [ ] Verify error clears when typing new amount
- [ ] Verify haptic feedback plays on error
- [ ] Verify keyboard focuses amount field after dismissing alert
- [ ] Verify can save successfully after entering valid amount

## Future Enhancements

Potential improvements:
- Add real-time validation as user types
- Show inline error message below field instead of/in addition to alert
- Add minimum amount validation (e.g., > $0.01)
- Add maximum amount validation for reasonableness
- Suggest typical prices based on service name

## Related Files

- `/kansyl/Models/SubscriptionType.swift` - Enum definition
- `/kansyl/Views/AddSubscriptionView.swift` - New subscription form
- `/kansyl/Views/EditSubscriptionView.swift` - Edit subscription form
- `/kansyl/Utilities/HapticManager.swift` - Haptic feedback
- `/kansyl/Models/UserSpecificPreferences.swift` - Currency preferences