//
//  ExchangeRateMonitor.swift
//  kansyl
//
//  Monitors exchange rate changes and updates subscription amounts
//

import Foundation
import CoreData
import UserNotifications

class ExchangeRateMonitor {
    static let shared = ExchangeRateMonitor()
    private let conversionService = CurrencyConversionService.shared
    
    // Threshold for significant rate change (5% by default)
    private let significantChangeThreshold: Double = 0.05
    
    private init() {}
    
    /// Check all subscriptions for exchange rate changes and update if needed
    func checkAndUpdateExchangeRates(in context: NSManagedObjectContext) async {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        // Only get subscriptions with foreign currency
        request.predicate = NSPredicate(format: "originalCurrency != nil")
        
        do {
            let subscriptions = try context.fetch(request)
            var updatedCount = 0
            
            for subscription in subscriptions {
                if await shouldUpdateSubscription(subscription) {
                    await updateSubscriptionAmount(subscription, in: context)
                    updatedCount += 1
                }
            }
            
            if updatedCount > 0 {
                try context.save()
                print("✅ Updated \(updatedCount) subscription(s) with new exchange rates")
                
                // Send notification about rate updates
                NotificationManager.shared.sendExchangeRateUpdateNotification(count: updatedCount)
            }
        } catch {
            print("❌ Failed to check exchange rates: \(error)")
        }
    }
    
    /// Check if a subscription needs exchange rate update
    private func shouldUpdateSubscription(_ subscription: Subscription) async -> Bool {
        guard let originalCurrency = subscription.originalCurrency,
              let lastUpdate = subscription.lastRateUpdate else {
            return false
        }
        
        // Check if it's been at least 24 hours since last update
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        if hoursSinceUpdate < 24 {
            return false
        }
        
        // Get current exchange rate
        let userCurrency = AppPreferences.shared.currencyCode
        guard let currentRate = await conversionService.getExchangeRate(
            from: originalCurrency,
            to: userCurrency
        ) else {
            return false
        }
        
        // Check if rate has changed significantly
        let oldRate = subscription.exchangeRate
        if oldRate > 0 {
            let changePercentage = abs(currentRate - oldRate) / oldRate
            return changePercentage >= significantChangeThreshold
        }
        
        return true
    }
    
    /// Update subscription amount with current exchange rate
    private func updateSubscriptionAmount(_ subscription: Subscription, in context: NSManagedObjectContext) async {
        guard let originalCurrency = subscription.originalCurrency,
              subscription.originalAmount > 0 else {
            return
        }
        
        let userCurrency = AppPreferences.shared.currencyCode
        
        // Get current exchange rate
        guard let currentRate = await conversionService.getExchangeRate(
            from: originalCurrency,
            to: userCurrency
        ) else {
            print("⚠️ Could not get current exchange rate for \(originalCurrency) to \(userCurrency)")
            return
        }
        
        // Calculate new amounts
        let originalAmount = subscription.originalAmount
        let newAmount = originalAmount * currentRate
        let oldAmount = subscription.billingAmount
        let oldRate = subscription.exchangeRate
        
        // Update subscription
        subscription.billingAmount = newAmount
        subscription.exchangeRate = currentRate
        subscription.lastRateUpdate = Date()
        
        // Update monthly price if needed
        if let billingCycle = subscription.billingCycle {
            switch billingCycle.lowercased() {
            case "yearly", "annual":
                subscription.monthlyPrice = newAmount / 12
            case "quarterly":
                subscription.monthlyPrice = newAmount / 3
            case "semi-annual", "biannual":
                subscription.monthlyPrice = newAmount / 6
            case "weekly":
                subscription.monthlyPrice = newAmount * 4.33
            default:
                subscription.monthlyPrice = newAmount
            }
        }
        
        // Add note about rate update
        let changePercentage = ((currentRate - oldRate) / oldRate) * 100
        let changeDirection = changePercentage > 0 ? "increased" : "decreased"
        
        let updateNote = "\n[Rate Update \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))]: Exchange rate \(changeDirection) by \(String(format: "%.1f", abs(changePercentage)))%. New rate: 1 \(originalCurrency) = \(String(format: "%.4f", currentRate)) \(userCurrency). Amount changed from \(userCurrency) \(String(format: "%.2f", oldAmount)) to \(String(format: "%.2f", newAmount))."
        
        subscription.notes = (subscription.notes ?? "") + updateNote
        
        print("📊 Updated \(subscription.name ?? "subscription"): \(originalCurrency) \(originalAmount) → \(userCurrency) \(String(format: "%.2f", newAmount)) (Rate: \(String(format: "%.4f", currentRate)))")
    }
    
    /// Get exchange rate change info for a subscription
    func getExchangeRateInfo(for subscription: Subscription) async -> ExchangeRateInfo? {
        guard let originalCurrency = subscription.originalCurrency else {
            return nil
        }
        
        let userCurrency = AppPreferences.shared.currencyCode
        
        // Get current rate
        guard let currentRate = await conversionService.getExchangeRate(
            from: originalCurrency,
            to: userCurrency
        ) else {
            return nil
        }
        
        let originalAmount = subscription.originalAmount
        let oldRate = subscription.exchangeRate
        let changePercentage = oldRate > 0 ? ((currentRate - oldRate) / oldRate) * 100 : 0
        let currentAmount = originalAmount * currentRate
        
        return ExchangeRateInfo(
            originalCurrency: originalCurrency,
            originalAmount: originalAmount,
            currentCurrency: userCurrency,
            currentAmount: currentAmount,
            currentRate: currentRate,
            previousRate: oldRate,
            changePercentage: changePercentage,
            lastUpdate: subscription.lastRateUpdate ?? Date()
        )
    }
}

// MARK: - Exchange Rate Info Model
struct ExchangeRateInfo {
    let originalCurrency: String
    let originalAmount: Double
    let currentCurrency: String
    let currentAmount: Double
    let currentRate: Double
    let previousRate: Double
    let changePercentage: Double
    let lastUpdate: Date
    
    var isSignificantChange: Bool {
        abs(changePercentage) >= 5.0
    }
    
    var changeDescription: String {
        if changePercentage > 0 {
            return "↑ \(String(format: "%.1f", changePercentage))%"
        } else if changePercentage < 0 {
            return "↓ \(String(format: "%.1f", abs(changePercentage)))%"
        } else {
            return "No change"
        }
    }
    
    var formattedCurrentAmount: String {
        CurrencyConversionService.shared.formatAmount(currentAmount, currency: currentCurrency)
    }
    
    var formattedOriginalAmount: String {
        CurrencyConversionService.shared.formatAmount(originalAmount, currency: originalCurrency)
    }
}

// MARK: - Notification Extension
extension NotificationManager {
    func sendExchangeRateUpdateNotification(count: Int) {
        let title = "Exchange Rates Updated"
        let body = count == 1 
            ? "1 subscription amount was updated due to exchange rate changes."
            : "\(count) subscription amounts were updated due to exchange rate changes."
        
        // Create and schedule notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "exchange-rate-update-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}