//
//  EnhancedSubscriptionCard.swift
//  kansyl
//
//  Enhanced subscription card with inline quick actions
//

import SwiftUI

struct EnhancedSubscriptionCard: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    
    @State private var showActions = false
    @State private var decisionMade: Decision? = nil
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @ObservedObject private var appPreferences = AppPreferences.shared
    
    enum Decision {
        case keep
        case cancel
        case pending
    }
    
    private var daysRemaining: Int {
        subscriptionStore.daysRemaining(for: subscription)
    }
    
    private var urgencyColor: Color {
        subscriptionStore.urgencyColor(for: subscription)
    }
    
    private var showInlineActions: Bool {
        // Show inline actions for subscriptions ending within 7 days
        return daysRemaining <= 7 && decisionMade == nil
    }
    
    private var currentStatus: SubscriptionStatus? {
        guard let statusString = subscription.status else { return nil }
        return SubscriptionStatus(rawValue: statusString)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Main card content
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
                            
                            // Status Badge if decision made
                            if let decision = decisionMade {
                                statusBadge(for: decision)
                            } else if let status = currentStatus, status != .active {
                                statusBadge(for: statusFromSubscription(status))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            // Days remaining with urgency indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(urgencyColor)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(daysRemaining) days left")
                                    .font(.system(size: 14))
                                    .foregroundColor(urgencyColor)
                            }
                            
                            Text("•")
                                .foregroundColor(Design.Colors.textSecondary)
                            
                            Text("\(SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice))/mo")
                                .font(.system(size: 14))
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side content
                    if showInlineActions {
                        // Quick action buttons for urgent subscriptions
                        HStack(spacing: 8) {
                            // Cancel button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cancelSubscription()
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "EF4444").opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "EF4444"))
                                }
                            }
                            .buttonStyle(SpringButtonStyle())
                            
                            // Keep button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    keepSubscription()
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "22C55E").opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "22C55E"))
                                }
                            }
                            .buttonStyle(SpringButtonStyle())
                        }
                    } else {
                        // Chevron for navigation
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textTertiary)
                    }
                }
                .padding(16)
                
                // Urgent banner for subscriptions ending today/tomorrow
                if daysRemaining <= 1 && decisionMade == nil {
                    urgentBanner
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(decisionMade != nil ? statusColor(for: decisionMade!) : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Design.Colors.primary.opacity(0.05),
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var logoView: some View {
        ZStack {
            // White background circle
            Circle()
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: colorScheme == .dark ? 4 : 2, x: 0, y: 1)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 0.5)
                )
            
            // Logo content
            if let serviceLogo = subscription.serviceLogo {
                // Check if it's a custom uploaded image
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    // Custom uploaded image
                    Image.bundleImage(serviceLogo, fallbackSystemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                } else {
                    // System image or bundled service logo
                    let logoImage = Image.bundleImage(serviceLogo, fallbackSystemName: getServiceFallbackIcon())
                    
                    // Check if we're using an SF Symbol fallback
                    if UIImage.bundleImage(named: serviceLogo) == nil {
                        // SF Symbol - use appropriate color
                        logoImage
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.black)
                    } else {
                        // Actual image asset - resize it
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
            } else {
                // Text fallback
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
    
    private func statusBadge(for decision: Decision) -> some View {
        HStack(spacing: 2) {
            Image(systemName: decision == .keep ? "checkmark.circle.fill" : decision == .cancel ? "xmark.circle.fill" : "clock.fill")
                .font(.system(size: 10))
            
            Text(decision == .keep ? "Keeping" : decision == .cancel ? "Canceling" : "Pending")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(statusColor(for: decision))
        )
    }
    
    private var urgentBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            
            Text(daysRemaining == 0 ? "Ends TODAY - Take action now!" : "Ends TOMORROW - Don't forget!")
                .font(.system(size: 12, weight: .medium))
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(0, corners: [.bottomLeft, .bottomRight])
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for decision: Decision) -> Color {
        switch decision {
        case .keep:
            return Color(hex: "22C55E")
        case .cancel:
            return Color(hex: "EF4444")
        case .pending:
            return Color(hex: "F59E0B")
        }
    }
    
    private func statusFromSubscription(_ status: SubscriptionStatus) -> Decision {
        switch status {
        case .kept:
            return .keep
        case .canceled:
            return .cancel
        default:
            return .pending
        }
    }
    
    private func keepSubscription() {
        HapticManager.shared.playSuccess()
        decisionMade = .keep
        subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
        
        // Show confirmation toast
        showToast("Marked as keeping - we won't remind you again")
    }
    
    private func cancelSubscription() {
        HapticManager.shared.playSuccess()
        decisionMade = .cancel
        subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
        
        // Show confirmation toast with undo
        showToast("Great! You saved \(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/month", showUndo: true)
    }
    
    private func showToast(_ message: String, showUndo: Bool = false) {
        // This would trigger a toast notification in the parent view
        NotificationCenter.default.post(
            name: Notification.Name("ShowToast"),
            object: nil,
            userInfo: [
                "message": message,
                "showUndo": showUndo,
                "subscription": subscription
            ]
        )
    }
}

// MARK: - Spring Button Style
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}