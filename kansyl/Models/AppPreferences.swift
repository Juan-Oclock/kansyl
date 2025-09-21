//
//  AppPreferences.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import SwiftUI

class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    // MARK: - Default Trial Settings
    @AppStorage("defaultTrialLength") var defaultTrialLength: Int = 30
    @AppStorage("defaultTrialLengthUnit") private var defaultTrialLengthUnitRaw: String = TrialLengthUnit.days.rawValue
    
    var defaultTrialLengthUnit: TrialLengthUnit {
        get { TrialLengthUnit(rawValue: defaultTrialLengthUnitRaw) ?? .days }
        set { defaultTrialLengthUnitRaw = newValue.rawValue }
    }
    
    // MARK: - Currency Settings
    @AppStorage("currencyCode") var currencyCode: String = "USD" {
        didSet {
            // Automatically update currency symbol when currency code changes
            if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: currencyCode) {
                currencySymbol = currencyInfo.symbol
            }
            // Sync to standard UserDefaults for widget access
            UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
        }
    }
    @AppStorage("currencySymbol") var currencySymbol: String = "$" {
        didSet {
            // Sync to standard UserDefaults for widget access
            UserDefaults.standard.set(currencySymbol, forKey: "currencySymbol")
        }
    }
    
    // MARK: - Display Preferences
    @AppStorage("showTrialLogos") var showTrialLogos: Bool = true
    @AppStorage("compactMode") var compactMode: Bool = false
    @AppStorage("groupByEndDate") var groupByEndDate: Bool = true
    @AppStorage("appThemeRaw") var appThemeRaw: String = AppTheme.system.rawValue {
        didSet {
            objectWillChange.send()
        }
    }
    
    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { 
            appThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    // MARK: - Quiet Hours
    @AppStorage("quietHoursEnabled") var quietHoursEnabled: Bool = false
    @AppStorage("quietHoursStart") var quietHoursStart: Int = 22 // 10 PM
    @AppStorage("quietHoursEnd") var quietHoursEnd: Int = 8 // 8 AM
    
    // MARK: - Premium Status
    @AppStorage("isPremiumUser") var isPremiumUser: Bool = false
    @AppStorage("premiumExpirationDate") private var premiumExpirationTimestamp: Double = 0
    
    var premiumExpirationDate: Date? {
        get {
            guard premiumExpirationTimestamp > 0 else { return nil }
            return Date(timeIntervalSince1970: premiumExpirationTimestamp)
        }
        set {
            premiumExpirationTimestamp = newValue?.timeIntervalSince1970 ?? 0
        }
    }
    
    // MARK: - Analytics
    @AppStorage("analyticsEnabled") var analyticsEnabled: Bool = true
    @AppStorage("crashReportingEnabled") var crashReportingEnabled: Bool = true
    
    // MARK: - App Info
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    private init() {
        // Initialize currency settings in UserDefaults for widget access
        initializeCurrencySettings()
    }
    
    private func initializeCurrencySettings() {
        // Sync current AppStorage values to UserDefaults for widget access
        UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
        UserDefaults.standard.set(currencySymbol, forKey: "currencySymbol")
    }
    
    // MARK: - Helper Methods
    func resetToDefaults() {
        defaultTrialLength = 30
        defaultTrialLengthUnit = .days
        // Default to USD for easier international use
        currencyCode = "USD"
        currencySymbol = "$"
        showTrialLogos = true
        compactMode = false
        groupByEndDate = true
        appTheme = .system
        quietHoursEnabled = false
        quietHoursStart = 22
        quietHoursEnd = 8
        analyticsEnabled = true
        crashReportingEnabled = true
    }
    
    func getDefaultTrialEndDate(from startDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch defaultTrialLengthUnit {
        case .days:
            return calendar.date(byAdding: .day, value: defaultTrialLength, to: startDate) ?? startDate
        case .weeks:
            return calendar.date(byAdding: .weekOfYear, value: defaultTrialLength, to: startDate) ?? startDate
        case .months:
            return calendar.date(byAdding: .month, value: defaultTrialLength, to: startDate) ?? startDate
        }
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        if quietHoursStart < quietHoursEnd {
            // Normal case: e.g., 22:00 to 08:00
            return currentHour >= quietHoursStart || currentHour < quietHoursEnd
        } else {
            // Spans midnight: e.g., 22:00 to 08:00
            return currentHour >= quietHoursStart || currentHour < quietHoursEnd
        }
    }
}

enum TrialLengthUnit: String, CaseIterable {
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    
    var displayName: String {
        switch self {
        case .days: return "Days"
        case .weeks: return "Weeks"
        case .months: return "Months"
        }
    }
}

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
