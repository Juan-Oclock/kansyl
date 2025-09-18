//
//  ReceiptScanner.swift
//  kansyl
//
//  AI-powered receipt scanning for automatic subscription detection
//

import Foundation
import Vision
import UIKit
import Combine

class ReceiptScanner: ObservableObject {
    
    // MARK: - Parsed Receipt Data
    struct ParsedReceiptData {
        var serviceName: String?
        var merchantName: String?
        var amount: Double?
        var originalAmount: Double? // Original amount before conversion
        var currency: String?
        var originalCurrency: String? // Original currency before conversion
        var date: Date?
        var receiptNumber: String?
        var subscriptionType: String? // monthly, yearly, etc.
        var nextBillingDate: Date?
        var isSubscription: Bool = false
        var confidence: Float = 0.0
        
        var isValid: Bool {
            return serviceName != nil && amount != nil && isSubscription
        }
    }
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastScanResult: ParsedReceiptData?
    @Published var errorMessage: String?
    
    private let aiAnalysisService = AIAnalysisService()
    
    // MARK: - Main Scanning Function
    func scanReceipt(from image: UIImage) async -> ParsedReceiptData? {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        do {
            // Step 1: Extract text using Vision OCR
            let extractedText = try await extractTextFromImage(image)
            
            // Step 2: Analyze with AI to identify subscription information
            let parsedData = try await aiAnalysisService.analyzeReceiptText(extractedText)
            
            DispatchQueue.main.async {
                self.lastScanResult = parsedData
            }
            
            return parsedData
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to scan receipt: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - OCR Text Extraction
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: ReceiptScannerError.invalidImage)
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ReceiptScannerError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure for better receipt text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Convenience Methods
    func scanReceiptFromCamera() async -> ParsedReceiptData? {
        // This would trigger camera capture UI
        // Implementation depends on your camera handling
        return nil
    }
    
    func scanReceiptFromPhotoLibrary() async -> ParsedReceiptData? {
        // This would trigger photo library picker
        // Implementation depends on your photo picker handling
        return nil
    }
}

// MARK: - AI Analysis Service
class AIAnalysisService {
    private let configManager = AIConfigManager.shared
    
    func analyzeReceiptText(_ text: String) async throws -> ReceiptScanner.ParsedReceiptData {
        guard configManager.isAIEnabled else {
            throw ReceiptScannerError.apiError
        }
        
        guard configManager.canMakeAPICall() else {
            throw ReceiptScannerError.rateLimited
        }
        
        let prompt = """
        Analyze this receipt text and extract subscription service information. 
        Return the information in the following JSON format:
        
        {
            "serviceName": "exact service name if this is a subscription",
            "merchantName": "merchant or company name",
            "amount": "numeric amount only",
            "currency": "currency code (USD, EUR, etc.)",
            "date": "transaction date in YYYY-MM-DD format",
            "receiptNumber": "receipt or transaction number",
            "subscriptionType": "monthly/yearly/weekly or null",
            "isSubscription": "true if this appears to be a subscription service",
            "confidence": "confidence score between 0.0 and 1.0"
        }
        
        Only return valid JSON. If you can't identify a subscription service, set isSubscription to false.
        Look for keywords like: subscription, monthly, yearly, renewal, auto-renew, trial, premium, plus, pro.
        Common subscription services include: Netflix, Spotify, Disney+, Hulu, Apple, Google, Microsoft, Adobe, etc.
        
        Receipt text:
        \(text)
        """
        
        // Make API call to OpenAI or similar service
        let parsedData = try await makeAIRequest(prompt: prompt)
        configManager.recordAPICall()
        configManager.recordAIScan() // Track usage in production
        return parsedData
    }
    
    private func makeAIRequest(prompt: String) async throws -> ReceiptScanner.ParsedReceiptData {
        guard let apiKey = configManager.deepSeekAPIKey else {
            throw ReceiptScannerError.apiKeyMissing
        }
        
        // Check usage limits in production
        guard configManager.canMakeAIScan else {
            throw ReceiptScannerError.usageLimitExceeded
        }
        
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.1,
            "max_tokens": 500
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ReceiptScannerError.apiError
        }
        
        // Parse DeepSeek response and extract the JSON content
        guard let aiResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse API response as JSON")
            print("📦 Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw ReceiptScannerError.invalidAPIResponse
        }
        
        guard let choices = aiResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ Failed to extract content from API response")
            print("📦 Response structure: \(aiResponse)")
            throw ReceiptScannerError.invalidAPIResponse
        }
        
        print("📤 AI Response content: \(content.prefix(200))...")
        
        // Clean the content - remove markdown code blocks if present
        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse the AI-generated JSON
        guard let contentData = cleanedContent.data(using: .utf8) else {
            print("❌ Failed to convert content to data")
            throw ReceiptScannerError.invalidJSONResponse
        }
        
        do {
            guard let parsedJSON = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
                print("❌ Parsed JSON is not a dictionary")
                throw ReceiptScannerError.invalidJSONResponse
            }
            print("✅ Successfully parsed AI response JSON")
            var receiptData = try parseReceiptDataFromJSON(parsedJSON)
            
            // Convert currency if needed
            let userCurrency = AppPreferences.shared.currencyCode
            if let originalCurrency = receiptData.originalCurrency,
               let originalAmount = receiptData.amount,
               originalCurrency != userCurrency {
                print("💱 Currency conversion needed: \(originalCurrency) → \(userCurrency)")
                
                if let convertedAmount = await CurrencyConversionService.shared.convert(
                    amount: originalAmount,
                    from: originalCurrency,
                    to: userCurrency
                ) {
                    receiptData.amount = convertedAmount
                    receiptData.currency = userCurrency
                    print("✅ Converted: \(originalAmount) \(originalCurrency) = \(String(format: "%.2f", convertedAmount)) \(userCurrency)")
                } else {
                    print("⚠️ Conversion failed, using original amount")
                }
            }
            
            return receiptData
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📦 Content that failed to parse: \(cleanedContent)")
            throw ReceiptScannerError.invalidJSONResponse
        }
    }
    
    private func parseReceiptDataFromJSON(_ json: [String: Any]) throws -> ReceiptScanner.ParsedReceiptData {
        print("🔍 Parsing receipt data from JSON")
        print("📦 JSON keys: \(json.keys.joined(separator: ", "))")
        
        var data = ReceiptScanner.ParsedReceiptData()
        
        // Handle both nested and flat JSON structures from DeepSeek
        let receiptData: [String: Any]
        if let nestedData = json["receipt_data"] as? [String: Any] {
            receiptData = nestedData
        } else {
            receiptData = json
        }
        
        // Try multiple key variations for each field (handle different response formats)
        data.serviceName = (receiptData["serviceName"] as? String) ??
                          (receiptData["service_name"] as? String) ??
                          (receiptData["name"] as? String)
        
        data.merchantName = (receiptData["merchantName"] as? String) ??
                           (receiptData["merchant_name"] as? String) ??
                           (receiptData["merchant"] as? String)
        
        // Handle amount parsing with string or number formats
        if let amountString = receiptData["amount"] as? String {
            // Remove currency symbols and commas
            let cleanAmount = amountString
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            data.amount = Double(cleanAmount)
        } else if let amountNumber = receiptData["amount"] as? Double {
            data.amount = amountNumber
        } else if let amountInt = receiptData["amount"] as? Int {
            data.amount = Double(amountInt)
        }
        
        // Parse currency
        data.originalCurrency = (receiptData["currency"] as? String) ?? "USD"
        data.currency = data.originalCurrency
        data.originalAmount = data.amount
        data.receiptNumber = (receiptData["receiptNumber"] as? String) ??
                            (receiptData["receipt_number"] as? String)
        
        data.subscriptionType = (receiptData["subscriptionType"] as? String) ??
                               (receiptData["subscription_type"] as? String) ??
                               (receiptData["billing_cycle"] as? String)
        
        data.isSubscription = (receiptData["isSubscription"] as? Bool) ??
                             (receiptData["is_subscription"] as? Bool) ?? false
        
        data.confidence = (receiptData["confidence"] as? Float) ?? 0.0
        
        print("  ✅ Parsed: \(data.serviceName ?? "Unknown") - $\(data.amount ?? 0)")
        
        // Parse date - try multiple formats and key variations
        var dateString: String?
        dateString = (receiptData["date"] as? String) ??
                    (receiptData["receipt_date"] as? String) ??
                    (receiptData["transaction_date"] as? String) ??
                    (receiptData["purchase_date"] as? String)
        
        if let dateStr = dateString {
            print("  📅 Parsing date string: \(dateStr)")
            data.date = parseDate(from: dateStr)
            if data.date != nil {
                print("  ✅ Successfully parsed date: \(DateFormatter.localizedString(from: data.date!, dateStyle: .medium, timeStyle: .none))")
            } else {
                print("  ⚠️ Could not parse date, using today's date")
            }
        }
        
        // Calculate next billing date based on subscription type
        if let subscriptionType = data.subscriptionType,
           let startDate = data.date {
            switch subscriptionType.lowercased() {
            case "monthly":
                data.nextBillingDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
            case "yearly":
                data.nextBillingDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)
            case "weekly":
                data.nextBillingDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)
            default:
                data.nextBillingDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
            }
        }
        
        return data
    }
    
    // Helper function to parse dates from various formats
    private func parseDate(from dateString: String) -> Date? {
        let dateFormatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "MMM dd, yyyy",
            "MMMM dd, yyyy",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "MMM d, yyyy",
            "MMMM d, yyyy",
            "Jul 31, 2025", // Specific format from your example
            "d MMM yyyy",
            "dd MMM yyyy"
        ]
        
        for format in dateFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Try with natural language date parsing
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}

// MARK: - Error Types
enum ReceiptScannerError: LocalizedError {
    case invalidImage
    case noTextFound
    case apiError
    case apiKeyMissing
    case rateLimited
    case usageLimitExceeded
    case invalidAPIResponse
    case invalidJSONResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image"
        case .noTextFound:
            return "No text found in the image"
        case .apiError:
            return "AI service unavailable"
        case .apiKeyMissing:
            if ProductionAIConfig.isProduction {
                return "AI service temporarily unavailable. Please try again later."
            } else {
                return "AI service not configured. Please add your DeepSeek API key in settings."
            }
        case .rateLimited:
            return "AI service rate limited. Please try again in a moment."
        case .usageLimitExceeded:
            return "AI scan limit reached. Please contact support for assistance."
        case .invalidAPIResponse:
            return "Invalid response from AI service"
        case .invalidJSONResponse:
            return "Could not parse AI response"
        }
    }
}

// MARK: - Receipt Scanner Extensions
extension ReceiptScanner {
    
    // Try to match with existing service templates using enhanced AI matching
    func matchWithServiceTemplate(_ parsedData: ParsedReceiptData) -> (template: ServiceTemplateData?, confidence: Float) {
        guard let serviceName = parsedData.serviceName else { return (nil, 0.0) }
        
        let serviceManager = ServiceTemplateManager.shared
        
        // Use the enhanced AI matching capabilities
        let result = serviceManager.validateAndEnhance(
            serviceName: serviceName,
            amount: parsedData.amount
        )
        
        return result
    }
    
    // Convert parsed receipt data to subscription
    func createSubscriptionFromReceipt(_ parsedData: ParsedReceiptData, 
                                     subscriptionStore: SubscriptionStore) -> Subscription? {
        guard parsedData.isValid else {
            print("❌ Receipt data is not valid, cannot create subscription")
            return nil
        }
        
        print("📦 Creating subscription from receipt data:")
        print("  Service: \(parsedData.serviceName ?? "Unknown")")
        print("  Amount: \(parsedData.amount ?? 0)")
        print("  Type: \(parsedData.subscriptionType ?? "Unknown")")
        print("  Date from receipt: \(parsedData.date != nil ? DateFormatter.localizedString(from: parsedData.date!, dateStyle: .medium, timeStyle: .none) : "Not found")")
        
        let serviceName = parsedData.serviceName ?? "Unknown Service"
        // Use the date from the receipt if available, otherwise use today
        let startDate = parsedData.date ?? Date()
        let amount = parsedData.amount ?? 0.0
        var subscriptionLength = 30 // Default to monthly
        var billingPeriodDescription = "Monthly"
        
        // Determine subscription length based on type (keep original price, don't convert)
        if let subscriptionType = parsedData.subscriptionType {
            switch subscriptionType.lowercased() {
            case "yearly", "annual":
                subscriptionLength = 365
                billingPeriodDescription = "Yearly"
            case "quarterly":
                subscriptionLength = 90 // 3 months
                billingPeriodDescription = "Quarterly"
            case "weekly":
                subscriptionLength = 7
                billingPeriodDescription = "Weekly"
            case "monthly":
                subscriptionLength = 30
                billingPeriodDescription = "Monthly"
            case "semi-annual", "biannual":
                subscriptionLength = 180 // 6 months
                billingPeriodDescription = "Semi-Annual"
            default:
                subscriptionLength = 30
                billingPeriodDescription = "Monthly"
            }
        }
        
        print("💵 Using original price: $\(amount) per \(billingPeriodDescription.lowercased())")
        print("📅 Subscription period: \(subscriptionLength) days")
        print("📆 Start date: \(DateFormatter.localizedString(from: startDate, dateStyle: .medium, timeStyle: .none))")
        
        let endDate = Calendar.current.date(byAdding: .day, value: subscriptionLength, to: startDate) ?? startDate
        
        // Try to find matching service template for logo and enhanced data
        var logoName = "receipt"
        let matchResult = matchWithServiceTemplate(parsedData)
        
        if let template = matchResult.template, matchResult.confidence > 0.5 {
            logoName = template.logoName
            print("🎯 Matched with template (confidence: \(matchResult.confidence))")
        }
        
        print("🔄 Adding subscription to store...")
        print("  Name: \(serviceName)")
        print("  Price: $\(amount) per \(billingPeriodDescription.lowercased())")
        print("  Start Date: \(DateFormatter.localizedString(from: startDate, dateStyle: .medium, timeStyle: .none))")
        print("  End Date: \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .none))")
        print("  Logo: \(logoName)")
        
        // Calculate monthly price for storage (SubscriptionStore expects monthly price)
        var monthlyPrice = amount
        switch subscriptionLength {
        case 365: // Yearly
            monthlyPrice = amount / 12
        case 180: // Semi-annual
            monthlyPrice = amount / 6
        case 90: // Quarterly
            monthlyPrice = amount / 3
        case 7: // Weekly
            monthlyPrice = amount * 4.33
        default: // Monthly or default
            monthlyPrice = amount
        }
        
        print("📊 Calculated monthly price for storage: $\(String(format: "%.2f", monthlyPrice))")
        
        // Create notes with currency conversion info if applicable
        var notes = "Added from receipt scan. \(billingPeriodDescription) billing: \(parsedData.currency ?? "USD") \(String(format: "%.2f", amount)) every \(subscriptionLength) days."
        
        if let originalAmount = parsedData.originalAmount,
           let originalCurrency = parsedData.originalCurrency,
           originalCurrency != parsedData.currency {
            notes += " Original: \(originalCurrency) \(String(format: "%.2f", originalAmount))."
        }
        
        notes += " Receipt date: \(DateFormatter.localizedString(from: parsedData.date ?? Date(), dateStyle: .short, timeStyle: .none))"
        
        // Calculate exchange rate if conversion occurred
        var exchangeRate: Double? = nil
        if let origAmount = parsedData.originalAmount,
           let origCurrency = parsedData.originalCurrency,
           origAmount > 0 && origCurrency != parsedData.currency {
            exchangeRate = amount / origAmount
            print("📊 Exchange rate used: 1 \(origCurrency) = \(String(format: "%.4f", exchangeRate ?? 0)) \(parsedData.currency ?? "")")
        }
        
        let subscription = subscriptionStore.addSubscription(
            name: serviceName,
            startDate: startDate,
            endDate: endDate,
            monthlyPrice: monthlyPrice,
            serviceLogo: logoName,
            notes: notes,
            addToCalendar: false,
            billingCycle: billingPeriodDescription.lowercased(),
            billingAmount: amount,
            originalCurrency: parsedData.originalCurrency,
            originalAmount: parsedData.originalAmount,
            exchangeRate: exchangeRate
        )
        
        if let subscription = subscription {
            print("✅ Successfully created subscription with ID: \(subscription.id?.uuidString ?? "unknown")")
        } else {
            print("❌ Failed to create subscription - user not logged in")
        }
        
        return subscription
    }
}