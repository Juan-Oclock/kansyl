//
//  OnboardingView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var currentPage = 0
    @State private var showingNotificationPrompt = false
    
    let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Never Forget to Cancel",
            subtitle: "Track all your free trials in one place",
            imageName: "calendar.badge.exclamationmark",
            imageColor: .blue,
            description: "Get timely reminders before trials end, so you never pay for services you don't want."
        ),
        OnboardingPage(
            title: "Save Money Effortlessly",
            subtitle: "See your potential savings at a glance",
            imageName: "dollarsign.circle.fill",
            imageColor: .green,
            description: "Track how much you've saved by canceling unwanted subscriptions before they charge."
        ),
        OnboardingPage(
            title: "Lightning-Fast Setup",
            subtitle: "Add trials in seconds",
            imageName: "bolt.fill",
            imageColor: .orange,
            description: "Choose from popular services or add custom trials with our streamlined interface."
        ),
        OnboardingPage(
            title: "Smart Notifications",
            subtitle: "Never miss a trial deadline",
            imageName: "bell.badge.fill",
            imageColor: .purple,
            description: "Customizable reminders at 3 days, 1 day, and day-of trial expiration."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundColor(.secondary)
                .padding()
            }
            
            // Content
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Page indicators and button
            VStack(spacing: 20) {
                // Custom page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Action button
                Button(action: handleButtonAction) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingNotificationPrompt) {
            NotificationPermissionView {
                completeOnboarding()
            }
        }
    }
    
    private var buttonTitle: String {
        if currentPage < onboardingPages.count - 1 {
            return "Next"
        } else {
            return "Get Started"
        }
    }
    
    private func handleButtonAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if currentPage < onboardingPages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            // Last page - request notifications then complete
            if !notificationManager.notificationsEnabled {
                showingNotificationPrompt = true
            } else {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let imageColor: Color
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: page.imageName)
                    .font(.system(size: 70))
                    .foregroundColor(page.imageColor)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            isAnimating = true
        }
    }
}

struct NotificationPermissionView: View {
    let onComplete: () -> Void
    @State private var isAnimating = false
    
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
                .foregroundColor(.purple)
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
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
