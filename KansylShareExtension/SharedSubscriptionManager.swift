//
//  SharedSubscriptionManager.swift
//  kansyl
//
//  Manages data sharing between Share Extension and main app via App Group
//

import Foundation

class SharedSubscriptionManager {
    static let shared = SharedSubscriptionManager()
    
    // App Group identifier - must match entitlements
    private let appGroupIdentifier = "group.com.juan-oclock.kansyl"
    private let pendingSubscriptionsKey = "pendingSubscriptions"
    
    // Store a reference to the shared UserDefaults
    private let sharedDefaults: UserDefaults?
    
    private init() {
        // Initialize shared UserDefaults once
        self.sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        if sharedDefaults != nil {
            print("✅ [SharedSubscriptionManager] Initialized with App Group: \(appGroupIdentifier)")
        } else {
            print("❌ [SharedSubscriptionManager] Failed to initialize App Group: \(appGroupIdentifier)")
            print("   Make sure both targets have the App Group capability enabled!")
        }
    }
    
    // MARK: - Save Pending Subscription (from Share Extension)
    func savePendingSubscription(_ data: [String: Any]) {
        guard let defaults = sharedDefaults else {
            print("❌ [SharedSubscriptionManager] Could not access shared UserDefaults")
            return
        }
        
        var pending = getPendingSubscriptions()
        pending.append(data)
        
        defaults.set(pending, forKey: pendingSubscriptionsKey)
        defaults.synchronize()
        
        print("✅ [SharedSubscriptionManager] Saved pending subscription: \(data["serviceName"] ?? "Unknown")")
        print("   Total pending: \(pending.count)")
    }
    
    // MARK: - Get Pending Subscriptions (from Main App)
    func getPendingSubscriptions() -> [[String: Any]] {
        guard let defaults = sharedDefaults else {
            print("❌ [SharedSubscriptionManager] Could not access shared UserDefaults")
            return []
        }
        
        let pending = defaults.array(forKey: pendingSubscriptionsKey) as? [[String: Any]] ?? []
        print("📥 [SharedSubscriptionManager] Retrieved \(pending.count) pending subscription(s)")
        return pending
    }
    
    // MARK: - Clear Pending Subscriptions (after processing in Main App)
    func clearPendingSubscriptions() {
        guard let defaults = sharedDefaults else {
            print("❌ [SharedSubscriptionManager] Could not access shared UserDefaults")
            return
        }
        
        defaults.removeObject(forKey: pendingSubscriptionsKey)
        defaults.synchronize()
        
        print("🗑️ [SharedSubscriptionManager] Cleared all pending subscriptions")
    }
    
    // MARK: - Remove Single Pending Subscription
    func removePendingSubscription(at index: Int) {
        guard let defaults = sharedDefaults else { return }
        
        var pending = getPendingSubscriptions()
        guard index >= 0 && index < pending.count else { return }
        
        pending.remove(at: index)
        defaults.set(pending, forKey: pendingSubscriptionsKey)
        defaults.synchronize()
        
        print("🗑️ [SharedSubscriptionManager] Removed pending subscription at index \(index)")
    }
    
    // MARK: - Debug Helper
    func debugPrintPendingSubscriptions() {
        let pending = getPendingSubscriptions()
        print("🔍 [SharedSubscriptionManager] Debug - Pending Subscriptions:")
        for (index, data) in pending.enumerated() {
            print("   \(index): \(data)")
        }
    }
}
