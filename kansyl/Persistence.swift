//
//  Persistence.swift
//  kansyl
//
//  Created on 9/12/25.
//

import CoreData

struct PersistenceController {
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
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error and attempt recovery
                // Debug: // Debug: print("Core Data error: \(error), \(error.userInfo)")
                
                // In production, you might want to:
                // 1. Try to delete and recreate the store
                // 2. Show user-friendly error message
                // 3. Fall back to in-memory store
                // For now, we'll still crash in debug builds but handle it better
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #else
                // In release, attempt to recover by using in-memory store
                container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
                #endif
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
