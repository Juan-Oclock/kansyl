//
//  EmailParser.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation

class EmailParser {
    
    // MARK: - Parsed Trial Data
    struct ParsedTrialData {
        var serviceName: String?
        var trialDuration: Int? // in days
        var startDate: Date?
        var endDate: Date?
        var price: Double?
        var currency: String?
        var confirmationNumber: String?
        var emailAddress: String?
        
        var isValid: Bool {
            return serviceName != nil && (trialDuration != nil || endDate != nil)
        }
    }
    
    // MARK: - Known Service Patterns
    private let servicePatterns: [String: [String]] = [
        "Netflix": ["netflix", "netflix.com", "start your free trial", "netflix subscription"],
        "Spotify": ["spotify", "spotify.com", "spotify premium", "try premium free"],
        "Disney+": ["disney+", "disneyplus", "disney plus", "disneyplus.com"],
        "Amazon Prime": ["amazon prime", "prime membership", "prime video", "amazon.com/prime"],
        "Apple TV+": ["apple tv+", "apple tv plus", "tv.apple.com"],
        "Hulu": ["hulu", "hulu.com", "start your free trial"],
        "HBO Max": ["hbo max", "hbomax", "hbomax.com"],
        "YouTube Premium": ["youtube premium", "youtube.com/premium", "youtube music"],
        "Paramount+": ["paramount+", "paramountplus", "paramount plus"],
        "Peacock": ["peacock", "peacocktv", "peacocktv.com"]
    ]
    
    // MARK: - Date Patterns
    private let datePatterns = [
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd",
        "MMM dd, yyyy",
        "dd MMM yyyy",
        "MMMM dd, yyyy"
    ]
    
    // MARK: - Main Parsing Function
    func parseEmail(_ emailContent: String) -> ParsedTrialData {
        var parsedData = ParsedTrialData()
        
        let lowercasedContent = emailContent.lowercased()
        
        // Extract service name
        parsedData.serviceName = extractServiceName(from: lowercasedContent)
        
        // Extract trial duration
        parsedData.trialDuration = extractTrialDuration(from: lowercasedContent)
        
        // Extract dates
        let dates = extractDates(from: emailContent)
        parsedData.startDate = dates.start
        parsedData.endDate = dates.end
        
        // Extract price
        let priceInfo = extractPrice(from: emailContent)
        parsedData.price = priceInfo.price
        parsedData.currency = priceInfo.currency
        
        // Extract confirmation number
        parsedData.confirmationNumber = extractConfirmationNumber(from: emailContent)
        
        // Extract email address
        parsedData.emailAddress = extractEmailAddress(from: emailContent)
        
        // If we couldn't get duration but have dates, calculate it
        if parsedData.trialDuration == nil,
           let start = parsedData.startDate,
           let end = parsedData.endDate {
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day
            parsedData.trialDuration = days
        }
        
        return parsedData
    }
    
    // MARK: - Service Name Extraction
    private func extractServiceName(from content: String) -> String? {
        for (service, patterns) in servicePatterns {
            for pattern in patterns {
                if content.contains(pattern) {
                    return service
                }
            }
        }
        
        // Try to extract from common patterns
        if let match = extractUsingRegex(pattern: "(?:subscription|trial|membership) (?:to|for|with) ([A-Za-z0-9+\\s]+)", 
                                         from: content) {
            return match.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    // MARK: - Trial Duration Extraction
    private func extractTrialDuration(from content: String) -> Int? {
        // Common patterns for trial duration
        let patterns = [
            "(\\d+)[\\s-]?day(?:s)?[\\s]?(?:free)?[\\s]?trial",
            "trial[\\s]?(?:period)?[:\\s]?(\\d+)[\\s]?day",
            "(\\d+)[\\s]?month(?:s)?[\\s]?(?:free)?[\\s]?trial",
            "free[\\s]?(?:for)?[\\s]?(\\d+)[\\s]?day",
            "try[\\s]?(?:for)?[\\s]?(\\d+)[\\s]?day"
        ]
        
        for pattern in patterns {
            if let match = extractUsingRegex(pattern: pattern, from: content),
               let days = Int(match) {
                // Check if it's months and convert to days
                if content.contains("month") && match == match {
                    return days * 30
                }
                return days
            }
        }
        
        // Check for common durations
        if content.contains("7 day") || content.contains("seven day") || content.contains("week") {
            return 7
        } else if content.contains("14 day") || content.contains("fourteen day") || content.contains("two week") {
            return 14
        } else if content.contains("30 day") || content.contains("thirty day") || content.contains("one month") {
            return 30
        } else if content.contains("60 day") || content.contains("sixty day") || content.contains("two month") {
            return 60
        } else if content.contains("90 day") || content.contains("ninety day") || content.contains("three month") {
            return 90
        }
        
        return nil
    }
    
    // MARK: - Date Extraction
    private func extractDates(from content: String) -> (start: Date?, end: Date?) {
        var startDate: Date?
        var endDate: Date?
        
        // Look for explicit start/end dates
        let startPatterns = [
            "start(?:s|ing)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "begin(?:s|ning)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "effective[\\s]?(?:date|from)?[:\\s]?([^\\n,]+)"
        ]
        
        let endPatterns = [
            "end(?:s|ing)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "expire(?:s)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "renew(?:s|al)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "cancel[\\s]?(?:by|before)?[:\\s]?([^\\n,]+)"
        ]
        
        // Try to find start date
        for pattern in startPatterns {
            if let dateString = extractUsingRegex(pattern: pattern, from: content),
               let date = parseDate(from: dateString) {
                startDate = date
                break
            }
        }
        
        // Try to find end date
        for pattern in endPatterns {
            if let dateString = extractUsingRegex(pattern: pattern, from: content),
               let date = parseDate(from: dateString) {
                endDate = date
                break
            }
        }
        
        // If no explicit start date, assume today
        if startDate == nil && endDate != nil {
            startDate = Date()
        }
        
        return (startDate, endDate)
    }
    
    // MARK: - Price Extraction
    private func extractPrice(from content: String) -> (price: Double?, currency: String?) {
        let pricePatterns = [
            "\\$([0-9]+\\.?[0-9]*)",
            "€([0-9]+\\.?[0-9]*)",
            "£([0-9]+\\.?[0-9]*)",
            "¥([0-9]+\\.?[0-9]*)",
            "([0-9]+\\.?[0-9]*)\\s?(?:USD|EUR|GBP|JPY)"
        ]
        
        for pattern in pricePatterns {
            if let match = extractUsingRegex(pattern: pattern, from: content),
               let price = Double(match.replacingOccurrences(of: ",", with: "")) {
                
                // Determine currency
                var currency = "USD" // Default
                if content.contains("€") || content.contains("EUR") {
                    currency = "EUR"
                } else if content.contains("£") || content.contains("GBP") {
                    currency = "GBP"
                } else if content.contains("¥") || content.contains("JPY") {
                    currency = "JPY"
                }
                
                return (price, currency)
            }
        }
        
        return (nil, nil)
    }
    
    // MARK: - Confirmation Number Extraction
    private func extractConfirmationNumber(from content: String) -> String? {
        let patterns = [
            "confirmation[\\s]?(?:#|number|code)?[:\\s]?([A-Z0-9-]+)",
            "order[\\s]?(?:#|number|id)?[:\\s]?([A-Z0-9-]+)",
            "reference[\\s]?(?:#|number|code)?[:\\s]?([A-Z0-9-]+)",
            "transaction[\\s]?(?:#|id)?[:\\s]?([A-Z0-9-]+)"
        ]
        
        for pattern in patterns {
            if let match = extractUsingRegex(pattern: pattern, from: content.uppercased()) {
                return match
            }
        }
        
        return nil
    }
    
    // MARK: - Email Address Extraction
    private func extractEmailAddress(from content: String) -> String? {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return extractUsingRegex(pattern: emailPattern, from: content)
    }
    
    // MARK: - Helper Methods
    private func extractUsingRegex(pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: text) {
                    return String(text[swiftRange])
                }
            }
        } catch {
            // Debug: print("Regex error: \(error)")
        }
        
        return nil
    }
    
    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        
        for pattern in datePatterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        
        // Try natural language parsing
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.date(from: dateString)
    }
}

// MARK: - Email Parser Extension for Common Templates
extension EmailParser {
    
    func parseFromURL(_ url: URL) -> ParsedTrialData? {
        // Extract service from URL domain
        let host = url.host?.lowercased() ?? ""
        var parsedData = ParsedTrialData()
        
        for (service, patterns) in servicePatterns {
            for pattern in patterns {
                if host.contains(pattern.replacingOccurrences(of: ".com", with: "")) {
                    parsedData.serviceName = service
                    break
                }
            }
        }
        
        // Extract from URL parameters if available
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                switch item.name.lowercased() {
                case "trial", "trial_days", "trial_period":
                    if let value = item.value, let days = Int(value) {
                        parsedData.trialDuration = days
                    }
                case "price", "amount":
                    if let value = item.value, let price = Double(value) {
                        parsedData.price = price
                    }
                case "email", "user_email":
                    parsedData.emailAddress = item.value
                default:
                    break
                }
            }
        }
        
        return parsedData.isValid ? parsedData : nil
    }
}
