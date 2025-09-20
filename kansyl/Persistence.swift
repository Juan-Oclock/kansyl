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
    
    let container: NSPersistentContainer
    private(set) var isLoaded = false
    private(set) var loadError: Error?
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Kansyl")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
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
}
