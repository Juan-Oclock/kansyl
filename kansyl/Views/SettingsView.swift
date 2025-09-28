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
    @StateObject private var configManager = AIConfigManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingPremiumFeatures = false
    @State private var showingResetAlert = false
    @State private var showingUserProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingResetOnboardingAlert = false
    @State private var showingSignOutError = false
    @State private var signOutErrorMessage = ""
    @FocusState private var isTrialLengthFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header - similar to other views
                customHeader
                    .background(Design.Colors.background)
                
                Form {
                // User Profile Section
                userProfileSection
                
                // Premium Status (if applicable)
                if userPreferences.isPremiumUser {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
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
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            Image(systemName: "star.circle.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
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
                    HStack {
                        Label("Default Trial Length", systemImage: "calendar")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("Length", value: $userPreferences.defaultTrialLength, formatter: NumberFormatter())
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .focused($isTrialLengthFocused)
                            
                            Picker("Unit", selection: $userPreferences.defaultTrialLengthUnit) {
                                ForEach(TrialLengthUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
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
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.blue)
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
                    Text("Notification Settings")
                } footer: {
                    Text("Customize when and how you receive trial reminders")
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
                                .foregroundColor(.purple)
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
                            .foregroundColor(.red)
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
                    
                    #if DEBUG
                    Button(action: { showingResetOnboardingAlert = true }) {
                        Label("Reset Onboarding (Debug)", systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left")
                            .foregroundColor(.purple)
                    }
                    #endif
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("These settings help improve the app experience")
                }
                
                // 9. About & Support Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(userPreferences.appVersion) (\(userPreferences.buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@kansyl.app?subject=Kansyl%20Support") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Label("Contact Support", systemImage: "envelope")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("support@kansyl.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://twitter.com/kansylapp") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Label("Follow Us", systemImage: "at")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("@kansylapp")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://kansyl.app")!) {
                        HStack {
                            Label("Website", systemImage: "globe")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("kansyl.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://kansyl.app/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://kansyl.app/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/app/kansyl/id123456789") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Label("Rate on App Store", systemImage: "star")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About & Support")
                } footer: {
                    Text("Made with ❤️ in San Francisco\n© 2025 Kansyl. All rights reserved.")
                        .multilineTextAlignment(.center)
                        .font(.caption)
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
            .alert("Reset Onboarding?", isPresented: $showingResetOnboardingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetOnboarding()
                }
            } message: {
                Text("This will show the onboarding screen again next time you open the app.")
            }
            .alert("Sign Out Error", isPresented: $showingSignOutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(signOutErrorMessage)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTrialLengthFocused = false
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Design.Colors.primary)
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
    
    private func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "device_has_completed_onboarding")
        UserDefaults.standard.synchronize()
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
