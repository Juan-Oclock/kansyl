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
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @ObservedObject private var premiumManager = PremiumManager.shared
    @ObservedObject private var appPreferences = AppPreferences.shared
    @State private var showingAddSubscription = false
    @State private var showingPremiumRequired = false
    @State private var selectedSubscription: Subscription?
    @State private var animateElements = false
    @State private var subscriptionJustAdded = false
    @State private var searchText = ""
    @State private var showEndingSoonSection = true
    @State private var showActiveSection = true
    @AppStorage("userName") private var userName = "Juan Oclock"
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Theme-aware background
                Design.Colors.background
                    .ignoresSafeArea(.all, edges: .top)
                
                VStack(spacing: 0) {
                    // Static Header that remains fixed at top
                    stickyHeader
                        .background(Design.Colors.background)
                        .zIndex(1) // Keep header above scrolling content
                    
                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: true) {
                        ScrollViewReader { proxy in
                            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                                // Scroll to top anchor
                                Color.clear.frame(height: 1).id("top")
                                
                                // Free Trial Card removed
                                
                                // Savings Spotlight Card
                                savingsSpotlightCard
                                    .padding(.horizontal, 20)
                                
                                // Search Bar - Always visible below spotlight card
                                searchBarView
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                                
                                // Subscription sections
                                if !subscriptionStore.activeSubscriptions.isEmpty {
                                    subscriptionSections
                                } else {
                                    // Empty state when no subscriptions
                                    emptyStateView
                                }
                                
                                // Bottom padding for tab bar and safe area
                                Color.clear.frame(height: 100)
                            }
                            .padding(.top, 6)
                            .padding(.bottom, 90) // Extra padding to prevent tab bar cutoff
                        }
                    }
                    .clipped() // Ensure proper clipping behavior
                    .contentShape(Rectangle()) // Ensure scroll area is accessible
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
        }
    }
    
    // MARK: - Helper Methods
    private func isSubscriptionEndingSoon(_ subscription: Subscription) -> Bool {
        guard let endDate = subscription.endDate else { return false }
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return daysRemaining <= 7 && daysRemaining >= 0
    }
    
    private func updateScrollBasedUI(offset: CGFloat) {
        // Scroll-based UI updates can be added here if needed
    }
    
    // MARK: - Static Header (No Dynamic Calculations)
    private var stickyHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(userName)")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                
                Text("Your Subscriptions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
            }
            
            Spacer()
            
            // Add Button
            Button(action: { showingAddSubscription = true }) {
                ZStack {
                    Circle()
                        .fill(Design.Colors.surface)
                        .frame(width: 44, height: 44)
                        .shadow(color: Design.Colors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .scaleEffect(animateElements ? 1.0 : 0.8)
            .opacity(animateElements ? 1.0 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1), value: animateElements)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6) // Minimal bottom padding to reduce space
    }
    
    
    // MARK: - Savings Spotlight Card
    private var savingsSpotlightCard: some View {
        SavingsSpotlightCard(subscriptionStore: subscriptionStore)
            .scaleEffect(animateElements ? 1.0 : 0.95)
            .opacity(animateElements ? 1.0 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4), value: animateElements)
    }
    
    // MARK: - Subscription Sections
    private var subscriptionSections: some View {
        Group {
            if appPreferences.groupByEndDate {
                // Group by end date: Ending Soon and Active sections
                
                // Ending Soon Section
                if !filteredEndingSoonSubscriptions.isEmpty {
                    Section(header: collapsibleSectionHeader("Ending Soon", count: filteredEndingSoonSubscriptions.count, isExpanded: $showEndingSoonSection)) {
                        if showEndingSoonSection {
                            subscriptionsList(subscriptions: filteredEndingSoonSubscriptions, startIndex: 0, isCompact: appPreferences.compactMode)
                        }
                    }
                }
                
                // Active Subscriptions Section
                if !filteredActiveSubscriptions.isEmpty {
                    Section(header: collapsibleSectionHeader("Active Subscriptions", count: filteredActiveSubscriptions.count, isExpanded: $showActiveSection)) {
                        if showActiveSection {
                            subscriptionsList(subscriptions: filteredActiveSubscriptions, startIndex: filteredEndingSoonSubscriptions.count, isCompact: appPreferences.compactMode)
                        }
                    }
                }
            } else {
                // No grouping: Show all subscriptions in one list
                let allSubscriptions = filteredEndingSoonSubscriptions + filteredActiveSubscriptions
                if !allSubscriptions.isEmpty {
                    subscriptionsList(subscriptions: allSubscriptions, startIndex: 0, isCompact: appPreferences.compactMode)
                }
            }
        }
    }
    
    // MARK: - Filtered Subscriptions
    private var filteredEndingSoonSubscriptions: [Subscription] {
        let endingSoon = subscriptionStore.activeSubscriptions.filter { isSubscriptionEndingSoon($0) }
        if searchText.isEmpty {
            return endingSoon
        } else {
            return endingSoon.filter { subscription in
                (subscription.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredActiveSubscriptions: [Subscription] {
        let active = subscriptionStore.activeSubscriptions.filter { !isSubscriptionEndingSoon($0) }
        if searchText.isEmpty {
            return active
        } else {
            return active.filter { subscription in
                (subscription.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Subscription List
    private func subscriptionsList(subscriptions: [Subscription], startIndex: Int, isCompact: Bool = false) -> some View {
        LazyVStack(spacing: isCompact ? 8 : 12) {
            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
                // Wrap card with badge overlay if ending soon
                VStack(spacing: 0) {
                    // Ending soon badge at the very top (hide in compact mode)
                    if !isCompact && isSubscriptionEndingSoon(subscription) {
                        HStack {
                            Spacer()
                            EndingSoonBadge()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                    }
                    
                    // Use the smart card selector for better quick actions
                    SubscriptionCardSelector(
                        subscription: subscription,
                        subscriptionStore: subscriptionStore,
                        isCompactMode: isCompact,
                        action: {
                            selectedSubscription = subscription
                        }
                    )
                }
                .padding(.horizontal, 20)
                .scaleEffect(animateElements ? 1.0 : 0.99) // Lighter animation
                .opacity(animateElements ? 1.0 : 0.8) // Less dramatic opacity change
                .animation(
                    // Simpler, faster animation with reduced delay calculations
                    .easeOut(duration: 0.2).delay(min(0.2, Double(index) * 0.02)),
                    value: animateElements
                )
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
    // MARK: - Section Header
    private func collapsibleSectionHeader(_ title: String, count: Int, isExpanded: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.wrappedValue.toggle()
                HapticManager.shared.playSelection()
            }
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                
                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Design.Colors.primary)
                    .animation(.spring(), value: isExpanded.wrappedValue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Design.Colors.background.opacity(0.95)) // Slight transparency for better performance
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Design.Colors.textSecondary.opacity(0.7))
                    .font(.system(size: 14))
                
                TextField("Search subscriptions", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Design.Colors.textPrimary)
                    .focused($isSearchFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isSearchFocused = false
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.primary)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Design.Colors.textSecondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Design.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSearchFocused ? Design.Colors.primary : Color.gray.opacity(0.15), lineWidth: isSearchFocused ? 2 : 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
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
                    Text(formatPrice(for: subscription))
                        .font(Design.Typography.callout(.semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                        .opacity(priceOpacity)
                        .animation(Design.Animation.smooth, value: priceOpacity)
                    
                    Text(formatBillingCycle(for: subscription))
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
    
    private func formatPrice(for subscription: Subscription) -> String {
        // Use billingAmount if available, otherwise fall back to monthlyPrice
        let amount = subscription.billingAmount > 0 ? subscription.billingAmount : subscription.monthlyPrice
        let cycle = subscription.billingCycle ?? "monthly"
        
        // Format price with appropriate period suffix
        switch cycle.lowercased() {
        case "yearly", "annual":
            return "\(AppPreferences.shared.formatPrice(amount))/yr"
        case "quarterly":
            return "\(AppPreferences.shared.formatPrice(amount))/qtr"
        case "weekly":
            return "\(AppPreferences.shared.formatPrice(amount))/wk"
        case "semi-annual", "biannual":
            return "\(AppPreferences.shared.formatPrice(amount))/6mo"
        default:
            return "\(AppPreferences.shared.formatPrice(amount))/mo"
        }
    }
    
    private func formatBillingCycle(for subscription: Subscription) -> String {
        let cycle = subscription.billingCycle ?? "monthly"
        return cycle.capitalized
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
        ModernSubscriptionsView()
            .environmentObject(SubscriptionStore.shared)
    }
}
