//
//  ModernSubscriptionsView.swift
//  kansyl
//
//  Created on 9/13/25.
//  Updated to match new mockup design
//

import SwiftUI
import CoreData

// MARK: - Scroll Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ModernSubscriptionsView: View {
    @StateObject private var subscriptionStore: SubscriptionStore
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var showingAddSubscription = false
    @State private var showingPremiumRequired = false
    @State private var selectedSubscription: Subscription?
    @State private var animateElements = false
    @State private var scrollOffset: CGFloat = 0.0
    @State private var initialCardPosition: CGFloat? = nil
    @State private var isScrollTrackingEnabled = false
    @State private var lastUpdateTime = Date()
    @State private var showFreeTrialCard = false
    @State private var freeTrialCardTimer: Timer?
    @State private var subscriptionJustAdded = false
    @AppStorage("userName") private var userName = "Juan Oclock"
    
    init(context: NSManagedObjectContext) {
        _subscriptionStore = StateObject(wrappedValue: SubscriptionStore(context: context))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Theme-aware background
                Design.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sticky Header that remains fixed at top
                    stickyHeader
                        .background(Design.Colors.background)
                        .zIndex(1) // Keep header above scrolling content
                    
                    // Scrollable Content with working scroll detection
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Free Trial Card - only show when flag is true
                            if showFreeTrialCard {
                                freeTrialCard
                                    .padding(.horizontal, 20)
                                    .transition(.opacity)
                            }
                            
                            // Savings Spotlight Card with scroll detector
                            savingsSpotlightCard
                                .padding(.horizontal, 20)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                // Store initial position after a delay to ensure layout is complete
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    self.initialCardPosition = geo.frame(in: .global).minY
                                                    self.scrollOffset = 0
                                                    self.isScrollTrackingEnabled = true
                                                }
                                            }
                                            .onChange(of: geo.frame(in: .global).minY) { minY in
                                                // Only track scroll after initial position is set
                                                guard self.isScrollTrackingEnabled,
                                                      let initialPos = self.initialCardPosition else { return }
                                                
                                                // Calculate target offset
                                                let targetOffset = max(0, initialPos - minY)
                                                
                                                // Only update if there's a meaningful change (reduces flicker)
                                                let difference = abs(targetOffset - self.scrollOffset)
                                                if difference > 0.5 {
                                                    // Smooth update without animation wrapper
                                                    self.scrollOffset = targetOffset
                                                    
                                                    // Hide free trial card when scrolling up
                                                    if targetOffset > 10 && self.showFreeTrialCard {
                                                        withAnimation(.easeOut(duration: 0.3)) {
                                                            self.showFreeTrialCard = false
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                )
                            
                            // Single unified subscription section
                            if !subscriptionStore.activeSubscriptions.isEmpty {
                                allSubscriptionsSection
                            } else {
                                // Empty state when no subscriptions
                                emptyStateView
                            }
                            
                            // Reduced spacing for bottom nav
                            Color.clear.frame(height: 20)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView(subscriptionStore: subscriptionStore) { _ in
                    // Callback when subscription is saved
                    subscriptionStore.fetchSubscriptions()
                    // Mark that a subscription was added
                    subscriptionJustAdded = true
                    // Post notification that a subscription was added
                    NotificationCenter.default.post(name: .subscriptionAdded, object: nil)
                }
            }
            .sheet(item: $selectedSubscription) { subscription in
                ModernSubscriptionDetailView(subscription: subscription, subscriptionStore: subscriptionStore)
            }
            .sheet(isPresented: $showingPremiumRequired) {
                PremiumFeatureView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateElements = true
                }
                subscriptionStore.fetchSubscriptions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Refresh when Core Data context saves
                subscriptionStore.fetchSubscriptions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionAdded)) { _ in
                // Show free trial card when a subscription is added from any source
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showFreeTrialCard = true
                }
                
                // Hide the card after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.showFreeTrialCard = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isSubscriptionEndingSoon(_ subscription: Subscription) -> Bool {
        guard let endDate = subscription.endDate else { return false }
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return daysRemaining <= 7 && daysRemaining >= 0
    }
    
    // MARK: - Sticky Header with Dynamic Sizing
    private var stickyHeader: some View {
        // Calculate dynamic values based on scroll - more subtle scaling
        let scrollProgress = min(scrollOffset / 50, 1.0) // Progress over 50 points
        let titleSize: CGFloat = 32 - (scrollProgress * 8) // From 32 to 24 (was 14)
        let greetingOpacity = max(0, 1.0 - (scrollProgress * 2))
        let showGreeting = scrollProgress < 0.45 // Hide at 45% scroll progress
        let bottomPadding: CGFloat = 10 - (scrollProgress * 5) // From 10 to 5
        
        return VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // Greeting - completely removed when hidden
                    if showGreeting {
                        Text("Hi, \(userName)")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Design.Colors.textSecondary)
                            .opacity(greetingOpacity)
                    }
                    
                    // Title - scales down when scrolling
                    Text("Your Current\nSubscription")
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Add Button - stays same size
                Button(action: { showingAddSubscription = true }) {
                    ZStack {
                        Circle()
                            .fill(Design.Colors.surface)
                            .frame(width: 50, height: 50)
                            .shadow(color: Design.Colors.primary.opacity(0.1), radius: 6, x: 0, y: 2)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Design.Colors.primary)
                    }
                }
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: animateElements)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, bottomPadding)
        }
        .animation(.easeInOut(duration: 0.15), value: scrollOffset)
    }
    
    // MARK: - Free Trial Card
    private var freeTrialCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Trial Slots")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                
                Text("\(subscriptionStore.activeSubscriptions.count)/\(PremiumManager.freeTrialLimit) used")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
            }
            
            Spacer()
            
            Button(action: { showingPremiumRequired = true }) {
                Text("Upgrade")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(hex: "22C55E"))
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .background(Design.Colors.surface)
        .cornerRadius(16)
        .shadow(color: Design.Colors.primary.opacity(0.05), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Savings Spotlight Card
    private var savingsSpotlightCard: some View {
        SavingsSpotlightCard(subscriptionStore: subscriptionStore)
            .scaleEffect(animateElements ? 1.0 : 0.95)
            .opacity(animateElements ? 1.0 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4), value: animateElements)
    }
    
    // MARK: - All Subscriptions Section (unified)
    private var allSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Subscriptions")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Text("\(subscriptionStore.activeSubscriptions.count) active")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(Array(subscriptionStore.activeSubscriptions.enumerated()), id: \.element.id) { index, subscription in
                    // Check if ending soon (within 7 days)
                    let isEndingSoon = isSubscriptionEndingSoon(subscription)
                    
                    // Wrap card with badge overlay if ending soon
                    ZStack(alignment: .topTrailing) {
                        // Use the smart card selector for better quick actions
                        SubscriptionCardSelector(
                            subscription: subscription,
                            subscriptionStore: subscriptionStore,
                            action: {
                                selectedSubscription = subscription
                            }
                        )
                        
                        // Ending soon badge
                        if isEndingSoon {
                            EndingSoonBadge()
                                .offset(x: -16, y: 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .scaleEffect(animateElements ? 1.0 : 0.95)
                    .opacity(animateElements ? 1.0 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(0.6 + Double(index) * 0.05),
                        value: animateElements
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Design.Colors.textSecondary)
            
            Text("No Active Subscriptions")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Text("Start tracking your subscriptions\nto never miss a cancellation deadline")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Design.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
                Text("Add First Subscription")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Design.Colors.textSecondary)
        }
        .padding(40)
        .scaleEffect(animateElements ? 1.0 : 0.9)
        .opacity(animateElements ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateElements)
    }
}

// MARK: - Subscription Row Card
struct SubscriptionRowCard: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    @State private var isPressed = false
    @State private var showingDeleteAlert = false
    @State private var offset: CGSize = .zero
    @State private var swipeState: SwipeState = .none
    @State private var isDragging = false
    @State private var debugSwipeValue: CGFloat = 0 // Debug helper
    @Environment(\.colorScheme) private var colorScheme
    
    enum SwipeState {
        case none
        case swiping
        case showingActions
    }
    
    // Calculate opacity for price based on swipe progress
    private var priceOpacity: Double {
        let progress = abs(offset.width) / 160
        return max(0, 1 - progress * 1.2) // Fade out faster than swipe
    }
    
    // Calculate opacity for action buttons based on swipe progress
    private var actionButtonsOpacity: Double {
        let progress = abs(offset.width) / 160
        return min(1, progress * 1.5) // Fade in as user swipes
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background actions container
            HStack(spacing: 0) {
                Spacer()
                
                // Action buttons container with fade-in effect
                HStack(spacing: 0) {
                    // Keep Button
                    Button(action: {
                        withAnimation(Design.Animation.spring) {
                            keepSubscription()
                        }
                    }) {
                        VStack(spacing: Design.Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                            Text("Keep")
                                .font(Design.Typography.caption(.medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Design.Colors.kept, Design.Colors.kept.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .opacity(actionButtonsOpacity)
                    .scaleEffect(actionButtonsOpacity > 0.5 ? 1 : 0.8)
                    
                    // Cancel Button  
                    Button(action: {
                        withAnimation(Design.Animation.spring) {
                            cancelSubscription()
                        }
                    }) {
                        VStack(spacing: Design.Spacing.xxs) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                            Text("Cancel")
                                .font(Design.Typography.caption(.medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Design.Colors.success, Design.Colors.success.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .opacity(actionButtonsOpacity)
                    .scaleEffect(actionButtonsOpacity > 0.5 ? 1 : 0.8)
                }
                .animation(Design.Animation.smooth, value: actionButtonsOpacity)
            }
            .cornerRadius(Design.Radius.md)
            
            // Main card content
            HStack(spacing: AppPreferences.shared.showTrialLogos ? 16 : 0) {
                // Service Logo with white background for dark mode visibility
                if AppPreferences.shared.showTrialLogos {
                    logoBackground
                }
                
                // Service Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name ?? "Unknown")
                        .font(Design.Typography.callout(.semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("\(daysRemaining) days left")
                        .font(Design.Typography.footnote())
                        .foregroundColor(urgencyColor)
                }
                
                Spacer()
                
                // Price Info with fade animation
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/mo")
                        .font(Design.Typography.callout(.semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                        .opacity(priceOpacity)
                        .animation(Design.Animation.smooth, value: priceOpacity)
                    
                    Text("Monthly")
                        .font(Design.Typography.caption())
                        .foregroundColor(Design.Colors.textSecondary)
                        .opacity(priceOpacity)
                        .animation(Design.Animation.smooth, value: priceOpacity)
                }
            }
            .padding(Design.Spacing.md)
            .background(Design.Colors.surface)
            .cornerRadius(Design.Radius.md)
            .shadow(
                color: Design.Shadow.sm.color,
                radius: Design.Shadow.sm.radius,
                x: Design.Shadow.sm.x,
                y: Design.Shadow.sm.y
            )
            .offset(x: offset.width)
            .onTapGesture {
                // Only allow tap when not swiping
                if swipeState == .none && !isDragging {
                    action()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30) // Increased from 10 to 30
                    .onChanged { value in
                        // Only respond to horizontal swipes (prioritize vertical scroll)
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        // Only activate swipe if horizontal movement is dominant
                        guard horizontalAmount > verticalAmount * 1.5 else { return }
                        
                        isDragging = true
                        debugSwipeValue = value.translation.width // Debug tracking
                        
                        // Only allow left swipe
                        if value.translation.width < -20 { // More deliberate swipe required
                            // Smooth elastic resistance at the end
                            let resistance = value.translation.width < -160 ? 0.5 : 1.0
                            let newOffset = max(value.translation.width * resistance, -180)
                            
                            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 1, blendDuration: 0)) {
                                offset = CGSize(width: newOffset, height: 0)
                            }
                            
                            if value.translation.width < -80 {
                                // Light haptic when reaching action threshold
                                if swipeState != .showingActions {
                                    HapticManager.shared.playSelection()
                                    swipeState = .showingActions
                                }
                            } else {
                                swipeState = .swiping
                            }
                        } else if swipeState == .showingActions {
                            // Allow swipe right to close when actions are showing
                            let newOffset = min(value.translation.width - 160, 0)
                            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 1, blendDuration: 0)) {
                                offset = CGSize(width: newOffset, height: 0)
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        debugSwipeValue = 0 // Reset debug
                        
                        withAnimation(Design.Animation.spring) {
                            if value.translation.width < -80 {
                                // Show action buttons with snap effect
                                offset = CGSize(width: -160, height: 0)
                                swipeState = .showingActions
                            } else {
                                // Reset position with bounce
                                offset = .zero
                                swipeState = .none
                            }
                        }
                    }
            )
        }
        .simultaneousGesture(DragGesture()) // Allow vertical scroll to work simultaneously
        .alert("Delete Subscription?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    subscriptionStore.deleteSubscription(subscription)
                }
            }
        } message: {
            Text("This will permanently delete this subscription from your tracking.")
        }
    }
    
    private var daysRemaining: Int {
        guard let endDate = subscription.endDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    private var urgencyColor: Color {
        if daysRemaining <= 3 {
            return Design.Colors.danger // Critical alert
        } else if daysRemaining <= 5 {
            return Design.Colors.warning // Mild alert
        } else {
            return Design.Colors.textSecondary // Normal
        }
    }
    
    @ViewBuilder
    private var logoBackground: some View {
        ZStack {
            // White background circle - more visible in dark mode, subtle in light mode
            Circle()
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: colorScheme == .dark ? 4 : 2, x: 0, y: 1)
                .overlay(
                    // Add subtle border for better definition
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 0.5)
                )
            
            // Content on top of white background
            if let serviceLogo = subscription.serviceLogo {
                // Check if it's a custom uploaded image
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    // Custom uploaded image - smaller size to show white background
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
                            .foregroundColor(getLogoDisplayColor())
                    } else {
                        // Actual image asset - resize it
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
            } else {
                // Text fallback with service color
                Text(subscription.name?.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(serviceColor)
            }
        }
    }
    
    private var serviceColor: Color {
        // All logos should be black for consistency
        return Color.black
    }
    
    // Get appropriate SF Symbol fallback for service
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
    
    // Get logo display color - all logos should be black
    private func getLogoDisplayColor() -> Color {
        // All logos should be black for consistency
        return Color.black
    }
    
    // MARK: - Actions
    private func cancelSubscription() {
        // Immediate haptic feedback
        HapticManager.shared.playSuccess()
        
        withAnimation(Design.Animation.spring) {
            // Update status to canceled
            subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
            
            // Reset swipe position with smooth animation
            offset = .zero
            swipeState = .none
            
            // Analytics
            AnalyticsManager.shared.track(.subscriptionCanceled, properties: AnalyticsProperties(
                subscriptionId: subscription.id?.uuidString ?? "",
                subscriptionName: subscription.name ?? ""
            ))
        }
    }
    
    private func keepSubscription() {
        // Immediate haptic feedback
        HapticManager.shared.playSuccess()
        
        withAnimation(Design.Animation.spring) {
            // Update status to kept
            subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
            
            // Reset swipe position with smooth animation
            offset = .zero
            swipeState = .none
            
            // Analytics
            AnalyticsManager.shared.track(.subscriptionKept, properties: AnalyticsProperties(
                subscriptionId: subscription.id?.uuidString ?? "",
                subscriptionName: subscription.name ?? ""
            ))
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "creditcard", label: "Subscription", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabBarItem(icon: "clock", label: "History", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            // Center Add Button
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0F172A"))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10)
            
            TabBarItem(icon: "chart.bar", label: "Stats", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            
            TabBarItem(icon: "gearshape", label: "Settings", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 30)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "0F172A") : Color(hex: "94A3B8"))
                
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? Color(hex: "0F172A") : Color(hex: "94A3B8"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}


// MARK: - Preview
struct ModernSubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernSubscriptionsView(context: PersistenceController.preview.container.viewContext)
    }
}