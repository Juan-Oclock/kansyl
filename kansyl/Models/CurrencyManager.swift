//
//  CurrencyManager.swift
//  kansyl
//
//  Currency management with location-based detection and comprehensive currency support
//

import Foundation
import CoreLocation

struct CurrencyInfo: Identifiable {
    let id: String
    let code: String
    let symbol: String
    let name: String
    let countries: [String]
    
    init(code: String, symbol: String, name: String, countries: [String]) {
        self.id = code
        self.code = code
        self.symbol = symbol
        self.name = name
        self.countries = countries
    }
}

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    // MARK: - Supported Currencies
    static let supportedCurrencies: [CurrencyInfo] = [
        // Major Global Currencies
        CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar", countries: ["US", "EC", "SV", "PA", "TL"]),
        CurrencyInfo(code: "EUR", symbol: "€", name: "Euro", countries: ["DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE", "GR", "FI", "SK", "SI", "EE", "LV", "LT", "LU", "CY", "MT"]),
        CurrencyInfo(code: "GBP", symbol: "£", name: "British Pound", countries: ["GB"]),
        CurrencyInfo(code: "JPY", symbol: "¥", name: "Japanese Yen", countries: ["JP"]),
        
        // Asia-Pacific
        CurrencyInfo(code: "PHP", symbol: "₱", name: "Philippine Peso", countries: ["PH"]),
        CurrencyInfo(code: "SGD", symbol: "S$", name: "Singapore Dollar", countries: ["SG"]),
        CurrencyInfo(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar", countries: ["HK"]),
        CurrencyInfo(code: "KRW", symbol: "₩", name: "South Korean Won", countries: ["KR"]),
        CurrencyInfo(code: "CNY", symbol: "¥", name: "Chinese Yuan", countries: ["CN"]),
        CurrencyInfo(code: "INR", symbol: "₹", name: "Indian Rupee", countries: ["IN"]),
        CurrencyInfo(code: "THB", symbol: "฿", name: "Thai Baht", countries: ["TH"]),
        CurrencyInfo(code: "MYR", symbol: "RM", name: "Malaysian Ringgit", countries: ["MY"]),
        CurrencyInfo(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", countries: ["ID"]),
        CurrencyInfo(code: "VND", symbol: "₫", name: "Vietnamese Dong", countries: ["VN"]),
        
        // Americas
        CurrencyInfo(code: "CAD", symbol: "C$", name: "Canadian Dollar", countries: ["CA"]),
        CurrencyInfo(code: "AUD", symbol: "A$", name: "Australian Dollar", countries: ["AU"]),
        CurrencyInfo(code: "MXN", symbol: "$", name: "Mexican Peso", countries: ["MX"]),
        CurrencyInfo(code: "BRL", symbol: "R$", name: "Brazilian Real", countries: ["BR"]),
        CurrencyInfo(code: "ARS", symbol: "$", name: "Argentine Peso", countries: ["AR"]),
        CurrencyInfo(code: "CLP", symbol: "$", name: "Chilean Peso", countries: ["CL"]),
        CurrencyInfo(code: "COP", symbol: "$", name: "Colombian Peso", countries: ["CO"]),
        CurrencyInfo(code: "PEN", symbol: "S/", name: "Peruvian Sol", countries: ["PE"]),
        
        // Europe (Non-Euro)
        CurrencyInfo(code: "CHF", symbol: "CHF", name: "Swiss Franc", countries: ["CH", "LI"]),
        CurrencyInfo(code: "NOK", symbol: "kr", name: "Norwegian Krone", countries: ["NO"]),
        CurrencyInfo(code: "SEK", symbol: "kr", name: "Swedish Krona", countries: ["SE"]),
        CurrencyInfo(code: "DKK", symbol: "kr", name: "Danish Krone", countries: ["DK"]),
        CurrencyInfo(code: "PLN", symbol: "zł", name: "Polish Złoty", countries: ["PL"]),
        CurrencyInfo(code: "CZK", symbol: "Kč", name: "Czech Koruna", countries: ["CZ"]),
        CurrencyInfo(code: "HUF", symbol: "Ft", name: "Hungarian Forint", countries: ["HU"]),
        CurrencyInfo(code: "RON", symbol: "lei", name: "Romanian Leu", countries: ["RO"]),
        CurrencyInfo(code: "BGN", symbol: "лв", name: "Bulgarian Lev", countries: ["BG"]),
        CurrencyInfo(code: "RUB", symbol: "₽", name: "Russian Ruble", countries: ["RU"]),
        CurrencyInfo(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia", countries: ["UA"]),
        CurrencyInfo(code: "TRY", symbol: "₺", name: "Turkish Lira", countries: ["TR"]),
        
        // Middle East & Africa
        CurrencyInfo(code: "SAR", symbol: "﷼", name: "Saudi Riyal", countries: ["SA"]),
        CurrencyInfo(code: "AED", symbol: "د.إ", name: "UAE Dirham", countries: ["AE"]),
        CurrencyInfo(code: "ILS", symbol: "₪", name: "Israeli Shekel", countries: ["IL"]),
        CurrencyInfo(code: "ZAR", symbol: "R", name: "South African Rand", countries: ["ZA"]),
        CurrencyInfo(code: "EGP", symbol: "£", name: "Egyptian Pound", countries: ["EG"]),
        
        // Others
        CurrencyInfo(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar", countries: ["NZ"]),
        CurrencyInfo(code: "TWD", symbol: "NT$", name: "Taiwan Dollar", countries: ["TW"])
    ]
    
    private init() {}
    
    // MARK: - Currency Detection
    
    /// Detects the preferred currency based on the user's location
    func detectCurrencyFromLocation() -> CurrencyInfo? {
        // First try system locale
        if let localeCountryCode = Locale.current.regionCode {
            if let currency = Self.supportedCurrencies.first(where: { $0.countries.contains(localeCountryCode) }) {
                return currency
            }
        }
        
        // Fallback to system currency code if supported
        if let systemCurrencyCode = Locale.current.currencyCode,
           let currency = Self.supportedCurrencies.first(where: { $0.code == systemCurrencyCode }) {
            return currency
        }
        
        // Default to USD
        return Self.supportedCurrencies.first { $0.code == "USD" }
    }
    
    /// Gets currency info for a specific currency code
    func getCurrencyInfo(for code: String) -> CurrencyInfo? {
        return Self.supportedCurrencies.first { $0.code == code }
    }
    
    /// Formats a price with the given currency
    func formatPrice(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        // Use our custom symbols if available
        if let currencyInfo = getCurrencyInfo(for: currencyCode) {
            formatter.currencySymbol = currencyInfo.symbol
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(amount)"
    }
    
    /// Gets popular currencies for the region
    func getRegionalCurrencies() -> [CurrencyInfo] {
        guard let countryCode = Locale.current.regionCode else {
            return Array(Self.supportedCurrencies.prefix(10))
        }
        
        // Define regional groupings
        let asianCountries = ["PH", "SG", "MY", "TH", "ID", "VN", "JP", "KR", "CN", "IN", "HK", "TW"]
        let europeanCountries = ["GB", "DE", "FR", "IT", "ES", "CH", "NO", "SE", "DK", "PL", "CZ", "HU", "RO", "BG", "RU", "UA", "TR"]
        let americanCountries = ["US", "CA", "MX", "BR", "AR", "CL", "CO", "PE"]
        let middleEastAfricaCountries = ["SA", "AE", "IL", "ZA", "EG"]
        
        var regionalCurrencies: [String] = []
        
        if asianCountries.contains(countryCode) {
            regionalCurrencies = ["PHP", "SGD", "JPY", "KRW", "CNY", "INR", "THB", "MYR", "IDR", "HKD", "VND", "TWD", "USD", "EUR"]
        } else if europeanCountries.contains(countryCode) {
            regionalCurrencies = ["EUR", "GBP", "CHF", "NOK", "SEK", "DKK", "PLN", "CZK", "HUF", "RON", "BGN", "RUB", "TRY", "USD"]
        } else if americanCountries.contains(countryCode) {
            regionalCurrencies = ["USD", "CAD", "MXN", "BRL", "ARS", "CLP", "COP", "PEN", "EUR", "GBP"]
        } else if middleEastAfricaCountries.contains(countryCode) {
            regionalCurrencies = ["SAR", "AED", "ILS", "ZAR", "EGP", "USD", "EUR", "GBP"]
        } else {
            regionalCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "PHP", "SGD"]
        }
        
        // Return currencies in regional order
        var orderedCurrencies: [CurrencyInfo] = []
        for code in regionalCurrencies {
            if let currency = getCurrencyInfo(for: code) {
                orderedCurrencies.append(currency)
            }
        }
        
        // Add remaining currencies
        for currency in Self.supportedCurrencies {
            if !orderedCurrencies.contains(where: { $0.code == currency.code }) {
                orderedCurrencies.append(currency)
            }
        }
        
        return orderedCurrencies
    }
}