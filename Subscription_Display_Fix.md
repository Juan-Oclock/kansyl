# Subscription Display Fix - Billing Cycles and Amounts

## Problem
Subscriptions were always displaying as "Monthly" with the monthly-converted price (e.g., ₱15.00/mo) even when they were actually quarterly, yearly, or other billing cycles. The Mobbin Pro subscription that was ₱45.00 quarterly was incorrectly showing as ₱15.00/mo Monthly.

## Root Cause
The Core Data model and display logic only supported monthly pricing. There was no way to store or display the actual billing cycle and amount.

## Solution Implemented

### 1. **Core Data Model Update**
Added two new attributes to the Subscription entity:
- `billingAmount` (Double): The actual amount charged per billing cycle
- `billingCycle` (String): The billing period (monthly, quarterly, yearly, etc.)

### 2. **SubscriptionStore Enhancement**
Updated `addSubscription` method to accept optional parameters:
- `billingCycle`: The actual billing period
- `billingAmount`: The actual amount charged

### 3. **ReceiptScanner Update**
Modified to pass the actual billing information:
```swift
subscriptionStore.addSubscription(
    // ... other parameters
    billingCycle: "quarterly",  // Not "monthly"
    billingAmount: 45.00        // Not 15.00
)
```

### 4. **Display Logic Update**
Updated `ModernSubscriptionsView` to show correct billing information:
- Shows "₱45.00/qtr" instead of "₱15.00/mo"
- Shows "Quarterly" instead of "Monthly"

## How It Works Now

### Receipt Scan → Storage → Display

1. **Receipt Scan Detects**:
   - Service: Mobbin Pro
   - Amount: ₱45.00
   - Cycle: Quarterly
   - Date: Jul 31, 2025

2. **Stored in Database**:
   - `billingAmount`: 45.00
   - `billingCycle`: "quarterly"
   - `monthlyPrice`: 15.00 (calculated for budgeting)
   - `startDate`: Jul 31, 2025
   - `endDate`: Oct 29, 2025 (90 days)

3. **Displayed as**:
   - **₱45.00/qtr** (not ₱15.00/mo)
   - **Quarterly** (not Monthly)
   - 90 days subscription period

## Supported Billing Formats

| Cycle | Display Price | Display Text |
|-------|--------------|--------------|
| Weekly | ₱X.XX/wk | Weekly |
| Monthly | ₱X.XX/mo | Monthly |
| Quarterly | ₱X.XX/qtr | Quarterly |
| Semi-Annual | ₱X.XX/6mo | Semi-Annual |
| Yearly | ₱X.XX/yr | Yearly |

## Files Modified

### Core Data Model
- `/kansyl/Kansyl.xcdatamodeld/Kansyl.xcdatamodel/contents`
  - Added `billingAmount` and `billingCycle` attributes

### Business Logic
- `/kansyl/Models/SubscriptionStore.swift`
  - Updated `addSubscription` to support billing cycle and amount

- `/kansyl/Utilities/ReceiptScanner.swift`
  - Passes actual billing cycle and amount to store

### UI Components
- `/kansyl/Views/ModernSubscriptionsView.swift`
  - Added `formatPrice` and `formatBillingCycle` functions
  - Updated display to show actual billing information

## Migration Notes

### For Existing Subscriptions
Existing subscriptions will:
- Continue to work normally
- Show as "Monthly" (default)
- Use `monthlyPrice` as `billingAmount` if not set

### For New Subscriptions
New subscriptions from receipt scans will:
- Show correct billing cycle
- Display actual charged amount
- Store both actual and monthly-calculated prices

## Benefits

1. **Accurate Display**: Users see what they actually pay (₱45/quarter, not ₱15/month)
2. **Clear Billing Cycles**: Shows "Quarterly", "Yearly", etc., not always "Monthly"
3. **Better Understanding**: Users know their actual payment schedule
4. **Flexible Budgeting**: Still calculates monthly cost internally for budget reports

## Testing

1. Delete the app to reset Core Data
2. Scan a quarterly receipt (like Mobbin Pro)
3. Verify it shows:
   - ₱45.00/qtr (not ₱15.00/mo)
   - Quarterly (not Monthly)
4. Check that budgets still calculate correctly using internal monthly price

## Future Enhancements

1. Add migration for existing subscriptions to set billing cycle
2. Allow editing billing cycle in subscription details
3. Show both actual and monthly-equivalent prices
4. Add support for custom billing periods (e.g., every 2 months)