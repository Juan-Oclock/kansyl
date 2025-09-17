//
//  NavigationCoordinator.swift
//  kansyl
//
//  Handles app-wide navigation between tabs
//

import SwiftUI

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var selectedTab: Int = 0
    @Published var showingAddSubscription = false
    
    private init() {}
    
    // Tab indices
    enum Tab: Int {
        case subscriptions = 0
        case history = 1
        case stats = 3
        case settings = 4
    }
    
    // Navigation methods
    func navigateToStats() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = Tab.stats.rawValue
        }
    }
    
    func navigateToSubscriptions() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = Tab.subscriptions.rawValue
        }
    }
    
    func navigateToHistory() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = Tab.history.rawValue
        }
    }
    
    func navigateToSettings() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = Tab.settings.rawValue
        }
    }
    
    func showAddSubscription() {
        showingAddSubscription = true
    }
}