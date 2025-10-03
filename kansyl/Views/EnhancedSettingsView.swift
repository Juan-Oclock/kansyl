//
//  EnhancedSettingsView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData

struct EnhancedSettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var appPreferences = AppPreferences.shared
    // CloudKit disabled for v1.0
    // @StateObject private var cloudKitManager = CloudKitManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingNotificationSettings = false
    @State private var showingPremiumFeatures = false
    @State private var showingExportSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingResetAlert = false
    @State private var showingContactSupport = false
    @State private var showingUserProfile = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Profile Section
                userProfileSection
                
                // Quick Settings
                quickSettingsSection
                
                // Notifications
                notificationsSection
                
                // App Preferences
                appPreferencesSection
                
                // Premium Features
                premiumSection
                
                // Data Management
                dataManagementSection
                
                // About & Support
                aboutSection
                
                // Advanced Settings
                advancedSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPremiumFeatures) {
                PremiumFeaturesView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(context: viewContext)
            }
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
            }
            .alert(isPresented: $showingClearDataAlert) {
                Alert(
                    title: Text("Clear All Data?"),
                    message: Text("This will permanently delete all your trial data. This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        clearAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset Settings?"),
                    message: Text("This will reset all app preferences to their default values."),
                    primaryButton: .default(Text("Reset")) {
                        appPreferences.resetToDefaults()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - User Profile Section
    private var userProfileSection: some View {
        Section("Account") {
            // User Profile Button
            Button(action: { showingUserProfile = true }) {
                HStack(spacing: 16) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                        
                        Text(getInitials(from: authManager.userProfile?.fullName ?? authManager.currentUser?.email ?? "U"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.userProfile?.fullName ?? "User")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let email = authManager.userProfile?.email ?? authManager.currentUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: authManager.isEmailVerified ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .font(.caption)
                                .foregroundColor(authManager.isEmailVerified ? .green : .orange)
                            
                            Text(authManager.isEmailVerified ? "Verified" : "Not Verified")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Sign Out Button
            Button(action: { showingSignOutAlert = true }) {
                HStack {
                    Label("Sign Out", systemImage: "arrow.right.square")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Quick Settings Section
    private var quickSettingsSection: some View {
        Section(header: Text("Quick Settings")) {
            Toggle(isOn: $appPreferences.showTrialLogos) {
                Label("Show Service Icons", systemImage: "app.badge")
            }
            
            Toggle(isOn: $appPreferences.compactMode) {
                Label("Compact View", systemImage: "rectangle.compress.vertical")
            }
            
            Toggle(isOn: $appPreferences.groupByEndDate) {
                Label("Group by End Date", systemImage: "calendar.badge.clock")
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Button(action: { showingNotificationSettings = true }) {
                HStack {
                    Label("Notification Settings", systemImage: "bell.badge")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(notificationManager.notificationsEnabled ? "On" : "Off")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quiet Hours
            Toggle(isOn: $appPreferences.quietHoursEnabled) {
                Label("Quiet Hours", systemImage: "moon.fill")
            }
            
            if appPreferences.quietHoursEnabled {
                HStack {
                    Text("From")
                    Spacer()
                    Picker("Start", selection: $appPreferences.quietHoursStart) {
                        ForEach(0..<24) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    Picker("End", selection: $appPreferences.quietHoursEnd) {
                        ForEach(0..<24) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
    
    // MARK: - App Preferences Section
    private var appPreferencesSection: some View {
        Section(header: Text("App Preferences")) {
            // Default Trial Length
            HStack {
                Label("Default Trial Length", systemImage: "calendar")
                Spacer()
                HStack(spacing: 4) {
                    TextField("Length", value: $appPreferences.defaultTrialLength, formatter: NumberFormatter())
                        .frame(width: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Picker("Unit", selection: $appPreferences.defaultTrialLengthUnit) {
                        ForEach(TrialLengthUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Currency Settings
            HStack {
                Label("Currency", systemImage: "dollarsign.circle")
                Spacer()
                Picker("Currency", selection: $appPreferences.currencyCode) {
                    Text("USD ($)").tag("USD")
                    Text("EUR (€)").tag("EUR")
                    Text("GBP (£)").tag("GBP")
                    Text("JPY (¥)").tag("JPY")
                    Text("CAD ($)").tag("CAD")
                    Text("AUD ($)").tag("AUD")
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    // MARK: - Premium Section
    private var premiumSection: some View {
        Section(header: Text("Premium")) {
            Button(action: { showingPremiumFeatures = true }) {
                HStack {
                    if appPreferences.isPremiumUser {
                        Label("Manage Subscription", systemImage: "star.circle.fill")
                            .foregroundColor(.primary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Unlock Premium", systemImage: "star.circle")
                                .foregroundColor(.primary)
                            Text("Track unlimited subscriptions & unlock all features")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        Section(header: Text("Data Management")) {
            Button(action: { showingExportSheet = true }) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            
            // CloudKit sync disabled for v1.0 - will be enabled as premium feature
            /*
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("iCloud Sync", systemImage: "icloud")
                    Spacer()
                    
                    if cloudKitManager.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { cloudKitManager.isSyncEnabled },
                            set: { enabled in
                                Task {
                                    do {
                                        if enabled {
                                            try await cloudKitManager.enableSync()
                                        } else {
                                            await cloudKitManager.disableSync()
                                        }
                                    } catch {
                                        // Handle error silently or show toast
                                    }
                                }
                            }
                        ))
                        .disabled(!cloudKitManager.canSync && !cloudKitManager.isSyncEnabled)
                    }
                }
                
                HStack {
                    Text(cloudKitManager.syncStatusMessage)
                        .font(.caption)
                        .foregroundColor(cloudKitManager.syncStatusColor)
                    
                    Spacer()
                    
                    if cloudKitManager.canSync && cloudKitManager.isSyncEnabled {
                        Button("Sync Now") {
                            Task {
                                try? await cloudKitManager.performManualSync()
                            }
                        }
                        .font(.caption)
                        .disabled(cloudKitManager.isSyncing)
                    }
                }
                
                if let lastSync = cloudKitManager.lastSyncDate {
                    Text("Last sync: \(formatSyncDate(lastSync))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            */
            
            Button(action: { showingClearDataAlert = true }) {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section("About & Support") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("\(appPreferences.appVersion) (\(appPreferences.buildNumber))")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                if let url = URL(string: "mailto:kansyl@juan-oclock.com?subject=Kansyl%20Support") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Contact Support", systemImage: "envelope")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("kansyl@juan-oclock.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                if let url = URL(string: "https://kansyl.juan-oclock.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Website", systemImage: "globe")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("kansyl.juan-oclock.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                if let url = URL(string: "https://kansyl.juan-oclock.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                if let url = URL(string: "https://kansyl.juan-oclock.com/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Advanced Section
    private var advancedSection: some View {
        Section(header: Text("Advanced"), footer: Text("These settings help improve the app experience")) {
            Toggle(isOn: $appPreferences.analyticsEnabled) {
                Label("Share Analytics", systemImage: "chart.bar.xaxis")
            }
            
            Toggle(isOn: $appPreferences.crashReportingEnabled) {
                Label("Crash Reporting", systemImage: "exclamationmark.triangle")
            }
            
            Button(action: { showingResetAlert = true }) {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getInitials(from text: String) -> String {
        let words = text.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        } else if let firstChar = text.first {
            return String(firstChar)
        }
        return "U"
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    @MainActor
    private func signOut() async {
        do {
            try await authManager.signOut()
        } catch {
            // Handle error - could show an error alert
            // Debug: print("Sign out error: \(error)")
        }
    }
    
    private func clearAllData() {
        // Only clear data for the current user
        guard let currentUserID = authManager.currentUser?.id.uuidString else {
            return
        }
        
        let subscriptionRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        subscriptionRequest.predicate = NSPredicate(format: "userID == %@", currentUserID)
        let deleteSubscriptionsRequest = NSBatchDeleteRequest(fetchRequest: subscriptionRequest)
        
        // ServiceTemplate might not have userID, check if it needs user filtering
        let templateRequest: NSFetchRequest<NSFetchRequestResult> = ServiceTemplate.fetchRequest()
        let deleteTemplatesRequest = NSBatchDeleteRequest(fetchRequest: templateRequest)
        
        do {
            try viewContext.execute(deleteSubscriptionsRequest)
            try viewContext.execute(deleteTemplatesRequest)
            try viewContext.save()
            
            // Refresh the subscription store after clearing data
            SubscriptionStore.shared.fetchSubscriptions()
        } catch {
            // Debug: print("Error clearing data: \(error)")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Preview
struct EnhancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedSettingsView()
            .environmentObject(NotificationManager.shared)
    }
}
