//
//  PremiumManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import StoreKit

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    
    // Check if running on simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // Premium limits - New freemium model: All features available, subscription limit only
    static let freeSubscriptionLimit = 5 // Free users limited to 5 subscriptions
    static let premiumSubscriptionLimit = Int.max // Premium users have unlimited subscriptions
    
    // Product identifiers
    private let premiumProductId = "com.kansyl.premium"
    private let premiumYearlyProductId = "com.kansyl.premium.yearly"
    
    private var products: [Product] = []
    private var purchaseTask: Task<Void, Error>?
    
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchased
        case failed(Error)
        
        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.purchased, .purchased):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    init() {
        // DISABLED: ALL StoreKit initialization to prevent freezing
        // when user is not signed into App Store
        // Both Product.products and Transaction.currentEntitlements can hang
        print("⚠️ [PremiumManager] StoreKit initialization disabled to prevent freezing")
        print("⚠️ [PremiumManager] Defaulting to free tier (5 subscriptions max)")
        
        // Set default to non-premium
        isPremium = false
        
        // StoreKit will only be accessed when user explicitly tries to purchase
        // This prevents any hanging at app startup or in Settings
    }
    
    @MainActor
    func loadProducts() async {
        // Add protection against hanging
        do {
            // Use timeout to prevent hanging when not signed into App Store
            try await withTimeout(seconds: 2.0) {
                self.products = try await Product.products(for: [self.premiumProductId, self.premiumYearlyProductId])
            }
            print("✅ [PremiumManager] Products loaded successfully")
        } catch {
            print("⚠️ [PremiumManager] Failed to load products: \(error.localizedDescription)")
            products = [] // Ensure products array is empty on failure
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        var hasPremium = false
        
        // CRITICAL FIX: Skip StoreKit entirely if it's going to hang
        // This prevents app freezing when user is not signed into App Store
        print("💰 [PremiumManager] Checking premium status...")
        
        // Quick check: Try to access transactions with immediate timeout
        let checkTask = Task {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                if transaction.productID == self.premiumProductId || 
                   transaction.productID == self.premiumYearlyProductId {
                    return true
                }
            }
            return false
        }
        
        // Give it only 0.5 seconds before cancelling
        do {
            hasPremium = try await withTimeout(seconds: 0.5) {
                return await checkTask.value
            }
            print("✅ [PremiumManager] Successfully checked entitlements: isPremium = \(hasPremium)")
        } catch {
            // Cancel the hanging task
            checkTask.cancel()
            
            print("⚠️ [PremiumManager] StoreKit check timed out or failed: \(error.localizedDescription)")
            print("⚠️ [PremiumManager] This usually means you're not signed into the App Store")
            print("⚠️ [PremiumManager] Defaulting to free tier (5 subscriptions max)")
            hasPremium = false
        }
        
        isPremium = hasPremium
    }
    
    // Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw PremiumError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func observeTransactionUpdates() {
        // DISABLED: This causes freezing when user is not signed into App Store
        // Transaction.updates hangs indefinitely waiting for App Store connection
        // Will be called manually after successful purchase instead
        print("⚠️ [PremiumManager] Transaction observer disabled to prevent freezing")
    }
    
    @MainActor
    func purchase(yearly: Bool = false) async {
        purchaseState = .loading
        
        // Check if running on simulator FIRST (before checking products)
        if isSimulator {
            print("⚠️ [PremiumManager] Simulator detected, cannot proceed with purchase")
            purchaseState = .failed(PremiumError.simulatorNotSupported)
            return
        }
        
        // On real device, check if products are loaded
        let productId = yearly ? premiumYearlyProductId : premiumProductId
        var product = products.first(where: { $0.id == productId })
        
        if product == nil {
            print("⚠️ [PremiumManager] Product not found: \(productId)")
            print("⚠️ [PremiumManager] Available products: \(products.map { $0.id })")
            
            // Try to reload products
            await loadProducts()
            
            // Check again
            product = products.first(where: { $0.id == productId })
            
            guard product != nil else {
                purchaseState = .failed(PremiumError.productNotFound)
                return
            }
            
            print("✅ [PremiumManager] Product found after reload")
        }
        
        do {
            let result = try await product!.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                    purchaseState = .purchased
                case .unverified:
                    purchaseState = .failed(PremiumError.unverifiedTransaction)
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }
    
    @MainActor
    func restore() async {
        purchaseState = .loading
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            purchaseState = isPremium ? .purchased : .idle
        } catch {
            purchaseState = .failed(error)
        }
    }
    
    // Subscription limit checks - New freemium model
    func canAddMoreSubscriptions(currentCount: Int) -> Bool {
        return isPremium || currentCount < Self.freeSubscriptionLimit
    }
    
    func getRemainingSubscriptions(currentCount: Int) -> Int {
        if isPremium {
            return Int.max // Unlimited
        } else {
            return max(0, Self.freeSubscriptionLimit - currentCount)
        }
    }
    
    func getSubscriptionLimitMessage(currentCount: Int) -> String {
        if isPremium {
            return "Unlimited subscriptions"
        } else {
            let remaining = getRemainingSubscriptions(currentCount: currentCount)
            if remaining == 0 {
                return "Free limit reached (\(Self.freeSubscriptionLimit) subscriptions)"
            } else {
                return "\(remaining) of \(Self.freeSubscriptionLimit) subscriptions remaining"
            }
        }
    }
    
    // Legacy method for backward compatibility - will be removed
    func canAddMoreTrials(currentCount: Int) -> Bool {
        return canAddMoreSubscriptions(currentCount: currentCount)
    }
    
    // Development/Testing helper - Enable premium for testing on simulator
    #if DEBUG
    @MainActor
    func enableTestPremium() {
        isPremium = true
        purchaseState = .purchased
        print("[PremiumManager] Test premium enabled for development")
    }
    
    @MainActor
    func disableTestPremium() {
        isPremium = false
        purchaseState = .idle
        print("[PremiumManager] Test premium disabled")
    }
    #endif
    
    func getMonthlyPrice() -> String? {
        guard let product = products.first(where: { $0.id == premiumProductId }) else {
            return nil
        }
        return product.displayPrice
    }
    
    func getYearlyPrice() -> String? {
        guard let product = products.first(where: { $0.id == premiumYearlyProductId }) else {
            return nil
        }
        return product.displayPrice
    }
}

enum PremiumError: LocalizedError, Equatable {
    case productNotFound
    case unverifiedTransaction
    case simulatorNotSupported
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Premium product not found"
        case .unverifiedTransaction:
            return "Transaction could not be verified"
        case .simulatorNotSupported:
            return "In-App Purchases are not supported on iOS Simulator. Please test on a real device or use the development bypass option."
        case .timeout:
            return "StoreKit connection timeout. Please sign into the App Store and try again."
        }
    }
}
