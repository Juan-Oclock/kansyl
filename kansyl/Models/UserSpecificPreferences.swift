//
//  UserSpecificPreferences.swift
//  kansyl
//
//  User-isolated preferences system to prevent preference leakage between users
//

import Foundation
import SwiftUI
import Supabase

class UserSpecificPreferences: ObservableObject {
    static let shared = UserSpecificPreferences()
    
    init() {
        // Initialize with default values
    }
    
    // Current user ID
    private var currentUserID: String?
    
    // UserDefaults suite for isolation
    private let defaults = UserDefaults.standard
    
    // MARK: - User Management
    func setCurrentUser(_ userID: String?) {
        currentUserID = userID
        objectWillChange.send()
        
        // When user changes, reload all preferences
        if userID != nil {
            loadUserPreferences()
        } else {
            // User logged out - reset to defaults but don't save
            resetToDefaultsWithoutSaving()
        }
    }
    
    // MARK: - Helper to get user-specific key
    private func userKey(_ key: String) -> String {
        guard let userID = currentUserID else {
            // Fallback to global key if no user (shouldn't happen in normal flow)
            return "global_\(key)"
        }
        return "user_\(userID)_\(key)"
    }
    
    // MARK: - User-Specific Properties
    
    // Theme
    @Published var appTheme: AppTheme = .system {
        didSet { savePreference(appTheme.rawValue, for: "appTheme") }
    }
    
    // Default Trial Settings
    @Published var defaultTrialLength: Int = 30 {
        didSet { savePreference(defaultTrialLength, for: "defaultTrialLength") }
    }
    
    @Published var defaultTrialLengthUnit: TrialLengthUnit = .days {
        didSet { savePreference(defaultTrialLengthUnit.rawValue, for: "defaultTrialLengthUnit") }
    }
    
    // Currency Settings
    @Published var currencyCode: String = "USD" {
        didSet {
            savePreference(currencyCode, for: "currencyCode")
            // Update symbol when code changes
            if let currencyInfo = CurrencyManager.shared.getCurrencyInfo(for: currencyCode) {
                currencySymbol = currencyInfo.symbol
            }
        }
    }
    
    @Published var currencySymbol: String = "$" {
        didSet { savePreference(currencySymbol, for: "currencySymbol") }
    }
    
    // Display Preferences
    @Published var showTrialLogos: Bool = true {
        didSet { savePreference(showTrialLogos, for: "showTrialLogos") }
    }
    
    @Published var compactMode: Bool = false {
        didSet { savePreference(compactMode, for: "compactMode") }
    }
    
    @Published var groupByEndDate: Bool = true {
        didSet { savePreference(groupByEndDate, for: "groupByEndDate") }
    }
    
    // Quiet Hours
    @Published var quietHoursEnabled: Bool = false {
        didSet { savePreference(quietHoursEnabled, for: "quietHoursEnabled") }
    }
    
    @Published var quietHoursStart: Int = 22 {
        didSet { savePreference(quietHoursStart, for: "quietHoursStart") }
    }
    
    @Published var quietHoursEnd: Int = 8 {
        didSet { savePreference(quietHoursEnd, for: "quietHoursEnd") }
    }
    
    // Premium Status (per user)
    @Published var isPremiumUser: Bool = false {
        didSet { savePreference(isPremiumUser, for: "isPremiumUser") }
    }
    
    @Published var premiumExpirationDate: Date? {
        didSet { 
            savePreference(premiumExpirationDate?.timeIntervalSince1970 ?? 0, for: "premiumExpirationDate")
        }
    }
    
    // Analytics (per user)
    @Published var analyticsEnabled: Bool = true {
        didSet { savePreference(analyticsEnabled, for: "analyticsEnabled") }
    }
    
    @Published var crashReportingEnabled: Bool = true {
        didSet { savePreference(crashReportingEnabled, for: "crashReportingEnabled") }
    }
    
    // Onboarding Status (per user)
    @Published var hasCompletedOnboarding: Bool = false {
        willSet {
            objectWillChange.send() // Send before change
        }
        didSet { 
            savePreference(hasCompletedOnboarding, for: "hasCompletedOnboarding")
        }
    }
    
    // MARK: - Persistence Methods
    
    private func savePreference<T>(_ value: T, for key: String) {
        guard currentUserID != nil else { 
            return 
        }
        let fullKey = userKey(key)
        defaults.set(value, forKey: fullKey)
        defaults.synchronize()
    }
    
    private func loadPreference<T>(for key: String, defaultValue: T) -> T {
        guard currentUserID != nil else { return defaultValue }
        return defaults.object(forKey: userKey(key)) as? T ?? defaultValue
    }
    
    // MARK: - Load User Preferences
    private func loadUserPreferences() {
        guard currentUserID != nil else { return }
        
        // Temporarily disable didSet to prevent recursive saves during loading
        let wasCompleted = loadPreference(for: "hasCompletedOnboarding", defaultValue: false)
        
        // Load all preferences for the current user
        appTheme = AppTheme(rawValue: loadPreference(for: "appTheme", defaultValue: AppTheme.system.rawValue)) ?? .system
        defaultTrialLength = loadPreference(for: "defaultTrialLength", defaultValue: 30)
        defaultTrialLengthUnit = TrialLengthUnit(rawValue: loadPreference(for: "defaultTrialLengthUnit", defaultValue: TrialLengthUnit.days.rawValue)) ?? .days
        
        // Currency - detect from location if not set
        let detectedCurrency = CurrencyManager.shared.detectCurrencyFromLocation()
        currencyCode = loadPreference(for: "currencyCode", defaultValue: detectedCurrency?.code ?? "USD")
        currencySymbol = loadPreference(for: "currencySymbol", defaultValue: detectedCurrency?.symbol ?? "$")
        
        // Display preferences
        showTrialLogos = loadPreference(for: "showTrialLogos", defaultValue: true)
        compactMode = loadPreference(for: "compactMode", defaultValue: false)
        groupByEndDate = loadPreference(for: "groupByEndDate", defaultValue: true)
        
        // Quiet hours
        quietHoursEnabled = loadPreference(for: "quietHoursEnabled", defaultValue: false)
        quietHoursStart = loadPreference(for: "quietHoursStart", defaultValue: 22)
        quietHoursEnd = loadPreference(for: "quietHoursEnd", defaultValue: 8)
        
        // Premium status
        isPremiumUser = loadPreference(for: "isPremiumUser", defaultValue: false)
        let premiumTimestamp = loadPreference(for: "premiumExpirationDate", defaultValue: 0.0)
        premiumExpirationDate = premiumTimestamp > 0 ? Date(timeIntervalSince1970: premiumTimestamp) : nil
        
        // Analytics
        analyticsEnabled = loadPreference(for: "analyticsEnabled", defaultValue: true)
        crashReportingEnabled = loadPreference(for: "crashReportingEnabled", defaultValue: true)
        
        // Onboarding - set this last and trigger UI update if needed
        if wasCompleted != hasCompletedOnboarding {
            hasCompletedOnboarding = wasCompleted
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        } else {
            hasCompletedOnboarding = wasCompleted
        }
    }
    
    // MARK: - Reset Methods
    
    func resetToDefaults() {
        defaultTrialLength = 30
        defaultTrialLengthUnit = .days
        let detectedCurrency = CurrencyManager.shared.detectCurrencyFromLocation()
        currencyCode = detectedCurrency?.code ?? "USD"
        currencySymbol = detectedCurrency?.symbol ?? "$"
        showTrialLogos = true
        compactMode = false
        groupByEndDate = true
        appTheme = .system
        quietHoursEnabled = false
        quietHoursStart = 22
        quietHoursEnd = 8
        analyticsEnabled = true
        crashReportingEnabled = true
        // Note: Don't reset hasCompletedOnboarding or premium status
    }
    
    private func resetToDefaultsWithoutSaving() {
        // Reset to defaults without triggering saves (for logout)
        let detectedCurrency = CurrencyManager.shared.detectCurrencyFromLocation()
        
        _appTheme = Published(initialValue: .system)
        _defaultTrialLength = Published(initialValue: 30)
        _defaultTrialLengthUnit = Published(initialValue: .days)
        _currencyCode = Published(initialValue: detectedCurrency?.code ?? "USD")
        _currencySymbol = Published(initialValue: detectedCurrency?.symbol ?? "$")
        _showTrialLogos = Published(initialValue: true)
        _compactMode = Published(initialValue: false)
        _groupByEndDate = Published(initialValue: true)
        _quietHoursEnabled = Published(initialValue: false)
        _quietHoursStart = Published(initialValue: 22)
        _quietHoursEnd = Published(initialValue: 8)
        _analyticsEnabled = Published(initialValue: true)
        _crashReportingEnabled = Published(initialValue: true)
        _isPremiumUser = Published(initialValue: false)
        _premiumExpirationDate = Published(initialValue: nil)
        _hasCompletedOnboarding = Published(initialValue: false)
    }
    
    // MARK: - Clear User Data
    func clearUserData() {
        guard let userID = currentUserID else { return }
        
        // Get all keys for this user and remove them
        let userPrefix = "user_\(userID)_"
        let allKeys = defaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.hasPrefix(userPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
        
        defaults.synchronize()
        currentUserID = nil
        resetToDefaultsWithoutSaving()
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - App Info (global)
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}