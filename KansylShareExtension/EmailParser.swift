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
            // Consider valid if we at least detected a service name.
            // The main app can infer a default 30-day end date when duration is missing.
            return serviceName != nil
        }
    }
    
    // MARK: - Known Service Patterns
    private let servicePatterns: [String: [String]] = [
        "Netflix": ["netflix", "netflix.com", "start your free trial", "netflix subscription"],
        "Spotify": ["spotify", "spotify.com", "spotify premium", "try premium free"],
        "Disney+": ["disney+", "disneyplus", "disney plus", "disneyplus.com"],
        "Amazon Prime": ["amazon prime", "prime membership", "prime video", "amazon.com/prime", "amazon.com"],
        "Apple TV+": ["apple tv+", "apple tv plus", "tv.apple.com", "apple.com"],
        "Hulu": ["hulu", "hulu.com", "start your free trial"],
        "HBO Max": ["hbo max", "hbomax", "hbomax.com"],
        "YouTube Premium": ["youtube premium", "youtube.com/premium", "youtube music", "youtube.com"],
        "Paramount+": ["paramount+", "paramountplus", "paramount plus"],
        "Peacock": ["peacock", "peacocktv", "peacocktv.com"],
        "Adobe": ["adobe", "adobe.com", "creative cloud"],
        "Microsoft 365": ["microsoft", "office", "office 365", "microsoft 365", "live.com", "office.com"],
        "Dropbox": ["dropbox", "dropbox.com"],
        "Google One": ["google one", "one.google.com", "storage plan", "google.com"],
        "Apple Music": ["apple music", "music.apple.com"],
        "iCloud": ["icloud", "icloud.com"]
    ]
    
    // MARK: - Date Patterns
    private let datePatterns = [
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd",
        "MMM dd, yyyy",
        "dd MMM yyyy",
        "MMMM dd, yyyy",
        "MM/dd/yy",
        "dd/MM/yy",
        "yyyy.MM.dd",
        "dd.MM.yyyy",
        "MMM d, yyyy",
        "d MMM yyyy",
        "MMMM d, yyyy",
        "yyyy-MM-dd'T'HH:mm:ss",
        "dd-MMM-yyyy"
    ]
    
    // MARK: - Main Parsing Function
    func parseEmail(_ emailContent: String) -> ParsedTrialData {
        var parsedData = ParsedTrialData()
        
        let lowercasedContent = emailContent.lowercased()
        
        // Extract service name
        parsedData.serviceName = extractServiceName(from: lowercasedContent)
        
        // Sanitize bogus service tokens (e.g., Gmail cache paths)
        if let s = parsedData.serviceName?.lowercased() {
            if ignoredServiceTokens.contains(s) || s.contains("attachment") || s.contains("cache") || s.contains("google") || s.contains("gmail") {
                parsedData.serviceName = nil
            }
        }
        
        // Extract trial duration
        parsedData.trialDuration = extractTrialDuration(from: lowercasedContent)
        
        // Extract dates - use original content for better date pattern matching
        let dates = extractDates(from: emailContent)
        parsedData.startDate = dates.start
        parsedData.endDate = dates.end
        
        // Log what we found for debugging
        print("📅 [EmailParser] Dates extracted - Start: \(parsedData.startDate?.description ?? "nil"), End: \(parsedData.endDate?.description ?? "nil")")
        
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
            print("📊 [EmailParser] Calculated duration from dates: \(days ?? 0) days")
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
        
        // Try to extract from invoice-like phrases
        if let company = extractFromInvoicePhrases(from: content) {
            return company
        }
        
        // Try to extract from common patterns
        if let match = extractUsingRegex(pattern: "(?:subscription|trial|membership|invoice|receipt) (?:to|for|with|from) ([A-Za-z0-9+\\s&.-]+)", 
                                         from: content) {
            return normalizeCompanyName(match)
        }
        
        // Try to infer from domains/emails/URLs
        if let domainName = extractServiceNameFromDomains(from: content) {
            return domainName
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
        
        // 1) Try to find ranges like "from <date> to <date>", "valid from <date> to <date>", "period <date> - <date>"
        let rangePatterns = [
            // Handle "Sep 29 - Oct 29, 2025" format (Warp invoice style)
            "([A-Za-z]{3}\\s+\\d{1,2})\\s*(?:-|–)\\s*([A-Za-z]{3}\\s+\\d{1,2},\\s+\\d{4})",
            // Also try with "Pro Plan" prefix
            "Pro Plan[\\s]*\\((?:per seats?\\))?[\\s]*([A-Za-z]{3}\\s+\\d{1,2})\\s*(?:-|–)\\s*([A-Za-z]{3}\\s+\\d{1,2},\\s+\\d{4})",
            "from\\s+([^\n,]+?)\\s+(?:to|until|through|thru|-|–)\\s+([^\n,]+)",
            "valid\\s+(?:from|between)\\s+([^\n,]+?)\\s+(?:to|until|through|thru|-|–)\\s+([^\n,]+)",
            "period\\s*:?\\s*([^\n,]+?)\\s*(?:-|–|to)\\s*([^\n,]+)",
            "([A-Za-z]{3,}\\s+\\d{1,2},\\s+\\d{4})\\s*(?:-|–|to)\\s*([A-Za-z]{3,}\\s+\\d{1,2},\\s+\\d{4})",
            "(\\d{1,2}/\\d{1,2}/\\d{2,4})\\s*(?:-|–|to)\\s*(\\d{1,2}/\\d{1,2}/\\d{2,4})",
            "billing\\s+period\\s*:?\\s*([^\n,]+?)\\s*(?:-|–|to)\\s*([^\n,]+)",
            "service\\s+period\\s*:?\\s*([^\n,]+?)\\s*(?:-|–|to)\\s*([^\n,]+)"
        ]
        for p in rangePatterns {
            if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: content.utf16.count)
                if let match = regex.firstMatch(in: content, options: [], range: range), match.numberOfRanges >= 3,
                   let r1 = Range(match.range(at: 1), in: content),
                   let r2 = Range(match.range(at: 2), in: content) {
                    var s1 = String(content[r1])
                    var s2 = String(content[r2])
                    
                    // Handle "Sep 29 - Oct 29, 2025" format where first date lacks year
                    if s1.range(of: "\\d{4}", options: .regularExpression) == nil && s2.range(of: "\\d{4}", options: .regularExpression) != nil {
                        // Extract year from second date
                        if let yearMatch = s2.range(of: "\\d{4}", options: .regularExpression) {
                            let year = String(s2[yearMatch])
                            s1 = s1 + ", " + year
                        }
                    }
                    
                    print("📆 [EmailParser] Trying to parse date range: '\(s1)' to '\(s2)'")
                    if let d1 = parseDate(from: s1), let d2 = parseDate(from: s2) {
                        startDate = d1
                        endDate = d2
                        print("✅ [EmailParser] Successfully parsed dates!")
                        return (startDate, endDate)
                    }
                }
            }
        }
        
        // 2) Look for explicit start/end labels
        let startPatterns = [
            "start(?:s|ing)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "begin(?:s|ning)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "effective[\\s]?(?:date|from)?[:\\s]?([^\\n,]+)",
            "invoice[\\s]?date[:\\s]?([^\\n,]+)",
            "date[\\s]?(?:of purchase|paid|:)[:\\s]?([^\\n,]+)",
            "billed[\\s]?on[:\\s]?([^\\n,]+)",
            "period\\s*start[:\\s]?([^\\n,]+)"
        ]
        
        let endPatterns = [
            "end(?:s|ing)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "expire(?:s)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "renew(?:s|al)?[\\s]?(?:date|on)?[:\\s]?([^\\n,]+)",
            "cancel[\\s]?(?:by|before)?[:\\s]?([^\\n,]+)",
            "next[\\s]?(?:billing|charge|renewal)[\\s]?date[:\\s]?([^\\n,]+)",
            "period\\s*end[:\\s]?([^\\n,]+)",
            "valid\\s*until[:\\s]?([^\\n,]+)",
            "until[:\\s]?([^\\n,]+)",
            "to[:\\s]?([^\\n,]+)"
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
        
        // If no explicit start date but we have end+price/duration indicators, assume today as start
        if startDate == nil && endDate != nil {
            startDate = Date()
        }
        
        return (startDate, endDate)
    }
    
    // MARK: - Price Extraction
    private func extractPrice(from content: String) -> (price: Double?, currency: String?) {
        // Prioritize totals/charges typical in receipts
        let labeledPatterns = [
            "total\\s*[:=]?\\s*[$€£¥]?\\s*([0-9]+[.,]?[0-9]*)",
            "amount\\s*(?:paid|charged)?\\s*[:=]?\\s*[$€£¥]?\\s*([0-9]+[.,]?[0-9]*)",
            "charged\\s*[$€£¥]\\s*([0-9]+[.,]?[0-9]*)",
            "billed\\s*[$€£¥]\\s*([0-9]+[.,]?[0-9]*)"
        ]
        for p in labeledPatterns {
            if let match = extractUsingRegex(pattern: p, from: content), let price = Double(match.replacingOccurrences(of: ",", with: ".")) {
                return (price, inferCurrency(from: content))
            }
        }
        
        // Fallback: any currency symbol + amount
        let pricePatterns = [
            "\\$([0-9]+[.,]?[0-9]*)",
            "€([0-9]+[.,]?[0-9]*)",
            "£([0-9]+[.,]?[0-9]*)",
            "¥([0-9]+[.,]?[0-9]*)",
            "([0-9]+[.,]?[0-9]*)\\s?(?:USD|EUR|GBP|JPY)"
        ]
        for pattern in pricePatterns {
            if let match = extractUsingRegex(pattern: pattern, from: content) {
                let normalized = match.replacingOccurrences(of: ",", with: ".")
                if let price = Double(normalized) {
                    return (price, inferCurrency(from: content))
                }
            }
        }
        return (nil, nil)
    }
    
    private func inferCurrency(from content: String) -> String {
        if content.contains("€") || content.range(of: "EUR", options: .caseInsensitive) != nil { return "EUR" }
        if content.contains("£") || content.range(of: "GBP", options: .caseInsensitive) != nil { return "GBP" }
        if content.contains("¥") || content.range(of: "JPY", options: .caseInsensitive) != nil { return "JPY" }
        if content.range(of: "USD", options: .caseInsensitive) != nil { return "USD" }
        return "USD"
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
    private let genericEmailHosts: Set<String> = [
        "gmail", "googlemail", "yahoo", "outlook", "hotmail", "live", "icloud", "me", "proton", "zoho", "aol"
    ]
    
    private func normalizeCompanyName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().contains("disney plus") { return "Disney+" }
        return trimmed.capitalized
    }
    
    private func extractFromInvoicePhrases(from content: String) -> String? {
        let patterns = [
            "invoice from ([A-Za-z0-9 &+.-]{2,})",
            "receipt from ([A-Za-z0-9 &+.-]{2,})",
            "invoice for ([A-Za-z0-9 &+.-]{2,})",
            "from ([A-Za-z0-9 &+.-]{2,}) invoice"
        ]
        for p in patterns {
            if let company = extractUsingRegex(pattern: p, from: content) { return normalizeCompanyName(company) }
        }
        return nil
    }
    
    private let ignoredServiceTokens: Set<String> = [
        "attachment", "attachments", "cache", "gbattachmentcache", "attachmentcache",
        "file", "files", "document", "documents", "pdf", "content", "localhost",
        "google", "gmail", "googleusercontent", "gstatic", "drive"
    ]
    
    private func extractServiceNameFromDomains(from content: String) -> String? {
        var domains = [String]()
        // Emails
        if let regex = try? NSRegularExpression(pattern: "[A-Z0-9._%+-]+@([A-Za-z0-9.-]+)\\.[A-Za-z]{2,}", options: .caseInsensitive) {
            let matches = regex.matches(in: content, range: NSRange(location: 0, length: content.utf16.count))
            for m in matches {
                if m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: content) {
                    domains.append(String(content[r]))
                }
            }
        }
        // URLs
        if let regex2 = try? NSRegularExpression(pattern: "(?:https?:\\/\\/)?(?:www\\.)?([A-Za-z0-9.-]+)\\.[A-Za-z]{2,}", options: .caseInsensitive) {
            let matches = regex2.matches(in: content, range: NSRange(location: 0, length: content.utf16.count))
            for m in matches {
                if m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: content) {
                    domains.append(String(content[r]))
                }
            }
        }
        
        for raw in domains {
            let base = baseDomain(from: raw)
            if base.isEmpty { continue }
            if genericEmailHosts.contains(base) { continue }
            if ignoredServiceTokens.contains(base) { continue }
            if let mapped = domainToServiceName(base) { return mapped }
            // Avoid returning obviously noisy tokens
            if base.count < 3 { continue }
            return base.capitalized
        }
        return nil
    }
    
    private func baseDomain(from domain: String) -> String {
        let parts = domain.lowercased().split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return parts.first ?? "" }
        let last = parts.last ?? ""
        let secondLast = parts.dropLast().last ?? ""
        if secondLast == "co" && last == "uk" && parts.count >= 3 {
            return parts.dropLast(2).last ?? ""
        }
        return secondLast
    }
    
    private func domainToServiceName(_ base: String) -> String? {
        // Map common vendor bases to service names
        let map: [String: String] = [
            "netflix": "Netflix",
            "spotify": "Spotify",
            "disneyplus": "Disney+",
            "disney": "Disney+",
            "amazon": "Amazon Prime",
            "adobe": "Adobe",
            "microsoft": "Microsoft 365",
            "office": "Microsoft 365",
            "dropbox": "Dropbox",
            "youtube": "YouTube Premium",
            "icloud": "iCloud",
            "apple": "Apple",
            "hulu": "Hulu",
            "hbomax": "HBO Max",
            "paramountplus": "Paramount+",
            "peacocktv": "Peacock",
            "peacock": "Peacock"
        ]
        if let v = map[base] { return v }
        return nil
    }
    
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
