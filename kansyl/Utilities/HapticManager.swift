//
//  HapticManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import UIKit
import CoreHaptics

class HapticManager {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
        
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    // MARK: - Simple Haptics
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        default:
            break
        }
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Custom Haptic Patterns
    
    func playSuccess() {
        notification(.success)
    }
    
    func playError() {
        notification(.error)
    }
    
    func playWarning() {
        notification(.warning)
    }
    
    func playButtonTap() {
        impact(.light)
    }
    
    func playToggle() {
        impact(.medium)
    }
    
    func playSelection() {
        selection()
    }
    
    func playDeleteConfirmation() {
        impact(.heavy)
    }
    
    func playSubscriptionAdded() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            playSuccess()
            return
        }
        
        do {
            let pattern = try createSubscriptionAddedPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            playSuccess()
        }
    }
    
    func playTrialExpiring() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            playWarning()
            return
        }
        
        do {
            let pattern = try createExpiringPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            playWarning()
        }
    }
    
    func playAchievementUnlocked() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            playSuccess()
            return
        }
        
        do {
            let pattern = try createAchievementPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            playSuccess()
        }
    }
    
    // MARK: - Pattern Creation
    
    private func createSubscriptionAddedPattern() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [intensity, sharpness],
                                   relativeTime: 0)
        
        let event2 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [intensity, sharpness],
                                   relativeTime: 0.15)
        
        return try CHHapticPattern(events: [event1, event2], parameters: [])
    }
    
    private func createExpiringPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        for i in 0..<3 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                 value: Float(0.6 + Double(i) * 0.2))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                 value: 0.8)
            
            let event = CHHapticEvent(eventType: .hapticTransient,
                                    parameters: [intensity, sharpness],
                                    relativeTime: Double(i) * 0.2)
            events.append(event)
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func createAchievementPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Rising intensity pattern
        for i in 0..<4 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                 value: Float(0.3 + Double(i) * 0.2))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                 value: Float(0.3 + Double(i) * 0.1))
            
            let event = CHHapticEvent(eventType: .hapticTransient,
                                    parameters: [intensity, sharpness],
                                    relativeTime: Double(i) * 0.1)
            events.append(event)
        }
        
        // Final celebration burst
        let finalIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let finalSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let finalEvent = CHHapticEvent(eventType: .hapticContinuous,
                                     parameters: [finalIntensity, finalSharpness],
                                     relativeTime: 0.5,
                                     duration: 0.2)
        events.append(finalEvent)
        
        return try CHHapticPattern(events: events, parameters: [])
    }
}

// MARK: - SwiftUI View Modifier
struct HapticFeedback: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.impact(style)
            }
    }
}

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticFeedback(style: style))
    }
}
