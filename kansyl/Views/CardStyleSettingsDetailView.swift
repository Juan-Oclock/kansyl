//
//  CardStyleSettingsDetailView.swift
//  kansyl
//
//  Detail view for selecting card interaction style with consistent UI
//

import SwiftUI

struct CardStyleSettingsDetailView: View {
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPreview = false
    
    var body: some View {
        Form {
            // Style Options Section
            Section {
                ForEach(CardInteractionStyle.allCases, id: \.self) { style in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            userPreferences.preferredCardStyle = style
                            HapticManager.shared.playSelection()
                        }
                    }) {
                        HStack {
                            // Icon and text
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.rawValue)
                                        .foregroundColor(.primary)
                                    Text(style.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: style.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(userPreferences.preferredCardStyle == style ? .white : .blue)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(userPreferences.preferredCardStyle == style ? Color.blue : Color.blue.opacity(0.1))
                                    )
                            }
                            
                            Spacer()
                            
                            // Checkmark for selected option
                            if userPreferences.preferredCardStyle == style {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } header: {
                Text("Interaction Style")
            } footer: {
                Text(footerText)
                    .font(.caption)
            }
            
            // Preview Section
            Section {
                Button(action: { showingPreview = true }) {
                    HStack {
                        Label("Preview Styles", systemImage: "eye")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Preview")
            } footer: {
                Text("See how each style works with sample subscription cards")
            }
        }
        .navigationTitle("Card Interaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreview) {
            CardStylePreview(selectedStyle: userPreferences.preferredCardStyle)
        }
    }
    
    private var footerText: String {
        switch userPreferences.preferredCardStyle {
        case .smart:
            return "Smart mode adapts the interaction style based on how urgent the subscription is. Cards ending within 3 days show inline buttons, 4-7 days use context menu, and others use standard interaction."
        case .inline:
            return "Always display Keep and Cancel buttons directly on the card for quick decisions. Best for users who want immediate access to actions."
        case .swipe:
            return "Swipe left on cards to reveal Keep and Cancel actions. A clean interface that keeps actions hidden until needed."
        case .menu:
            return "Long press on cards to show a context menu with all available actions. Provides the most options while keeping the interface minimal."
        }
    }
}

// MARK: - Preview Sheet
struct CardStylePreview: View {
    let selectedStyle: CardInteractionStyle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var mockStore = SubscriptionStore.shared
    
    // Sample subscription for preview
    private var sampleSubscriptions: [MockSubscription] {
        [
            MockSubscription(name: "Netflix", daysRemaining: 2, price: 15.99, logo: "tv"),
            MockSubscription(name: "Spotify", daysRemaining: 5, price: 9.99, logo: "music.note"),
            MockSubscription(name: "Disney+", daysRemaining: 15, price: 7.99, logo: "sparkles")
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: selectedStyle.icon)
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        
                        Text(selectedStyle.rawValue)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        Text(selectedStyle.description)
                            .font(.system(size: 15))
                            .foregroundColor(Design.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Instructions
                    instructionsSection
                    
                    // Sample Cards
                    VStack(spacing: 16) {
                        Text("Sample Cards")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        Text("These are non-functional preview cards")
                            .font(.system(size: 13))
                            .foregroundColor(Design.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        // Mock subscription cards
                        ForEach(sampleSubscriptions, id: \.name) { mock in
                            MockSubscriptionCard(
                                mock: mock,
                                style: selectedStyle
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Color.clear.frame(height: 40)
                }
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Use")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Group {
                switch selectedStyle {
                case .smart:
                    instructionRow(icon: "1.circle.fill", text: "Cards adapt based on urgency")
                    instructionRow(icon: "2.circle.fill", text: "Urgent cards show inline buttons")
                    instructionRow(icon: "3.circle.fill", text: "Others use swipe or long press")
                case .inline:
                    instructionRow(icon: "hand.tap.fill", text: "Tap Keep or Cancel buttons")
                    instructionRow(icon: "bolt.fill", text: "Quick decisions without extra steps")
                    instructionRow(icon: "eye.fill", text: "Actions always visible")
                case .swipe:
                    instructionRow(icon: "hand.draw.fill", text: "Swipe left to reveal actions")
                    instructionRow(icon: "arrow.left", text: "Swipe back to hide")
                    instructionRow(icon: "hand.tap.fill", text: "Tap card for details")
                case .menu:
                    instructionRow(icon: "hand.tap.fill", text: "Long press to show menu")
                    instructionRow(icon: "list.bullet", text: "Multiple options available")
                    instructionRow(icon: "link", text: "Direct cancellation links")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
        )
        .padding(.horizontal, 20)
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Mock Subscription for Preview
struct MockSubscription {
    let name: String
    let daysRemaining: Int
    let price: Double
    let logo: String
}

struct MockSubscriptionCard: View {
    let mock: MockSubscription
    let style: CardInteractionStyle
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingActions = false
    
    var urgencyColor: Color {
        if mock.daysRemaining <= 2 {
            return .red
        } else if mock.daysRemaining <= 6 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.black.opacity(0.08), radius: 2)
                    
                    Image(systemName: mock.logo)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(mock.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(urgencyColor)
                                .frame(width: 6, height: 6)
                            Text("\(mock.daysRemaining) days left")
                                .font(.system(size: 14))
                                .foregroundColor(urgencyColor)
                        }
                        
                        Text("•")
                            .foregroundColor(Design.Colors.textTertiary)
                        
                        Text("$\(String(format: "%.2f", mock.price))/mo")
                            .font(.system(size: 14))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Style-specific elements
                if style == .inline && mock.daysRemaining <= 3 {
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Text("Keep")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green)
                                )
                        }
                        
                        Button(action: {}) {
                            Text("Cancel")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red)
                                )
                        }
                    }
                } else if style == .swipe {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                        .foregroundColor(Design.Colors.textTertiary)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Design.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

// Preview
struct CardStyleSettingsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardStyleSettingsDetailView()
        }
    }
}