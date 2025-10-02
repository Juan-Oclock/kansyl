//
//  NotificationsView.swift
//  kansyl
//
//  View for managing and viewing app notifications
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isLoading = true
    @State private var showingClearAlert = false
    @State private var selectedSubscription: Subscription?
    
    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.lg) {
                        if isLoading {
                            loadingView
                        } else if deliveredNotifications.isEmpty {
                            emptyStateView
                        } else {
                            // Delivered Notifications Section
                            deliveredNotificationsSection
                        }
                    }
                    .padding(Design.Spacing.lg)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        if !deliveredNotifications.isEmpty {
                            Button(action: {
                                showingClearAlert = true
                            }) {
                                Text("Clear All")
                                    .foregroundColor(Design.Colors.primary)
                            }
                        }
                    }
                }
            }
            .alert("Clear All Notifications?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllNotifications()
                }
            } message: {
                Text("This will remove all delivered notifications and clear the badge.")
            }
            .onAppear {
                loadNotifications()
                // Clear the app icon badge when viewing notifications
                clearAppBadge()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Reload notifications when subscription data changes (keep/cancel)
                loadNotifications()
            }
            .onChange(of: selectedSubscription) { newValue in
                // When sheet is dismissed, reload notifications
                if newValue == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadNotifications()
                    }
                }
            }
            .sheet(item: $selectedSubscription) { subscription in
                ModernSubscriptionDetailView(subscription: subscription, subscriptionStore: subscriptionStore)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Design.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading notifications...")
                .font(Design.Typography.body(.medium))
                .foregroundColor(Design.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Design.Spacing.xl) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(Design.Colors.textTertiary)
            
            VStack(spacing: Design.Spacing.sm) {
                Text("No Notifications")
                    .font(Design.Typography.title3(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text("You're all caught up! We'll notify you about upcoming subscription renewals.")
                    .font(Design.Typography.body(.regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Delivered Notifications Section
    private var deliveredNotificationsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Recent")
                    .font(Design.Typography.title3(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Text("\(deliveredNotifications.count)")
                    .font(Design.Typography.callout(.medium))
                    .foregroundColor(Design.Colors.textSecondary)
                    .padding(.horizontal, Design.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Design.Colors.surfaceSecondary)
                    .cornerRadius(Design.Radius.sm)
            }
            
            VStack(spacing: Design.Spacing.sm) {
                ForEach(deliveredNotifications, id: \.request.identifier) { notification in
                    DeliveredNotificationCard(
                        notification: notification,
                        subscriptionStore: subscriptionStore,
                        onTap: {
                            handleNotificationTap(notification)
                        },
                        onDelete: {
                            removeNotification(notification)
                        }
                    )
                }
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func loadNotifications() {
        isLoading = true
        
        // Load only delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                self.deliveredNotifications = notifications.sorted { n1, n2 in
                    n1.date > n2.date
                }
                self.isLoading = false
            }
        }
    }
    
    private func clearAppBadge() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func setAppBadge(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    private func clearAllNotifications() {
        // Remove all delivered notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear badge
        clearAppBadge()
        
        // Reload
        deliveredNotifications = []
        
        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    private func handleNotificationTap(_ notification: UNNotification) {
        // Get subscription ID from notification userInfo
        guard let subscriptionId = notification.request.content.userInfo["subscriptionId"] as? String,
              let uuid = UUID(uuidString: subscriptionId) else {
            return
        }
        
        // Find the subscription
        if let subscription = subscriptionStore.allSubscriptions.first(where: { $0.id == uuid }) {
            selectedSubscription = subscription
            HapticManager.shared.playSelection()
        }
    }
    
    private func removeNotification(_ notification: UNNotification) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
        
        // Remove from list first
        deliveredNotifications.removeAll { $0.request.identifier == notification.request.identifier }
        
        // Update badge count to match remaining notifications
        setAppBadge(deliveredNotifications.count)
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
    
}

// MARK: - Delivered Notification Card
struct DeliveredNotificationCard: View {
    let notification: UNNotification
    @ObservedObject var subscriptionStore: SubscriptionStore
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var serviceName: String {
        if let subscriptionName = notification.request.content.userInfo["subscriptionName"] as? String {
            return subscriptionName
        }
        return "Subscription"
    }
    
    private var subscriptionType: String {
        if let type = notification.request.content.userInfo["subscriptionType"] as? String {
            switch type {
            case "trial":
                return "Trial"
            case "paid":
                return "Premium"
            case "promotional":
                return "Promo"
            default:
                return "Subscription"
            }
        }
        return "Subscription"
    }
    
    private var timeAgo: String {
        let date = notification.date
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Design.Spacing.md) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(Design.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(Design.Radius.md)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Service name as title
                    HStack(spacing: 6) {
                        Text(serviceName)
                            .font(Design.Typography.callout(.semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        // Subscription type badge
                        Text(subscriptionType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(subscriptionType == "Trial" ? Design.Colors.warning : Design.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((subscriptionType == "Trial" ? Design.Colors.warning : Design.Colors.success).opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text(notification.request.content.body)
                        .font(Design.Typography.caption(.regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .lineLimit(2)
                    
                    Text(timeAgo)
                        .font(Design.Typography.caption(.regular))
                        .foregroundColor(Design.Colors.textTertiary)
                }
                
                Spacer()
                
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Design.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Design.Spacing.md)
            .background(Design.Colors.surface)
            .cornerRadius(Design.Radius.lg)
            .shadow(color: Design.Colors.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .environmentObject(NotificationManager.shared)
    }
}
