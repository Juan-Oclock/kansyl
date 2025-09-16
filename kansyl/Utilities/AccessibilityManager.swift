//
//  AccessibilityManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

// MARK: - Accessibility Labels and Hints
extension View {
    func accessibleSubscriptionCard(_ subscription: Subscription) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(subscription.name ?? "Unknown service") subscription")
            .accessibilityHint(accessibilityHintForSubscription(subscription))
            .accessibilityAddTraits(subscription.status == SubscriptionStatus.active.rawValue ? [] : .isButton)
    }
    
    private func accessibilityHintForSubscription(_ subscription: Subscription) -> String {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: subscription.endDate ?? Date()).day ?? 0
        let statusText: String
        
        switch subscription.status {
        case SubscriptionStatus.active.rawValue:
            statusText = "\(daysRemaining) days remaining. Ends on \(subscription.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "unknown date")"
        case SubscriptionStatus.expired.rawValue:
            statusText = "Expired"
        case SubscriptionStatus.canceled.rawValue:
            statusText = "Cancelled"
        case SubscriptionStatus.kept.rawValue:
            statusText = "Kept"
        default:
            statusText = "Unknown status"
        }
        
        return "\(statusText). Double tap to view details."
    }
    
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleStatCard(title: String, value: String, trend: String? = nil) -> some View {
        let label = trend != nil ? "\(title): \(value), \(trend!)" : "\(title): \(value)"
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
    
    func accessibleChart(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Dynamic Type Support
struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var size: CGFloat
    var weight: Font.Weight = .regular
    var design: Font.Design = .default
    
    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

// MARK: - High Contrast Support
struct HighContrastBorder: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        differentiateWithoutColor ? Color.primary : Color.clear,
                        lineWidth: differentiateWithoutColor ? 2 : 0
                    )
            )
    }
}

extension View {
    func highContrastBorder() -> some View {
        modifier(HighContrastBorder())
    }
}

// MARK: - Reduced Motion Support
struct ReducedMotionAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var animation: Animation
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .none : animation, value: UUID())
    }
}

extension View {
    func reducedMotionAnimation(_ animation: Animation) -> some View {
        modifier(ReducedMotionAnimation(animation: animation))
    }
}

// MARK: - VoiceOver Announcements
class AccessibilityAnnouncer {
    static func announce(_ message: String, delay: Double = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announceLayoutChange() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
    
    static func announceScreenChange(focusView: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: focusView)
    }
}

// MARK: - Accessibility Focus Management
struct AccessibilityFocus: ViewModifier {
    @AccessibilityFocusState var isFocused: Bool
    let shouldFocus: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onAppear {
                if shouldFocus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFocused = true
                    }
                }
            }
    }
}

extension View {
    func initialAccessibilityFocus(_ shouldFocus: Bool = true) -> some View {
        modifier(AccessibilityFocus(shouldFocus: shouldFocus))
    }
}

// MARK: - Custom Rotor Support
struct SubscriptionRotor: ViewModifier {
    let subscriptions: [Subscription]
    
    func body(content: Content) -> some View {
        content.accessibilityRotor("Active Subscriptions") {
            ForEach(subscriptions.filter { $0.status == SubscriptionStatus.active.rawValue }, id: \.objectID) { subscription in
                AccessibilityRotorEntry("\(subscription.name ?? "Unknown") - \(daysRemaining(for: subscription)) days left", id: subscription.objectID)
            }
        }
        .accessibilityRotor("Expiring Soon") {
            ForEach(subscriptions.filter { isExpiringSoon($0) }, id: \.objectID) { subscription in
                AccessibilityRotorEntry("\(subscription.name ?? "Unknown") - \(daysRemaining(for: subscription)) days left", id: subscription.objectID)
            }
        }
    }
    
    private func daysRemaining(for subscription: Subscription) -> Int {
        guard let endDate = subscription.endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    private func isExpiringSoon(_ subscription: Subscription) -> Bool {
        daysRemaining(for: subscription) <= 3 && subscription.status == SubscriptionStatus.active.rawValue
    }
}

extension View {
    func subscriptionAccessibilityRotor(_ subscriptions: [Subscription]) -> some View {
        modifier(SubscriptionRotor(subscriptions: subscriptions))
    }
}
