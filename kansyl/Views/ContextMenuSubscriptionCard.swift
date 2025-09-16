//
//  ContextMenuSubscriptionCard.swift
//  kansyl
//
//  Subscription card with context menu for quick actions
//

import SwiftUI

struct ContextMenuSubscriptionCard: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    
    @State private var decisionMade: Decision? = nil
    @State private var showingHint = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var appPreferences = AppPreferences.shared
    
    enum Decision {
        case keep
        case cancel
    }
    
    private var daysRemaining: Int {
        subscriptionStore.daysRemaining(for: subscription)
    }
    
    private var urgencyColor: Color {
        subscriptionStore.urgencyColor(for: subscription)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: appPreferences.showTrialLogos ? 16 : 0) {
                // Service Logo
                if appPreferences.showTrialLogos {
                    logoView
                }
                
                // Service Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(subscription.name ?? "Unknown")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        // Decision indicator
                        if let decision = decisionMade {
                            Image(systemName: decision == .keep ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(decision == .keep ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(daysRemaining) days left")
                            .font(.system(size: 14))
                            .foregroundColor(urgencyColor)
                        
                        Text("•")
                            .foregroundColor(Design.Colors.textSecondary)
                        
                        Text("\(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/mo")
                            .font(.system(size: 14))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Visual hint for long press
                if daysRemaining <= 7 {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Design.Colors.textTertiary)
                        .opacity(showingHint ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showingHint)
                        .onAppear {
                            showingHint = true
                        }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(decisionMade != nil ? borderColor : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Design.Colors.primary.opacity(0.05),
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            quickActionMenu
        }
    }
    
    private var borderColor: Color {
        guard let decision = decisionMade else { return Color.clear }
        return decision == .keep ? Color(hex: "22C55E") : Color(hex: "EF4444")
    }
    
    // MARK: - Logo View
    @ViewBuilder
    private var logoView: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: colorScheme == .dark ? 4 : 2, x: 0, y: 1)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 0.5)
                )
            
            if let serviceLogo = subscription.serviceLogo {
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    Image.bundleImage(serviceLogo, fallbackSystemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                } else {
                    let logoImage = Image.bundleImage(serviceLogo, fallbackSystemName: getServiceFallbackIcon())
                    if UIImage.bundleImage(named: serviceLogo) == nil {
                        logoImage
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.black)
                    } else {
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
            } else {
                Text(subscription.name?.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.black)
            }
        }
    }
    
    private func getServiceFallbackIcon() -> String {
        guard let name = subscription.name?.lowercased() else { return "app.badge" }
        if name.contains("apple") {
            return "applelogo"
        } else if name.contains("music") {
            return "music.note"
        } else if name.contains("tv") || name.contains("streaming") {
            return "tv.fill"
        } else {
            return "app.badge"
        }
    }
    
    @ViewBuilder
    private var quickActionMenu: some View {
        // Cancel option
        Button(action: {
            cancelSubscription()
        }) {
            Label("Cancel & Save \(AppPreferences.shared.formatPrice(subscription.monthlyPrice))", systemImage: "xmark.circle.fill")
        }
        
        // Keep option
        Button(action: {
            keepSubscription()
        }) {
            Label("Keep Subscription", systemImage: "checkmark.circle.fill")
        }
        
        Divider()
        
        // Remind me later
        Button(action: {
            remindLater()
        }) {
            Label("Remind Me Later", systemImage: "clock.fill")
        }
        
        // View details
        Button(action: {
            action()
        }) {
            Label("View Details", systemImage: "info.circle")
        }
        
        if let serviceName = subscription.name {
            Divider()
            
            // Cancel on service website
            Button(action: {
                openCancellationPage()
            }) {
                Label("Cancel on \(serviceName) Website", systemImage: "safari")
            }
        }
    }
    
    private func cancelSubscription() {
        withAnimation(.spring()) {
            decisionMade = .cancel
        }
        HapticManager.shared.playSuccess()
        subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
    }
    
    private func keepSubscription() {
        withAnimation(.spring()) {
            decisionMade = .keep
        }
        HapticManager.shared.playSuccess()
        subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
    }
    
    private func remindLater() {
        // Schedule a reminder for tomorrow
        HapticManager.shared.playSelection()
        // Implementation for snooze functionality
    }
    
    private func openCancellationPage() {
        // Open the cancellation URL for the service
        if let url = getCancellationURL(for: subscription.name ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    private func getCancellationURL(for service: String) -> URL? {
        let cancellationURLs: [String: String] = [
            "Netflix": "https://www.netflix.com/cancelplan",
            "Spotify": "https://www.spotify.com/account/subscription/",
            "Disney+": "https://www.disneyplus.com/account/subscription",
            "Amazon Prime": "https://www.amazon.com/gp/primecentral",
            "Apple TV+": "https://tv.apple.com/settings/subscriptions",
            "Hulu": "https://secure.hulu.com/account",
            "HBO Max": "https://play.hbomax.com/settings/subscription"
        ]
        
        guard let urlString = cancellationURLs[service] else { return nil }
        return URL(string: urlString)
    }
}