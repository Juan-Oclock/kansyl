//
//  AppPreferencesMigration.swift
//  kansyl
//
//  Helper to migrate from AppPreferences to UserSpecificPreferences
//

import Foundation
import SwiftUI

// MARK: - Extension to make migration easier
extension AppPreferences {
    /// Sync values from UserSpecificPreferences for backward compatibility
    /// This allows existing code to work while we migrate
    func syncWithUserPreferences(_ userPrefs: UserSpecificPreferences) {
        // Sync theme
        if self.appTheme != userPrefs.appTheme {
            self.appTheme = userPrefs.appTheme
        }
        
        // Sync trial settings
        if self.defaultTrialLength != userPrefs.defaultTrialLength {
            self.defaultTrialLength = userPrefs.defaultTrialLength
        }
        if self.defaultTrialLengthUnit != userPrefs.defaultTrialLengthUnit {
            self.defaultTrialLengthUnit = userPrefs.defaultTrialLengthUnit
        }
        
        // Sync currency
        if self.currencyCode != userPrefs.currencyCode {
            self.currencyCode = userPrefs.currencyCode
        }
        if self.currencySymbol != userPrefs.currencySymbol {
            self.currencySymbol = userPrefs.currencySymbol
        }
        
        // Sync display preferences
        if self.showTrialLogos != userPrefs.showTrialLogos {
            self.showTrialLogos = userPrefs.showTrialLogos
        }
        if self.compactMode != userPrefs.compactMode {
            self.compactMode = userPrefs.compactMode
        }
        if self.groupByEndDate != userPrefs.groupByEndDate {
            self.groupByEndDate = userPrefs.groupByEndDate
        }
        
        // Sync quiet hours
        if self.quietHoursEnabled != userPrefs.quietHoursEnabled {
            self.quietHoursEnabled = userPrefs.quietHoursEnabled
        }
        if self.quietHoursStart != userPrefs.quietHoursStart {
            self.quietHoursStart = userPrefs.quietHoursStart
        }
        if self.quietHoursEnd != userPrefs.quietHoursEnd {
            self.quietHoursEnd = userPrefs.quietHoursEnd
        }
        
        // Sync premium status
        if self.isPremiumUser != userPrefs.isPremiumUser {
            self.isPremiumUser = userPrefs.isPremiumUser
        }
        if self.premiumExpirationDate != userPrefs.premiumExpirationDate {
            self.premiumExpirationDate = userPrefs.premiumExpirationDate
        }
        
        // Sync analytics
        if self.analyticsEnabled != userPrefs.analyticsEnabled {
            self.analyticsEnabled = userPrefs.analyticsEnabled
        }
        if self.crashReportingEnabled != userPrefs.crashReportingEnabled {
            self.crashReportingEnabled = userPrefs.crashReportingEnabled
        }
    }
    
    /// Create a UserSpecificPreferences from current AppPreferences values
    /// Useful for migrating existing user settings
    func migrateToUserPreferences(_ userPrefs: UserSpecificPreferences) {
        userPrefs.appTheme = self.appTheme
        userPrefs.defaultTrialLength = self.defaultTrialLength
        userPrefs.defaultTrialLengthUnit = self.defaultTrialLengthUnit
        userPrefs.currencyCode = self.currencyCode
        userPrefs.currencySymbol = self.currencySymbol
        userPrefs.showTrialLogos = self.showTrialLogos
        userPrefs.compactMode = self.compactMode
        userPrefs.groupByEndDate = self.groupByEndDate
        userPrefs.quietHoursEnabled = self.quietHoursEnabled
        userPrefs.quietHoursStart = self.quietHoursStart
        userPrefs.quietHoursEnd = self.quietHoursEnd
        userPrefs.isPremiumUser = self.isPremiumUser
        userPrefs.premiumExpirationDate = self.premiumExpirationDate
        userPrefs.analyticsEnabled = self.analyticsEnabled
        userPrefs.crashReportingEnabled = self.crashReportingEnabled
    }
}

// MARK: - View Modifier for easy migration
struct UserPreferencesModifier: ViewModifier {
    @StateObject private var userPreferences = UserSpecificPreferences.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(userPreferences)
            .onAppear {
                // Sync AppPreferences.shared with user preferences on appear
                AppPreferences.shared.syncWithUserPreferences(userPreferences)
            }
    }
}

extension View {
    /// Apply user-specific preferences to any view
    func withUserPreferences() -> some View {
        self.modifier(UserPreferencesModifier())
    }
}