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
    @ObservedObject private var appPreferences = AppPreferences.shared
    @StateObject private var configManager = AIConfigManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingPremiumFeatures = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Premium Status (if applicable)
                if appPreferences.isPremiumUser {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Member")
                                    .font(.headline)
                                if let expiration = appPreferences.premiumExpirationDate {
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
                
                // Notifications Section
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
                    Text("Notifications")
                } footer: {
                    Text("Customize when and how you receive trial reminders")
                }
                
                    
                // Siri Shortcuts Section
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
                    Text("Voice Control")
                } footer: {
                    Text("Use Siri to quickly add trials or check their status")
                }
                
                
                // Trial Settings Section
                Section {
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
                    
                    NavigationLink(destination: CurrencySettingsView()) {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle")
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: appPreferences.currencyCode) {
                                    Text("\(currencyInfo.code) (\(currencyInfo.symbol))")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(appPreferences.currencyCode)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $appPreferences.showTrialLogos) {
                        Label("Show Service Icons", systemImage: "app.badge")
                    }
                } header: {
                    Text("Trial Settings")
                } footer: {
                    Text("Configure default settings for new trials")
                }
                
                // Quick Actions Style Section
                Section {
                    CardStyleSettingsView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Quick Actions")
                } footer: {
                    Text("Choose how you prefer to interact with subscription cards")
                }
                
                // Display Preferences Section
                Section {
                    // Theme selector
                    HStack {
                        Label("Theme", systemImage: appPreferences.appTheme.iconName)
                        Spacer()
                        Picker("", selection: $appPreferences.appTheme) {
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
                    
                    Toggle(isOn: $appPreferences.compactMode) {
                        Label("Compact View", systemImage: "rectangle.compress.vertical")
                    }
                    
                    Toggle(isOn: $appPreferences.groupByEndDate) {
                        Label("Group by End Date", systemImage: "calendar.badge.clock")
                    }
                } header: {
                    Text("Display Preferences")
                } footer: {
                    Text("Customize how trials are displayed in the app")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appPreferences.appVersion) (\(appPreferences.buildNumber))")
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
                
                // Premium Section
                Section {
                    Button(action: { showingPremiumFeatures = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Unlock Premium", systemImage: "star.circle")
                                    .foregroundColor(.primary)
                                Text("Get unlimited trials, advanced analytics & more")
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
                
                // Data Management Section
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
                
                // Advanced Section
                Section {
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
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("These settings help improve the app experience")
                }
            }
            .navigationTitle("Settings")
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
                    appPreferences.resetToDefaults()
                }
            } message: {
                Text("This will reset all preferences to their defaults.")
            }
            .sheet(isPresented: $showingPremiumFeatures) {
                PremiumFeaturesView()
            }
        }
    }
    
    private func clearAllData() {
        let subscriptionRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        let deleteSubscriptionsRequest = NSBatchDeleteRequest(fetchRequest: subscriptionRequest)
        
        let templateRequest: NSFetchRequest<NSFetchRequestResult> = ServiceTemplate.fetchRequest()
        let deleteTemplatesRequest = NSBatchDeleteRequest(fetchRequest: templateRequest)
        
        do {
            try viewContext.execute(deleteSubscriptionsRequest)
            try viewContext.execute(deleteTemplatesRequest)
            try viewContext.save()
        } catch {
            print("Error clearing data: \(error)")
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
    }
}
