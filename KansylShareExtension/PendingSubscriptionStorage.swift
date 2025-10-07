//
//  PendingSubscriptionStorage.swift
//  kansyl
//
//  Alternative storage mechanism for Share Extension data transfer
//

import Foundation

class PendingSubscriptionStorage {
    static let shared = PendingSubscriptionStorage()
    
    // Use file-based storage as fallback
    private let fileName = "pending_subscriptions.json"
    
    private var fileURL: URL? {
        // Try to get shared container URL first
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.juan-oclock.kansyl") {
            print("✅ [PendingStorage] Using shared container at: \(containerURL.path)")
            return containerURL.appendingPathComponent(fileName)
        }
        
        // Fallback to documents directory
        print("⚠️ [PendingStorage] Falling back to documents directory")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsPath?.appendingPathComponent(fileName)
    }
    
    // MARK: - Save Subscription (from Share Extension)
    func savePendingSubscription(_ data: [String: Any]) {
        guard let url = fileURL else {
            print("❌ [PendingStorage] No file URL available")
            return
        }
        
        var pending = getPendingSubscriptions()
        pending.append(data)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: pending, options: .prettyPrinted)
            try jsonData.write(to: url)
            print("✅ [PendingStorage] Saved \(pending.count) pending subscription(s) to: \(url.lastPathComponent)")
            print("   Service: \(data["serviceName"] ?? "Unknown")")
            
            // Also try UserDefaults as backup
            if let defaults = UserDefaults(suiteName: "group.com.juan-oclock.kansyl") {
                defaults.set(pending, forKey: "pendingSubscriptions")
                defaults.synchronize()
                print("✅ [PendingStorage] Also saved to UserDefaults")
            }
        } catch {
            print("❌ [PendingStorage] Failed to save: \(error)")
        }
    }
    
    // MARK: - Get Subscriptions (from Main App)
    func getPendingSubscriptions() -> [[String: Any]] {
        // Try file first
        if let url = fileURL {
            do {
                let data = try Data(contentsOf: url)
                let pending = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                print("📥 [PendingStorage] Retrieved \(pending.count) subscription(s) from file")
                return pending
            } catch {
                print("⚠️ [PendingStorage] No file found or error reading: \(error.localizedDescription)")
            }
        }
        
        // Try UserDefaults as fallback
        if let defaults = UserDefaults(suiteName: "group.com.juan-oclock.kansyl"),
           let pending = defaults.array(forKey: "pendingSubscriptions") as? [[String: Any]] {
            print("📥 [PendingStorage] Retrieved \(pending.count) subscription(s) from UserDefaults")
            return pending
        }
        
        print("📥 [PendingStorage] No pending subscriptions found")
        return []
    }
    
    // MARK: - Clear Subscriptions
    func clearPendingSubscriptions() {
        // Clear file
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ [PendingStorage] Cleared file storage")
        }
        
        // Clear UserDefaults
        if let defaults = UserDefaults(suiteName: "group.com.juan-oclock.kansyl") {
            defaults.removeObject(forKey: "pendingSubscriptions")
            defaults.synchronize()
            print("🗑️ [PendingStorage] Cleared UserDefaults")
        }
    }
    
    // MARK: - Debug Helper
    func debugPrint() {
        print("\n🔍 [PendingStorage] Debug Info:")
        print("   File URL: \(fileURL?.path ?? "nil")")
        
        if let url = fileURL {
            let exists = FileManager.default.fileExists(atPath: url.path)
            print("   File exists: \(exists)")
            
            if exists {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                    let size = attributes[.size] as? Int ?? 0
                    let modified = attributes[.modificationDate] as? Date
                    print("   File size: \(size) bytes")
                    print("   Last modified: \(modified?.description ?? "unknown")")
                }
            }
        }
        
        let pending = getPendingSubscriptions()
        print("   Pending count: \(pending.count)")
        for (index, item) in pending.enumerated() {
            print("   [\(index)] \(item["serviceName"] ?? "Unknown")")
        }
        print("\n")
    }
}