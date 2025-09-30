//
//  SubscriptionStore.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import CoreData
import SwiftUI

enum SubscriptionStatus: String, CaseIterable {
    case active = "active"
    case canceled = "canceled"
    case kept = "kept"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .canceled: return "Canceled"
        case .kept: return "Keeping"
        case .expired: return "Expired"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .blue
        case .canceled: return .green
        case .kept: return .purple
        case .expired: return .red
        }
    }
}

class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()
    
    private var _viewContext: NSManagedObjectContext?
    var viewContext: NSManagedObjectContext {
        if _viewContext == nil {
            _viewContext = PersistenceController.shared.container.viewContext
        }
        return _viewContext!
    }
    
    private var _costEngine: CostCalculationEngine?
    var costEngine: CostCalculationEngine {
        if _costEngine == nil {
            _costEngine = CostCalculationEngine(context: viewContext)
        }
        return _costEngine!
    }
    
    @Published var activeSubscriptions: [Subscription] = []
    @Published var endingSoonSubscriptions: [Subscription] = []
    @Published var allSubscriptions: [Subscription] = []
    @Published var recentlyEndedSubscriptions: [Subscription] = []
    
    // Current user ID for data isolation
    @Published var currentUserID: String? {
        didSet {
            // Only fetch if we have a context ready
            if _viewContext != nil {
                fetchSubscriptions()
            }
        }
    }
    
    init(context: NSManagedObjectContext? = nil, userID: String? = nil) {
        AppLogger.debug("Initializing with lazy loading...", emoji: "📚", category: "SubscriptionStore")
        self._viewContext = context
        self.currentUserID = userID
        // Set up remote change notifications for CloudKit
        setupRemoteChangeNotifications()
        // Don't fetch subscriptions on init - wait until context is accessed
    }
    
    // MARK: - Fetch Operations
    
    func fetchSubscriptions() {
        AppLogger.log("🔄 fetchSubscriptions called", category: "SubscriptionStore")
        AppLogger.log("Current userID: \(currentUserID ?? "nil")", category: "SubscriptionStore")
        
        guard let userID = currentUserID else {
            AppLogger.log("No userID, clearing subscriptions", category: "SubscriptionStore")
            // No user logged in, clear all subscriptions
            DispatchQueue.main.async { [weak self] in
                self?.allSubscriptions = []
                self?.updateSubscriptionCategories()
            }
            return
        }
        
        AppLogger.log("Fetching subscriptions for user: \(userID)", category: "SubscriptionStore")
        
        // First, let's check ALL subscriptions in the database
        let allRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        do {
            let allSubs = try viewContext.fetch(allRequest)
            print("[SubscriptionStore] 📊 Total subscriptions in database: \(allSubs.count)")
            for sub in allSubs {
                print("[SubscriptionStore]   - \(sub.name ?? "Unknown"): userID=\(sub.userID ?? "nil"), id=\(sub.id?.uuidString ?? "nil")")
            }
        } catch {
            print("[SubscriptionStore] Failed to fetch all subscriptions: \(error)")
        }
        
        // Now fetch for specific user
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        request.returnsObjectsAsFaults = false // Force full object loading
        
        do {
            let subscriptions = try viewContext.fetch(request)
            AppLogger.success("Fetched \(subscriptions.count) subscriptions for user \(userID)", category: "SubscriptionStore")
            
            for subscription in subscriptions {
                print("[SubscriptionStore]   - \(subscription.name ?? "Unknown"): status=\(subscription.status ?? "nil"), type=\(subscription.subscriptionType ?? "nil"), endDate=\(subscription.endDate?.description ?? "nil")")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.allSubscriptions = subscriptions
                self?.updateSubscriptionCategories()
                print("[SubscriptionStore] Updated categories - Active: \(self?.activeSubscriptions.count ?? 0)")
            }
        } catch {
            AppLogger.error("Failed to fetch subscriptions: \(error.localizedDescription)", category: "SubscriptionStore")
            if let nsError = error as NSError? {
                print("[SubscriptionStore] Error details: \(nsError.userInfo)")
            }
        }
    }
    
    private func updateSubscriptionCategories() {
        let now = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        
        print("[SubscriptionStore] Updating categories with \(allSubscriptions.count) total subscriptions")
        for subscription in allSubscriptions {
            print("[SubscriptionStore]   - \(subscription.name ?? "Unknown"): status=\(subscription.status ?? "nil"), endDate=\(subscription.endDate?.description ?? "nil"), isActive=\(subscription.status == SubscriptionStatus.active.rawValue), isNotExpired=\((subscription.endDate ?? Date()) > now)")
        }
        
        activeSubscriptions = allSubscriptions.filter { subscription in
            subscription.status == SubscriptionStatus.active.rawValue && 
            (subscription.endDate ?? Date()) > now
        }
        
        print("[SubscriptionStore] Filtered to \(activeSubscriptions.count) active subscriptions")
        
        endingSoonSubscriptions = activeSubscriptions.filter { subscription in
            (subscription.endDate ?? Date()) <= sevenDaysFromNow
        }
        
        recentlyEndedSubscriptions = allSubscriptions.filter { subscription in
            subscription.status != SubscriptionStatus.active.rawValue &&
            (subscription.endDate ?? Date()) > thirtyDaysAgo &&
            (subscription.endDate ?? Date()) <= now
        }
    }
    
    // MARK: - CRUD Operations
    
    @discardableResult
    func addSubscription(name: String, startDate: Date, endDate: Date, 
                  monthlyPrice: Double, serviceLogo: String, notes: String? = nil,
                  addToCalendar: Bool = false, billingCycle: String? = nil, 
                  billingAmount: Double? = nil, originalCurrency: String? = nil,
                  originalAmount: Double? = nil, exchangeRate: Double? = nil,
                  subscriptionType: SubscriptionType? = nil) -> Subscription? {
        
        print("[SubscriptionStore] Adding subscription: \(name)")
        print("[SubscriptionStore] Current userID in addSubscription: \(currentUserID ?? "nil")")
        
        guard let userID = currentUserID else {
            print("[SubscriptionStore] No userID found, cannot add subscription")
            return nil
        }
        
        print("[SubscriptionStore] UserID: \(userID)")
        
        let newSubscription = Subscription(context: viewContext)
        newSubscription.id = UUID()
        newSubscription.userID = userID  // Set the user ID for data isolation
        newSubscription.name = name
        newSubscription.startDate = startDate
        newSubscription.endDate = endDate
        newSubscription.monthlyPrice = monthlyPrice
        newSubscription.serviceLogo = serviceLogo
        newSubscription.status = SubscriptionStatus.active.rawValue
        newSubscription.notes = notes
        
        // Set subscription type (default to trial if not provided)
        let type = subscriptionType ?? .trial
        newSubscription.subscriptionType = type.rawValue
        newSubscription.isTrial = (type == .trial)
        if type == .trial {
            newSubscription.trialEndDate = endDate
        }
        print("[SubscriptionStore] Set subscription type to: \(type.rawValue)")
        
        // Set billing cycle and amount
        newSubscription.billingCycle = billingCycle ?? "monthly"
        newSubscription.billingAmount = billingAmount ?? monthlyPrice
        
        // Set exchange rate tracking if currency was converted
        if let origCurrency = originalCurrency {
            newSubscription.originalCurrency = origCurrency
            newSubscription.originalAmount = originalAmount ?? billingAmount ?? monthlyPrice
            newSubscription.exchangeRate = exchangeRate ?? 1.0
            newSubscription.lastRateUpdate = Date()
        }
        
        print("[SubscriptionStore] About to save context...")
        print("[SubscriptionStore] Context before save: \(viewContext)")
        print("[SubscriptionStore] Subscription ID before save: \(newSubscription.id?.uuidString ?? "nil")")
        print("[SubscriptionStore] Subscription userID before save: \(newSubscription.userID ?? "nil")")
        
        // Save the context first
        saveContext()
        
        // Force the context to process pending changes
        viewContext.processPendingChanges()
        
        // Wait a moment for the save to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            print("[SubscriptionStore] Fetching subscriptions after save...")
            self?.fetchSubscriptions()
            print("[SubscriptionStore] Current subscription count: \(self?.allSubscriptions.count ?? 0)")
        }
        
        // Schedule notifications for the new subscription
        NotificationManager.shared.scheduleNotifications(for: newSubscription)
        
        // Only create calendar event if user opted in
        if addToCalendar {
            CalendarManager.shared.addOrUpdateEvent(for: newSubscription)
        }
        
        // Update cost calculations
        costEngine.refreshMetrics()
        
        return newSubscription
    }
    
    func updateSubscriptionStatus(_ subscription: Subscription, status: SubscriptionStatus) {
        subscription.status = status.rawValue
        saveContext()
        fetchSubscriptions()
        
        // Remove notifications and calendar event when subscription is no longer active
        if status != .active {
            NotificationManager.shared.removeNotifications(for: subscription)
            CalendarManager.shared.removeEvent(for: subscription)
        } else {
            CalendarManager.shared.addOrUpdateEvent(for: subscription)
        }
        
        // Record outcome for cost calculations
        costEngine.recordSubscriptionOutcome(subscription: subscription, newStatus: status)
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        // Remove notifications before deleting
        NotificationManager.shared.removeNotifications(for: subscription)
        CalendarManager.shared.removeEvent(for: subscription)
        
        viewContext.delete(subscription)
        saveContext()
        fetchSubscriptions()
        
        // Notify CloudKit manager of new data
        NotificationCenter.default.post(
            name: NSNotification.Name("SubscriptionDataChanged"),
            object: nil
        )
    }
    
    // MARK: - CloudKit Support
    
    private func setupRemoteChangeNotifications() {
        // Listen for CloudKit remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: PersistenceController.shared.container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            self?.handleRemoteChange()
        }
    }
    
    private func handleRemoteChange() {
        // Refresh data when CloudKit sync occurs
        fetchSubscriptions()
    }
    
    // MARK: - User Management
    
    func updateCurrentUser(userID: String?) {
        self.currentUserID = userID
    }
    
    // MARK: - Helper Methods
    
    func daysRemaining(for subscription: Subscription) -> Int {
        guard let endDate = subscription.endDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    func urgencyColor(for subscription: Subscription) -> Color {
        let days = daysRemaining(for: subscription)
        if days <= 2 {
            return .red
        } else if days <= 6 {
            return .orange
        } else {
            return .green
        }
    }
    
    func formattedEndDate(for subscription: Subscription) -> String {
        guard let endDate = subscription.endDate else { return "No end date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: endDate)
    }
    
    // MARK: - Statistics
    
    var totalMonthlyCost: Double {
        activeSubscriptions.reduce(0) { $0 + ($1.monthlyPrice) }
    }
    
    var totalSavings: Double {
        allSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }
            .reduce(0) { $0 + ($1.monthlyPrice) }
    }
    
    // MARK: - Core Data
    
    func saveContext() {
        AppLogger.log("saveContext called - hasChanges: \(viewContext.hasChanges)", category: "SubscriptionStore")
        print("[SubscriptionStore] Inserted objects: \(viewContext.insertedObjects.count)")
        print("[SubscriptionStore] Updated objects: \(viewContext.updatedObjects.count)")
        print("[SubscriptionStore] Deleted objects: \(viewContext.deletedObjects.count)")
        
        // Print details about inserted objects
        for object in viewContext.insertedObjects {
            if let subscription = object as? Subscription {
                print("[SubscriptionStore] Inserting subscription: \(subscription.name ?? "Unknown") with ID: \(subscription.id?.uuidString ?? "nil")")
            }
        }
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                AppLogger.success("Context saved successfully", category: "SubscriptionStore")
                
                // Verify the save by fetching immediately
                let verifyRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
                if let userID = currentUserID {
                    verifyRequest.predicate = NSPredicate(format: "userID == %@", userID)
                }
                let count = try viewContext.count(for: verifyRequest)
                print("[SubscriptionStore] Verification - Total subscriptions after save: \(count)")
                
            } catch let error as NSError {
                AppLogger.error("Failed to save context: \(error)", category: "SubscriptionStore")
                print("[SubscriptionStore] Error userInfo: \(error.userInfo)")
                print("[SubscriptionStore] Error code: \(error.code)")
                
                // Try to recover by resetting the context
                viewContext.rollback()
                print("[SubscriptionStore] Context rolled back")
            }
        } else {
            print("[SubscriptionStore] No changes to save")
        }
    }
    
    private func saveContextPrivate() {
        saveContext()
    }
    
    // MARK: - Subscription Type Management
    
    func convertTrialToPaid(_ subscription: Subscription, newEndDate: Date? = nil, billingCycle: String = "monthly") {
        subscription.subscriptionType = SubscriptionType.paid.rawValue
        subscription.isTrial = false
        subscription.convertedToPaid = Date()
        
        // Update end date for the paid subscription
        if let newDate = newEndDate {
            subscription.endDate = newDate
        } else {
            // Default to adding one month if no date provided
            subscription.endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        }
        
        // Update billing cycle
        subscription.billingCycle = billingCycle
        
        // Ensure status is active
        subscription.status = SubscriptionStatus.active.rawValue
        
        saveContext()
        fetchSubscriptions()
        
        // Update notifications for paid subscription
        NotificationManager.shared.removeNotifications(for: subscription)
        NotificationManager.shared.scheduleNotifications(for: subscription)
        
        // Update calendar event
        CalendarManager.shared.addOrUpdateEvent(for: subscription)
        
        // Track conversion analytics
        let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: subscription.startDate ?? Date(),
            to: Date()
        ).day ?? 0
        
        AnalyticsManager.shared.track(.subscriptionKept, properties: AnalyticsProperties(
            source: "trial_conversion",
            subscriptionName: subscription.name ?? ""
        ))
        
        // Update cost calculations
        costEngine.refreshMetrics()
    }
    
    // Get subscriptions by type
    func getSubscriptions(ofType type: SubscriptionType) -> [Subscription] {
        return allSubscriptions.filter { $0.subscriptionType == type.rawValue }
    }
    
    var trialSubscriptions: [Subscription] {
        return getSubscriptions(ofType: .trial)
    }
    
    var paidSubscriptions: [Subscription] {
        return getSubscriptions(ofType: .paid)
    }
    
    var promotionalSubscriptions: [Subscription] {
        return getSubscriptions(ofType: .promotional)
    }
    
    // MARK: - Memory Management
    
    /// Clear in-memory caches to free up memory
    func clearCaches() {
        AppLogger.log("Clearing caches due to memory pressure", category: "SubscriptionStore")
        // Note: Don't clear @Published arrays as they're needed for UI
        // Only clear cached computations if they exist
        // The cost engine maintains its own caches
        costEngine.clearCaches()
    }
}
