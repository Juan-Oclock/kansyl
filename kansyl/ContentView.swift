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
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @EnvironmentObject private var userPreferences: UserSpecificPreferences  // This will trigger updates
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var userStateManager = UserStateManager.shared
    
    // Success toast state
    @State private var showSuccessToast = false
    @State private var successToastMessage = ""
    @State private var successToastAmount: String? = nil
    
    init() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        // ContentView now assumes onboarding is complete (checked by AuthenticationWrapperView)
        mainAppView
            .onAppear {
                // Update subscription store with current user ID
                // Priority: anonymous user ID > authenticated user ID
                let userID: String?
                if userStateManager.isAnonymousMode {
                    userID = userStateManager.getAnonymousUserID()
                } else {
                    userID = authManager.currentUser?.id.uuidString
                }
                print("[ContentView] onAppear - Setting userID: \(userID ?? "nil") (anonymous: \(userStateManager.isAnonymousMode))")
                subscriptionStore.updateCurrentUser(userID: userID)
                
                // Connect theme manager to user preferences
                themeManager.setUserPreferences(userPreferences)
                
                // Sync user preferences to app preferences for backward compatibility
                AppPreferences.shared.syncWithUserPreferences(userPreferences)
            }
            .onChange(of: authManager.currentUser?.id.uuidString) { newUserID in
                // Update subscription store when user changes
                // Priority: anonymous user ID > authenticated user ID
                let userID: String?
                if userStateManager.isAnonymousMode {
                    userID = userStateManager.getAnonymousUserID()
                } else {
                    userID = newUserID
                }
                print("[ContentView] onChange - User changed, new userID: \(userID ?? "nil") (anonymous: \(userStateManager.isAnonymousMode))")
                subscriptionStore.updateCurrentUser(userID: userID)
            }
            .onChange(of: userPreferences.appTheme) { _ in
                // Force UI refresh when theme changes
                themeManager.applyTheme()
                
                // Sync the theme change to app preferences for backward compatibility
                AppPreferences.shared.syncWithUserPreferences(userPreferences)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionAddedFromEmail"))) { notification in
                print("🔔 [ContentView] Received SubscriptionAddedFromEmail notification")
                print("   UserInfo: \(notification.userInfo?.description ?? "nil")")
                
                // Show success toast when subscription is added from share extension
                if let userInfo = notification.userInfo,
                   let serviceName = userInfo["serviceName"] as? String {
                    let isDuplicate = userInfo["isDuplicate"] as? Bool ?? false
                    
                    if isDuplicate {
                        print("🔄 [ContentView] Showing duplicate notification for: \(serviceName)")
                        successToastMessage = "Already tracking \(serviceName)"
                    } else {
                        print("🎉 [ContentView] Showing success toast for: \(serviceName)")
                        successToastMessage = "\(serviceName) subscription added!"
                    }
                    
                    successToastAmount = nil // We could calculate savings if needed
                    
                    // Use animation when showing the toast
                    withAnimation(.spring()) {
                        showSuccessToast = true
                    }
                    print("   Toast state - showing: \(showSuccessToast), message: \(successToastMessage)")
                    
                    // Play haptic feedback (lighter for duplicate)
                    if isDuplicate {
                        HapticManager.shared.playSelection()
                    } else {
                        HapticManager.shared.playSuccess()
                    }
                    
                    // Navigate to subscriptions tab to show the subscription
                    navigationCoordinator.selectedTab = 0
                } else {
                    print("⚠️ [ContentView] Could not extract serviceName from notification")
                }
            }
    }
    
    var mainAppView: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch navigationCoordinator.selectedTab {
                case 0:
                    ModernSubscriptionsView()
                        .environmentObject(subscriptionStore)
                        .environmentObject(authManager)
                        .environmentObject(NotificationManager.shared)
                case 1:
                    HistoryView()
                        .environmentObject(subscriptionStore)
                case 3:
                    StatsView()
                        .environmentObject(subscriptionStore)
                case 4:
                    SettingsView()
                        .environmentObject(NotificationManager.shared)
                        .environmentObject(authManager)
                default:
                    ModernSubscriptionsView()
                        .environmentObject(subscriptionStore)
                        .environmentObject(authManager)
                        .environmentObject(NotificationManager.shared)
                }
            }
            .id("main-content-\(themeManager.currentTheme.rawValue)")
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Spacer()
                
                customTabBar
                    .id("tabbar-\(themeManager.currentTheme.rawValue)")
                    .background(
                        Design.Colors.surface
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .overlay(
            // Success toast for share extension imports - inline implementation
            VStack {
                if showSuccessToast {
                    HStack(spacing: 12) {
                        // Success icon
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Message
                        Text(successToastMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSuccessToast = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(
                                color: Color.green.opacity(0.2),
                                radius: 12,
                                x: 0,
                                y: 4
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .onAppear {
                        // Auto dismiss after 4 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSuccessToast = false
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .animation(.spring(), value: showSuccessToast)
            .zIndex(1002) // Above everything else
        )
        .sheet(isPresented: $navigationCoordinator.showingAddSubscription) {
            AddSubscriptionMethodSelector(subscriptionStore: subscriptionStore) { savedSubscription in
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
                        .foregroundColor(Design.Colors.primaryButtonText)
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