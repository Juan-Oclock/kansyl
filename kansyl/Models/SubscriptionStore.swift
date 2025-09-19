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
    static let shared = SubscriptionStore(context: PersistenceController.shared.container.viewContext)
    
    let viewContext: NSManagedObjectContext
    let costEngine: CostCalculationEngine
    
    @Published var activeSubscriptions: [Subscription] = []
    @Published var endingSoonSubscriptions: [Subscription] = []
    @Published var allSubscriptions: [Subscription] = []
    @Published var recentlyEndedSubscriptions: [Subscription] = []
    
    // Current user ID for data isolation
    @Published var currentUserID: String? {
        didSet {
            fetchSubscriptions()
        }
    }
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, userID: String? = nil) {
        self.viewContext = context
        self.costEngine = CostCalculationEngine(context: context)
        self.currentUserID = userID
        fetchSubscriptions()
    }
    
    // MARK: - Fetch Operations
    
    func fetchSubscriptions() {
        guard let userID = currentUserID else {
            // No user logged in, clear all subscriptions
            DispatchQueue.main.async { [weak self] in
                self?.allSubscriptions = []
                self?.updateSubscriptionCategories()
            }
            return
        }
        
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        
        do {
            let subscriptions = try viewContext.fetch(request)
            DispatchQueue.main.async { [weak self] in
                self?.allSubscriptions = subscriptions
                self?.updateSubscriptionCategories()
            }
        } catch {
            // Failed to fetch subscriptions
        }
    }
    
    private func updateSubscriptionCategories() {
        let now = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        
        activeSubscriptions = allSubscriptions.filter { subscription in
            subscription.status == SubscriptionStatus.active.rawValue && 
            (subscription.endDate ?? Date()) > now
        }
        
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
                  originalAmount: Double? = nil, exchangeRate: Double? = nil) -> Subscription? {
        
        guard let userID = currentUserID else {
            return nil
        }
        
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
        
        saveContext()
        fetchSubscriptions()
        
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
        costEngine.refreshMetrics()
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
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Failed to save context
            }
        }
    }
    
    private func saveContextPrivate() {
        saveContext()
    }
}