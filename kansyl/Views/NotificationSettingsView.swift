//
//  NotificationSettingsView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject private var appPreferences = AppPreferences.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingPermissionAlert = false
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // Permission Section
                Section {
                    HStack {
                        Image(systemName: notificationManager.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(notificationManager.notificationsEnabled ? Design.Colors.success : Design.Colors.danger)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.headline)
                            Text(notificationManager.notificationsEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.notificationsEnabled {
                            Button("Enable") {
                                checkAndRequestPermission()
                            }
                            .foregroundColor(Design.Colors.info)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if !notificationManager.notificationsEnabled {
                        Text("Enable notifications to receive reminders about your trial endings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if notificationManager.notificationsEnabled {
                    // Reminder Types Section
                    Section(header: Text("Reminder Types")) {
                        Toggle(isOn: $notificationManager.threeDayReminder) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(Design.Colors.info)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("3-Day Warning")
                                    Text("Get reminded 3 days before trial ends")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Toggle(isOn: $notificationManager.oneDayReminder) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Design.Colors.warning)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("1-Day Urgent")
                                    Text("Urgent reminder 1 day before")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Toggle(isOn: $notificationManager.dayOfReminder) {
                            HStack {
                                Image(systemName: "alarm.fill")
                                    .foregroundColor(Design.Colors.danger)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Day-Of Alert")
                                    Text("Final alert on the day trial ends")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Notification Time Section
                    Section(header: Text("Notification Time")) {
                        DatePicker(
                            "Preferred Time",
                            selection: Binding(
                                get: {
                                    let calendar = Calendar.current
                                    var components = DateComponents()
                                    components.hour = notificationManager.notificationHour
                                    components.minute = notificationManager.notificationMinute
                                    return calendar.date(from: components) ?? Date()
                                },
                                set: { newDate in
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: newDate)
                                    notificationManager.notificationHour = components.hour ?? 9
                                    notificationManager.notificationMinute = components.minute ?? 0
                                    notificationManager.savePreferences()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        
                        Text("All reminders will be sent at this time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quiet Hours Section
                    Section(header: Text("Quiet Hours")) {
                        Toggle(isOn: $appPreferences.quietHoursEnabled) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(Design.Colors.primary)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Quiet Hours")
                                    Text("Mute notifications during these hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if appPreferences.quietHoursEnabled {
                            HStack {
                                Text("From")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("Start", selection: $appPreferences.quietHoursStart) {
                                    ForEach(0..<24) { hour in
                                        Text("\(String(format: "%02d:00", hour))").tag(hour)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                Text("to")
                                    .foregroundColor(.secondary)
                                
                                Picker("End", selection: $appPreferences.quietHoursEnd) {
                                    ForEach(0..<24) { hour in
                                        Text("\(String(format: "%02d:00", hour))").tag(hour)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                    
                    // Notification Preview Section
                    Section(header: Text("Preview")) {
                        VStack(alignment: .leading, spacing: 12) {
                            NotificationPreview(
                                title: "⏰ Netflix trial ends in 3 days",
                                subtitle: "$15.99/month after trial",
                                bodyText: "Take action now to avoid unwanted charges. Tap to decide.",
                                time: "3 days before",
                                urgency: .normal
                            )
                            
                            NotificationPreview(
                                title: "⚠️ Spotify trial ends TOMORROW",
                                subtitle: "$9.99/month after trial",
                                bodyText: "Last chance to cancel! You'll be charged tomorrow if you don't act.",
                                time: "1 day before",
                                urgency: .urgent
                            )
                            
                            NotificationPreview(
                                title: "🚨 Disney+ trial ends TODAY!",
                                subtitle: "$7.99/month after trial",
                                bodyText: "Final warning! Cancel now or you'll be charged.",
                                time: "Day of trial end",
                                urgency: .critical
                            )
                        }
                    }
                    
                    // Test Notification Section
                    Section {
                        Button(action: sendTestNotification) {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Send Test Notification")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                trailing: Button("Done") {
                    notificationManager.savePreferences()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("Please enable notifications in Settings to receive trial reminders."),
                primaryButton: .default(Text("Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func checkAndRequestPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    notificationManager.requestNotificationPermission()
                } else if settings.authorizationStatus == .denied {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Test Notification"
        content.subtitle = "Your notifications are working!"
        content.body = "You'll receive reminders at your preferred time before trials end."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Test notification sent
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct NotificationPreview: View {
    let title: String
    let subtitle: String
    let bodyText: String
    let time: String
    let urgency: NotificationUrgency
    
    enum NotificationUrgency {
        case normal, urgent, critical
        
        var color: Color {
            switch self {
            case .normal: return Design.Colors.info
            case .urgent: return Design.Colors.warning
            case .critical: return Design.Colors.danger
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "app.badge.fill")
                    .foregroundColor(Design.Colors.info)
                Text("Kansyl")
                    .font(.system(.caption, design: .default).weight(.medium))
                Spacer()
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(bodyText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Cancel Trial")
                        .font(.system(.caption2, design: .default).weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Design.Colors.success.opacity(0.15))
                        .foregroundColor(Design.Colors.success)
                        .cornerRadius(6)
                }
                .disabled(true)
                
                Button(action: {}) {
                    Text("Keep Service")
                        .font(.system(.caption2, design: .default).weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Design.Colors.primary.opacity(0.15))
                        .foregroundColor(Design.Colors.primary)
                        .cornerRadius(6)
                }
                .disabled(true)
                
                if urgency == .normal {
                    Button(action: {}) {
                        Text("Snooze")
                            .font(.system(.caption2, design: .default).weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Design.Colors.neutral.opacity(0.15))
                            .foregroundColor(Design.Colors.textSecondary)
                            .cornerRadius(6)
                    }
                    .disabled(true)
                }
            }
        }
        .padding()
        .background(Design.Colors.surfaceSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgency.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}
