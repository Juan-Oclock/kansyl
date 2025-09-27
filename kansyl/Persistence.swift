//
//  Persistence.swift
//  kansyl
//
//  Created on 9/12/25.
//

import CoreData
import CloudKit

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
    
    let container: NSPersistentCloudKitContainer
    private(set) var isLoaded = false
    private(set) var loadError: Error?
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Kansyl")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            setupCloudKitStores()
        }
        
        // Enable automatic lightweight migration
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ [PersistenceController] Core Data failed to load: \(error.localizedDescription)")
                self?.loadError = error
                self?.isLoaded = false
                
                // Attempt recovery in production
                #if !DEBUG
                self?.attemptRecovery()
                #endif
            } else {
                print("✅ [PersistenceController] Core Data loaded successfully")
                self?.isLoaded = true
                // Configure context on success
                self?.container.viewContext.automaticallyMergesChangesFromParent = true
                self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                // Set up CloudKit remote change notifications (only if available)
                DispatchQueue.main.async {
                    // Check if CloudKit features are enabled before setting up notifications
                    #if DEBUG
                    // Skip CloudKit setup in debug mode for personal development teams
                    print("🔧 [PersistenceController] Skipping CloudKit notifications in DEBUG mode")
                    #else
                    CloudKitManager.shared.setupRemoteChangeNotifications()
                    #endif
                }
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
        // For development with personal team, use only local store to avoid CloudKit issues
        let localStoreDescription = NSPersistentStoreDescription(
            url: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("LocalStore.sqlite")
        )
        localStoreDescription.configuration = "LocalConfiguration"
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
