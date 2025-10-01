//
//  UserStateManager.swift
//  kansyl
//
//  Created on 10/1/25.
//  Manages user state: anonymous, signed in free, or premium
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// User state types
enum UserState {
    case anonymous
    case signedInFree
    case signedInPremium
}

/// Limit check results
enum SubscriptionLimitStatus {
    case allowed
    case needsAccount          // Anonymous user hit 5-sub limit
    case needsPremium          // Signed-in free user hit 5-sub limit
}

/// Manages user state and subscription limits
class UserStateManager: ObservableObject {
    static let shared = UserStateManager()
    
    // MARK: - Published Properties
    @Published var userState: UserState = .anonymous
    @Published var subscriptionCount: Int = 0
    @Published var isAnonymousMode: Bool = false
    
    // MARK: - Constants
    let anonymousSubscriptionLimit: Int = 5
    private let ANONYMOUS_MODE_KEY = "isAnonymousMode"
    private let ANONYMOUS_USER_ID_KEY = "anonymousUserID"
    
    // MARK: - Initialization
    private init() {
        loadAnonymousState()
    }
    
    // MARK: - Anonymous Mode Management
    
    /// Check if user is in anonymous mode
    func loadAnonymousState() {
        isAnonymousMode = UserDefaults.standard.bool(forKey: ANONYMOUS_MODE_KEY)
        
        // If in anonymous mode, restore the anonymous user ID to SubscriptionStore
        if isAnonymousMode {
            if let anonymousID = getAnonymousUserID() {
                SubscriptionStore.currentUserID = anonymousID
                print("✅ [UserStateManager] Restored anonymous mode with ID: \(anonymousID)")
            } else {
                // Anonymous mode flag is set but no ID exists - create one
                print("⚠️ [UserStateManager] Anonymous mode flag set but no ID found, creating new ID")
                enableAnonymousMode()
            }
        }
    }
    
    /// Enable anonymous mode (user chose to skip sign-in)
    func enableAnonymousMode() {
        let anonymousID = UUID().uuidString
        UserDefaults.standard.set(true, forKey: ANONYMOUS_MODE_KEY)
        UserDefaults.standard.set(anonymousID, forKey: ANONYMOUS_USER_ID_KEY)
        
        // Update UI properties on main thread
        DispatchQueue.main.async { [weak self] in
            self?.isAnonymousMode = true
            self?.userState = .anonymous
        }
        
        // CRITICAL: Set the SubscriptionStore's currentUserID so subscriptions can be saved
        // This MUST happen synchronously, not async
        SubscriptionStore.currentUserID = anonymousID
        
        print("✅ [UserStateManager] Anonymous mode enabled with ID: \(anonymousID)")
        print("✅ [UserStateManager] SubscriptionStore userID set to: \(anonymousID)")
        print("✅ [UserStateManager] Verification - SubscriptionStore.currentUserID = \(SubscriptionStore.currentUserID ?? "nil")")
    }
    
    /// Alias for enableAnonymousMode (for compatibility)
    func enterAnonymousMode() {
        enableAnonymousMode()
    }
    
    /// Disable anonymous mode (user created account)
    func disableAnonymousMode() {
        UserDefaults.standard.removeObject(forKey: ANONYMOUS_MODE_KEY)
        UserDefaults.standard.removeObject(forKey: ANONYMOUS_USER_ID_KEY)
        isAnonymousMode = false
        print("✅ [UserStateManager] Anonymous mode disabled")
    }
    
    /// Alias for disableAnonymousMode (for compatibility)
    func exitAnonymousMode() {
        disableAnonymousMode()
    }
    
    /// Get anonymous user ID
    func getAnonymousUserID() -> String? {
        return UserDefaults.standard.string(forKey: ANONYMOUS_USER_ID_KEY)
    }
    
    // MARK: - User State Updates
    
    /// Update user state based on auth and premium status
    func updateUserState(isAuthenticated: Bool, isPremium: Bool) {
        if !isAuthenticated && isAnonymousMode {
            userState = .anonymous
        } else if isAuthenticated && !isPremium {
            userState = .signedInFree
        } else if isAuthenticated && isPremium {
            userState = .signedInPremium
        } else {
            // Default to anonymous if not authenticated
            userState = .anonymous
        }
        
        print("📊 [UserStateManager] User state updated to: \(userState)")
    }
    
    // MARK: - Subscription Limit Checking
    
    /// Update subscription count
    func updateSubscriptionCount(_ count: Int) {
        subscriptionCount = count
    }
    
    /// Check if user can add a new subscription
    func canAddSubscription() -> Bool {
        switch userState {
        case .anonymous, .signedInFree:
            return subscriptionCount < anonymousSubscriptionLimit
        case .signedInPremium:
            return true // unlimited
        }
    }
    
    /// Check subscription limit and return status
    func checkSubscriptionLimit() -> SubscriptionLimitStatus {
        if subscriptionCount >= anonymousSubscriptionLimit {
            switch userState {
            case .anonymous:
                return .needsAccount
            case .signedInFree:
                return .needsPremium
            case .signedInPremium:
                return .allowed // shouldn't reach here
            }
        }
        return .allowed
    }
    
    /// Get remaining subscriptions in free tier
    func getRemainingFreeSubscriptions() -> Int {
        return max(0, anonymousSubscriptionLimit - subscriptionCount)
    }
    
    // MARK: - Data Migration
    
    /// Migrate anonymous user data to authenticated account
    func migrateAnonymousDataToAccount(
        viewContext: NSManagedObjectContext,
        newUserID: String
    ) async throws {
        print("🔄 [UserStateManager] Starting data migration for user: \(newUserID)")
        
        // 1. Fetch all subscriptions without a userID (anonymous subscriptions)
        let fetchRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userID == nil OR userID == %@", getAnonymousUserID() ?? "")
        
        do {
            let anonymousSubscriptions = try viewContext.fetch(fetchRequest)
            
            guard !anonymousSubscriptions.isEmpty else {
                print("ℹ️ [UserStateManager] No anonymous subscriptions to migrate")
                return
            }
            
            print("📦 [UserStateManager] Found \(anonymousSubscriptions.count) subscriptions to migrate")
            
            // 2. Assign new userID to all anonymous subscriptions
            for subscription in anonymousSubscriptions {
                subscription.userID = newUserID
            }
            
            // 3. Save changes
            try viewContext.save()
            
            // 4. Disable anonymous mode
            disableAnonymousMode()
            
            print("✅ [UserStateManager] Successfully migrated \(anonymousSubscriptions.count) subscriptions")
            
        } catch {
            print("❌ [UserStateManager] Migration failed: \(error.localizedDescription)")
            throw MigrationError.failed(error.localizedDescription)
        }
    }
}

// MARK: - Migration Error
enum MigrationError: LocalizedError {
    case failed(String)
    
    var errorDescription: String? {
        switch self {
        case .failed(let message):
            return "Migration failed: \(message)"
        }
    }
}

// MARK: - UserState Description
extension UserState: CustomStringConvertible {
    var description: String {
        switch self {
        case .anonymous:
            return "Anonymous"
        case .signedInFree:
            return "Free Tier"
        case .signedInPremium:
            return "Premium"
        }
    }
}
