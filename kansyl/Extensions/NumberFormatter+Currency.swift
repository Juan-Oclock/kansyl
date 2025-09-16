//
//  NumberFormatter+Currency.swift
//  kansyl
//
//  Extension for consistent currency formatting throughout the app
//

import Foundation

extension NumberFormatter {
    static func currency(for currencyCode: String = AppPreferences.shared.currencyCode) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        // Use our custom currency symbols if available
        if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: currencyCode) {
            formatter.currencySymbol = currencyInfo.symbol
        }
        
        return formatter
    }
}

extension Double {
    /// Formats the double value as currency using the user's preferred currency
    func formatted(as currencyCode: String = AppPreferences.shared.currencyCode) -> String {
        return CurrencyManager.shared.formatPrice(self, currencyCode: currencyCode)
    }
}

extension AppPreferences {
    /// Formats a price using the user's selected currency
    func formatPrice(_ amount: Double) -> String {
        return CurrencyManager.shared.formatPrice(amount, currencyCode: self.currencyCode)
    }
}