//
//  DebugHelper.swift
//  kansyl
//
//  Debug utilities for testing
//

import Foundation

struct DebugHelper {
    /// Clear the onboarding status for a specific user
    static func resetOnboardingForUser(_ userID: String?) {
        guard let userID = userID else { 
            // Debug: print("⚠️ No user ID provided to reset onboarding for")
            return 
        }
        
        let key = "user_\(userID)_hasCompletedOnboarding"
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
        // Debug: print("🗑 Cleared onboarding status for user: \(userID)")
    }
    
    /// Clear all stored preferences for testing
    static func clearAllUserPreferences() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.hasPrefix("user_") {
                defaults.removeObject(forKey: key)
                // Debug: print("🗑 Removed: \(key)")
            }
        }
        defaults.synchronize()
        // Debug: print("✅ All user preferences cleared")
    }
}