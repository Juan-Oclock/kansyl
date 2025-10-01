//
//  ModernSubscriptionsView.swift
//  kansyl
//
//  Created on 9/13/25.
//  Updated to match new mockup design
//

import SwiftUI
import CoreData
import UserNotifications

// MARK: - Scroll Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ModernSubscriptionsView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @ObservedObject private var premiumManager = PremiumManager.shared
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @ObservedObject private var appPreferences = AppPreferences.shared
    @State private var showingAddSubscription = false
    @State private var showingPremiumRequired = false
    @State private var showingNotifications = false
    @State private var selectedSubscription: Subscription?
    @State private var animateElements = false
    @State private var subscriptionJustAdded = false
    @State private var searchText = ""
    @State private var isSearchExpanded = false // Track search visibility
    @State private var showEndingSoonSection = true
    @State private var showActiveSection = true
    @State private var showingActionModal = false
    @State private var pendingAction: SubscriptionActionModal.SubscriptionAction?
    @State private var actionSubscription: Subscription?
    @State private var triggerConfetti = false
    @State private var showSuccessToast = false
    @State private var successToastMessage = ""
    @State private var successToastAmount: String? = nil
    @State private var notificationBadgeCount = 0
    @FocusState private var isSearchFocused: Bool
    
    // Cached filtered subscriptions (recomputed only when needed)
    @State private var cachedEndingSoon: [Subscription] = []
    @State private var cachedActive: [Subscription] = []
    @State private var lastFilteredSourceCount: Int = 0
    @State private var lastSearchText: String = ""
    
    // Computed property to get the display name from auth manager
    private var displayName: String {
        // Try to get first name only from full name
        if let fullName = authManager.userProfile?.fullName {
            let components = fullName.components(separatedBy: " ")
            return components.first ?? "User"
        }
        
        // Fallback to email username or generic "User"
        if let email = authManager.currentUser?.email {
            let emailComponents = email.components(separatedBy: "@")
            return emailComponents.first?.capitalized ?? "User"
        }
        
        return "User"
    }
    
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
                                
                                // Search Bar - Only visible when expanded
                                if isSearchExpanded {
                                    searchBarView
                                        .padding(.horizontal, 20)
                                        .padding(.top, 4)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
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
                AddSubscriptionMethodSelector(subscriptionStore: subscriptionStore) { _ in
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
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
                    .environmentObject(notificationManager)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateElements = true
                }
                subscriptionStore.fetchSubscriptions()
                loadNotificationBadgeCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Refresh when Core Data context saves
                subscriptionStore.fetchSubscriptions()
            }
            .onChange(of: showingNotifications) { isShowing in
                if !isShowing {
                    // Reload badge count when NotificationsView is dismissed
                    loadNotificationBadgeCount()
                }
            }
        }
        .overlay(
            Group {
                if showingActionModal, let subscription = actionSubscription, let action = pendingAction {
                    SubscriptionActionModal(
                        subscription: subscription,
                        action: action,
                        onConfirm: {
                            withAnimation(Design.Animation.spring) {
                                switch action {
                                case .keep:
                                    subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
                                    AnalyticsManager.shared.track(.subscriptionKept, properties: AnalyticsProperties(
                                        subscriptionId: subscription.id?.uuidString ?? "",
                                        subscriptionName: subscription.name ?? ""
                                    ))
                                case .cancel:
                                    subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
                                    AnalyticsManager.shared.track(.subscriptionCanceled, properties: AnalyticsProperties(
                                        subscriptionId: subscription.id?.uuidString ?? "",
                                        subscriptionName: subscription.name ?? ""
                                    ))
                                    
                                    // Trigger confetti celebration for saving money!
                                    triggerConfetti = true
                                    
                                    // Haptic celebration
                                    HapticManager.shared.playSuccess()
                                    
                                    // Show success toast after a delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        successToastMessage = "Subscription canceled successfully!"
                                        successToastAmount = SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice)
                                        showSuccessToast = true
                                    }
                                }
                                
                                // Reset state
                                showingActionModal = false
                                pendingAction = nil
                                actionSubscription = nil
                            }
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingActionModal = false
                                pendingAction = nil
                                actionSubscription = nil
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(999)
                }
            }
        )
        .overlay(
            // Confetti effects layer
            ConfettiView(trigger: $triggerConfetti, config: .savings)
                .allowsHitTesting(false)
                .zIndex(1000)
        )
        .overlay(
            // Success toast at the top
            VStack {
                SuccessToastView(
                    message: successToastMessage,
                    savedAmount: successToastAmount,
                    isShowing: $showSuccessToast
                )
                .padding(.top, 50) // Account for status bar
                
                Spacer()
            }
            .zIndex(1002)
        )
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
    
    private func loadNotificationBadgeCount() {
        // Get delivered notifications count
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                self.notificationBadgeCount = notifications.count
            }
        }
    }
    
    // MARK: - Static Header (No Dynamic Calculations)
    private var stickyHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(displayName)")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                
                Text("Your Subscriptions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
            }
            
            Spacer()
            
            // Notification Bell Button
            Button(action: {
                showingNotifications = true
                HapticManager.shared.playSelection()
            }) {
                ZStack(alignment: .topTrailing) {
                    // Background circle
                    Circle()
                        .fill(Design.Colors.surface)
                        .frame(width: 44, height: 44)
                        .shadow(color: Design.Colors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    // Bell icon - centered in the circle
                    Image(systemName: notificationBadgeCount > 0 ? "bell.badge.fill" : "bell")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.primary)
                        .frame(width: 44, height: 44) // Match circle size for centering
                    
                    // Badge indicator
                    if notificationBadgeCount > 0 {
                        Circle()
                            .fill(Design.Colors.danger)
                            .frame(width: 12, height: 12)
                            .offset(x: 6, y: -6)
                            .overlay(
                                Text(notificationBadgeCount > 9 ? "9+" : "\(notificationBadgeCount)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 6, y: -6)
                            )
                    }
                }
            }
            .scaleEffect(animateElements ? 1.0 : 0.8)
            .opacity(animateElements ? 1.0 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.02), value: animateElements)
            
            // Search Button - toggles search bar visibility
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSearchExpanded.toggle()
                    if isSearchExpanded {
                        // Auto-focus when expanded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFocused = true
                        }
                    } else {
                        // Clear search when collapsing
                        isSearchFocused = false
                        searchText = ""
                    }
                }
                HapticManager.shared.playSelection()
            }) {
                ZStack {
                    Circle()
                        .fill(Design.Colors.surface)
                        .frame(width: 44, height: 44)
                        .shadow(color: Design.Colors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: isSearchExpanded ? "xmark" : "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.primary)
                        .rotationEffect(.degrees(isSearchExpanded ? 90 : 0))
                }
            }
            .scaleEffect(animateElements ? 1.0 : 0.8)
            .opacity(animateElements ? 1.0 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.05), value: animateElements)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchExpanded)
            
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
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15), value: animateElements)
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
    
    // MARK: - Filtered Subscriptions with Caching
    private var filteredEndingSoonSubscriptions: [Subscription] {
        updateFilteredSubscriptionsIfNeeded()
        return cachedEndingSoon
    }
    
    private var filteredActiveSubscriptions: [Subscription] {
        updateFilteredSubscriptionsIfNeeded()
        return cachedActive
    }
    
    private func updateFilteredSubscriptionsIfNeeded() {
        // Only recompute if source data or search text changed
        let currentCount = subscriptionStore.activeSubscriptions.count
        let currentSearch = searchText
        
        guard lastFilteredSourceCount != currentCount || lastSearchText != currentSearch else {
            return // Cache is still valid
        }
        
        // Update cache
        let endingSoon = subscriptionStore.activeSubscriptions.filter { isSubscriptionEndingSoon($0) }
        let active = subscriptionStore.activeSubscriptions.filter { !isSubscriptionEndingSoon($0) }
        
        if searchText.isEmpty {
            cachedEndingSoon = endingSoon
            cachedActive = active
        } else {
            cachedEndingSoon = endingSoon.filter { subscription in
                (subscription.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
            cachedActive = active.filter { subscription in
                (subscription.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        lastFilteredSourceCount = currentCount
        lastSearchText = currentSearch
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
                        },
                        onSwipeAction: { action, sub in
                            actionSubscription = sub
                            pendingAction = action
                            showingActionModal = true
                        }
                    )
                }
                .padding(.horizontal, 20)
                .scaleEffect(animateElements ? 1.0 : 0.99) // Lighter animation
                .opacity(animateElements ? 1.0 : 0.8) // Less dramatic opacity change
                .animation(
                    // Simpler, faster animation with capped delay to prevent 5+ second delays
                    .easeOut(duration: 0.2).delay(min(0.3, Double(index) * 0.02)),
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
        HStack(spacing: 12) {
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
            
            // Cancel button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSearchFocused = false
                    isSearchExpanded = false
                    searchText = ""
                }
                HapticManager.shared.playSelection()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.primary)
            }
        }
    }
}

// MARK: - Subscription Row Card
struct SubscriptionRowCard: View {
    @ObservedObject var subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    var onSwipeAction: ((SubscriptionActionModal.SubscriptionAction, Subscription) -> Void)? = nil
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
                        HapticManager.shared.playSelection()
                        if let onSwipeAction = onSwipeAction {
                            onSwipeAction(.keep, subscription)
                        } else {
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
                        HapticManager.shared.playSelection()
                        if let onSwipeAction = onSwipeAction {
                            onSwipeAction(.cancel, subscription)
                        } else {
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
                    HStack(spacing: 6) {
                        Text(subscription.name ?? "Unknown")
                            .font(Design.Typography.callout(.semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        // Add subscription type badge
                        InlineSubscriptionTypeBadge(subscription: subscription)
                    }
                    
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
        
        // Format price with appropriate period suffix using SharedCurrencyFormatter
        switch cycle.lowercased() {
        case "yearly", "annual":
            return "\(SharedCurrencyFormatter.formatPrice(amount))/yr"
        case "quarterly":
            return "\(SharedCurrencyFormatter.formatPrice(amount))/qtr"
        case "weekly":
            return "\(SharedCurrencyFormatter.formatPrice(amount))/wk"
        case "semi-annual", "biannual":
            return "\(SharedCurrencyFormatter.formatPrice(amount))/6mo"
        default:
            return "\(SharedCurrencyFormatter.formatPrice(amount))/mo"
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
            if let serviceLogo = subscription.serviceLogo, !serviceLogo.isEmpty {
                // Check if it's a custom uploaded image
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    // Custom uploaded image - smaller size to show white background
                    Image.bundleImage(serviceLogo, fallbackSystemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                // Check if it's a generic system icon that should show first letter instead
                } else if shouldUseFirstLetter(serviceLogo) {
                    // Show first letter for generic icons
                    Text(subscription.name?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(serviceColor)
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
    
    // Check if we should use first letter instead of generic icon
    private func shouldUseFirstLetter(_ serviceLogo: String) -> Bool {
        let genericIcons = [
            "app.badge",
            "questionmark.circle",
            "square.fill",
            "circle.fill",
            "app",
            "apps.iphone"
        ]
        return genericIcons.contains(serviceLogo)
    }
    
    // MARK: - Actions
    private func cancelSubscription() {
        // Update status to canceled
        subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
        
        // Analytics
        AnalyticsManager.shared.track(.subscriptionCanceled, properties: AnalyticsProperties(
            subscriptionId: subscription.id?.uuidString ?? "",
            subscriptionName: subscription.name ?? ""
        ))
    }
    
    private func keepSubscription() {
        // Update status to kept
        subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
        
        // Analytics
        AnalyticsManager.shared.track(.subscriptionKept, properties: AnalyticsProperties(
            subscriptionId: subscription.id?.uuidString ?? "",
            subscriptionName: subscription.name ?? ""
        ))
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
