//
//  AddSubscriptionMethodSelector.swift
//  kansyl
//
//  A unified interface for choosing how to add a subscription
//

import SwiftUI

struct AddSubscriptionMethodSelector: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var subscriptionStore: SubscriptionStore
    @ObservedObject private var premiumManager = PremiumManager.shared
    
    // State for navigation
    @State private var showingTemplateMethod = false
    @State private var showingManualMethod = false
    @State private var showingReceiptScan = false
    @State private var showingEmailParser = false
    @State private var showingSiriShortcuts = false
    @State private var showingPremiumRequired = false
    @State private var animateCards = false
    @State private var showingLimitReached = false
    
    // Callback when subscription is added
    var onSubscriptionAdded: ((Subscription?) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Title Section
                            VStack(spacing: 8) {
                                Text("Add a Subscription")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                Text("Choose how you'd like to add your trial")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                // Subscription limit indicator
                                if !premiumManager.isPremium {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(premiumManager.getRemainingSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) <= 1 ? Color.orange : Color.blue.opacity(0.8))
                                        
                                        Text(premiumManager.getSubscriptionLimitMessage(currentCount: subscriptionStore.allSubscriptions.count))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Design.Colors.textSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(premiumManager.getRemainingSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) <= 1 ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                                    )
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.top, 12)
                            .scaleEffect(animateCards ? 1.0 : 0.9)
                            .opacity(animateCards ? 1.0 : 0)
                            
                            // Method Cards
                            VStack(spacing: 16) {
                                // Template Method
                                methodCard(
                                    icon: "square.grid.2x2.fill",
                                    iconColor: Color(hex: "3B82F6"),
                                    title: "Choose from Templates",
                                    description: "Quick setup with popular services",
                                    badge: "RECOMMENDED",
                                    badgeColor: Color(hex: "22C55E"),
                                    delay: 0.1
                                ) {
                                    if !premiumManager.canAddMoreSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) {
                                        showingLimitReached = true
                                    } else {
                                        showingTemplateMethod = true
                                    }
                                }
                                
                                // Manual Input Method
                                methodCard(
                                    icon: "pencil.circle.fill",
                                    iconColor: Color(hex: "8B5CF6"),
                                    title: "Manual Entry",
                                    description: "Add custom details manually",
                                    delay: 0.2
                                ) {
                                    if !premiumManager.canAddMoreSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) {
                                        showingLimitReached = true
                                    } else {
                                        showingManualMethod = true
                                    }
                                }
                                
                                // Receipt Scan with AI
                                methodCard(
                                    icon: "camera.fill",
                                    iconColor: Color(hex: "F59E0B"),
                                    title: "Scan with AI",
                                    description: "Extract info from screenshots",
                                    badge: nil,  // AI scanning now available for all users
                                    badgeColor: Color(hex: "FFD700"),
                                    delay: 0.3
                                ) {
                                    if !premiumManager.canAddMoreSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) {
                                        showingLimitReached = true
                                    } else {
                                        showingReceiptScan = true  // Allow all users to use AI scanning
                                    }
                                }
                                
                                // Email Parser
                                methodCard(
                                    icon: "envelope.fill",
                                    iconColor: Color(hex: "06B6D4"),
                                    title: "Parse from Email",
                                    description: "Import from confirmation emails",
                                    badge: "BETA",
                                    badgeColor: Color(hex: "06B6D4"),
                                    delay: 0.4
                                ) {
                                    if !premiumManager.canAddMoreSubscriptions(currentCount: subscriptionStore.allSubscriptions.count) {
                                        showingLimitReached = true
                                    } else {
                                        showingEmailParser = true
                                    }
                                }
                                
                                // Siri Shortcuts
                                methodCard(
                                    icon: "mic.fill",
                                    iconColor: Color(hex: "EF4444"),
                                    title: "Via Siri Shortcuts",
                                    description: "Say \"Hey Siri, add Netflix trial\" to quickly add subscriptions",
                                    badge: "SETUP",
                                    badgeColor: Color(hex: "EF4444"),
                                    delay: 0.5
                                ) {
                                    showingSiriShortcuts = true
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Bottom spacing
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingTemplateMethod) {
                AddSubscriptionView(
                    subscriptionStore: subscriptionStore,
                    onSave: { subscription in
                        onSubscriptionAdded?(subscription)
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingManualMethod) {
                AddSubscriptionView(
                    subscriptionStore: subscriptionStore,
                    startWithCustom: true,
                    onSave: { subscription in
                        onSubscriptionAdded?(subscription)
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingReceiptScan) {
                ReceiptScanView(subscriptionStore: subscriptionStore) { subscription in
                    onSubscriptionAdded?(subscription)
                    dismiss()
                }
            }
            .sheet(isPresented: $showingEmailParser) {
                EmailParserView(subscriptionStore: subscriptionStore) { subscription in
                    onSubscriptionAdded?(subscription)
                    dismiss()
                }
            }
            .sheet(isPresented: $showingSiriShortcuts) {
                SiriShortcutsView()
            }
            .sheet(isPresented: $showingPremiumRequired) {
                PremiumFeatureView()
            }
            .sheet(isPresented: $showingLimitReached) {
                PremiumFeatureView(isForSubscriptionLimit: true, currentCount: subscriptionStore.allSubscriptions.count)
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Design.Colors.surface)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Method Card
    private func methodCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        badge: String? = nil,
        badgeColor: Color = .blue,
        delay: Double = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(badgeColor)
                                )
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Design.Colors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Design.Colors.border.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: animateCards)
    }
}

// MARK: - Email Parser View
struct EmailParserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var subscriptionStore: SubscriptionStore
    var onComplete: ((Subscription?) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "06B6D4").opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(Color(hex: "06B6D4"))
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Parse from Email")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        Text("Use the Share Extension")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        instructionRow(number: "1", text: "Open your email app")
                        instructionRow(number: "2", text: "Find a subscription confirmation email")
                        instructionRow(number: "3", text: "Tap the Share button")
                        instructionRow(number: "4", text: "Select 'Kansyl' from the share menu")
                        instructionRow(number: "5", text: "The subscription details will be extracted automatically")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Note
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "06B6D4"))
                        
                        Text("This feature works with most subscription confirmation emails")
                            .font(.system(size: 13))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Email Parser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                }
            }
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(hex: "06B6D4"))
                )
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Design.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct AddSubscriptionMethodSelector_Previews: PreviewProvider {
    static var previews: some View {
        AddSubscriptionMethodSelector(subscriptionStore: SubscriptionStore.shared)
    }
}