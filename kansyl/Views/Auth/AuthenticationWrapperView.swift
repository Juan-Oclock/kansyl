//
//  AuthenticationWrapperView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//

import SwiftUI

struct AuthenticationWrapperView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if hasCompletedOnboarding {
                    // User is authenticated and has completed onboarding - show main app
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                        .environmentObject(NotificationManager.shared)
                        .environmentObject(AppPreferences.shared)
                        .environmentObject(ThemeManager.shared)
                        .environmentObject(authManager)
                } else {
                    // User is authenticated but needs onboarding
                    OnboardingView()
                        .environmentObject(authManager)
                }
            } else {
                // User is not authenticated - show login
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Set the current user ID in the shared SubscriptionStore
            SubscriptionStore.shared.updateCurrentUser(userID: authManager.currentUser?.id.uuidString)
        }
        .onChange(of: authManager.currentUser?.id.uuidString) { newUserID in
            // Update the shared SubscriptionStore when user changes
            SubscriptionStore.shared.updateCurrentUser(userID: newUserID)
        }
    }
}

struct AuthenticationWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationWrapperView()
    }
}