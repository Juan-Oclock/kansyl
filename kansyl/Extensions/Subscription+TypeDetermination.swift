//
//  Subscription+TypeDetermination.swift
//  kansyl
//
//  Created on 9/29/25.
//

import Foundation
import CoreData

extension Subscription {
    
    /// Set the subscription type manually
    func setSubscriptionType(_ type: SubscriptionType) {
        self.subscriptionType = type.rawValue
        self.isTrial = (type == .trial)
        
        // Set trial end date if it's a trial
        if type == .trial {
            self.trialEndDate = self.endDate
        }
    }
    
    /// Determine subscription type based on various heuristics
    func determineType() -> SubscriptionType {
        // Priority 1: Check name/title for keywords (highest priority)
        if let name = self.name?.lowercased() {
            // Check for promotional keywords first
            if name.contains("promo") || name.contains("promotional") || name.contains("discount") {
                return .promotional
            } else if name.contains("trial") || name.contains("free") {
                return .trial
            }
        }
        
        // Priority 2: Check notes for keywords
        if let notes = self.notes?.lowercased() {
            // Check for promotional keywords first
            if notes.contains("promo") || notes.contains("promotional") || notes.contains("discount") {
                return .promotional
            } else if notes.contains("trial") || notes.contains("free") {
                return .trial
            }
        }
        
        // Priority 3: Check if it's already marked as a trial (legacy support)
        // This is now lower priority than explicit keywords
        if self.isTrial && self.name?.lowercased().contains("promo") != true && 
           self.notes?.lowercased().contains("promo") != true {
            return .trial
        }
        
        // Priority 4: Check duration
        if let startDate = self.startDate,
           let endDate = self.endDate {
            let duration = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            
            switch duration {
            case 0...30:
                // Most trials are 30 days or less
                // But check price first - if paid, it's likely a monthly subscription
                if self.monthlyPrice > 0 {
                    // 30 days with a price is likely a monthly paid subscription
                    // Unless it has trial/promo keywords (already checked above)
                    return .paid
                } else {
                    return .trial
                }
                
            case 31...90:
                // Could be a quarterly subscription or extended trial
                if self.monthlyPrice == 0 {
                    return .trial
                } else {
                    // Already checked for promo keywords above
                    return .paid
                }
                
            case 91...365:
                // Likely a paid annual subscription
                return .paid
                
            default:
                // Very long duration, assume paid
                return .paid
            }
        }
        
        // Priority 5: Check if price is zero (free trial)
        if self.monthlyPrice == 0 {
            return .trial
        }
        
        // Default: If we have a price but can't determine duration, assume paid
        // This is safer than defaulting to trial for subscriptions with costs
        if self.monthlyPrice > 0 {
            return .paid
        }
        
        // Final fallback: Default to trial if we really can't determine
        return .trial
    }
    
    /// Check if subscription type needs updating based on current values
    func needsTypeUpdate() -> Bool {
        guard let currentTypeString = self.subscriptionType,
              let currentType = SubscriptionType(rawValue: currentTypeString) else {
            // No type set, needs update
            return true
        }
        
        let determinedType = determineType()
        return currentType != determinedType
    }
}