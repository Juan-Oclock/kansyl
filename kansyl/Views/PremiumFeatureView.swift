//
//  PremiumFeatureView.swift
//  kansyl
//
//  Premium upgrade view that handles subscription limits
//

import SwiftUI
import StoreKit

struct PremiumFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var userStateManager = UserStateManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    
    var isForSubscriptionLimit: Bool = false
    var currentCount: Int = 0
    
    @State private var selectedPlan = "yearly"
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSignInRequired = false
    @State private var showingSignInSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header Section
                        headerSection
                        
                        // Features List
                        featuresSection
                        
                        // Pricing Plans
                        pricingSection
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Terms
                        termsSection
                        
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
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
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSignInSheet) {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(userStateManager)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "FFD700").opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                if isForSubscriptionLimit {
                    Text("Subscription Limit Reached")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("You've reached the free limit of \(PremiumManager.freeSubscriptionLimit) subscriptions")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Current status
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("\(currentCount) of \(PremiumManager.freeSubscriptionLimit) subscriptions used")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.top, 8)
                } else {
                    Text("Unlock Premium")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("Get unlimited access to all features")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("What's Included")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                PremiumFeatureRow(
                    icon: "infinity",
                    title: "Unlimited Subscriptions",
                    description: "Track as many as you need",
                    isHighlighted: isForSubscriptionLimit
                )
                
                PremiumFeatureRow(
                    icon: "camera.viewfinder",
                    title: "AI Receipt Scanning",
                    description: "Already available to all users",
                    isHighlighted: false
                )
                
                PremiumFeatureRow(
                    icon: "bell.badge.fill",
                    title: "Smart Reminders",
                    description: "Never miss a cancellation",
                    isHighlighted: false
                )
                
                PremiumFeatureRow(
                    icon: "icloud.and.arrow.up",
                    title: "iCloud Sync",
                    description: "Access on all your devices",
                    isHighlighted: false
                )
                
                PremiumFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Track your savings over time",
                    isHighlighted: false
                )
                
                PremiumFeatureRow(
                    icon: "heart.fill",
                    title: "Priority Support",
                    description: "Get help when you need it",
                    isHighlighted: false
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Monthly Plan
            PremiumPlanCard(
                title: "Monthly",
                price: premiumManager.getMonthlyPrice() ?? "$2.99",
                period: "/month",
                isSelected: selectedPlan == "monthly",
                onTap: { selectedPlan = "monthly" }
            )
            
            // Yearly Plan
            PremiumPlanCard(
                title: "Yearly",
                price: premiumManager.getYearlyPrice() ?? "$19.99",
                period: "/year",
                badge: "SAVE 44%",
                isSelected: selectedPlan == "yearly",
                isPopular: true,
                onTap: { selectedPlan = "yearly" }
            )
            
            // Lifetime Plan (if needed in future)
            /*
            PlanCard(
                title: "Lifetime",
                price: "$49.99",
                period: "one time",
                badge: "BEST VALUE",
                isSelected: selectedPlan == "lifetime",
                onTap: { selectedPlan = "lifetime" }
            )
            */
        }
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button(action: {
            print("🛒 [PremiumFeatureView] Purchase button tapped")
            print("🔐 [PremiumFeatureView] isAuthenticated: \(authManager.isAuthenticated)")
            print("👤 [PremiumFeatureView] isAnonymousMode: \(userStateManager.isAnonymousMode)")
            
            // Check if user is authenticated FIRST
            if !authManager.isAuthenticated || userStateManager.isAnonymousMode {
                print("⚠️ [PremiumFeatureView] User not authenticated, showing sign-in prompt")
                showingSignInRequired = true
                return
            }
            
            Task {
                isPurchasing = true
                HapticManager.shared.playButtonTap()
                
                await premiumManager.purchase(yearly: selectedPlan == "yearly")
                
                isPurchasing = false
                
                // Handle purchase result
                switch premiumManager.purchaseState {
                case .purchased:
                    HapticManager.shared.playSuccess()
                    if premiumManager.isPremium {
                        dismiss()
                    }
                case .failed(let error):
                    HapticManager.shared.playError()
                    
                    // Check if it's a simulator error
                    if let premiumError = error as? PremiumError, premiumError == .simulatorNotSupported {
                        errorMessage = "In-app purchases are not supported on the iOS Simulator. Please test on a real device or use the DEBUG button below to enable test premium."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    showingError = true
                case .idle:
                    // User cancelled, no error needed
                    break
                case .loading:
                    break
                }
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    // Show different text based on authentication status
                    let buttonText = (authManager.isAuthenticated && !userStateManager.isAnonymousMode) 
                        ? "Continue to Upgrade" 
                        : "Upgrade to Premium"
                    Text(buttonText)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "0F172A"), Color(hex: "1E293B")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            // DEBUG test premium bypass - DISABLED
            // #if DEBUG
            // #if targetEnvironment(simulator)
            // // Simulator testing bypass
            // Button(action: {
            //     Task {
            //         await premiumManager.enableTestPremium()
            //         dismiss()
            //     }
            // }) {
            //     VStack(spacing: 4) {
            //         HStack(spacing: 6) {
            //             Image(systemName: "wrench.and.screwdriver.fill")
            //                 .font(.system(size: 12))
            //             Text("Enable Test Premium (Simulator Only)")
            //                 .font(.system(size: 12, weight: .semibold))
            //         }
            //         Text("Bypass purchase for testing - this only works on simulator")
            //             .font(.system(size: 10))
            //             .foregroundColor(.orange.opacity(0.8))
            //     }
            //     .foregroundColor(.orange)
            //     .padding(.horizontal, 16)
            //     .padding(.vertical, 10)
            //     .background(
            //         RoundedRectangle(cornerRadius: 12)
            //             .fill(Color.orange.opacity(0.15))
            //             .overlay(
            //                 RoundedRectangle(cornerRadius: 12)
            //                     .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            //             )
            //     )
            // }
            // .padding(.bottom, 8)
            // #else
            // // Real device testing info
            // Text("Testing in sandbox mode - use your Apple ID")
            //     .font(.system(size: 11))
            //     .foregroundColor(.orange)
            //     .padding(.bottom, 4)
            // #endif
            // #endif
            
            Text("Cancel anytime. No hidden fees.")
                .font(.system(size: 13))
                .foregroundColor(Design.Colors.textSecondary)
            
            HStack(spacing: 16) {
                Button("Restore Purchases") {
                    Task {
                        await premiumManager.restore()
                        if premiumManager.isPremium {
                            dismiss()
                        }
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Design.Colors.primary)
                
                Button("Terms") {
                    if let url = URL(string: "https://kansyl.juan-oclock.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Design.Colors.primary)
                
                Button("Privacy") {
                    if let url = URL(string: "https://kansyl.juan-oclock.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Design.Colors.primary)
            }
        }
    }
}

// MARK: - Supporting Views
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isHighlighted ? .orange : Color(hex: "3B82F6"))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Design.Colors.textSecondary)
            }
            
            Spacer()
            
            if isHighlighted {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
        }
    }
}

struct PremiumPlanCard: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    var isSelected: Bool
    var isPopular: Bool = false
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            if let badge = badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(isPopular ? Color(hex: "22C55E") : Color(hex: "3B82F6"))
                                    )
                            }
                        }
                        
                        HStack(spacing: 2) {
                            Text(price)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            Text(period)
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? Color(hex: "22C55E") : Design.Colors.textTertiary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color(hex: "22C55E") : Design.Colors.border.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
                
                if isPopular {
                    VStack {
                        HStack {
                            Spacer()
                            Text("MOST POPULAR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color(hex: "22C55E")
                                        .premiumCornerRadius(6, corners: [.topRight, .bottomLeft])
                                )
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Corner radius extension
extension View {
    func premiumCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(PremiumRoundedCorner(radius: radius, corners: corners))
    }
}

struct PremiumRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Preview
struct PremiumFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumFeatureView(isForSubscriptionLimit: true, currentCount: 5)
    }
}