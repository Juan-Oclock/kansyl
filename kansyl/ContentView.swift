//
//  ContentView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/12/25.
//  Updated to match new navigation design
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var subscriptionStore: SubscriptionStore
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _subscriptionStore = StateObject(wrappedValue: SubscriptionStore(context: context))
        
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        if hasCompletedOnboarding {
            mainAppView
        } else {
            OnboardingView()
        }
    }
    
    var mainAppView: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch navigationCoordinator.selectedTab {
                case 0:
                    ModernSubscriptionsView(context: viewContext)
                case 1:
                    HistoryView()
                case 3:
                    StatsView(context: viewContext)
                case 4:
                    SettingsView()
                default:
                    ModernSubscriptionsView(context: viewContext)
                }
            }
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Spacer()
                
                customTabBar
                    .background(
                        Design.Colors.surface
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .sheet(isPresented: $navigationCoordinator.showingAddSubscription) {
            AddSubscriptionView(subscriptionStore: subscriptionStore) { savedSubscription in
                // After saving, navigate back to Subscriptions tab
                navigationCoordinator.selectedTab = 0
                
                // Post notification that a subscription was added
                NotificationCenter.default.post(name: .subscriptionAdded, object: nil)
                
                // Track analytics
                AnalyticsManager.shared.track(.subscriptionAdded, properties: AnalyticsProperties(
                    source: "center_tab_button"
                ))
            }
            .environment(\.managedObjectContext, viewContext)
        }
    }
    
    var customTabBar: some View {
        HStack(spacing: 0) {
            // Subscription Tab
            TabBarButton(
                icon: "creditcard.fill",
                label: "Subscription",
                isSelected: navigationCoordinator.selectedTab == 0
            ) {
                navigationCoordinator.selectedTab = 0
                HapticManager.shared.playButtonTap()
            }
            
            // History Tab
            TabBarButton(
                icon: "clock.arrow.circlepath",
                label: "History",
                isSelected: navigationCoordinator.selectedTab == 1
            ) {
                navigationCoordinator.selectedTab = 1
                HapticManager.shared.playButtonTap()
            }
            
            // Center Add Button
            Button(action: {
                HapticManager.shared.playButtonTap()
                navigationCoordinator.showingAddSubscription = true
            }) {
                ZStack {
                    Circle()
                        .fill(Design.Colors.buttonPrimary)
                        .frame(width: 56, height: 56)
                        .shadow(color: Design.Colors.buttonPrimary.opacity(0.3), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(navigationCoordinator.showingAddSubscription ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: navigationCoordinator.showingAddSubscription)
                }
            }
            .offset(y: -10)
            
            // Stats Tab
            TabBarButton(
                icon: "chart.bar.fill",
                label: "Stats",
                isSelected: navigationCoordinator.selectedTab == 3
            ) {
                navigationCoordinator.selectedTab = 3
                HapticManager.shared.playButtonTap()
            }
            
            // Settings Tab
            TabBarButton(
                icon: "gearshape.fill",
                label: "Settings",
                isSelected: navigationCoordinator.selectedTab == 4
            ) {
                navigationCoordinator.selectedTab = 4
                HapticManager.shared.playButtonTap()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Design.Colors.surface)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.textTertiary)
                
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}