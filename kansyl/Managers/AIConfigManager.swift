//
//  AIConfigManager.swift
//  kansyl
//
//  Secure configuration manager for AI services
//

import Foundation
import Security

class AIConfigManager: ObservableObject {
    static let shared = AIConfigManager()
    
    private let keychain = KeychainManager()
    private let deepSeekKeyIdentifier = "com.kansyl.deepseek.apikey"
    
    private init() {}
    
    // MARK: - API Key Management
    var deepSeekAPIKey: String? {
        get {
            // In production, use embedded API key
            if ProductionAIConfig.isProduction {
                return ProductionAIConfig.getAPIKey()
            }
            
            // Development fallback: try keychain (user-configured)
            if let keychainKey = keychain.get(key: deepSeekKeyIdentifier), !keychainKey.isEmpty {
                return keychainKey
            }
            
            // Try development configuration
            if let developmentKey = APIConfig.getAPIKey() {
                return developmentKey
            }
            
            // Try fallback development config
            if let fallbackKey = DevelopmentConfig.getAPIKey() {
                return fallbackKey
            }
            
            return nil
        }
        set {
            // Only allow setting API key in development mode
            if !ProductionAIConfig.isProduction {
                if let key = newValue {
                    keychain.set(key: deepSeekKeyIdentifier, value: key)
                } else {
                    keychain.delete(key: deepSeekKeyIdentifier)
                }
            }
        }
    }
    
    // MARK: - Configuration
    var isAIEnabled: Bool {
        return deepSeekAPIKey != nil && !deepSeekAPIKey!.isEmpty
    }
    
    // MARK: - Usage Tracking (Production Only)
    private let userDefaults = UserDefaults.standard
    private let scanCountKey = "com.kansyl.ai.scanCount"
    
    var currentUserScanCount: Int {
        get {
            return userDefaults.integer(forKey: scanCountKey)
        }
        set {
            userDefaults.set(newValue, forKey: scanCountKey)
        }
    }
    
    var canMakeAIScan: Bool {
        if ProductionAIConfig.isProduction {
            return ProductionAIConfig.canMakeScanRequest(currentUserScans: currentUserScanCount)
        }
        return true // No limits in development
    }
    
    var remainingScans: Int {
        if ProductionAIConfig.isProduction {
            return ProductionAIConfig.remainingScans(currentUserScans: currentUserScanCount)
        }
        return Int.max // Unlimited in development
    }
    
    func recordAIScan() {
        currentUserScanCount += 1
        print("📊 AI scan recorded. Total scans: \(currentUserScanCount)")
    }
    
    // MARK: - Alternative AI Services
    // Using DeepSeek API for cost-effective AI processing
    var useDeepSeek: Bool = true
    var useLocalProcessing: Bool = false // For privacy-focused users
    
    // MARK: - Rate Limiting
    private var lastAPICall: Date = Date.distantPast
    private let minimumInterval: TimeInterval = 1.0 // 1 second between calls
    
    func canMakeAPICall() -> Bool {
        return Date().timeIntervalSince(lastAPICall) >= minimumInterval
    }
    
    func recordAPICall() {
        lastAPICall = Date()
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    
    func set(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}