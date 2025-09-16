#!/usr/bin/swift

// Test script to add sample subscriptions
// This can be used to test if subscriptions appear properly on the Subscription Page

import Foundation
import CoreData

// Sample subscription data for testing
struct TestSubscription {
    let name: String
    let monthlyPrice: Double
    let daysUntilEnd: Int
    let logo: String
}

let testSubscriptions = [
    TestSubscription(name: "Spotify", monthlyPrice: 9.99, daysUntilEnd: 3, logo: "music.note"),
    TestSubscription(name: "Netflix", monthlyPrice: 15.99, daysUntilEnd: 5, logo: "tv"),
    TestSubscription(name: "Apple Music", monthlyPrice: 10.99, daysUntilEnd: 12, logo: "applelogo"),
    TestSubscription(name: "YouTube Premium", monthlyPrice: 11.99, daysUntilEnd: 8, logo: "play.rectangle"),
    TestSubscription(name: "Disney+", monthlyPrice: 7.99, daysUntilEnd: 15, logo: "star.fill")
]

print("📱 Test Subscription Adder")
print("========================")
print("")
print("This script would add the following test subscriptions:")
print("")

for (index, sub) in testSubscriptions.enumerated() {
    let endDate = Calendar.current.date(byAdding: .day, value: sub.daysUntilEnd, to: Date())!
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    
    print("\(index + 1). \(sub.name)")
    print("   💵 Price: $\(String(format: "%.2f", sub.monthlyPrice))/month")
    print("   📅 Ends: \(formatter.string(from: endDate)) (\(sub.daysUntilEnd) days)")
    print("   🎨 Icon: \(sub.logo)")
    print("")
}

print("⚠️  Note: To actually add these subscriptions:")
print("1. Open the app in the simulator")
print("2. Tap the '+' button on the Subscription page")
print("3. Select a service or enter custom details")
print("4. Save the subscription")
print("")
print("The subscriptions should then appear on the main Subscription page.")
print("")
print("If subscriptions don't appear after adding:")
print("• Check that Core Data is saving properly")
print("• Verify that fetchSubscriptions() is being called")
print("• Ensure the view is refreshing after dismissing the add sheet")