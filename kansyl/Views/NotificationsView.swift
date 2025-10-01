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
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.lg) {
                        if isLoading {
                            loadingView
                        } else if deliveredNotifications.isEmpty && pendingNotifications.isEmpty {
                            emptyStateView
                        } else {
                            // Delivered Notifications Section
                            if !deliveredNotifications.isEmpty {
                                deliveredNotificationsSection
                            }
                            
                            // Pending Notifications Section
                            if !pendingNotifications.isEmpty {
                                pendingNotificationsSection
                            }
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
                    DeliveredNotificationCard(notification: notification) {
                        removeNotification(notification)
                    }
                }
            }
        }
    }
    
    // MARK: - Pending Notifications Section
    private var pendingNotificationsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Scheduled")
                    .font(Design.Typography.title3(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Text("\(pendingNotifications.count)")
                    .font(Design.Typography.callout(.medium))
                    .foregroundColor(Design.Colors.textSecondary)
                    .padding(.horizontal, Design.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Design.Colors.surfaceSecondary)
                    .cornerRadius(Design.Radius.sm)
            }
            
            VStack(spacing: Design.Spacing.sm) {
                ForEach(pendingNotifications, id: \.identifier) { request in
                    PendingNotificationCard(request: request) {
                        cancelNotification(request)
                    }
                }
            }
        }
        .padding(.top, Design.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private func loadNotifications() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Load delivered notifications
        group.enter()
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                self.deliveredNotifications = notifications.sorted { n1, n2 in
                    n1.date > n2.date
                }
                group.leave()
            }
        }
        
        // Load pending notifications
        group.enter()
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests.sorted { r1, r2 in
                    guard let trigger1 = r1.trigger as? UNCalendarNotificationTrigger,
                          let trigger2 = r2.trigger as? UNCalendarNotificationTrigger,
                          let date1 = trigger1.nextTriggerDate(),
                          let date2 = trigger2.nextTriggerDate() else {
                        return false
                    }
                    return date1 < date2
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func clearAllNotifications() {
        // Remove all delivered notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Reload
        deliveredNotifications = []
        
        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    private func removeNotification(_ notification: UNNotification) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
        
        // Update badge count
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            UIApplication.shared.applicationIconBadgeNumber -= 1
        }
        
        // Remove from list
        deliveredNotifications.removeAll { $0.request.identifier == notification.request.identifier }
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
    
    private func cancelNotification(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        
        // Remove from list
        pendingNotifications.removeAll { $0.identifier == request.identifier }
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
}

// MARK: - Delivered Notification Card
struct DeliveredNotificationCard: View {
    let notification: UNNotification
    let onDelete: () -> Void
    
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
        HStack(alignment: .top, spacing: Design.Spacing.md) {
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(Design.Colors.primary)
                .frame(width: 40, height: 40)
                .background(Design.Colors.primary.opacity(0.1))
                .cornerRadius(Design.Radius.md)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.request.content.title)
                    .font(Design.Typography.callout(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(notification.request.content.body)
                    .font(Design.Typography.caption(.regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .lineLimit(2)
                
                Text(timeAgo)
                    .font(Design.Typography.caption(.regular))
                    .foregroundColor(Design.Colors.textTertiary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Design.Colors.textTertiary)
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.surface)
        .cornerRadius(Design.Radius.lg)
        .shadow(color: Design.Colors.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Pending Notification Card
struct PendingNotificationCard: View {
    let request: UNNotificationRequest
    let onCancel: () -> Void
    
    private var scheduledDate: Date? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }
        return trigger.nextTriggerDate()
    }
    
    private var scheduledText: String {
        guard let date = scheduledDate else {
            return "Unknown time"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Design.Spacing.md) {
            Image(systemName: "clock")
                .font(.title3)
                .foregroundColor(Design.Colors.info)
                .frame(width: 40, height: 40)
                .background(Design.Colors.info.opacity(0.1))
                .cornerRadius(Design.Radius.md)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.content.title)
                    .font(Design.Typography.callout(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(request.content.body)
                    .font(Design.Typography.caption(.regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(scheduledText)
                }
                .font(Design.Typography.caption(.regular))
                .foregroundColor(Design.Colors.textTertiary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Design.Colors.textTertiary)
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.surface)
        .cornerRadius(Design.Radius.lg)
        .shadow(color: Design.Colors.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .environmentObject(NotificationManager.shared)
    }
}
