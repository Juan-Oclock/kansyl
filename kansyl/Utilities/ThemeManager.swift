//
//  ThemeManager.swift
//  kansyl
//
//  Created on 1/17/25.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var cancellables = Set<AnyCancellable>()
    private var userPreferences: UserSpecificPreferences?
    
    private init() {
        // Initialize with system default
        currentTheme = .system
    }
    
    // Set the user preferences instance and subscribe to changes
    func setUserPreferences(_ userPrefs: UserSpecificPreferences) {
        self.userPreferences = userPrefs
        self.currentTheme = userPrefs.appTheme
        
        // Subscribe to theme changes from UserSpecificPreferences
        userPrefs.$appTheme
            .sink { [weak self] newTheme in
                DispatchQueue.main.async {
                    self?.currentTheme = newTheme
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    // Get the effective color scheme based on user preference
    func effectiveColorScheme(systemScheme: ColorScheme) -> ColorScheme {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemScheme
        }
    }
    
    // Check if dark mode is active
    func isDarkMode(systemScheme: ColorScheme) -> Bool {
        return effectiveColorScheme(systemScheme: systemScheme) == .dark
    }
    
    // Apply theme to the app
    func applyTheme() {
        // This will trigger UI updates through the @Published property
        objectWillChange.send()
    }
}

// MARK: - Theme-aware View Modifier
struct ThemedView: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(preferredColorScheme)
    }
    
    private var preferredColorScheme: ColorScheme? {
        switch themeManager.currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Let system decide
        }
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedView())
    }
}

// MARK: - Dynamic Color Extension
extension Design.Colors {
    // Helper function to get colors based on current theme
    static func getColor(light: Color, dark: Color) -> Color {
        let themeManager = ThemeManager.shared
        let currentTheme = themeManager.currentTheme
        
        switch currentTheme {
        case .light:
            return light
        case .dark:
            return dark
        case .system:
            // For system mode, we still use the dynamic approach
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(dark)
                case .light, .unspecified:
                    return UIColor(light)
                @unknown default:
                    return UIColor(light)
                }
            })
        }
    }
}

// MARK: - Updated Color Accessors with Theme Support
extension Design.Colors {
    // Override the static color accessors to be theme-aware
    static var primary: Color {
        getColor(light: Light.primary, dark: Dark.primary)
    }
    
    static var primaryLight: Color {
        getColor(light: Light.primaryLight, dark: Dark.primaryLight)
    }
    
    static var secondary: Color {
        getColor(light: Light.secondary, dark: Dark.secondary)
    }
    
    static var buttonPrimary: Color {
        getColor(light: Light.buttonPrimary, dark: Dark.buttonPrimary)
    }
    
    static var primaryButtonText: Color {
        getColor(light: Light.primaryButtonText, dark: Dark.primaryButtonText)
    }
    
    static var background: Color {
        getColor(light: Light.background, dark: Dark.background)
    }
    
    static var surface: Color {
        getColor(light: Light.surface, dark: Dark.surface)
    }
    
    static var highlightBackground: Color {
        getColor(light: Light.highlightBackground, dark: Dark.highlightBackground)
    }
    
    static var surfaceSecondary: Color {
        getColor(light: Light.surfaceSecondary, dark: Dark.surfaceSecondary)
    }
    
    static var textPrimary: Color {
        getColor(light: Light.textPrimary, dark: Dark.textPrimary)
    }
    
    static var textSecondary: Color {
        getColor(light: Light.textSecondary, dark: Dark.textSecondary)
    }
    
    static var textTertiary: Color {
        getColor(light: Light.textTertiary, dark: Dark.textTertiary)
    }
    
    static var success: Color {
        getColor(light: Light.success, dark: Dark.success)
    }
    
    static var warning: Color {
        getColor(light: Light.warning, dark: Dark.warning)
    }
    
    static var danger: Color {
        getColor(light: Light.danger, dark: Dark.danger)
    }
    
    static var neutral: Color {
        getColor(light: Light.neutral, dark: Dark.neutral)
    }
    
    static var info: Color {
        getColor(light: Light.info, dark: Dark.info)
    }
    
    static var border: Color {
        getColor(light: Light.border, dark: Dark.border)
    }
    
    static var borderLight: Color {
        getColor(light: Light.borderLight, dark: Dark.borderLight)
    }
    
    static var active: Color {
        getColor(light: Light.active, dark: Dark.active)
    }
    
    static var saved: Color {
        getColor(light: Light.saved, dark: Dark.saved)
    }
    
    static var kept: Color {
        getColor(light: Light.kept, dark: Dark.kept)
    }
    
    static var expired: Color {
        getColor(light: Light.expired, dark: Dark.expired)
    }
}