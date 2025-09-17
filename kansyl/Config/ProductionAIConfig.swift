//
//  ProductionAIConfig.swift
//  kansyl
//
//  Production AI Configuration - SECURE EMBEDDED API KEY
//
//  IMPORTANT: This is for production use where the app provides AI services
//  Users do not need to configure API keys
//

import Foundation

struct ProductionAIConfig {
    
    // MARK: - Production Configuration
    static let isProduction = true
    static let enableLogging = false // Disable logs in production
    
    // MARK: - DeepSeek API Configuration 
    // 🔒 LOAD API KEY FROM CONFIG.PLIST
    // This key will be used for all users' receipt scanning
    static let deepSeekAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["DeepSeekAPIKey"] as? String else {
            print("⚠️ ProductionAIConfig: Could not load API key from Config.plist")
            return ""
        }
        return apiKey
    }()
    
    // MARK: - Usage Limits (Optional but Recommended)
    static let maxScansPerDay = 50  // Limit to prevent abuse
    static let maxScansPerUser = 200 // Per user lifetime limit
    
    // MARK: - API Endpoints
    static let deepSeekBaseURL = "https://api.deepseek.com/v1"
    static let deepSeekModel = "deepseek-chat"
    
    // MARK: - Validation
    static var isValidAPIKey: Bool {
        return !deepSeekAPIKey.isEmpty && 
               deepSeekAPIKey != "sk-your-production-deepseek-api-key-here" && 
               deepSeekAPIKey.hasPrefix("sk-")
    }
    
    // MARK: - Configuration Loading
    static func loadConfiguration() {
        // Force early loading to detect configuration issues
        let _ = deepSeekAPIKey
        
        if !isValidAPIKey {
            print("⚠️ ProductionAIConfig: Invalid or missing API key")
            print("📝 To fix this:")
            print("   1. Get your production API key from https://platform.deepseek.com")
            print("   2. Add it to Config.plist as 'DeepSeekAPIKey'")
            print("   3. Make sure Config.plist is added to your Xcode project")
        }
    }
    
    static func getAPIKey() -> String? {
        guard isValidAPIKey else {
            print("⚠️ ProductionAIConfig: Invalid production API key")
            print("📝 To fix this:")
            print("   1. Get your production API key from https://platform.deepseek.com")
            print("   2. Replace 'sk-your-production-deepseek-api-key-here' above")
            print("   3. This key will be used for all users")
            return nil
        }
        
        return deepSeekAPIKey
    }
    
    // MARK: - Usage Tracking
    static func canMakeScanRequest(currentUserScans: Int) -> Bool {
        return currentUserScans < maxScansPerUser
    }
    
    static func remainingScans(currentUserScans: Int) -> Int {
        return max(0, maxScansPerUser - currentUserScans)
    }
}