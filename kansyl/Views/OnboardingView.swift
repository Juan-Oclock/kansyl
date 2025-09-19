//
//  OnboardingView.swift
//  kansyl
//
//  Created on 9/12/25.
//  Modern single-page onboarding design
//

import SwiftUI

struct OnboardingView: View {
    @Binding var deviceHasCompletedOnboarding: Bool
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingNotificationPrompt = false
    @State private var logoAnimation = false
    @State private var contentAnimation = false
    @State private var buttonAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
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
                    // Skip button (top right)
                    HStack {
                        Spacer()
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(Design.Typography.callout(.medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .padding(.trailing, Design.Spacing.xl)
                        .padding(.top, Design.Spacing.lg)
                    }
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    // Main content
                    VStack(spacing: Design.Spacing.xxxl) {
                        // Kansyl Logo - Text only, sleek and modern
                        VStack(spacing: Design.Spacing.sm) {
                            Text("Kansyl")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Design.Colors.primary, Design.Colors.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .scaleEffect(logoAnimation ? 1.0 : 0.8)
                                .opacity(logoAnimation ? 1.0 : 0.0)
                                .animation(Design.Animation.spring.delay(0.2), value: logoAnimation)
                            
                            Text("Never miss a subscription deadline")
                                .font(Design.Typography.callout(.medium))
                                .foregroundColor(Design.Colors.textSecondary)
                                .opacity(contentAnimation ? 1.0 : 0.0)
                                .offset(y: contentAnimation ? 0 : 20)
                                .animation(Design.Animation.spring.delay(0.6), value: contentAnimation)
                        }
                        
                        // Feature highlights
                        VStack(spacing: Design.Spacing.xl) {
                            OnboardingFeatureRow(
                                title: "Track Free (and Premium) Subscriptions",
                                description: "Never forget to cancel unwanted subscriptions",
                                delay: 0.8
                            )
                            
                            OnboardingFeatureRow(
                                title: "Smart Reminders",
                                description: "Get notified before trials expire",
                                delay: 1.0
                            )
                            
                            OnboardingFeatureRow(
                                title: "Save Money",
                                description: "Track your savings with every cancellation",
                                delay: 1.2
                            )
                        }
                        .opacity(contentAnimation ? 1.0 : 0.0)
                        .offset(y: contentAnimation ? 0 : 30)
                        .animation(Design.Animation.spring.delay(0.8), value: contentAnimation)
                    }
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    // Get Started button
                    VStack(spacing: Design.Spacing.lg) {
                        Button(action: handleGetStartedAction) {
                            HStack {
                                Text("Get Started")
                                    .font(Design.Typography.headline(.semibold))
                                    .foregroundColor(Design.Colors.background)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Design.Colors.background)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Design.Spacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [Design.Colors.textPrimary, Design.Colors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Design.Radius.lg)
                            .shadow(
                                color: Design.Colors.textPrimary.opacity(0.3),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .scaleEffect(buttonAnimation ? 1.0 : 0.9)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                        .animation(Design.Animation.spring.delay(1.4), value: buttonAnimation)
                        .padding(.horizontal, Design.Spacing.xl)
                        
                        Text("Start tracking your subscriptions today")
                            .font(Design.Typography.caption(.regular))
                            .foregroundColor(Design.Colors.textSecondary)
                            .opacity(buttonAnimation ? 1.0 : 0.0)
                            .animation(Design.Animation.spring.delay(1.6), value: buttonAnimation)
                    }
                    .padding(.bottom, Design.Spacing.xxxl)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
        .sheet(isPresented: $showingNotificationPrompt) {
            NotificationPermissionView {
                completeOnboarding()
            }
        }
    }
    
    private func startAnimationSequence() {
        // Stagger the animations for a smooth entrance
        withAnimation {
            logoAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                contentAnimation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                buttonAnimation = true
            }
        }
    }
    
    private func handleGetStartedAction() {
        HapticManager.shared.playButtonTap()
        
        // Request notifications then complete onboarding
        if !notificationManager.notificationsEnabled {
            showingNotificationPrompt = true
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        HapticManager.shared.playButtonTap()
        
        withAnimation(Design.Animation.smooth) {
            deviceHasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Feature Row Component
struct OnboardingFeatureRow: View {
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: Design.Spacing.lg) {
            // Checkmark circle
            ZStack {
                Circle()
                    .fill(Design.Colors.success.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(Design.Animation.spring.delay(delay), value: isVisible)
            
            // Text content
            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text(title)
                    .font(Design.Typography.headline(.semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(Design.Typography.callout(.regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(x: isVisible ? 0 : 20)
            .animation(Design.Animation.spring.delay(delay + 0.1), value: isVisible)
            
            Spacer()
        }
        .padding(.horizontal, Design.Spacing.xl)
        .onAppear {
            isVisible = true
        }
    }
}

struct NotificationPermissionView: View {
    let onComplete: () -> Void
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            // Close button
            HStack {
                Spacer()
                Button("Later") {
                    onComplete()
                }
                .foregroundColor(.secondary)
                .padding()
            }
            
            Spacer()
            
            // Bell animation
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .rotationEffect(.degrees(isAnimating ? -10 : 10))
                .animation(
                    .easeInOut(duration: 0.2)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }
            
            VStack(spacing: 16) {
                Text("Enable Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get reminders before your trials end")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    NotificationBenefit(icon: "calendar", text: "3 days before expiration")
                    NotificationBenefit(icon: "exclamationmark.triangle", text: "1 day urgent reminder")
                    NotificationBenefit(icon: "alarm", text: "Day-of final alert")
                }
                .padding(.top, 20)
            }
            
            Spacer()
            
            Button(action: {
                NotificationManager.shared.requestNotificationPermission()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }) {
                Text("Enable Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct NotificationBenefit: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var deviceHasCompletedOnboarding = false
        private let userPreferences = UserSpecificPreferences()
        
        init() {
            // Set up preview user preferences
            userPreferences.setCurrentUser("preview_user")
        }
        
        var body: some View {
            OnboardingView(deviceHasCompletedOnboarding: $deviceHasCompletedOnboarding)
                .environmentObject(userPreferences)
                .environmentObject(SupabaseAuthManager.shared)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
