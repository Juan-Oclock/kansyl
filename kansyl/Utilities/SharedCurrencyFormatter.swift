//
//  SharedCurrencyFormatter.swift
//  kansyl
//
//  Shared currency formatting utility for main app and widgets
//

import Foundation

/// A shared currency formatter that works in both main app and widget contexts
struct SharedCurrencyFormatter {
    
    /// Formats a price using the stored currency preference
    static func formatPrice(_ amount: Double) -> String {
        // Try to get stored currency preferences
        let currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(String(format: "%.2f", amount))"
    }
    
    /// Formats a price with abbreviated format (for widgets)
    static func formatPriceCompact(_ amount: Double) -> String {
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        
        if amount >= 1000 {
            return "\(currencySymbol)\(String(format: "%.0f", amount / 1000))k"
        } else {
            return "\(currencySymbol)\(String(format: "%.0f", amount))"
        }
    }
    
    /// Get the currency symbol
    static var currencySymbol: String {
        return UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
    }
}

extension UserDefaults {
    /// Widget suite identifier - needs to match the App Group
    static let widgetSuite = UserDefaults(suiteName: "group.com.juan-oclock.kansyl") ?? UserDefaults.standard
}