# Subscription Type Enhancement Guide

## 1. Core Data Model Update

### Add New Fields to Subscription Entity
Update the Core Data model (Kansyl.xcdatamodeld) to include:

```xml
<attribute name="subscriptionType" attributeType="String" defaultValueString="trial"/>
<attribute name="isTrial" attributeType="Boolean" defaultValueString="YES" usesScalarValueType="YES"/>
<attribute name="convertedToPaid" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
<attribute name="trialEndDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
```

## 2. Create Subscription Type Enum

```swift
// SubscriptionType.swift
enum SubscriptionType: String, CaseIterable {
    case trial = "trial"
    case paid = "paid"
    case promotional = "promotional"
    
    var displayName: String {
        switch self {
        case .trial: return "Free Trial"
        case .paid: return "Premium"
        case .promotional: return "Promo"
        }
    }
    
    var icon: String {
        switch self {
        case .trial: return "clock.badge.checkmark"
        case .paid: return "star.fill"
        case .promotional: return "gift"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .trial: return .orange
        case .paid: return .green
        case .promotional: return .purple
        }
    }
}
```

## 3. Update SubscriptionStore.swift

```swift
// Add to SubscriptionStore.swift
func addSubscription(
    name: String, 
    startDate: Date, 
    endDate: Date,
    monthlyPrice: Double, 
    serviceLogo: String, 
    notes: String? = nil,
    subscriptionType: SubscriptionType = .trial,  // New parameter
    // ... other parameters
) -> Subscription? {
    // ... existing code ...
    
    newSubscription.subscriptionType = subscriptionType.rawValue
    newSubscription.isTrial = (subscriptionType == .trial)
    
    // Set trial end date if it's a trial
    if subscriptionType == .trial {
        newSubscription.trialEndDate = endDate
    }
    
    // ... rest of the method
}

// Add method to convert trial to paid
func convertTrialToPaid(_ subscription: Subscription, newEndDate: Date? = nil) {
    subscription.subscriptionType = SubscriptionType.paid.rawValue
    subscription.isTrial = false
    subscription.convertedToPaid = Date()
    
    // Optionally update the end date for the paid subscription
    if let newDate = newEndDate {
        subscription.endDate = newDate
    }
    
    // Update status if needed
    subscription.status = SubscriptionStatus.active.rawValue
    
    saveContext()
    fetchSubscriptions()
    
    // Update notifications for paid subscription
    NotificationManager.shared.scheduleNotifications(for: subscription)
    
    // Track conversion
    AnalyticsManager.shared.track(.trialConverted, properties: [
        "service": subscription.name ?? "",
        "days_used": Calendar.current.dateComponents([.day], 
            from: subscription.startDate ?? Date(), 
            to: Date()).day ?? 0
    ])
}
```

## 4. Visual Distinction in UI

### Update Subscription Cards

```swift
// In HybridSubscriptionCard.swift or similar views
struct SubscriptionTypeBadge: View {
    let subscription: Subscription
    
    var subscriptionType: SubscriptionType {
        SubscriptionType(rawValue: subscription.subscriptionType ?? "trial") ?? .trial
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: subscriptionType.icon)
                .font(.system(size: 10, weight: .semibold))
            
            Text(subscriptionType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(subscriptionType.badgeColor)
        .cornerRadius(6)
    }
}

// Add to subscription card views
var body: some View {
    VStack(alignment: .leading) {
        HStack {
            // Service logo and name
            // ...
            
            Spacer()
            
            // Add subscription type badge
            SubscriptionTypeBadge(subscription: subscription)
        }
        
        // Rest of the card content
        // ...
    }
}
```

## 5. Add Conversion Flow

### Create Trial Conversion View

```swift
// TrialConversionView.swift
struct TrialConversionView: View {
    @ObservedObject var subscription: Subscription
    @State private var selectedPlan: BillingPlan = .monthly
    @State private var newEndDate = Date()
    @Environment(\.dismiss) var dismiss
    
    enum BillingPlan: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var months: Int {
            switch self {
            case .monthly: return 1
            case .yearly: return 12
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.yellow)
                    
                    Text("Convert to Premium")
                        .font(.title.bold())
                    
                    Text("Keep enjoying \(subscription.name ?? "") with a premium subscription")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Billing options
                VStack(spacing: 12) {
                    ForEach(BillingPlan.allCases, id: \.self) { plan in
                        BillingPlanRow(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            price: calculatePrice(for: plan),
                            onTap: { selectedPlan = plan }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Premium Benefits")
                        .font(.headline)
                    
                    BenefitRow(icon: "checkmark.circle.fill", text: "Continued access")
                    BenefitRow(icon: "bell.fill", text: "Smart reminders")
                    BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Usage analytics")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: convertToPremium) {
                        Text("Convert to Premium")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button("Keep as Trial") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func convertToPremium() {
        let newEndDate = Calendar.current.date(
            byAdding: .month,
            value: selectedPlan.months,
            to: Date()
        ) ?? Date()
        
        SubscriptionStore.shared.convertTrialToPaid(
            subscription,
            newEndDate: newEndDate
        )
        
        dismiss()
    }
}
```

## 6. Statistics and Analytics

### Update StatsView to Show Trial vs Paid Breakdown

```swift
// Add to StatsView
struct SubscriptionTypeStats: View {
    let subscriptions: [Subscription]
    
    var trialCount: Int {
        subscriptions.filter { $0.isTrial }.count
    }
    
    var paidCount: Int {
        subscriptions.filter { !$0.isTrial }.count
    }
    
    var conversionRate: Double {
        let converted = subscriptions.filter { $0.convertedToPaid != nil }.count
        let total = subscriptions.count
        return total > 0 ? Double(converted) / Double(total) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscription Types")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Trials",
                    value: "\(trialCount)",
                    icon: "clock.badge.checkmark",
                    color: .orange
                )
                
                StatCard(
                    title: "Premium",
                    value: "\(paidCount)",
                    icon: "star.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Conversion",
                    value: "\(Int(conversionRate))%",
                    icon: "arrow.triangle.turn.up.right.circle",
                    color: .blue
                )
            }
        }
    }
}
```

## 7. Smart Notifications

### Update NotificationManager for Different Message Types

```swift
// In NotificationManager.swift
func scheduleNotifications(for subscription: Subscription) {
    let subscriptionType = SubscriptionType(rawValue: subscription.subscriptionType ?? "trial") ?? .trial
    
    // Different notification strategies based on type
    switch subscriptionType {
    case .trial:
        scheduleTrialNotifications(for: subscription)
    case .paid:
        schedulePaidNotifications(for: subscription)
    case .promotional:
        schedulePromoNotifications(for: subscription)
    }
}

private func scheduleTrialNotifications(for subscription: Subscription) {
    // More aggressive reminders for trials
    let intervals = [7, 3, 1, 0] // days before end
    
    for days in intervals {
        let title = days == 0 ? "⚠️ Trial Ending Today!" : "Trial Ending Soon"
        let body = "Your \(subscription.name ?? "") free trial ends in \(days) days. Decide if you want to continue."
        
        // Schedule notification...
    }
}

private func schedulePaidNotifications(for subscription: Subscription) {
    // Less frequent reminders for paid
    let intervals = [7, 1] // days before renewal
    
    for days in intervals {
        let title = "Subscription Renewal"
        let body = "Your \(subscription.name ?? "") premium subscription renews in \(days) days."
        
        // Schedule notification...
    }
}
```

## 8. Migration Strategy

For existing users, add a migration to set subscription types based on duration:

```swift
// DataMigration.swift
func migrateSubscriptionTypes() {
    let subscriptions = fetchAllSubscriptions()
    
    for subscription in subscriptions {
        // If subscription type is not set
        if subscription.subscriptionType == nil {
            // Determine type based on duration and price
            let duration = Calendar.current.dateComponents(
                [.day], 
                from: subscription.startDate ?? Date(), 
                to: subscription.endDate ?? Date()
            ).day ?? 0
            
            // Assume <= 30 days is likely a trial
            if duration <= 30 {
                subscription.subscriptionType = SubscriptionType.trial.rawValue
                subscription.isTrial = true
                subscription.trialEndDate = subscription.endDate
            } else {
                subscription.subscriptionType = SubscriptionType.paid.rawValue
                subscription.isTrial = false
            }
        }
    }
    
    saveContext()
}
```

## 9. Quick Actions

Add context menu actions for easy conversion:

```swift
// In subscription card context menu
.contextMenu {
    if subscription.isTrial {
        Button {
            showConversionSheet = true
        } label: {
            Label("Convert to Premium", systemImage: "star.fill")
        }
    }
    
    // Other actions...
}
```

## 10. Widget Updates

Update widgets to show subscription type:

```swift
// In widget views
HStack {
    Image(systemName: subscription.isTrial ? "clock.badge" : "star.fill")
        .foregroundColor(subscription.isTrial ? .orange : .green)
    
    Text(subscription.name ?? "")
        .font(.caption)
}
```

## Implementation Priority

1. **High Priority**
   - Add Core Data fields
   - Create SubscriptionType enum
   - Update SubscriptionStore methods
   - Add visual badges to cards

2. **Medium Priority**
   - Implement conversion flow
   - Update notifications
   - Add statistics view

3. **Low Priority**
   - Migration for existing users
   - Widget updates
   - Advanced analytics

This enhancement will provide clear visual and functional distinction between free trials and premium subscriptions throughout the app.