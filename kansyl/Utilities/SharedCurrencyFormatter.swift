//
//  SharedCurrencyFormatter.swift
//  kansyl
//
//  Shared currency formatting utility for main app and widgets
//

import Foundation

/// A shared currency formatter that works in both main app and widget contexts
struct SharedCurrencyFormatter {
    
    /// Get the current currency code from user preferences
    private static func getCurrentCurrencyCode() -> String {
        // Get from UserSpecificPreferences which is always non-nil
        let userSpecific = UserSpecificPreferences.shared.currencyCode
        if !userSpecific.isEmpty {
            return userSpecific
        }
        // Fallback to global key or default
        return UserDefaults.standard.string(forKey: "global_currencyCode") ?? "USD"
    }
    
    /// Get the current currency symbol from user preferences
    private static func getCurrentCurrencySymbol() -> String {
        // Get from UserSpecificPreferences which is always non-nil
        let userSpecific = UserSpecificPreferences.shared.currencySymbol
        if !userSpecific.isEmpty {
            return userSpecific
        }
        // Fallback to global key or default
        return UserDefaults.standard.string(forKey: "global_currencySymbol") ?? "$"
    }
    
    /// Formats a price using the stored currency preference
    static func formatPrice(_ amount: Double) -> String {
        // Get current currency from UserSpecificPreferences
        let currencyCode = getCurrentCurrencyCode()
        let currencySymbol = getCurrentCurrencySymbol()
        
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
        let currencySymbol = getCurrentCurrencySymbol()
        
        if amount >= 1000 {
            return "\(currencySymbol)\(String(format: "%.0f", amount / 1000))k"
        } else {
            return "\(currencySymbol)\(String(format: "%.0f", amount))"
        }
    }
    
    /// Get the currency symbol
    static var currencySymbol: String {
        return getCurrentCurrencySymbol()
    }
}

extension UserDefaults {
    /// Widget suite identifier - needs to match the App Group
    static let widgetSuite = UserDefaults(suiteName: "group.com.juan-oclock.kansyl") ?? UserDefaults.standard
}