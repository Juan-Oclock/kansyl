//
//  TrialConversionView.swift
//  kansyl
//
//  Created on 9/29/25.
//

import SwiftUI
import CoreData

struct TrialConversionView: View {
    @ObservedObject var subscription: Subscription
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPlan: BillingPlan = .monthly
    @State private var customEndDate = Date()
    @State private var showingDatePicker = false
    @State private var isConverting = false
    
    enum BillingPlan: String, CaseIterable {
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case custom = "Custom"
        
        var months: Int {
            switch self {
            case .monthly: return 1
            case .quarterly: return 3
            case .yearly: return 12
            case .custom: return 0
            }
        }
        
        var icon: String {
            switch self {
            case .monthly: return "calendar"
            case .quarterly: return "calendar.badge.plus"
            case .yearly: return "star.circle"
            case .custom: return "slider.horizontal.3"
            }
        }
        
        func displayPrice(monthlyPrice: Double, currencyCode: String) -> String {
            let totalPrice = monthlyPrice * Double(months)
            return CurrencyManager.shared.formatPrice(totalPrice, currencyCode: currencyCode)
        }
        
        func savings(monthlyPrice: Double) -> Double? {
            switch self {
            case .yearly:
                // Assume 10% discount for yearly
                return monthlyPrice * 12 * 0.1
            case .quarterly:
                // Assume 5% discount for quarterly
                return monthlyPrice * 3 * 0.05
            default:
                return nil
            }
        }
    }
    
    private var calculatedEndDate: Date {
        if selectedPlan == .custom {
            return customEndDate
        } else {
            return Calendar.current.date(
                byAdding: .month,
                value: selectedPlan.months,
                to: Date()
            ) ?? Date()
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Current Trial Info
                    currentTrialInfo
                    
                    // Billing Options
                    billingOptionsSection
                    
                    // Benefits
                    benefitsSection
                    
                    // Conversion Summary
                    conversionSummary
                }
                .padding()
            }
            .background(colorScheme == .dark ? Color(hex: "1A1A1A") : Design.Colors.background)
            .navigationTitle("Convert to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: convertToPremium) {
                        if isConverting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("Convert")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(Design.Colors.primary)
                    .disabled(isConverting)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $customEndDate)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Design.Colors.primary.opacity(0.1),
                                Design.Colors.primary.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Design.Colors.primary)
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Upgrade \(subscription.name ?? "Subscription")")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text("Convert your free trial to a premium subscription")
                    .font(.system(size: 15))
                    .foregroundColor(Design.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Current Trial Info
    private var currentTrialInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Trial")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Design.Colors.textSecondary)
                .textCase(.uppercase)
            
            HStack {
                // Service Logo
                if let serviceLogo = subscription.serviceLogo {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        Image.bundleImage(serviceLogo, fallbackSystemName: "app.badge")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name ?? "Unknown Service")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    HStack(spacing: 8) {
                        // Trial end date
                        if let endDate = subscription.endDate {
                            Label(
                                "Ends \(endDate.formatted(date: .abbreviated, time: .omitted))",
                                systemImage: "calendar"
                            )
                            .font(.system(size: 14))
                            .foregroundColor(Design.Colors.textSecondary)
                        }
                        
                        // Days remaining
                        let daysRemaining = subscriptionStore.daysRemaining(for: subscription)
                        Label(
                            "\(daysRemaining) days left",
                            systemImage: "clock"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(subscriptionStore.urgencyColor(for: subscription))
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
        }
    }
    
    // MARK: - Billing Options
    private var billingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Billing Period")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Design.Colors.textSecondary)
                .textCase(.uppercase)
            
            VStack(spacing: 8) {
                ForEach(BillingPlan.allCases, id: \.self) { plan in
                    BillingPlanRow(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        monthlyPrice: subscription.monthlyPrice,
                        currencyCode: userPreferences.currencyCode,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPlan = plan
                                if plan == .custom {
                                    showingDatePicker = true
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Benefits")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Design.Colors.textSecondary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 12) {
                TrialBenefitRow(icon: "checkmark.circle.fill", text: "Continued access to service", color: Design.Colors.success)
                TrialBenefitRow(icon: "bell.fill", text: "Smart renewal reminders", color: Design.Colors.primary)
                TrialBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Usage analytics & insights", color: .purple)
                TrialBenefitRow(icon: "shield.checkmark.fill", text: "Premium support", color: .blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Design.Colors.primary.opacity(0.05))
            )
        }
    }
    
    // MARK: - Conversion Summary
    private var conversionSummary: some View {
        VStack(spacing: 16) {
            // Summary details
            VStack(spacing: 8) {
                HStack {
                    Text("New billing cycle:")
                        .font(.system(size: 14))
                        .foregroundColor(Design.Colors.textSecondary)
                    Spacer()
                    Text(selectedPlan == .custom ? "Custom" : selectedPlan.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                }
                
                HStack {
                    Text("Next renewal:")
                        .font(.system(size: 14))
                        .foregroundColor(Design.Colors.textSecondary)
                    Spacer()
                    Text(calculatedEndDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                }
                
                if selectedPlan != .custom {
                    HStack {
                        Text("Amount:")
                            .font(.system(size: 14))
                            .foregroundColor(Design.Colors.textSecondary)
                        Spacer()
                        Text(selectedPlan.displayPrice(
                            monthlyPrice: subscription.monthlyPrice,
                            currencyCode: userPreferences.currencyCode
                        ))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    }
                }
                
                if let savings = selectedPlan.savings(monthlyPrice: subscription.monthlyPrice) {
                    HStack {
                        Text("You save:")
                            .font(.system(size: 14))
                            .foregroundColor(Design.Colors.textSecondary)
                        Spacer()
                        Text(CurrencyManager.shared.formatPrice(savings, currencyCode: userPreferences.currencyCode))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Design.Colors.success)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: convertToPremium) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Convert to Premium")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Design.Colors.primary, Design.Colors.primary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isConverting)
                
                Button(action: { dismiss() }) {
                    Text("Keep as Trial")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func convertToPremium() {
        isConverting = true
        
        // Perform conversion
        subscriptionStore.convertTrialToPaid(
            subscription,
            newEndDate: calculatedEndDate,
            billingCycle: selectedPlan == .custom ? "custom" : selectedPlan.rawValue.lowercased()
        )
        
        // Haptic feedback
        HapticManager.shared.playSuccess()
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct BillingPlanRow: View {
    let plan: TrialConversionView.BillingPlan
    let isSelected: Bool
    let monthlyPrice: Double
    let currencyCode: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: plan.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.textSecondary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    if plan != .custom {
                        Text(plan.displayPrice(monthlyPrice: monthlyPrice, currencyCode: currencyCode))
                            .font(.system(size: 13))
                            .foregroundColor(Design.Colors.textSecondary)
                    } else {
                        Text("Set your own renewal date")
                            .font(.system(size: 13))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let savings = plan.savings(monthlyPrice: monthlyPrice) {
                    Text("Save \(CurrencyManager.shared.formatPrice(savings, currencyCode: currencyCode))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Design.Colors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Design.Colors.success.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.textTertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Design.Colors.primary.opacity(0.05) : Design.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrialBenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select renewal date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle("Custom Renewal Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct TrialConversionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let subscription = Subscription(context: context)
        subscription.name = "Netflix"
        subscription.serviceLogo = "netflix-logo"
        subscription.monthlyPrice = 15.99
        subscription.startDate = Date()
        subscription.endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        subscription.subscriptionType = SubscriptionType.trial.rawValue
        subscription.isTrial = true
        
        return TrialConversionView(subscription: subscription)
    }
}