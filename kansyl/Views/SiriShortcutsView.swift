//
//  SiriShortcutsView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import Intents
import IntentsUI

// Wrapper to make INShortcut work with SwiftUI sheets without conformance warning
struct IdentifiableShortcut: Identifiable {
    let id = UUID()
    let shortcut: INShortcut
    
    init(_ shortcut: INShortcut) {
        self.shortcut = shortcut
    }
}

struct SiriShortcutsView: View {
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @State private var selectedShortcut: IdentifiableShortcut?
    @State private var existingVoiceShortcuts: [INVoiceShortcut] = []
    
    var body: some View {
        List {
            // Header Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Siri Shortcuts")
                                .font(.headline)
                            Text("Add voice commands to manage trials")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Text("Say \"Hey Siri\" followed by your phrase to quickly add trials or check their status.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // My Shortcuts Section
            if !existingVoiceShortcuts.isEmpty {
                Section(header: Text("My Shortcuts")) {
                    ForEach(existingVoiceShortcuts, id: \.identifier) { voiceShortcut in
                        VoiceShortcutRow(voiceShortcut: voiceShortcut) {
                            loadExistingShortcuts()
                        }
                    }
                }
            }
            
            // Suggested Shortcuts Section
            Section(header: Text("Suggested Shortcuts")) {
                // Generic Add Trial Shortcut
                ShortcutRow(
                    icon: "plus.circle.fill",
                    title: "Add a Trial",
                    phrase: "Add trial",
                    color: .purple
                ) {
                    createAndPresentGenericAddTrialShortcut()
                }
                
                // Check Trials Shortcut
                ShortcutRow(
                    icon: "list.bullet",
                    title: "Check My Trials",
                    phrase: "Check my trials",
                    color: .blue
                ) {
                    createAndPresentShortcut(for: "Check My Trials", activityType: "com.kansyl.checkTrials")
                }
                
                // Popular Services - Direct Add
                ForEach(popularServices, id: \.self) { service in
                    ShortcutRow(
                        icon: service.icon,
                        title: "Add \(service.name) Trial",
                        phrase: "Add \(service.name) trial",
                        color: service.color
                    ) {
                        createAndPresentShortcut(
                            for: "Add \(service.name) Trial",
                            activityType: "com.kansyl.quickAddTrial",  // Use quickAdd for direct add
                            userInfo: ["serviceName": service.name, "autoAdd": true]
                        )
                    }
                }
            }
            
            // Quick Actions Section
            Section(header: Text("Quick Actions")) {
                ShortcutRow(
                    icon: "bolt.fill",
                    title: "Quick Add Netflix",
                    phrase: "Quick add Netflix",
                    color: .red
                ) {
                    createAndPresentShortcut(
                        for: "Quick Add Netflix",
                        activityType: "com.kansyl.quickAddTrial",
                        userInfo: ["serviceName": "Netflix", "quick": true]
                    )
                }
                
                ShortcutRow(
                    icon: "bolt.fill",
                    title: "Quick Add Spotify",
                    phrase: "Quick add Spotify",
                    color: .green
                ) {
                    createAndPresentShortcut(
                        for: "Quick Add Spotify",
                        activityType: "com.kansyl.quickAddTrial",
                        userInfo: ["serviceName": "Spotify", "quick": true]
                    )
                }
            }
            
            // Tips Section
            Section(header: Text("Tips")) {
                TipRow(
                    icon: "lightbulb.fill",
                    text: "You can also create shortcuts in the Shortcuts app"
                )
                
                TipRow(
                    icon: "mic.fill",
                    text: "Customize the phrase for each shortcut"
                )
                
                TipRow(
                    icon: "bell.fill",
                    text: "Shortcuts work with notifications enabled"
                )
            }
        }
        .navigationTitle("Siri Shortcuts")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadExistingShortcuts()
        }
        .sheet(item: $selectedShortcut) { identifiableShortcut in
            ShortcutButton(shortcut: identifiableShortcut.shortcut) {
                // Refresh shortcuts list after adding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadExistingShortcuts()
                }
            }
            .ignoresSafeArea()
            .onDisappear {
                selectedShortcut = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadExistingShortcuts() {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let shortcuts = shortcuts {
                DispatchQueue.main.async {
                    self.existingVoiceShortcuts = shortcuts
                }
            }
        }
    }
    
    private func createAndPresentShortcut(for title: String, activityType: String, userInfo: [String: Any]? = nil) {
        // Create a user activity for the shortcut
        let userActivity = NSUserActivity(activityType: activityType)
        userActivity.title = title
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = title.lowercased().replacingOccurrences(of: "add ", with: "Add ")
        userActivity.persistentIdentifier = "\(activityType)-\(UUID().uuidString)"
        
        if let userInfo = userInfo {
            userActivity.userInfo = userInfo
        }
        
        // Create an INShortcut from the user activity
        let shortcut = INShortcut(userActivity: userActivity)
        selectedShortcut = IdentifiableShortcut(shortcut)
    }
    
    private func createAndPresentGenericAddTrialShortcut() {
        // Create a generic user activity that accepts any service name
        let userActivity = NSUserActivity(activityType: "com.kansyl.addTrial")
        userActivity.title = "Add Trial"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        
        // Use a more flexible invocation phrase that Siri can parse
        userActivity.suggestedInvocationPhrase = "Add trial"
        userActivity.persistentIdentifier = "generic-add-trial-\(UUID().uuidString)"
        
        // Set up for variable input
        userActivity.userInfo = ["acceptsVariableInput": true]
        userActivity.requiredUserInfoKeys = Set(["serviceName"])
        
        // Create an INShortcut from the user activity
        let shortcut = INShortcut(userActivity: userActivity)
        selectedShortcut = IdentifiableShortcut(shortcut)
    }
    
    private func createCheckTrialsIntent() -> INIntent {
        // Use NSUserActivity-based intent for checking trials
        let userActivity = NSUserActivity(activityType: "com.kansyl.checkTrials")
        userActivity.title = "Check My Trials"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Check my trials"
        userActivity.persistentIdentifier = "check-trials"
        
        // Create an INShortcut from the user activity
        let intent = userActivity.interaction?.intent ?? INIntent()
        return intent
    }
    
    private func createAddTrialIntent(for serviceName: String) -> INIntent {
        // Use NSUserActivity-based intent for adding a trial
        let userActivity = NSUserActivity(activityType: "com.kansyl.addTrial")
        userActivity.title = "Add \(serviceName) Trial"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Add \(serviceName) trial"
        userActivity.persistentIdentifier = "add-trial-\(serviceName.lowercased())" 
        userActivity.userInfo = ["serviceName": serviceName]
        
        let intent = userActivity.interaction?.intent ?? INIntent()
        return intent
    }
    
    private func createQuickAddIntent(for serviceName: String) -> INIntent {
        // Use NSUserActivity-based intent for quick add
        let userActivity = NSUserActivity(activityType: "com.kansyl.quickAddTrial")
        userActivity.title = "Quick Add \(serviceName)"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Quick add \(serviceName)"
        userActivity.persistentIdentifier = "quick-add-\(serviceName.lowercased())"
        userActivity.userInfo = ["serviceName": serviceName, "quick": true]
        
        let intent = userActivity.interaction?.intent ?? INIntent()
        return intent
    }
    
    // MARK: - Data
    private let popularServices = [
        ServiceShortcut(name: "Netflix", icon: "tv", color: .red),
        ServiceShortcut(name: "Spotify", icon: "music.note", color: .green),
        ServiceShortcut(name: "Disney+", icon: "star.fill", color: .blue),
        ServiceShortcut(name: "Amazon Prime", icon: "cart.fill", color: .orange),
        ServiceShortcut(name: "Apple TV+", icon: "appletv", color: .black),
        ServiceShortcut(name: "Hulu", icon: "h.square.fill", color: .green)
    ]
}

struct ServiceShortcut: Hashable {
    let name: String
    let icon: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct ShortcutRow: View {
    let icon: String
    let title: String
    let phrase: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("\"Hey Siri, \(phrase)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoiceShortcutRow: View {
    let voiceShortcut: INVoiceShortcut
    let onUpdate: (() -> Void)?
    @State private var showingEdit = false
    
    init(voiceShortcut: INVoiceShortcut, onUpdate: (() -> Void)? = nil) {
        self.voiceShortcut = voiceShortcut
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        Button(action: { showingEdit = true }) {
            HStack {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceShortcut.invocationPhrase)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    let shortcut = voiceShortcut.shortcut
                    if let userActivity = shortcut.userActivity {
                        Text(userActivity.title ?? "Shortcut")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let intent = shortcut.intent {
                        Text(String(describing: type(of: intent)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEdit) {
            EditShortcutButton(voiceShortcut: voiceShortcut) {
                // Refresh shortcuts list after editing or deleting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onUpdate?()
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SiriShortcutsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SiriShortcutsView()
        }
    }
}
