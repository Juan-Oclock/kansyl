//
//  AuthenticationWrapperView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//

import SwiftUI

struct AuthenticationWrapperView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @ObservedObject private var userStateManager = UserStateManager.shared
    // Device-level onboarding (not user-specific)
    @AppStorage("device_has_completed_onboarding") private var deviceHasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !deviceHasCompletedOnboarding {
                // Show onboarding first (before login)
                OnboardingView(deviceHasCompletedOnboarding: $deviceHasCompletedOnboarding)
                    .environmentObject(authManager)
            } else if authManager.isAuthenticated || userStateManager.isAnonymousMode {
                // User is authenticated OR in anonymous mode - show main app
                ContentView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                    .environmentObject(NotificationManager.shared)
                    .environmentObject(AppPreferences.shared)
                    .environmentObject(ThemeManager.shared)
                    .environmentObject(authManager)
                    .environmentObject(userStateManager)
            } else {
                // Device onboarding complete but user not authenticated - show login
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(userStateManager)
            }
        }
        .environmentObject(userPreferences)
        .themed()
        .onAppear {
            // Set the current user ID in the shared SubscriptionStore and preferences
            // Priority: anonymous user ID > authenticated user ID
            let userID: String?
            if userStateManager.isAnonymousMode {
                userID = userStateManager.getAnonymousUserID()
            } else {
                userID = authManager.currentUser?.id.uuidString
            }
            print("[AuthWrapper] onAppear - Setting userID: \(userID ?? "nil") (anonymous: \(userStateManager.isAnonymousMode))")
            SubscriptionStore.shared.updateCurrentUser(userID: userID)
            userPreferences.setCurrentUser(userID)
            
            // Connect theme manager to user preferences early
            ThemeManager.shared.setUserPreferences(userPreferences)
        }
        .onChange(of: authManager.currentUser?.id.uuidString) { newUserID in
            // Update the shared SubscriptionStore and preferences when user changes
            // Priority: anonymous user ID > authenticated user ID
            let userID: String?
            if userStateManager.isAnonymousMode {
                userID = userStateManager.getAnonymousUserID()
            } else {
                userID = newUserID
            }
            print("[AuthWrapper] onChange - User changed, new userID: \(userID ?? "nil") (anonymous: \(userStateManager.isAnonymousMode))")
            SubscriptionStore.shared.updateCurrentUser(userID: userID)
            userPreferences.setCurrentUser(userID)
            
            // Reconnect theme manager to user preferences when user changes
            ThemeManager.shared.setUserPreferences(userPreferences)
        }
    }
}

struct AuthenticationWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationWrapperView()
    }
}