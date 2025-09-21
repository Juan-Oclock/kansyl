//
//  HybridSubscriptionCard.swift
//  kansyl
//
//  Hybrid subscription card with improved swipe gestures and visual hints
//

import SwiftUI

struct HybridSubscriptionCard: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    var onSwipeConfirm: ((SubscriptionActionModal.SubscriptionAction, Subscription) -> Void)? = nil
    
    @State private var offset: CGFloat = 0
    @State private var swipeState: SwipeState = .idle
    @State private var decisionMade: Decision? = nil
    @State private var showSwipeHint = false
    @State private var hasShownSwipeHint = false
    @AppStorage("hasSeenSwipeHint") private var userHasSeenSwipeHint = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var appPreferences = AppPreferences.shared
    
    enum SwipeState {
        case idle
        case swiping
        case revealing
        case confirmed
    }
    
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
    
    private var shouldShowHint: Bool {
        return daysRemaining <= 7 && !userHasSeenSwipeHint && !hasShownSwipeHint
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Background action indicators
            HStack(spacing: 0) {
                Spacer()
                
                // Action icons that appear behind the card
                HStack(spacing: 20) {
                    // Keep icon
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Design.Colors.kept)
                        Text("Keep")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Design.Colors.kept)
                    }
                    .opacity(offset < -30 ? Double(abs(offset) - 30) / 50 : 0)
                    
                    // Cancel icon
                    VStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Design.Colors.success)
                        Text("Cancel")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Design.Colors.success)
                    }
                    .opacity(offset < -80 ? Double(abs(offset) - 80) / 50 : 0)
                }
                .padding(.trailing, 20)
            }
            
            // Main card
            Button(action: {
                if swipeState == .idle {
                    action()
                }
            }) {
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
                            
                            // Status indicator
                            if let decision = decisionMade {
                                statusBadge(for: decision)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            // Urgency dot
                            Circle()
                                .fill(urgencyColor)
                                .frame(width: 6, height: 6)
                            
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
                    
                    // Swipe hint for urgent subscriptions
                    if daysRemaining <= 7 && swipeState == .idle {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                                .opacity(0.6)
                        }
                        .foregroundColor(urgencyColor)
                        .opacity(showSwipeHint ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatCount(3, autoreverses: true),
                            value: showSwipeHint
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: decisionMade != nil ? 2 : 0)
                )
                .shadow(
                    color: Design.Colors.primary.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 2
                )
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .gesture(swipeGesture)
            .onAppear {
                if shouldShowHint {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSwipeHint = true
                        hasShownSwipeHint = true
                    }
                }
            }
            
            // Overlay hint toast for first-time users
            if showSwipeHint && !userHasSeenSwipeHint {
                swipeHintToast
            }
        }
    }
    
    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Only allow left swipe
                if value.translation.width < 0 {
                    let maxSwipe: CGFloat = -160
                    let resistance: CGFloat = 0.5
                    
                    if value.translation.width > maxSwipe {
                        offset = value.translation.width
                    } else {
                        // Apply resistance after max swipe
                        let overflow = value.translation.width - maxSwipe
                        offset = maxSwipe + (overflow * resistance)
                    }
                    
                    // Update state based on swipe distance
                    if abs(offset) > 120 {
                        if swipeState != .revealing {
                            HapticManager.shared.playSelection()
                            swipeState = .revealing
                        }
                    } else {
                        swipeState = .swiping
                    }
                    
                    // Mark that user has seen swipe
                    if !userHasSeenSwipeHint {
                        userHasSeenSwipeHint = true
                    }
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if abs(offset) > 120 {
                        // Confirm action
                        confirmAction()
                    } else if abs(offset) > 60 {
                        // Snap to action position
                        offset = -80
                        swipeState = .revealing
                    } else {
                        // Reset
                        offset = 0
                        swipeState = .idle
                    }
                }
            }
    }
    
    // MARK: - Helper Views
    private func statusBadge(for decision: Decision) -> some View {
        HStack(spacing: 4) {
            Image(systemName: decision == .keep ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
            Text(decision == .keep ? "Keeping" : "Canceled")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(decision == .keep ? Design.Colors.kept : Design.Colors.success)
        )
    }
    
    private var swipeHintToast: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 16))
                Text("Swipe left for quick actions")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showSwipeHint = false
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    private var borderColor: Color {
        guard let decision = decisionMade else { return Color.clear }
        return decision == .keep ? Design.Colors.kept : Design.Colors.success
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
    
    // MARK: - Actions
    private func confirmAction() {
        // Determine which action based on swipe position
        HapticManager.shared.playSelection()
        if let onSwipeConfirm = onSwipeConfirm {
            if offset < -120 {
                // User swiped far enough - show cancel confirmation
                onSwipeConfirm(.cancel, subscription)
            } else {
                // Default to cancel
                onSwipeConfirm(.cancel, subscription)
            }
        } else {
            // Fallback to direct action
            if offset < -120 {
                cancelSubscription()
            }
        }
        
        // Reset swipe position
        withAnimation(.spring()) {
            offset = 0
            swipeState = .idle
        }
    }
    
    private func cancelSubscription() {
        withAnimation(.spring()) {
            decisionMade = .cancel
            swipeState = .confirmed
        }
        subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
    }
    
    private func keepSubscription() {
        withAnimation(.spring()) {
            decisionMade = .keep
            swipeState = .confirmed
        }
        subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
    }
}