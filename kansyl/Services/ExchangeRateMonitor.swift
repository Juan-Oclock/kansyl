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
    /// OPTIMIZED: Groups by currency and fetches rates once per currency (90% fewer API calls)
    func checkAndUpdateExchangeRates(in context: NSManagedObjectContext) async {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        // Only get subscriptions with foreign currency and due for update (24h+)
        request.predicate = NSPredicate(
            format: "originalCurrency != nil AND (lastRateUpdate == nil OR lastRateUpdate < %@)",
            Date().addingTimeInterval(-24 * 3600) as NSDate
        )
        
        do {
            let subscriptions = try context.fetch(request)
            guard !subscriptions.isEmpty else { return }
            
            AppLogger.log("Checking exchange rates for \(subscriptions.count) subscriptions", category: "ExchangeRateMonitor")
            
            // OPTIMIZATION: Group subscriptions by currency to minimize API calls
            let currencyGroups = Dictionary(grouping: subscriptions) { subscription in
                subscription.originalCurrency ?? ""
            }
            
            // Remove empty currency key
            let validGroups = currencyGroups.filter { !$0.key.isEmpty }
            
            // Fetch exchange rates for all unique currencies (SINGLE batch of API calls)
            let userCurrency = AppPreferences.shared.currencyCode
            var rates: [String: Double] = [:]
            
            for currency in validGroups.keys {
                // This uses the cached rate if available (1-hour cache)
                if let rate = await conversionService.getExchangeRate(
                    from: currency,
                    to: userCurrency
                ) {
                    rates[currency] = rate
                }
            }
            
            AppLogger.log("Fetched rates for \(rates.count) currencies", category: "ExchangeRateMonitor")
            
            // Update all subscriptions with fetched rates (NO MORE API CALLS)
            var updatedCount = 0
            for (currency, subscriptions) in validGroups {
                guard let currentRate = rates[currency] else { continue }
                
                for subscription in subscriptions {
                    if shouldUpdateWithRate(subscription, rate: currentRate) {
                        updateSubscriptionWithRate(subscription, rate: currentRate, in: context)
                        updatedCount += 1
                    }
                }
            }
            
            if updatedCount > 0 {
                try context.save()
                AppLogger.success("Updated \(updatedCount) subscription(s) with new exchange rates", category: "ExchangeRateMonitor")
                
                // Send notification about rate updates
                NotificationManager.shared.sendExchangeRateUpdateNotification(count: updatedCount)
            }
        } catch {
            AppLogger.error("Failed to check exchange rates: \(error)", category: "ExchangeRateMonitor")
        }
    }
    
    /// Check if subscription should be updated with the given rate (no API call)
    private func shouldUpdateWithRate(_ subscription: Subscription, rate: Double) -> Bool {
        let oldRate = subscription.exchangeRate
        
        // If no previous rate, update
        guard oldRate > 0 else { return true }
        
        // Check if rate has changed significantly (5% threshold)
        let changePercentage = abs(rate - oldRate) / oldRate
        return changePercentage >= significantChangeThreshold
    }
    
    /// Update subscription amount with pre-fetched exchange rate (no API call)
    private func updateSubscriptionWithRate(_ subscription: Subscription, rate: Double, in context: NSManagedObjectContext) {
        guard let originalCurrency = subscription.originalCurrency,
              subscription.originalAmount > 0 else {
            return
        }
        
        let userCurrency = AppPreferences.shared.currencyCode
        
        // Calculate new amounts with pre-fetched rate
        let originalAmount = subscription.originalAmount
        let newAmount = originalAmount * rate
        let oldAmount = subscription.billingAmount
        let oldRate = subscription.exchangeRate
        
        // Update subscription with new rate
        subscription.billingAmount = newAmount
        subscription.exchangeRate = rate
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
        let changePercentage = ((rate - oldRate) / oldRate) * 100
        let changeDirection = changePercentage > 0 ? "increased" : "decreased"
        
        let updateNote = "\n[Rate Update \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))]: Exchange rate \(changeDirection) by \(String(format: "%.1f", abs(changePercentage)))%. New rate: 1 \(originalCurrency) = \(String(format: "%.4f", rate)) \(userCurrency). Amount changed from \(userCurrency) \(String(format: "%.2f", oldAmount)) to \(String(format: "%.2f", newAmount))."
        
        subscription.notes = (subscription.notes ?? "") + updateNote
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