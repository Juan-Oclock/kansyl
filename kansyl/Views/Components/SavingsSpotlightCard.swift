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
    @ObservedObject private var appPreferences = AppPreferences.shared
    @State private var isExpanded = false
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "4ADE80"))
                    
                    Text("SAVINGS SPOTLIGHT")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "4ADE80"))
                        .tracking(0.5)
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to detailed stats
                }) {
                    HStack(spacing: 6) {
                        Text("Manage")
                            .font(.system(size: 15, weight: .semibold))
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "4ADE80"))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Main Amount
            VStack(spacing: 4) {
                Text(appPreferences.formatPrice(totalSaved))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("saved this year!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.top, 16)
            
            // Metrics Row
            HStack(spacing: 0) {
                // Cancelled metric
                MetricPill(
                    icon: "xmark.circle.fill",
                    value: "\(cancelledCount)",
                    label: "Cancelled",
                    color: Color(hex: "4ADE80")
                )
                
                Divider()
                    .frame(width: 1, height: 30)
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 12)
                
                // Kept metric
                MetricPill(
                    icon: "checkmark.circle.fill",
                    value: "\(keptCount)",
                    label: "Kept",
                    color: Color(hex: "60A5FA")
                )
                
                Divider()
                    .frame(width: 1, height: 30)
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 12)
                
                // Success rate
                MetricPill(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(successRate)%",
                    label: "Success",
                    color: Color(hex: "F59E0B")
                )
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
            
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
                        
                        Text(appPreferences.formatPrice(projectedAnnualSavings))
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
            
            // Expand/Collapse button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    HapticManager.shared.playButtonTap()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.vertical, 12)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1F2937"),
                    Color(hex: "111827")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
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

