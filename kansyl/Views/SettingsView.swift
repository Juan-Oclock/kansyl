//
//  SettingsView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @EnvironmentObject private var userPreferences: UserSpecificPreferences
    @ObservedObject private var userStateManager = UserStateManager.shared
    @StateObject private var configManager = AIConfigManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingPremiumFeatures = false
    @State private var showingResetAlert = false
    @State private var showingUserProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var showingSignInSheet = false
    @State private var showingNotificationsView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header - similar to other views
                customHeader
                    .background(Design.Colors.background)
                
                Form {
                // Anonymous Mode Warning (if applicable)
                if userStateManager.isAnonymousMode && !authManager.isAuthenticated {
                    anonymousModeWarningSection
                }
                
                // User Profile Section
                if authManager.isAuthenticated {
                    userProfileSection
                }
                
                // Premium Status (if applicable)
                if userPreferences.isPremiumUser {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Design.Colors.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Member")
                                    .font(.headline)
                                if let expiration = userPreferences.premiumExpirationDate {
                                    Text("Expires \(expiration, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Lifetime Access")
                                        .font(.caption)
                                        .foregroundColor(Design.Colors.success)
                                }
                            }
                            Spacer()
                            Image(systemName: "star.circle.fill")
                                .font(.title)
                                .foregroundColor(Design.Colors.warning)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 1. Display Preferences Section
                Section {
                    // Theme selector
                    HStack {
                        Label("Theme", systemImage: userPreferences.appTheme.iconName)
                        Spacer()
                        Picker("", selection: $userPreferences.appTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                HStack {
                                    Image(systemName: theme.iconName)
                                    Text(theme.displayName)
                                }
                                .tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                    
                    Toggle(isOn: $userPreferences.compactMode) {
                        Label("Compact View", systemImage: "rectangle.compress.vertical")
                    }
                    
                    Toggle(isOn: $userPreferences.groupByEndDate) {
                        Label("Group by End Date", systemImage: "calendar.badge.clock")
                    }
                } header: {
                    Text("Display Preferences")
                } footer: {
                    Text("Customize how trials are displayed in the app")
                }
                
                // 2. Trial Settings Section
                Section {
                    NavigationLink(destination: TrialLengthSettingsView()) {
                        HStack {
                            Label("Default Trial Length", systemImage: "calendar")
                            Spacer()
                            Text("\(userPreferences.defaultTrialLength) \(userPreferences.defaultTrialLengthUnit.displayName)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: CurrencySettingsView()) {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle")
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: userPreferences.currencyCode) {
                                    Text("\(currencyInfo.code) (\(currencyInfo.symbol))")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(userPreferences.currencyCode)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $userPreferences.showTrialLogos) {
                        Label("Show Service Icons", systemImage: "app.badge")
                    }
                } header: {
                    Text("Trial Settings")
                } footer: {
                    Text("Configure default settings for new trials")
                }
                
                // 3. Notification Settings Section
                Section {
                    // View Notifications
                    Button(action: { showingNotificationsView = true }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(Design.Colors.primary)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Notifications")
                                    .foregroundColor(.primary)
                                Text("Manage delivered and scheduled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Notification Settings
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(Design.Colors.primary)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notification Settings")
                                    .foregroundColor(.primary)
                                Text(notificationManager.notificationsEnabled ? "Enabled" : "Tap to set up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("View your notifications and customize reminder preferences")
                }
                
                // 4. Quick Actions Section
                Section {
                    NavigationLink(destination: CardStyleSettingsDetailView()) {
                        HStack {
                            Label("Card Interaction Style", systemImage: "hand.tap.fill")
                            Spacer()
                            Text(userPreferences.preferredCardStyle.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Quick Actions")
                } footer: {
                    Text("Choose how you prefer to interact with subscription cards")
                }
                
                // 5. Siri Section
                Section {
                    NavigationLink(destination: SiriShortcutsView()) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(Design.Colors.info)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Siri Shortcuts")
                                    .foregroundColor(.primary)
                                Text("Add voice commands for trials")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Siri")
                } footer: {
                    Text("Use Siri to quickly add trials or check their status")
                }
                
                // 6. Premium Features Section
                Section {
                    Button(action: { showingPremiumFeatures = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Unlock Premium", systemImage: "star.circle")
                                    .foregroundColor(.primary)
                                Text("Track unlimited subscriptions & unlock all features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Premium Features")
                }
                
                // 7. Data Management Section
                Section {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingClearDataAlert = true }) {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(Design.Colors.danger)
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export your trial data as JSON or permanently delete all data from this device.")
                }
                
                // 8. Advanced Section
                Section {
                    Toggle(isOn: $userPreferences.analyticsEnabled) {
                        Label("Share Analytics", systemImage: "chart.bar.xaxis")
                    }
                    Toggle(isOn: $userPreferences.crashReportingEnabled) {
                        Label("Crash Reporting", systemImage: "exclamationmark.triangle")
                    }
                    Button(action: { showingResetAlert = true }) {
                        Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("These settings help improve the app experience")
                }
                
                // DEBUG Section (Simulator Only)
                #if DEBUG
                Section {
                    Toggle(isOn: Binding(
                        get: { PremiumManager.shared.isPremium },
                        set: { newValue in
                            if newValue {
                                Task { @MainActor in
                                    PremiumManager.shared.enableTestPremium()
                                }
                            } else {
                                Task { @MainActor in
                                    PremiumManager.shared.disableTestPremium()
                                }
                            }
                        }
                    )) {
                        Label("Enable Test Premium", systemImage: "ladybug")
                    }
                } header: {
                    Text("🐛 DEBUG (Simulator Only)")
                } footer: {
                    Text("Enable premium features for testing on simulator. This toggle only works in DEBUG builds.")
                }
                #endif
                
                // 9. About & Support Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(userPreferences.appVersion) (\(userPreferences.buildNumber))")
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
                    
                    Link(destination: URL(string: "https://kansyl.juan-oclock.com")!) {
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
                    
                    Link(destination: URL(string: "https://kansyl.juan-oclock.com/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://kansyl.juan-oclock.com/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About & Support")
                }
            }
            .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
            .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your trial data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(context: viewContext)
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingNotificationsView) {
                NotificationsView()
                    .environmentObject(notificationManager)
                    .environmentObject(SubscriptionStore.shared)
            }
            .alert("Reset All Settings?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    userPreferences.resetToDefaults()
                }
            } message: {
                Text("This will reset all preferences to their defaults.")
            }
            .sheet(isPresented: $showingPremiumFeatures) {
                PremiumFeaturesView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
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
            .alert("Sign Out Error", isPresented: $showingSignOutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(signOutErrorMessage)
            }
            .sheet(isPresented: $showingSignInSheet) {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(userStateManager)
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Design.Colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    
    // MARK: - Anonymous Mode Warning Section
    private var anonymousModeWarningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Warning Icon and Title
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Design.Colors.warning)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Account")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Using without sign-in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Warning Message
                Text("Your data is stored only on this device and is not backed up to the cloud. Create an account to sync across devices and keep your data safe.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Subscription Limit Info
                let subscriptionCount = SubscriptionStore.shared.allSubscriptions.count
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(subscriptionCount >= userStateManager.anonymousSubscriptionLimit ? Design.Colors.danger : Design.Colors.warning)
                    
                    Text("\(subscriptionCount) / \(userStateManager.anonymousSubscriptionLimit) subscriptions used")
                        .font(.caption)
                        .foregroundColor(subscriptionCount >= userStateManager.anonymousSubscriptionLimit ? Design.Colors.danger : Design.Colors.textSecondary)
                }
                
                // Create Account Button
                Button(action: {
                    showingSignInSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Create Account or Sign In")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Design.Colors.primary, Design.Colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
        } header: {
            Text("Account Status")
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
                            .fill(Design.Colors.primary)
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
                                .foregroundColor(authManager.isEmailVerified ? Design.Colors.success : Design.Colors.warning)
                            
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
                        .foregroundColor(Design.Colors.danger)
                    Spacer()
                }
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
    
    @MainActor
    private func signOut() async {
        do {
            print("🔑 [SettingsView] Starting sign out process...")
            try await authManager.signOut()
            print("✅ [SettingsView] Sign out completed successfully")
            
            // Add haptic feedback for successful sign out
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ [SettingsView] Sign out failed: \(error.localizedDescription)")
            
            // Show error to user
            signOutErrorMessage = "Failed to sign out: \(error.localizedDescription)"
            showingSignOutError = true
            
            // Add error haptic feedback
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
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
}

private var dateFormatter: DateFormatter {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(NotificationManager.shared)
            .environmentObject(SupabaseAuthManager.shared)
    }
}
