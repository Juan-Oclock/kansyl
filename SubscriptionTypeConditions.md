# Subscription Type Conditions & Auto-Detection

## Overview
Subscription types are automatically determined and updated based on various conditions. The app supports three subscription types: **Trial**, **Paid**, and **Promotional**.

## Type Determination Logic (Priority Order)

The system checks in this exact order (first match wins):

### Priority 1: Name Keywords (Highest Priority)
- Contains "promo", "promotional", or "discount" → **Promotional** 🟣
- Contains "trial" or "free" → **Trial** 🟠

### Priority 2: Notes Keywords
- Contains "promo", "promotional", or "discount" → **Promotional** 🟣
- Contains "trial" or "free" → **Trial** 🟠

### Priority 3: Legacy isTrial Flag
- If `isTrial` = true AND no promo keywords → **Trial** 🟠

### Priority 4: Duration & Price
- 0-30 days with price > $0 → **Paid** 🟢
- 0-30 days with price = $0 → **Trial** 🟠
- 31-90 days with price = $0 → **Trial** 🟠
- 31-90 days with price > $0 → **Paid** 🟢
- 91+ days → **Paid** 🟢

### Priority 5: Price Only
- Price = $0 → **Trial** 🟠
- Price > $0 → **Paid** 🟢

### 3. 🟢 **Paid Subscriptions**
A subscription is classified as "Paid" when:
1. **Duration ≤ 30 days with price > $0** (monthly subscriptions)
2. **Duration 31-90 days with price > $0** (quarterly subscriptions)
3. **Duration 91-365 days** (annual subscriptions)
4. **Duration > 365 days** (long-term subscriptions)
5. **Has a price > $0** and doesn't match trial/promo conditions

## Auto-Update Scenarios

The subscription type is automatically recalculated in these situations:

### 1. **When Creating a New Subscription**
- Type is determined based on the name, notes, duration, and price
- User entering "Netflix Trial" → automatically marked as Trial
- User entering "Spotify Promo" → automatically marked as Promotional

### 2. **When Editing an Existing Subscription**
- Type is recalculated when user saves changes
- If user changes name from "Netflix" to "Netflix Trial" → updates to Trial
- If user adds "50% discount" to notes → updates to Promotional
- If user changes price from $0 to $9.99 → updates from Trial to Paid

### 3. **During Initial Migration**
- All existing subscriptions are analyzed on first app launch
- Types are assigned based on current values

### 4. **Manual Conversion**
- When converting trial to paid via the TrialConversionView
- Type changes from Trial to Paid automatically

## Implementation Files

- **Type Determination Logic**: `/kansyl/Extensions/Subscription+TypeDetermination.swift`
- **Migration Logic**: `/kansyl/Models/SubscriptionMigration.swift`
- **Edit Updates**: `/kansyl/Views/EditSubscriptionView.swift` (line 424)
- **Create Updates**: `/kansyl/Models/SubscriptionStore.swift` (line 162)
- **Visual Badges**: `/kansyl/Views/Components/SubscriptionTypeBadge.swift`

## Visual Indicators

Each type has distinct visual characteristics in the UI:
- **Trial**: Orange badge with clock icon ("Trial")
- **Paid**: Green badge with star icon ("Premium")
- **Promotional**: Purple badge with gift icon ("Promo")

## Examples

### Name-Based Detection
- "Netflix Free Trial" → **Trial** 🟠
- "Spotify Premium Promo" → **Promotional** 🟣
- "Disney+" → **Paid** 🟢 (if has price)

### Duration & Price Based
- 30 days, $0 → **Trial** 🟠
- 30 days, $9.99 → **Paid** 🟢
- 90 days, $4.99, notes: "Student discount" → **Promotional** 🟣
- 365 days, $99 → **Paid** 🟢

### Edit Scenarios
1. User edits "Netflix" subscription, changes name to "Netflix Trial" → Updates to **Trial**
2. User edits subscription, adds note "50% off for 3 months" → Updates to **Promotional**
3. User edits trial subscription, changes price from $0 to $15.99 → Updates to **Paid**

## Testing

To test the auto-detection:
1. Create a new subscription with "trial" in the name
2. Edit an existing subscription and add "promo" to notes
3. Check that badges update accordingly in the subscription list