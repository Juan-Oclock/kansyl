//
//  CoreDataReset.swift
//  kansyl
//
//  Created on 9/29/25.
//

import Foundation
import CoreData

/// Utility class for resetting and recovering Core Data stack
class CoreDataReset {
    static let shared = CoreDataReset()
    
    private init() {}
    
    /// Completely reset Core Data stores
    func resetCoreDataStack(completion: @escaping (Bool, Error?) -> Void) {
        print("🔧 [CoreDataReset] Starting Core Data reset...")
        
        // Get the persistent store coordinator
        let coordinator = PersistenceController.shared.container.persistentStoreCoordinator
        let stores = coordinator.persistentStores
        
        // Remove all persistent stores
        for store in stores {
            do {
                try coordinator.remove(store)
                
                // Delete the store file if it exists
                if let storeURL = store.url, storeURL.path != "/dev/null" {
                    try FileManager.default.removeItem(at: storeURL)
                    print("🗑️ [CoreDataReset] Deleted store at: \(storeURL)")
                }
            } catch {
                print("❌ [CoreDataReset] Failed to remove store: \(error)")
            }
        }
        
        // Reload persistent stores
        PersistenceController.shared.container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                print("❌ [CoreDataReset] Failed to reload stores: \(error)")
                completion(false, error)
            } else {
                print("✅ [CoreDataReset] Core Data reset completed successfully")
                completion(true, nil)
            }
        }
    }
    
    /// Clear all data for a specific user
    func clearUserData(userID: String, completion: @escaping (Bool, Error?) -> Void) {
        print("🧹 [CoreDataReset] Clearing data for user: \(userID)")
        
        let context = PersistenceController.shared.container.viewContext
        
        // Create batch delete request for subscriptions
        let subscriptionRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        subscriptionRequest.predicate = NSPredicate(format: "userID == %@", userID)
        let deleteSubscriptions = NSBatchDeleteRequest(fetchRequest: subscriptionRequest)
        
        do {
            // Execute batch delete
            try context.execute(deleteSubscriptions)
            try context.save()
            
            print("✅ [CoreDataReset] Successfully cleared data for user: \(userID)")
            
            // Force refresh subscription store
            DispatchQueue.main.async {
                SubscriptionStore.shared.fetchSubscriptions()
            }
            
            completion(true, nil)
        } catch {
            print("❌ [CoreDataReset] Failed to clear user data: \(error)")
            completion(false, error)
        }
    }
    
    /// Verify Core Data integrity
    func verifyDataIntegrity() -> (isValid: Bool, issues: [String]) {
        print("🔍 [CoreDataReset] Verifying Core Data integrity...")
        
        var issues: [String] = []
        let context = PersistenceController.shared.container.viewContext
        
        // Check if context is available
        guard context.persistentStoreCoordinator != nil else {
            issues.append("Persistent store coordinator is nil")
            return (false, issues)
        }
        
        // Check if stores are loaded
        let stores = context.persistentStoreCoordinator?.persistentStores ?? []
        if stores.isEmpty {
            issues.append("No persistent stores loaded")
        }
        
        // Try to fetch subscriptions
        do {
            let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
            let count = try context.count(for: request)
            print("✅ [CoreDataReset] Found \(count) subscriptions in database")
        } catch {
            issues.append("Failed to fetch subscriptions: \(error.localizedDescription)")
        }
        
        // Check for merge conflicts
        if context.hasChanges {
            issues.append("Context has unsaved changes")
        }
        
        let isValid = issues.isEmpty
        if isValid {
            print("✅ [CoreDataReset] Core Data integrity check passed")
        } else {
            print("⚠️ [CoreDataReset] Core Data integrity issues found:")
            for issue in issues {
                print("  - \(issue)")
            }
        }
        
        return (isValid, issues)
    }
    
    /// Force save any pending changes
    func forceSaveContext() {
        print("💾 [CoreDataReset] Force saving context...")
        
        let context = PersistenceController.shared.container.viewContext
        
        // Process any pending changes
        context.processPendingChanges()
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ [CoreDataReset] Context saved successfully")
            } catch {
                print("❌ [CoreDataReset] Failed to save context: \(error)")
                // Try rollback as last resort
                context.rollback()
                print("🔄 [CoreDataReset] Context rolled back")
            }
        } else {
            print("ℹ️ [CoreDataReset] No changes to save")
        }
    }
    
    /// Debug: Print all subscriptions in the database
    func debugPrintAllSubscriptions() {
        print("\n📊 [CoreDataReset] DEBUG: All Subscriptions in Database")
        print("=" * 50)
        
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        do {
            let subscriptions = try context.fetch(request)
            print("Total subscriptions: \(subscriptions.count)\n")
            
            for (index, subscription) in subscriptions.enumerated() {
                print("[\(index + 1)] Subscription:")
                print("  - ID: \(subscription.id?.uuidString ?? "nil")")
                print("  - Name: \(subscription.name ?? "Unknown")")
                print("  - UserID: \(subscription.userID ?? "nil")")
                print("  - Status: \(subscription.status ?? "nil")")
                print("  - StartDate: \(subscription.startDate?.description ?? "nil")")
                print("  - EndDate: \(subscription.endDate?.description ?? "nil")")
                print("  - MonthlyPrice: \(subscription.monthlyPrice)")
                print("  - Type: \(subscription.subscriptionType ?? "nil")")
                print("  - IsTrial: \(subscription.isTrial)")
                print("")
            }
        } catch {
            print("❌ Failed to fetch subscriptions: \(error)")
        }
        
        print("=" * 50)
    }
}

// MARK: - String Extension for Repeat
extension String {
    static func *(left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}