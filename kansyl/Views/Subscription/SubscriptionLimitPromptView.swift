//
//  SubscriptionLimitPromptView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//  Prompt shown when user hits subscription limit in anonymous mode
//

import SwiftUI

struct SubscriptionLimitPromptView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @EnvironmentObject private var userStateManager: UserStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignUp = false
    @State private var showingLogin = false
    @State private var headerAnimation = false
    @State private var contentAnimation = false
    @State private var buttonAnimation = false
    
    let subscriptionLimit: Int = 5
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Modern background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Design.Colors.background,
                            Design.Colors.background.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // Close indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Design.Colors.border.opacity(0.4))
                            .frame(width: 36, height: 4)
                            .padding(.top, Design.Spacing.md)
                            .scaleEffect(headerAnimation ? 1.0 : 0.8)
                            .opacity(headerAnimation ? 1.0 : 0.0)
                            .animation(Design.Animation.spring.delay(0.1), value: headerAnimation)
                        
                        Spacer(minLength: geometry.size.height * 0.08)
                        
                        // Header with icon
                        VStack(spacing: Design.Spacing.xl) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Design.Colors.warning.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Design.Colors.warning)
                            }
                            .scaleEffect(headerAnimation ? 1.0 : 0.8)
                            .opacity(headerAnimation ? 1.0 : 0.0)
                            .animation(Design.Animation.spring.delay(0.2), value: headerAnimation)
                            
                            VStack(spacing: Design.Spacing.md) {
                                Text("Subscription Limit Reached")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Design.Colors.primary, Design.Colors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                
                                Text("You've reached the limit of \(subscriptionLimit) subscriptions for accounts without sign-in.")
                                    .font(Design.Typography.body(.medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                            .opacity(contentAnimation ? 1.0 : 0.0)
                            .offset(y: contentAnimation ? 0 : 20)
                            .animation(Design.Animation.spring.delay(0.4), value: contentAnimation)
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        
                        Spacer(minLength: geometry.size.height * 0.08)
                        
                        // Benefits section
                        VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                            Text("Create an account to unlock:")
                                .font(Design.Typography.headline(.semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            VStack(spacing: Design.Spacing.md) {
                                FeatureBenefitRow(
                                    icon: "infinity",
                                    title: "Unlimited Subscriptions",
                                    description: "Track as many subscriptions as you need"
                                )
                                
                                FeatureBenefitRow(
                                    icon: "cloud.fill",
                                    title: "Cloud Backup",
                                    description: "Your data is safely backed up and synced"
                                )
                                
                                FeatureBenefitRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Multi-Device Sync",
                                    description: "Access your subscriptions from any device"
                                )
                            }
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.vertical, Design.Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.xl)
                                .fill(Design.Colors.surface)
                                .shadow(
                                    color: Design.Colors.textPrimary.opacity(0.05),
                                    radius: 12,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .padding(.horizontal, Design.Spacing.xl)
                        .opacity(contentAnimation ? 1.0 : 0.0)
                        .offset(y: contentAnimation ? 0 : 30)
                        .animation(Design.Animation.spring.delay(0.6), value: contentAnimation)
                        
                        Spacer(minLength: geometry.size.height * 0.08)
                        
                        // Action buttons
                        VStack(spacing: Design.Spacing.md) {
                            // Sign Up button (primary)
                            Button(action: {
                                showingSignUp = true
                            }) {
                                Text("Create Account")
                                    .font(Design.Typography.headline(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [Design.Colors.primary, Design.Colors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(Design.Radius.xl)
                                    .shadow(
                                        color: Design.Colors.primary.opacity(0.3),
                                        radius: 16,
                                        x: 0,
                                        y: 8
                                    )
                            }
                            
                            // Sign In button (secondary)
                            Button(action: {
                                showingLogin = true
                            }) {
                                Text("Sign In to Existing Account")
                                    .font(Design.Typography.headline(.semibold))
                                    .foregroundColor(Design.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: Design.Radius.xl)
                                            .stroke(Design.Colors.primary.opacity(0.3), lineWidth: 1.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: Design.Radius.xl)
                                                    .fill(Design.Colors.primary.opacity(0.05))
                                            )
                                    )
                            }
                            
                            // Cancel button (tertiary)
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Maybe Later")
                                    .font(Design.Typography.subheadline(.medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .underline()
                            }
                            .padding(.top, Design.Spacing.sm)
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                        .offset(y: buttonAnimation ? 0 : 30)
                        .animation(Design.Animation.spring.delay(0.8), value: buttonAnimation)
                        
                        Spacer(minLength: Design.Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                startAnimationSequence()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
                    .environmentObject(authManager)
                    .onDisappear {
                        // If user successfully signed up, dismiss this prompt
                        if authManager.isAuthenticated {
                            dismiss()
                        }
                    }
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(userStateManager)
                    .onDisappear {
                        // If user successfully logged in, dismiss this prompt
                        if authManager.isAuthenticated {
                            dismiss()
                        }
                    }
            }
        }
    }
    
    private func startAnimationSequence() {
        withAnimation {
            headerAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                contentAnimation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                buttonAnimation = true
            }
        }
    }
}

// MARK: - Feature Benefit Row

struct FeatureBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Design.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Design.Colors.primary)
            }
            
            // Text
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(title)
                    .font(Design.Typography.subheadline(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(Design.Typography.caption(.regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionLimitPromptView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionLimitPromptView()
            .environmentObject(SupabaseAuthManager.shared)
            .environmentObject(UserStateManager.shared)
    }
}
