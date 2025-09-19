//
//  CurrencyConversionService.swift
//  kansyl
//
//  Handles currency conversion with real-time exchange rates
//

import Foundation

class CurrencyConversionService {
    static let shared = CurrencyConversionService()
    
    // Cache for exchange rates
    private var exchangeRates: [String: Double] = [:]
    private var lastUpdateDate: Date?
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    // Fallback exchange rates (as of late 2024, update periodically)
    private let fallbackRates: [String: Double] = [
        "USD": 1.0,
        "PHP": 56.50,  // 1 USD = ~56.50 PHP
        "EUR": 0.85,
        "GBP": 0.73,
        "JPY": 110.0,
        "SGD": 1.35,
        "CAD": 1.25,
        "AUD": 1.50,
        "CNY": 6.90,
        "INR": 83.0,
        "KRW": 1300.0,
        "HKD": 7.80,
        "MYR": 4.50,
        "THB": 35.0,
        "IDR": 15400.0
    ]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Convert amount from one currency to another
    func convert(amount: Double, from fromCurrency: String, to toCurrency: String) async -> Double? {
        // If same currency, no conversion needed
        if fromCurrency == toCurrency {
            return amount
        }
        
        // Get exchange rates
        let rates = await getExchangeRates()
        
        // Get rate for source currency (to USD)
        let fromRate = rates[fromCurrency] ?? fallbackRates[fromCurrency] ?? 1.0
        
        // Get rate for target currency (from USD)
        let toRate = rates[toCurrency] ?? fallbackRates[toCurrency] ?? 1.0
        
        // Convert: amount / fromRate * toRate
        // This converts to USD first, then to target currency
        let convertedAmount = (amount / fromRate) * toRate
        
        // Debug: // Debug: print("💱 Currency conversion: \(amount) \(fromCurrency) = \(String(format: "%.2f", convertedAmount)) \(toCurrency)")
        // Debug: // Debug: print("   Exchange rates: 1 USD = \(fromRate) \(fromCurrency), 1 USD = \(toRate) \(toCurrency)")
        
        return convertedAmount
    }
    
    /// Get current exchange rate between two currencies
    func getExchangeRate(from fromCurrency: String, to toCurrency: String) async -> Double? {
        if fromCurrency == toCurrency {
            return 1.0
        }
        
        let rates = await getExchangeRates()
        let fromRate = rates[fromCurrency] ?? fallbackRates[fromCurrency] ?? 1.0
        let toRate = rates[toCurrency] ?? fallbackRates[toCurrency] ?? 1.0
        
        return toRate / fromRate
    }
    
    // MARK: - Private Methods
    
    private func getExchangeRates() async -> [String: Double] {
        // Check if cache is still valid
        if let lastUpdate = lastUpdateDate,
           Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval,
           !exchangeRates.isEmpty {
            return exchangeRates
        }
        
        // Try to fetch fresh rates
        if let freshRates = await fetchLatestExchangeRates() {
            exchangeRates = freshRates
            lastUpdateDate = Date()
            return freshRates
        }
        
        // Fall back to hardcoded rates
        return fallbackRates
    }
    
    private func fetchLatestExchangeRates() async -> [String: Double]? {
        // Using a free exchange rate API (exchangerate-api.com)
        // You can get a free API key from https://app.exchangerate-api.com/dashboard
        // For now, we'll use the free tier without API key which has limited requests
        
        let urlString = "https://api.exchangerate-api.com/v4/latest/USD"
        
        guard let url = URL(string: urlString) else {
            // Debug: // Debug: print("⚠️ Invalid exchange rate API URL")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Debug: // Debug: print("⚠️ Exchange rate API returned error")
                return nil
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Double] {
                // Debug: // Debug: print("✅ Fetched fresh exchange rates for \(rates.count) currencies")
                return rates
            }
        } catch {
            // Debug: // Debug: print("⚠️ Failed to fetch exchange rates: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Format amount with currency symbol
    func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        // Use custom symbols from CurrencyManager
        if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: currency) {
            formatter.currencySymbol = currencyInfo.symbol
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
    }
    
    /// Detect currency from text (e.g., "$45", "USD 45", "₱100")
    func detectCurrency(from text: String) -> String? {
        // Common currency symbols and their codes
        let symbolMap: [String: String] = [
            "$": "USD",
            "₱": "PHP",
            "€": "EUR",
            "£": "GBP",
            "¥": "JPY",
            "₹": "INR",
            "₩": "KRW",
            "C$": "CAD",
            "A$": "AUD",
            "S$": "SGD",
            "HK$": "HKD",
            "R$": "BRL",
            "₺": "TRY",
            "₽": "RUB"
        ]
        
        // Check for currency symbols
        for (symbol, code) in symbolMap {
            if text.contains(symbol) {
                return code
            }
        }
        
        // Check for currency codes (e.g., "USD", "PHP")
        let currencyCodes = ["USD", "PHP", "EUR", "GBP", "JPY", "CAD", "AUD", "SGD", "CNY", "INR", "KRW", "HKD"]
        for code in currencyCodes {
            if text.uppercased().contains(code) {
                return code
            }
        }
        
        // Default to nil if no currency detected
        return nil
    }
}

// MARK: - Exchange Rate Response Models
private struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}