//
//  ExchangeRateCard.swift
//  kansyl
//
//  Displays exchange rate information for subscriptions with foreign currency
//

import SwiftUI

struct ExchangeRateCard: View {
    let subscription: Subscription
    @State private var rateInfo: ExchangeRateInfo?
    @State private var isLoading = false
    @State private var showUpdateButton = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if subscription.originalCurrency != nil {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label("Exchange Rate", systemImage: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let info = rateInfo {
                        Text(info.changeDescription)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(info.changePercentage > 0 ? .red : .green)
                    }
                }
                
                if let info = rateInfo {
                    // Current vs Original Amount
                    VStack(spacing: 8) {
                        HStack {
                            Text("Current Amount")
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                            Spacer()
                            Text(info.formattedCurrentAmount)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                        }
                        
                        HStack {
                            Text("Original Amount")
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                            Spacer()
                            Text(info.formattedOriginalAmount)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                        
                        Divider()
                        
                        // Exchange Rate Details
                        HStack {
                            Text("Exchange Rate")
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                            Spacer()
                            Text("1 \(info.originalCurrency) = \(String(format: "%.4f", info.currentRate)) \(info.currentCurrency)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Design.Colors.textPrimary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                            Spacer()
                            Text(DateFormatter.localizedString(from: info.lastUpdate, dateStyle: .short, timeStyle: .none))
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                    }
                    
                    // Warning if significant change
                    if info.isSignificantChange {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            
                            Text("Exchange rate has changed significantly since last update")
                                .font(.system(size: 12))
                                .foregroundColor(Design.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Update button
                    if showUpdateButton {
                        Button(action: updateExchangeRate) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                Text("Update to Current Rate")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Design.Colors.primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(16)
            .background(Design.Colors.surface)
            .cornerRadius(12)
            .shadow(color: Design.Shadow.sm.color, radius: Design.Shadow.sm.radius)
            .onAppear {
                loadExchangeRateInfo()
            }
        }
    }
    
    private func loadExchangeRateInfo() {
        isLoading = true
        
        Task {
            if let info = await ExchangeRateMonitor.shared.getExchangeRateInfo(for: subscription) {
                await MainActor.run {
                    self.rateInfo = info
                    self.showUpdateButton = info.isSignificantChange
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateExchangeRate() {
        isLoading = true
        
        Task {
            // Update the subscription with current rate
            await ExchangeRateMonitor.shared.checkAndUpdateExchangeRates(
                in: subscription.managedObjectContext ?? PersistenceController.shared.container.viewContext
            )
            
            // Reload info
            loadExchangeRateInfo()
        }
    }
}