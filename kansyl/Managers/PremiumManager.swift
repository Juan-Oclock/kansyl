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
    
    // Premium limits - New freemium model: All features available, subscription limit only
    static let freeSubscriptionLimit = 5 // Free users can track up to 5 subscriptions
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
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
        
        // Listen for transaction updates
        observeTransactionUpdates()
    }
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: [premiumProductId, premiumYearlyProductId])
        } catch {
            // Debug: print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        var hasPremium = false
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.productID == premiumProductId || 
               transaction.productID == premiumYearlyProductId {
                hasPremium = true
                break
            }
        }
        
        isPremium = hasPremium
    }
    
    private func observeTransactionUpdates() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await updatePurchasedProducts()
                }
            }
        }
    }
    
    @MainActor
    func purchase(yearly: Bool = false) async {
        purchaseState = .loading
        
        let productId = yearly ? premiumYearlyProductId : premiumProductId
        guard let product = products.first(where: { $0.id == productId }) else {
            purchaseState = .failed(PremiumError.productNotFound)
            return
        }
        
        do {
            let result = try await product.purchase()
            
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

enum PremiumError: LocalizedError {
    case productNotFound
    case unverifiedTransaction
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Premium product not found"
        case .unverifiedTransaction:
            return "Transaction could not be verified"
        }
    }
}
