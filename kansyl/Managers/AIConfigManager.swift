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
            // First try keychain (user-configured)
            if let keychainKey = keychain.get(key: deepSeekKeyIdentifier), !keychainKey.isEmpty {
                return keychainKey
            }
            
            // Fallback to development configuration
            if let developmentKey = APIConfig.getAPIKey() {
                return developmentKey
            }
            
            return nil
        }
        set {
            if let key = newValue {
                keychain.set(key: deepSeekKeyIdentifier, value: key)
            } else {
                keychain.delete(key: deepSeekKeyIdentifier)
            }
        }
    }
    
    // MARK: - Configuration
    var isAIEnabled: Bool {
        return deepSeekAPIKey != nil && !deepSeekAPIKey!.isEmpty
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