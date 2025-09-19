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
    static let freeSubscriptionLimit = 7 // Free users can track up to 7 subscriptions
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
            return "\(remaining) of \(Self.freeSubscriptionLimit) subscriptions remaining"
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

// MARK: - Premium Feature View
struct PremiumFeatureView: View {
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPlan: PremiumPlan = .monthly
    @State private var showingPurchaseError = false
    
    enum PremiumPlan {
        case monthly
        case yearly
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection
                    purchaseButton
                    restoreButton
                    termsSection
                }
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showingPurchaseError) {
            Alert(
                title: Text("Purchase Failed"),
                message: Text(getPurchaseErrorMessage()),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(premiumManager.$purchaseState) { state in
            switch state {
            case .purchased:
                presentationMode.wrappedValue.dismiss()
            case .failed:
                showingPurchaseError = true
            default:
                break
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Unlock Premium")
                            .font(.largeTitle.weight(.bold))
                        
                        Text("Get the most out of Kansyl")
                            .font(.title3)
                            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
                        PremiumFeatureRow(
                            icon: "infinity",
                            title: "Unlimited Trials",
                            description: "Track as many trials as you need"
                        )
                        
                        PremiumFeatureRow(
                            icon: "bell.badge",
                            title: "Advanced Notifications",
                            description: "Custom sounds and more reminder options"
                        )
                        
                        PremiumFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Detailed Analytics",
                            description: "Deep insights into your savings patterns"
                        )
                        
                        PremiumFeatureRow(
                            icon: "clock.badge.checkmark",
                            title: "Smart Scheduling",
                            description: "AI-powered trial recommendations"
                        )
                        
                        PremiumFeatureRow(
                            icon: "icloud.and.arrow.up",
                            title: "Cloud Backup",
                            description: "Never lose your trial data"
                        )
        }
        .padding(.horizontal)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
            
            HStack(spacing: 16) {
                            PricingCard(
                                title: "Monthly",
                                price: premiumManager.getMonthlyPrice() ?? "$2.99",
                                period: "per month",
                                isSelected: selectedPlan == .monthly,
                                action: { selectedPlan = .monthly }
                            )
                            
                            PricingCard(
                                title: "Yearly",
                                price: premiumManager.getYearlyPrice() ?? "$19.99",
                                period: "per year",
                                badge: "Save 44%",
                                isSelected: selectedPlan == .yearly,
                                action: { selectedPlan = .yearly }
                            )
            }
            .padding(.horizontal)
        }
    }
    
    private var purchaseButton: some View {
        Button(action: purchasePremium) {
            HStack {
                            if premiumManager.purchaseState == .loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Upgrade Now")
                                    .font(.body.weight(.semibold))
                            }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor)
            )
        }
        .padding(.horizontal, 40)
        .disabled(premiumManager.purchaseState == .loading)
    }
    
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await premiumManager.restore()
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://kansyl.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://kansyl.app/privacy")!)
            }
            .font(.caption2)
        }
    }
    
    private func purchasePremium() {
        Task {
            await premiumManager.purchase(yearly: selectedPlan == .yearly)
        }
    }
    
    private func getPurchaseErrorMessage() -> String {
        if case .failed(let error) = premiumManager.purchaseState {
            return error.localizedDescription
        }
        return "An unknown error occurred"
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, price: String, period: String, badge: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.period = period
        self.badge = badge
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                        )
                }
                
                Text(title)
                    .font(.headline)
                
                Text(price)
                    .font(.title2.weight(.bold))
                
                Text(period)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
