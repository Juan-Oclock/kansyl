//
//  PremiumFeaturesView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct PremiumFeaturesView: View {
    @ObservedObject var appPreferences = AppPreferences.shared
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPlan = PremiumPlan.yearly
    @State private var showingPurchaseAlert = false
    
    enum PremiumPlan: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
        case lifetime = "lifetime"
        
        var price: String {
            switch self {
            case .monthly: return "$2.99"
            case .yearly: return "$19.99"
            case .lifetime: return "$49.99"
            }
        }
        
        var duration: String {
            switch self {
            case .monthly: return "per month"
            case .yearly: return "per year"
            case .lifetime: return "one time"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 44%"
            case .lifetime: return "Best Value"
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
        .alert(isPresented: $showingPurchaseAlert) {
            Alert(
                title: Text("Coming Soon"),
                message: Text("Premium features will be available in the next update. Stay tuned!"),
                dismissButton: .default(Text("OK"))
            )
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
                
                Text("Get the most out of Kansyl with advanced features")
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
                    description: "Track unlimited free trials",
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
                    title: "iCloud Backup",
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
        Button(action: { showingPurchaseAlert = true }) {
            VStack(spacing: 4) {
                Text("Start Free Trial")
                    .font(.headline)
                Text("7 days free, then \(selectedPlan.price) \(selectedPlan.duration)")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
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
                    if let url = URL(string: "https://kansyl.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                
                Button("Terms of Service") {
                    if let url = URL(string: "https://kansyl.app/terms") {
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
