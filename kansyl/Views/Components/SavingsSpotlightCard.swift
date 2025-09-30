//
//  SavingsSpotlightCard.swift
//  kansyl
//
//  Enhanced savings card with multiple metrics
//

import SwiftUI
import CoreData

struct SavingsSpotlightCard: View {
    @ObservedObject var subscriptionStore: SubscriptionStore
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var isExpanded = false
    
    // Optional action for manage button - allows parent view to handle navigation
    var onManageTapped: (() -> Void)? = nil
    
    // Computed metrics
    private var cancelledCount: Int {
        subscriptionStore.allSubscriptions
            .filter { $0.status == SubscriptionStatus.canceled.rawValue }
            .count
    }
    
    private var keptCount: Int {
        subscriptionStore.allSubscriptions
            .filter { $0.status == SubscriptionStatus.kept.rawValue }
            .count
    }
    
    private var totalSaved: Double {
        subscriptionStore.allSubscriptions
            .filter { $0.status == SubscriptionStatus.canceled.rawValue }
            .reduce(0) { $0 + $1.monthlyPrice }
    }
    
    private var successRate: Int {
        let total = cancelledCount + keptCount
        guard total > 0 else { return 0 }
        return Int((Double(cancelledCount) / Double(total)) * 100)
    }
    
    private var monthlyAverage: Double {
        guard cancelledCount > 0 else { return 0 }
        return totalSaved / Double(max(1, cancelledCount))
    }
    
    private var projectedAnnualSavings: Double {
        // Calculate based on current rate
        let monthsElapsed = Double(Calendar.current.component(.month, from: Date()))
        guard monthsElapsed > 0 else { return totalSaved }
        let monthlyRate = totalSaved / monthsElapsed
        return monthlyRate * 12
    }
    
    // Subscription type counts
    private var trialCount: Int {
        subscriptionStore.activeSubscriptions
            .filter { SubscriptionType(rawValue: $0.subscriptionType ?? "trial") == .trial }
            .count
    }
    
    private var paidCount: Int {
        subscriptionStore.activeSubscriptions
            .filter { SubscriptionType(rawValue: $0.subscriptionType ?? "paid") == .paid }
            .count
    }
    
    private var promoCount: Int {
        subscriptionStore.activeSubscriptions
            .filter { SubscriptionType(rawValue: $0.subscriptionType ?? "promotional") == .promotional }
            .count
    }
    
    private var hasActiveSubscriptions: Bool {
        trialCount + paidCount + promoCount > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "22C55E"))
                    
                    Text("SAVINGS SPOTLIGHT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "22C55E"))
                        .tracking(0.5)
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.playButtonTap()
                    if let onManageTapped = onManageTapped {
                        onManageTapped()
                    } else {
                        navigationCoordinator.navigateToStats()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Manage")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "22C55E"))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Compact Main Amount
            VStack(spacing: 2) {
                Text(SharedCurrencyFormatter.formatPrice(totalSaved))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("saved this year!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.top, 10)
            
            // Simplified Metrics Row
            HStack(spacing: 20) {
                // Cancelled metric
                MinimalMetric(
                    icon: "xmark",
                    value: "\(cancelledCount)",
                    label: "CANCELLED",
                    color: Color(hex: "22C55E")
                )
                
                Divider()
                    .frame(width: 0.5, height: 24)
                    .background(Color.white.opacity(0.15))
                
                // Kept metric
                MinimalMetric(
                    icon: "checkmark",
                    value: "\(keptCount)",
                    label: "KEPT",
                    color: Color(hex: "3B82F6")
                )
                
                Divider()
                    .frame(width: 0.5, height: 24)
                    .background(Color.white.opacity(0.15))
                
                // Success rate
                MinimalMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(successRate)%",
                    label: "SUCCESS",
                    color: Color(hex: "F59E0B")
                )
            }
            .padding(.top, 14)
            .padding(.bottom, 6)
            
            // Subscription Type Breakdown (if any active subscriptions)
            if hasActiveSubscriptions {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    HStack(spacing: 12) {
                        // Trial
                        if trialCount > 0 {
                            TypePill(
                                icon: "clock.badge.checkmark",
                                count: trialCount,
                                label: "Trial",
                                color: Color.orange
                            )
                        }
                        
                        // Premium
                        if paidCount > 0 {
                            if trialCount > 0 {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: 3)
                            }
                            
                            TypePill(
                                icon: "star.fill",
                                count: paidCount,
                                label: "Premium",
                                color: Color(hex: "22C55E")
                            )
                        }
                        
                        // Promo
                        if promoCount > 0 {
                            if trialCount > 0 || paidCount > 0 {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: 3)
                            }
                            
                            TypePill(
                                icon: "gift",
                                count: promoCount,
                                label: "Promo",
                                color: Color.purple
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
            
            // Expandable projection section
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 8) {
                        Text("Projected Annual Savings")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Text(SharedCurrencyFormatter.formatPrice(projectedAnnualSavings))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4ADE80"))
                        
                        Text("Based on current rate")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Minimal Expand/Collapse button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    HapticManager.shared.playButtonTap()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "1E293B"),
                            Color(hex: "0F172A")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

// Helper component for metrics
struct MetricPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
                .textCase(.uppercase)
        }
    }
}

// New minimal metric component for cleaner design
struct MinimalMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.3)
            }
        }
    }
}

// Compact subscription type pill
struct TypePill: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

