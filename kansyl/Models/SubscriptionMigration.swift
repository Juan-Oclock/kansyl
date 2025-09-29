//
//  SubscriptionMigration.swift
//  kansyl
//
//  Created on 9/29/25.
//

import Foundation
import CoreData

class SubscriptionMigration {
    static let shared = SubscriptionMigration()
    private let defaults = UserDefaults.standard
    private let migrationKey = "SubscriptionTypeMigrationCompleted_v1"
    
    private init() {}
    
    /// Check if migration is needed and perform it
    func performMigrationIfNeeded(context: NSManagedObjectContext) {
        // Check if we've already performed this migration
        if defaults.bool(forKey: migrationKey) {
            print("📦 [Migration] Subscription type migration already completed")
            return
        }
        
        print("📦 [Migration] Starting subscription type migration...")
        performMigration(context: context)
    }
    
    /// Perform the actual migration
    private func performMigration(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        do {
            let subscriptions = try context.fetch(fetchRequest)
            var migratedCount = 0
            
            for subscription in subscriptions {
                // Only migrate if subscriptionType is not set
                if subscription.subscriptionType == nil || subscription.subscriptionType?.isEmpty == true {
                    migrateSubscription(subscription)
                    migratedCount += 1
                }
            }
            
            // Save changes
            if context.hasChanges {
                try context.save()
                print("📦 [Migration] Successfully migrated \(migratedCount) subscriptions")
            }
            
            // Mark migration as completed
            defaults.set(true, forKey: migrationKey)
            
            // Track migration analytics
            AnalyticsManager.shared.track(.subscriptionAdded, properties: AnalyticsProperties(
                source: "subscription_type_migration",
                subscriptionName: "Migration: \(migratedCount) subscriptions"
            ))
            
        } catch {
            print("📦 [Migration] Failed to migrate subscriptions: \(error)")
        }
    }
    
    /// Migrate a single subscription to set default type
    private func migrateSubscription(_ subscription: Subscription) {
        // Just set a default type if none exists
        if subscription.subscriptionType == nil || subscription.subscriptionType?.isEmpty == true {
            subscription.subscriptionType = SubscriptionType.paid.rawValue
            subscription.isTrial = false
        }
        
        print("📦 [Migration] Set default type for '\(subscription.name ?? "Unknown")' as \(subscription.subscriptionType ?? "unknown")")
    }
    
    // This method is now replaced by the Subscription extension
    // See Subscription+TypeDetermination.swift
    
    /// Reset migration (useful for testing)
    func resetMigration() {
        defaults.set(false, forKey: migrationKey)
        print("📦 [Migration] Reset migration flag")
    }
    
    /// Check if migration has been completed
    var isMigrationCompleted: Bool {
        return defaults.bool(forKey: migrationKey)
    }
}

// MARK: - App Launch Integration
extension SubscriptionMigration {
    /// Call this method on app launch after Core Data is initialized
    static func performMigrationOnLaunch() {
        DispatchQueue.main.async {
            let context = PersistenceController.shared.container.viewContext
            SubscriptionMigration.shared.performMigrationIfNeeded(context: context)
        }
    }
}