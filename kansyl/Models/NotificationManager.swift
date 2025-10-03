//
//  NotificationManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import UserNotifications
import CoreData
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var notificationsEnabled = false
    @Published var threeDayReminder = true
    @Published var oneDayReminder = true
    @Published var dayOfReminder = true
    @Published var notificationHour = 9 // Default notification hour (9 AM)
    @Published var notificationMinute = 0
    
    // User preferences stored in UserDefaults
    @AppStorage("notificationHour") private var storedHour = 9
    @AppStorage("notificationMinute") private var storedMinute = 0
    @AppStorage("threeDayReminder") private var storedThreeDay = true
    @AppStorage("oneDayReminder") private var storedOneDay = true
    @AppStorage("dayOfReminder") private var storedDayOf = true
    
    override private init() {
        super.init()
        loadPreferences()
        checkNotificationPermission()
        setupNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
            
            if error != nil {
                // Failed to request notification permission
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Urgency
    enum NotificationUrgency {
        case normal
        case urgent
        case critical
    }
    
    // MARK: - Preferences
    private func loadPreferences() {
        notificationHour = storedHour
        notificationMinute = storedMinute
        threeDayReminder = storedThreeDay
        oneDayReminder = storedOneDay
        dayOfReminder = storedDayOf
    }
    
    func savePreferences() {
        storedHour = notificationHour
        storedMinute = notificationMinute
        storedThreeDay = threeDayReminder
        storedOneDay = oneDayReminder
        storedDayOf = dayOfReminder
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleNotifications(for subscription: Subscription) {
        guard notificationsEnabled,
              subscription.id?.uuidString != nil,
              subscription.name != nil,
              subscription.endDate != nil else {
            return
        }
        
        // Remove existing notifications for this subscription
        removeNotifications(for: subscription)
        
        // Schedule new notifications
        scheduleNotificationsWithoutRemoval(for: subscription)
    }
    
    // MARK: - Private Scheduling (Without Removal)
    
    private func scheduleNotificationsWithoutRemoval(for subscription: Subscription) {
        guard notificationsEnabled,
              let subscriptionId = subscription.id?.uuidString,
              let subscriptionName = subscription.name,
              let endDate = subscription.endDate else {
            return
        }
        
        // Determine subscription type
        let subscriptionType = SubscriptionType(rawValue: subscription.subscriptionType ?? "trial") ?? .trial
        
        // Use type-specific notification scheduling
        switch subscriptionType {
        case .trial:
            scheduleTrialNotifications(for: subscription, id: subscriptionId, name: subscriptionName, endDate: endDate)
        case .paid:
            schedulePaidNotifications(for: subscription, id: subscriptionId, name: subscriptionName, endDate: endDate)
        case .promotional:
            schedulePromoNotifications(for: subscription, id: subscriptionId, name: subscriptionName, endDate: endDate)
        }
    }
    
    // MARK: - Type-Specific Notification Scheduling
    
    private func scheduleTrialNotifications(for subscription: Subscription, id: String, name: String, endDate: Date) {
        let subscriptionType = SubscriptionType.trial
        let calendar = Calendar.current
        let now = Date()
        let daysUntilEnd = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        
        // Check if subscription is already in a reminder window and deliver immediately
        if daysUntilEnd <= 0 && dayOfReminder {
            // Day-of or past due - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-dayof-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: 0),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                subscription: subscription,
                urgency: .critical
            )
        } else if daysUntilEnd <= 1 && oneDayReminder {
            // 1 day or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-1day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .urgent
            )
        } else if daysUntilEnd <= 3 && threeDayReminder {
            // 3 days or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-3day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .normal
            )
        }
        
        // Also schedule future notifications if applicable
        
        // Schedule 3-day reminder if enabled
        if threeDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -3, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-3day",
                        title: subscriptionType.notificationTitle(daysRemaining: 3),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 3),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule 1-day reminder if enabled
        if oneDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -1, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-1day",
                        title: subscriptionType.notificationTitle(daysRemaining: 1),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 1),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .urgent
                    )
                }
            }
        }
        
        // Schedule day-of reminder if enabled
        if dayOfReminder {
            let adjustedDate = setNotificationTime(for: endDate)
            if adjustedDate > Date() {
                scheduleNotification(
                    id: "\(id)-dayof",
                    title: subscriptionType.notificationTitle(daysRemaining: 0),
                    body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                    date: adjustedDate,
                    subscription: subscription,
                    urgency: .critical
                )
            }
        }
    }
    
    private func schedulePaidNotifications(for subscription: Subscription, id: String, name: String, endDate: Date) {
        let subscriptionType = SubscriptionType.paid
        let calendar = Calendar.current
        let now = Date()
        let daysUntilEnd = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        
        // Check if subscription is already in a reminder window and deliver immediately
        if daysUntilEnd <= 0 && dayOfReminder {
            // Day-of or past due - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-dayof-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: 0),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                subscription: subscription,
                urgency: .normal
            )
        } else if daysUntilEnd <= 1 && oneDayReminder {
            // 1 day or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-1day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .normal
            )
        } else if daysUntilEnd <= 3 && threeDayReminder {
            // 3 days or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-3day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .normal
            )
        }
        
        // Also schedule future notifications if applicable
        
        // Schedule 3-day reminder if enabled
        if threeDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -3, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-3day",
                        title: subscriptionType.notificationTitle(daysRemaining: 3),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 3),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule 1-day reminder if enabled
        if oneDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -1, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-1day",
                        title: subscriptionType.notificationTitle(daysRemaining: 1),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 1),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule day-of reminder if enabled
        if dayOfReminder {
            let adjustedDate = setNotificationTime(for: endDate)
            if adjustedDate > Date() {
                scheduleNotification(
                    id: "\(id)-dayof",
                    title: subscriptionType.notificationTitle(daysRemaining: 0),
                    body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                    date: adjustedDate,
                    subscription: subscription,
                    urgency: .normal
                )
            }
        }
    }
    
    private func schedulePromoNotifications(for subscription: Subscription, id: String, name: String, endDate: Date) {
        let subscriptionType = SubscriptionType.promotional
        let calendar = Calendar.current
        let now = Date()
        let daysUntilEnd = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        
        // Check if subscription is already in a reminder window and deliver immediately
        if daysUntilEnd <= 0 && dayOfReminder {
            // Day-of or past due - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-dayof-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: 0),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                subscription: subscription,
                urgency: .urgent
            )
        } else if daysUntilEnd <= 1 && oneDayReminder {
            // 1 day or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-1day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .normal
            )
        } else if daysUntilEnd <= 3 && threeDayReminder {
            // 3 days or less - deliver immediately
            deliverImmediateNotification(
                id: "\(id)-3day-immediate",
                title: subscriptionType.notificationTitle(daysRemaining: max(0, daysUntilEnd)),
                body: subscriptionType.notificationBody(serviceName: name, daysRemaining: max(0, daysUntilEnd)),
                subscription: subscription,
                urgency: .normal
            )
        }
        
        // Also schedule future notifications if applicable
        
        // Schedule 3-day reminder if enabled
        if threeDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -3, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-3day",
                        title: subscriptionType.notificationTitle(daysRemaining: 3),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 3),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule 1-day reminder if enabled
        if oneDayReminder {
            if let notificationDate = calendar.date(byAdding: .day, value: -1, to: endDate) {
                let adjustedDate = setNotificationTime(for: notificationDate)
                if adjustedDate > Date() {
                    scheduleNotification(
                        id: "\(id)-1day",
                        title: subscriptionType.notificationTitle(daysRemaining: 1),
                        body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 1),
                        date: adjustedDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule day-of reminder if enabled
        if dayOfReminder {
            let adjustedDate = setNotificationTime(for: endDate)
            if adjustedDate > Date() {
                scheduleNotification(
                    id: "\(id)-dayof",
                    title: subscriptionType.notificationTitle(daysRemaining: 0),
                    body: subscriptionType.notificationBody(serviceName: name, daysRemaining: 0),
                    date: adjustedDate,
                    subscription: subscription,
                    urgency: .urgent
                )
            }
        }
    }
    
    // Legacy method for backward compatibility
    private func scheduleLegacyNotifications(for subscription: Subscription) {
        guard let subscriptionId = subscription.id?.uuidString,
              let subscriptionName = subscription.name,
              let endDate = subscription.endDate else {
            return
        }
        
        let calendar = Calendar.current
        
        // Schedule 3-day reminder
        if threeDayReminder {
            if let threeDaysDate = calendar.date(byAdding: .day, value: -3, to: endDate) {
                let notificationDate = setNotificationTime(for: threeDaysDate)
                if notificationDate > Date() {
                    scheduleNotification(
                        id: "\(subscriptionId)-3day",
                        title: "⏰ \(subscriptionName) subscription ends in 3 days",
                        body: "Take action now to avoid unwanted charges. Tap to decide.",
                        date: notificationDate,
                        subscription: subscription,
                        urgency: .normal
                    )
                }
            }
        }
        
        // Schedule 1-day reminder
        if oneDayReminder {
            if let oneDayDate = calendar.date(byAdding: .day, value: -1, to: endDate) {
                let notificationDate = setNotificationTime(for: oneDayDate)
                if notificationDate > Date() {
                    scheduleNotification(
                        id: "\(subscriptionId)-1day",
                        title: "⚠️ \(subscriptionName) subscription ends TOMORROW",
                        body: "Last chance to cancel! You'll be charged tomorrow if you don't act.",
                        date: notificationDate,
                        subscription: subscription,
                        urgency: .urgent
                    )
                }
            }
        }
        
        // Schedule day-of reminder
        if dayOfReminder {
            let morningDate = setNotificationTime(for: endDate, hour: 9, minute: 0)
            if morningDate > Date() {
                scheduleNotification(
                    id: "\(subscriptionId)-dayof",
                    title: "🚨 \(subscriptionName) subscription ends TODAY!",
                    body: "Final warning! Cancel now or you'll be charged.",
                    date: morningDate,
                    subscription: subscription,
                    urgency: .critical
                )
            }
        }
    }
    
    private func setNotificationTime(for date: Date, hour: Int? = nil, minute: Int? = nil) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour ?? notificationHour
        components.minute = minute ?? notificationMinute
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Immediate Notification Delivery
    
    /// Delivers a notification immediately (within 1 second) for subscriptions already in reminder window
    private func deliverImmediateNotification(id: String, title: String, body: String, subscription: Subscription? = nil, urgency: NotificationUrgency = .normal) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = urgency == .critical ? .defaultCritical : .default
        content.categoryIdentifier = urgency == .critical ? "SUBSCRIPTION_REMINDER_URGENT" : "SUBSCRIPTION_REMINDER"
        // Don't set badge here - let the system manage it based on delivered notification count
        
        // Add subscription data to userInfo for handling actions
        if let subscription = subscription, let subscriptionId = subscription.id?.uuidString {
            content.userInfo = [
                "subscriptionId": subscriptionId,
                "subscriptionName": subscription.name ?? "Unknown",
                "monthlyPrice": subscription.monthlyPrice,
                "subscriptionType": subscription.subscriptionType ?? "trial",
                "isTrial": subscription.isTrial
            ]
            
            // Add subtitle with price info
            if subscription.monthlyPrice > 0 {
                content.subtitle = "$\(String(format: "%.2f", subscription.monthlyPrice))/month after subscription"
            }
        }
        
        // Add attachment for rich notification (service logo)
        if let subscription = subscription, let logoName = subscription.serviceLogo {
            content.threadIdentifier = "subscription-\(subscription.id?.uuidString ?? "unknown")"
            
            // Create a simple image attachment using SF Symbols
            if let imageURL = createSymbolImage(name: logoName) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "logo", url: imageURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    // Failed to create notification attachment
                }
            }
        }
        
        // Trigger in 1 second (immediate delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver immediate notification: \(error)")
            } else {
                // Update badge count after notification is delivered with a delay
                // to ensure it appears in delivered notifications list
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.updateBadgeCount()
                }
            }
        }
    }
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date, subscription: Subscription? = nil, urgency: NotificationUrgency = .normal) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = urgency == .urgent ? .defaultCritical : .default
        content.categoryIdentifier = urgency == .urgent ? "SUBSCRIPTION_REMINDER_URGENT" : "SUBSCRIPTION_REMINDER"
        // Don't set badge here - let the system manage it based on delivered notification count
        
        // Add subscription data to userInfo for handling actions
        if let subscription = subscription, let subscriptionId = subscription.id?.uuidString {
            content.userInfo = [
                "subscriptionId": subscriptionId,
                "subscriptionName": subscription.name ?? "Unknown",
                "monthlyPrice": subscription.monthlyPrice,
                "subscriptionType": subscription.subscriptionType ?? "trial",
                "isTrial": subscription.isTrial
            ]
            
            // Add subtitle with price info
            if subscription.monthlyPrice > 0 {
                content.subtitle = "$\(String(format: "%.2f", subscription.monthlyPrice))/month after subscription"
            }
        }
        
        // Add attachment for rich notification (service logo)
        if let subscription = subscription, let logoName = subscription.serviceLogo {
            content.threadIdentifier = "subscription-\(subscription.id?.uuidString ?? "unknown")"
            
            // Create a simple image attachment using SF Symbols
            if let imageURL = createSymbolImage(name: logoName) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "logo", url: imageURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    // Failed to create notification attachment
                }
            }
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Notification scheduled
        }
    }
    
    func removeNotifications(for subscription: Subscription) {
        guard let subscriptionId = subscription.id?.uuidString else { return }
        
        let notificationIds = [
            "\(subscriptionId)-3day",
            "\(subscriptionId)-1day", 
            "\(subscriptionId)-dayof",
            "\(subscriptionId)-3day-immediate",
            "\(subscriptionId)-1day-immediate",
            "\(subscriptionId)-dayof-immediate"
        ]
        
        // Remove pending (scheduled) notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIds)
        
        // Remove delivered notifications from notification center
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationIds)
        
        // Update badge count after removal
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                if #available(iOS 16.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(notifications.count)
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = notifications.count
                }
            }
        }
    }
    
    func scheduleAllSubscriptionNotifications(subscriptions: [Subscription]) {
        // Only schedule for active subscriptions
        let activeSubscriptions = subscriptions.filter { $0.status == SubscriptionStatus.active.rawValue }
        
        // OPTIMIZATION: Batch remove all old notifications first (single API call)
        let allNotificationIds = activeSubscriptions.flatMap { subscription -> [String] in
            guard let id = subscription.id?.uuidString else { return [] }
            return ["\(id)-3day", "\(id)-1day", "\(id)-dayof"]
        }
        
        if !allNotificationIds.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allNotificationIds)
        }
        
        // Then schedule new notifications (without individual removes)
        for subscription in activeSubscriptions {
            scheduleNotificationsWithoutRemoval(for: subscription)
        }
    }
    
    // MARK: - Notification Actions
    
    func setupNotificationCategories() {
        // Normal reminder actions
        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_SUBSCRIPTION",
            title: "🚫 Cancel Subscription",
            options: [.foreground]
        )
        
        let keepAction = UNNotificationAction(
            identifier: "KEEP_SUBSCRIPTION", 
            title: "✅ Keep Service",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_2H",
            title: "⏰ Remind in 2 hours",
            options: []
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SUBSCRIPTION",
            title: "📱 Open App",
            options: [.foreground]
        )
        
        // Normal category
        let normalCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION_REMINDER",
            actions: [cancelAction, keepAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Urgent category with fewer options
        let urgentCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION_REMINDER_URGENT",
            actions: [cancelAction, keepAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([normalCategory, urgentCategory])
    }
    
    // MARK: - Helper Methods
    
    /// Updates the app icon badge to match the number of delivered notifications
    private func updateBadgeCount() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                let count = notifications.count
                if #available(iOS 16.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(count)
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        }
    }
    
    private func createSymbolImage(name: String) -> URL? {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Create background
            UIColor.systemBlue.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // Draw SF Symbol
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
            if let symbolImage = UIImage(systemName: name, withConfiguration: config) {
                let imageRect = CGRect(
                    x: (size.width - 40) / 2,
                    y: (size.height - 40) / 2,
                    width: 40,
                    height: 40
                )
                symbolImage.withTintColor(.white).draw(in: imageRect)
            }
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png")
        if let data = image.pngData() {
            try? data.write(to: tempURL)
            return tempURL
        }
        
        return nil
    }
    
    func scheduleSnoozeNotification(for subscriptionId: String, subscriptionName: String, hours: Int = 2) {
        let date = Date().addingTimeInterval(TimeInterval(hours * 3600))
        
        scheduleNotification(
            id: "\(subscriptionId)-snooze-\(Date().timeIntervalSince1970)",
            title: "⏰ Reminder: \(subscriptionName)",
            body: "You snoozed this earlier. Don't forget to take action on your subscription.",
            date: date,
            subscription: nil,
            urgency: .normal
        )
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        guard let subscriptionId = userInfo["subscriptionId"] as? String else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "CANCEL_SUBSCRIPTION":
            handleSubscriptionAction(subscriptionId: subscriptionId, action: .cancel)
        case "KEEP_SUBSCRIPTION":
            handleSubscriptionAction(subscriptionId: subscriptionId, action: .keep)
        case "SNOOZE_2H":
            if let subscriptionName = userInfo["subscriptionName"] as? String {
                scheduleSnoozeNotification(for: subscriptionId, subscriptionName: subscriptionName)
            }
        case "VIEW_SUBSCRIPTION", UNNotificationDefaultActionIdentifier:
            openSubscriptionInApp(subscriptionId: subscriptionId)
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    private func handleSubscriptionAction(subscriptionId: String, action: SubscriptionAction) {
        // Post notification to handle in app
        NotificationCenter.default.post(
            name: Notification.Name("SubscriptionActionFromNotification"),
            object: nil,
            userInfo: ["subscriptionId": subscriptionId, "action": action.rawValue]
        )
    }
    
    private func openSubscriptionInApp(subscriptionId: String) {
        // Post notification to handle in app
        NotificationCenter.default.post(
            name: Notification.Name("OpenSubscriptionFromNotification"),
            object: nil,
            userInfo: ["subscriptionId": subscriptionId]
        )
    }
    
    enum SubscriptionAction: String {
        case cancel = "cancel"
        case keep = "keep"
    }
}
