//
//  Persistence.swift
//  kansyl
//
//  Created on 9/12/25.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    // Preview with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample subscription data for previews
        let sampleSubscription = Subscription(context: viewContext)
        sampleSubscription.id = UUID()
        sampleSubscription.name = "Netflix Premium"
        sampleSubscription.startDate = Date()
        sampleSubscription.endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        sampleSubscription.monthlyPrice = 19.99
        sampleSubscription.serviceLogo = "tv"
        sampleSubscription.status = "active"
        sampleSubscription.notes = "Testing the 4K plan"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    // Use regular NSPersistentContainer instead of CloudKit container for v1.0
    // CloudKit will be enabled in a future version as a premium feature
    let container: NSPersistentContainer
    private(set) var isLoaded = false
    private(set) var loadError: Error?
    
    init(inMemory: Bool = false) {
        // Use regular NSPersistentContainer for v1.0 (local storage only)
        container = NSPersistentContainer(name: "Kansyl")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        // Note: setupCloudKitStores() is not called - CloudKit disabled for v1.0
        
        // Enable automatic lightweight migration
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Additional options to handle model changes more gracefully
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            // Enable persistent history tracking for better sync
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ [PersistenceController] Core Data failed to load: \(error.localizedDescription)")
                print("❌ [PersistenceController] Error code: \(error.code)")
                self?.loadError = error
                self?.isLoaded = false
                
                // Check if this is a model incompatibility error
                if error.code == 134020 || error.code == 134100 {
                    print("🔧 [PersistenceController] Model incompatibility detected. Attempting to recreate store...")
                    self?.recreateStore()
                } else {
                    // Attempt recovery in production
                    #if !DEBUG
                    self?.attemptRecovery()
                    #endif
                }
            } else {
                print("✅ [PersistenceController] Core Data loaded successfully")
                self?.isLoaded = true
                // Configure context on success
                self?.container.viewContext.automaticallyMergesChangesFromParent = true
                self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                // CloudKit disabled for v1.0 - will be enabled as premium feature in future
                print("📋 [PersistenceController] CloudKit sync disabled - using local Core Data storage only")
            }
        }
    }
    
    private func recreateStore() {
        print("🔄 [PersistenceController] Recreating Core Data store...")
        
        // Get the persistent store coordinator
        let coordinator = container.persistentStoreCoordinator
        let stores = coordinator.persistentStores
        
        // Remove all stores from coordinator
        for store in stores {
            do {
                try coordinator.remove(store)
                
                // Delete the store files
                if let storeURL = store.url, storeURL.path != "/dev/null" {
                    try FileManager.default.removeItem(at: storeURL)
                    print("🗑 [PersistenceController] Deleted store at: \(storeURL)")
                    
                    // Also delete associated files
                    let walURL = storeURL.appendingPathExtension("wal")
                    let shmURL = storeURL.appendingPathExtension("shm")
                    try? FileManager.default.removeItem(at: walURL)
                    try? FileManager.default.removeItem(at: shmURL)
                }
            } catch {
                print("⚠️ [PersistenceController] Could not remove/delete store: \(error)")
            }
        }
        
        // Reload stores with same configuration
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                print("❌ [PersistenceController] Failed to recreate store: \(error)")
                self?.loadError = error
                // Fall back to in-memory store
                self?.attemptRecovery()
            } else {
                print("✅ [PersistenceController] Store recreated successfully")
                self?.isLoaded = true
                self?.container.viewContext.automaticallyMergesChangesFromParent = true
                self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
    }
    
    private func attemptRecovery() {
        print("🔧 [PersistenceController] Attempting recovery with in-memory store...")
        
        // Reset container with in-memory store
        container.persistentStoreDescriptions.forEach { description in
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Try loading again
        container.loadPersistentStores { [weak self] (_, error) in
            if let error = error {
                print("❌ [PersistenceController] Recovery failed: \(error.localizedDescription)")
                self?.loadError = error
            } else {
                print("✅ [PersistenceController] Recovery successful with in-memory store")
                self?.isLoaded = true
                self?.container.viewContext.automaticallyMergesChangesFromParent = true
            }
        }
    }
    
    private func setupCloudKitStores() {
        #if DEBUG
        // For development with personal team, use a store without configuration restrictions
        // This allows all entities to be saved in DEBUG mode
        let localStoreDescription = NSPersistentStoreDescription(
            url: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("LocalStore.sqlite")
        )
        // IMPORTANT: Don't set configuration in DEBUG to allow all entities
        // localStoreDescription.configuration = "LocalConfiguration"  // <-- This was the problem!
        localStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.persistentStoreDescriptions = [localStoreDescription]
        #else
        // CloudKit store for user data that syncs (production)
        let cloudKitStoreDescription = NSPersistentStoreDescription(
            url: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CloudKitStore.sqlite")
        )
        cloudKitStoreDescription.configuration = "CloudKitConfiguration"
        cloudKitStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        cloudKitStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Set CloudKit container identifier
        let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.juan-oclock.kansyl.kansyl"
        )
        cloudKitStoreDescription.cloudKitContainerOptions = cloudKitContainerOptions
        
        // Local store for data that doesn't need to sync (templates, etc.)
        let localStoreDescription = NSPersistentStoreDescription(
            url: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("LocalStore.sqlite")
        )
        localStoreDescription.configuration = "LocalConfiguration"
        
        container.persistentStoreDescriptions = [cloudKitStoreDescription, localStoreDescription]
        #endif
    }
}
