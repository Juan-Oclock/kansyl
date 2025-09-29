//
//  SubscriptionType.swift
//  kansyl
//
//  Created on 9/29/25.
//

import Foundation
import SwiftUI

enum SubscriptionType: String, CaseIterable, Codable {
    case trial = "trial"
    case paid = "paid"
    case promotional = "promotional"
    
    var displayName: String {
        switch self {
        case .trial: return "Free Trial"
        case .paid: return "Premium"
        case .promotional: return "Promo"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .trial: return "Trial"
        case .paid: return "Premium"
        case .promotional: return "Promo"
        }
    }
    
    var icon: String {
        switch self {
        case .trial: return "clock.badge.checkmark"
        case .paid: return "star.fill"
        case .promotional: return "gift"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .trial: return .orange
        case .paid: return Design.Colors.success
        case .promotional: return .purple
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .trial:
            return [Color.orange.opacity(0.8), Color.orange]
        case .paid:
            return [Design.Colors.success.opacity(0.8), Design.Colors.success]
        case .promotional:
            return [Color.purple.opacity(0.8), Color.purple]
        }
    }
    
    // Notification settings
    var notificationIntervals: [Int] {
        switch self {
        case .trial:
            // More aggressive reminders for trials (days before end)
            return [7, 3, 1, 0]
        case .paid:
            // Gentler reminders for paid subscriptions
            return [7, 1]
        case .promotional:
            // Medium frequency for promotional
            return [7, 3, 0]
        }
    }
    
    func notificationTitle(daysRemaining: Int) -> String {
        switch self {
        case .trial:
            if daysRemaining == 0 {
                return "⚠️ Trial Ending Today!"
            } else if daysRemaining == 1 {
                return "⏰ Trial Ends Tomorrow"
            } else {
                return "📅 Trial Ending Soon"
            }
        case .paid:
            if daysRemaining == 0 {
                return "💳 Renewal Today"
            } else {
                return "💳 Subscription Renewal"
            }
        case .promotional:
            if daysRemaining == 0 {
                return "🎁 Promo Ends Today!"
            } else {
                return "🎁 Promotional Period Ending"
            }
        }
    }
    
    func notificationBody(serviceName: String, daysRemaining: Int) -> String {
        switch self {
        case .trial:
            if daysRemaining == 0 {
                return "Your \(serviceName) free trial ends today. Decide if you want to continue or cancel."
            } else if daysRemaining == 1 {
                return "Your \(serviceName) free trial ends tomorrow. Time to make a decision!"
            } else {
                return "Your \(serviceName) free trial ends in \(daysRemaining) days. Consider if you want to keep it."
            }
        case .paid:
            if daysRemaining == 0 {
                return "Your \(serviceName) premium subscription renews today."
            } else {
                return "Your \(serviceName) premium subscription renews in \(daysRemaining) days."
            }
        case .promotional:
            if daysRemaining == 0 {
                return "Your \(serviceName) promotional period ends today. Regular pricing will apply."
            } else {
                return "Your \(serviceName) promotional period ends in \(daysRemaining) days."
            }
        }
    }
}