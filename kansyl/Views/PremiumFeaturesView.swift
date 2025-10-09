//
//  PremiumFeaturesView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct PremiumFeaturesView: View {
    @ObservedObject var appPreferences = AppPreferences.shared
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var userStateManager = UserStateManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPlan = PremiumPlan.yearly
    @State private var showingPurchaseAlert = false
    @State private var showingSignInRequired = false
    @State private var showingSignInSheet = false
    @State private var isPurchasing = false
    @State private var purchaseErrorMessage = ""
    @State private var wasUnauthenticated = false
    @State private var showSignInToast = false
    
    enum PremiumPlan: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
        // case lifetime = "lifetime"  // TODO: Add in v1.1
        
        var price: String {
            switch self {
            case .monthly: return "$2.99"
            case .yearly: return "$19.99"
            // case .lifetime: return "$49.99"
            }
        }
        
        var duration: String {
            switch self {
            case .monthly: return "per month"
            case .yearly: return "per year"
            // case .lifetime: return "one time"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 44%"
            // case .lifetime: return "Best Value"
            }
        }
        
        var isPopular: Bool {
            self == .yearly
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features Comparison
                    featuresSection
                    
                    // Pricing Plans
                    pricingSection
                    
                    // Purchase Button
                    purchaseButton
                    
                    // Terms
                    termsSection
                }
                .padding()
            }
            .background((colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background).ignoresSafeArea())
            .navigationTitle("Kansyl Premium")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            Task {
                print("📱 [PremiumFeaturesView] View appeared, checking auth state")
                print("🔐 [PremiumFeaturesView] Current isAuthenticated: \(authManager.isAuthenticated)")
                print("👤 [PremiumFeaturesView] Current user: \(authManager.currentUser?.id.uuidString ?? "nil")")
                
                // Refresh auth state when view appears
                await authManager.checkExistingSession()
                
                print("✅ [PremiumFeaturesView] Auth state refreshed on view appear")
                print("🔐 [PremiumFeaturesView] Updated isAuthenticated: \(authManager.isAuthenticated)")
            }
        }
        .alert("Sign In Required", isPresented: $showingSignInRequired) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                showingSignInSheet = true
            }
        } message: {
            Text("You need to sign in or create an account before purchasing premium features. This ensures your purchase is linked to your account.")
        }
        .alert("Purchase Error", isPresented: $showingPurchaseAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .sheet(isPresented: $showingSignInSheet) {
            LoginView()
                .environmentObject(authManager)
                .environmentObject(userStateManager)
        }
        .overlay(
            VStack {
                SuccessToastView(
                    message: "Signed in! You can complete your purchase now.",
                    savedAmount: nil,
                    isShowing: $showSignInToast
                )
                .padding(.top, 50)

                Spacer()
            }
            .zIndex(1002)
        )
        .onAppear {
            // Track if user was unauthenticated when view appeared
            wasUnauthenticated = !authManager.isAuthenticated
            print("🎫 [PremiumFeaturesView] View appeared - wasUnauthenticated: \(wasUnauthenticated)")
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            print("🔄 [PremiumFeaturesView] Authentication changed - isAuthenticated: \(isAuthenticated), wasUnauthenticated: \(wasUnauthenticated)")
            // If user was unauthenticated and now is authenticated, keep the premium sheet open
            // Close the login sheet and show a confirmation toast so the user can continue purchase
            if wasUnauthenticated && isAuthenticated {
                print("✅ [PremiumFeaturesView] User signed in - keeping premium view open and showing confirmation toast")
                showingSignInSheet = false
                showSignInToast = true
                wasUnauthenticated = false
                HapticManager.shared.playSuccess()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .background(
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(width: 100, height: 100)
                )
            
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(.system(.largeTitle, design: .default).weight(.bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text("Track unlimited subscriptions and access all premium features")
                    .font(.body)
                    .foregroundColor(Design.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .foregroundColor(Design.Colors.textPrimary)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Entry",
                    description: "Track unlimited subscriptions",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "doc.text.viewfinder",
                    title: "Scan Receipt with AI",
                    description: "AI-powered receipt scanning",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "mic.fill",
                    title: "Siri Shortcuts",
                    description: "Voice control for trials",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "bell.badge.waveform",
                    title: "Smart Notifications",
                    description: "Advanced reminder system",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Calendar Integration",
                    description: "Sync with Apple Calendar",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Subscription History",
                    description: "Complete trial history",
                    isFree: false,
                    isPremium: true
                )
                
                FeatureRow(
                    icon: "icloud.and.arrow.up",
                    title: "Cloud Sync",
                    description: "Sync across all devices",
                    isFree: false,
                    isPremium: true
                )
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(Design.Colors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(PremiumPlan.allCases, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onTap: { selectedPlan = plan }
                    )
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                
                VStack(spacing: 4) {
                    Text(isPurchasing ? "Processing..." : "Start Premium")
                        .font(.headline)
                    if !isPurchasing {
                        Text(selectedPlan.price + " " + selectedPlan.duration)
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: isPurchasing ? [Color.gray, Color.gray] : [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Purchase Handler
    private func handlePurchase() {
        print("🛒 [PremiumFeaturesView] Purchase button tapped")
        print("🔐 [PremiumFeaturesView] Initial isAuthenticated: \(authManager.isAuthenticated)")
        print("👤 [PremiumFeaturesView] isAnonymousMode: \(userStateManager.isAnonymousMode)")
        print("👤 [PremiumFeaturesView] currentUser: \(authManager.currentUser?.id.uuidString ?? "nil")")
        
        // Re-validate session before checking authentication
        Task {
            print("🔄 [PremiumFeaturesView] Re-validating session before purchase...")
            await authManager.checkExistingSession()
            
            await MainActor.run {
                print("✅ [PremiumFeaturesView] Session validation complete")
                print("🔐 [PremiumFeaturesView] Updated isAuthenticated: \(authManager.isAuthenticated)")
                print("👤 [PremiumFeaturesView] Updated currentUser: \(authManager.currentUser?.id.uuidString ?? "nil")")
                
                // Check if user is authenticated after session validation
                if !authManager.isAuthenticated {
                    print("⚠️ [PremiumFeaturesView] User not authenticated after session check, showing sign-in prompt")
                    showingSignInRequired = true
                    return
                }
                
                // Proceed with purchase
                print("✅ [PremiumFeaturesView] User authenticated, initiating purchase")
                isPurchasing = true
                
                Task {
                    await performPurchase()
                }
            }
        }
    }
    
    private func performPurchase() async {
        let isYearly = selectedPlan == .yearly
        await premiumManager.purchase(yearly: isYearly)
        
        await MainActor.run {
            isPurchasing = false
            
            switch premiumManager.purchaseState {
            case .purchased:
                print("✅ [PremiumFeaturesView] Purchase successful")
                presentationMode.wrappedValue.dismiss()
            case .failed(let error):
                print("❌ [PremiumFeaturesView] Purchase failed: \(error.localizedDescription)")
                
                // Check if it's a simulator error
                if let premiumError = error as? PremiumError, premiumError == .simulatorNotSupported {
                    purchaseErrorMessage = "In-app purchases are not supported on the iOS Simulator. Please test on a real device or use the DEBUG toggle in Settings to enable test premium."
                } else {
                    purchaseErrorMessage = error.localizedDescription
                }
                
                showingPurchaseAlert = true
            case .idle:
                print("ℹ️ [PremiumFeaturesView] Purchase cancelled or pending")
            default:
                break
            }
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Terms & Conditions")
                .font(.caption)
                .foregroundColor(Design.Colors.textSecondary)
            
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    if let url = URL(string: "https://kansyl.juan-oclock.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                
                Button("Terms of Service") {
                    if let url = URL(string: "https://kansyl.juan-oclock.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                
                Button("Restore Purchases") {
                    // Restore purchases
                }
                .font(.caption)
            }
        }
        .padding(.top)
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isFree: Bool
    let isPremium: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .default).weight(.medium))
                    .foregroundColor(Design.Colors.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Design.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isFree {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if isPremium {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
    }
}

struct PlanCard: View {
    let plan: PremiumFeaturesView.PremiumPlan
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.system(.caption2, design: .default).weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.duration)
                        .font(.caption)
                        .foregroundColor(Design.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(.title3, design: .default).weight(.bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct PremiumFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumFeaturesView()
    }
}
