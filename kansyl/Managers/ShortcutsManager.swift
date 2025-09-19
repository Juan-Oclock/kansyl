//
//  ShortcutsManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Intents
import IntentsUI
import SwiftUI
import CoreData

class ShortcutsManager: NSObject, ObservableObject {
    static let shared = ShortcutsManager()
    
    @Published var suggestedShortcuts: [INShortcut] = []
    
    private override init() {
        super.init()
        setupSuggestedShortcuts()
    }
    
    // MARK: - Setup Suggested Shortcuts
    private func setupSuggestedShortcuts() {
        // This will be implemented once .intentdefinition file is created
        // For now, we'll use placeholder user activities
        
        var shortcuts: [INShortcut] = []
        
        // Create user activity shortcuts as placeholders
        let checkActivity = NSUserActivity(activityType: "com.kansyl.checkTrials")
        checkActivity.title = "Check My Trials"
        checkActivity.suggestedInvocationPhrase = "Check my trials"
        checkActivity.isEligibleForSearch = true
        checkActivity.isEligibleForPrediction = true
        let checkShortcut = INShortcut(userActivity: checkActivity)
        shortcuts.append(checkShortcut)
        
        // Add trial shortcuts for popular services
        let popularServices = ["Netflix", "Spotify", "Disney+", "Amazon Prime", "Apple TV+", "Hulu"]
        for service in popularServices {
            let activity = NSUserActivity(activityType: "com.kansyl.addTrial")
            activity.title = "Add \(service) Trial"
            activity.suggestedInvocationPhrase = "Add \(service) trial"
            activity.userInfo = ["serviceName": service]
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            let shortcut = INShortcut(userActivity: activity)
            shortcuts.append(shortcut)
        }
        
        self.suggestedShortcuts = shortcuts
        
        // Update Siri suggestions
        INVoiceShortcutCenter.shared.setShortcutSuggestions(shortcuts)
    }
    
    // MARK: - Donate Shortcuts
    func donateAddTrialShortcut(for serviceName: String) {
        // Using NSUserActivity until intent types are available
        let activity = NSUserActivity(activityType: "com.kansyl.addTrial")
        activity.title = "Add \(serviceName) Trial"
        activity.userInfo = ["serviceName": serviceName]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Add \(serviceName) trial"
        
        activity.becomeCurrent()
    }
    
    func donateCheckTrialsShortcut() {
        let activity = NSUserActivity(activityType: "com.kansyl.checkTrials")
        activity.title = "Check My Trials"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Check my trials"
        
        activity.becomeCurrent()
    }
    
    func donateQuickAddShortcut(for serviceName: String) {
        let activity = NSUserActivity(activityType: "com.kansyl.quickAdd")
        activity.title = "Quick Add \(serviceName)"
        activity.userInfo = ["serviceName": serviceName]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Quick add \(serviceName)"
        
        activity.becomeCurrent()
    }
    
    // MARK: - Delete Shortcuts
    func deleteAllDonatedShortcuts() {
        INInteraction.deleteAll { _ in
            // Handle deletion result if needed
        }
    }
    
    func deleteDonatedShortcuts(with identifiers: [String]) {
        INInteraction.delete(with: identifiers) { _ in
            // Handle deletion result if needed
        }
    }
}

// MARK: - Intent Types Documentation
/*
 The following intent types will be auto-generated from the .intentdefinition file:
 
 1. AddTrialIntent - For adding a new trial
 2. CheckTrialsIntent - For checking trial status
 3. QuickAddTrialIntent - For quickly adding popular services
 
 Each intent will have corresponding:
 - Intent handling protocols
 - Response types
 - Response codes
 
 These will be automatically created when you add the .intentdefinition file in Xcode.
*/

// MARK: - Shortcut Button View
struct ShortcutButton: UIViewControllerRepresentable {
    let shortcut: INShortcut
    let onCompletion: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    init(shortcut: INShortcut, onCompletion: (() -> Void)? = nil) {
        self.shortcut = shortcut
        self.onCompletion = onCompletion
    }
    
    func makeUIViewController(context: Context) -> INUIAddVoiceShortcutViewController {
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: INUIAddVoiceShortcutViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
        let parent: ShortcutButton
        
        init(_ parent: ShortcutButton) {
            self.parent = parent
        }
        
        func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, 
                                           didFinishWith voiceShortcut: INVoiceShortcut?, 
                                           error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCompletion?()
        }
        
        func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Edit Shortcut Button View
struct EditShortcutButton: UIViewControllerRepresentable {
    let voiceShortcut: INVoiceShortcut
    let onCompletion: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    init(voiceShortcut: INVoiceShortcut, onCompletion: (() -> Void)? = nil) {
        self.voiceShortcut = voiceShortcut
        self.onCompletion = onCompletion
    }
    
    func makeUIViewController(context: Context) -> INUIEditVoiceShortcutViewController {
        let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: INUIEditVoiceShortcutViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, INUIEditVoiceShortcutViewControllerDelegate {
        let parent: EditShortcutButton
        
        init(_ parent: EditShortcutButton) {
            self.parent = parent
        }
        
        func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, 
                                            didUpdate voiceShortcut: INVoiceShortcut?, 
                                            error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCompletion?()
        }
        
        func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, 
                                            didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCompletion?()
        }
        
        func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
