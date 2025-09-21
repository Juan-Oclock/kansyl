//
//  SubscriptionActionModal.swift
//  kansyl
//
//  Modern confirmation modal for subscription actions
//

import SwiftUI

struct SubscriptionActionModal: View {
    let subscription: Subscription
    let action: SubscriptionAction
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum SubscriptionAction {
        case keep
        case cancel
        
        var title: String {
            switch self {
            case .keep:
                return "Keep Subscription?"
            case .cancel:
                return "Cancel Subscription?"
            }
        }
        
        var message: String {
            switch self {
            case .keep:
                return "You're choosing to continue this subscription after the trial ends."
            case .cancel:
                return "Mark this as canceled to track your savings."
            }
        }
        
        var icon: String {
            switch self {
            case .keep:
                return "checkmark.circle.fill"
            case .cancel:
                return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .keep:
                return Design.Colors.kept
            case .cancel:
                return Design.Colors.success
            }
        }
        
        var confirmText: String {
            switch self {
            case .keep:
                return "Keep"
            case .cancel:
                return "Cancel"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onCancel()
                    }
                }
            
            // Modal content container
            VStack {
                Spacer()
                
                // Modal card
                VStack(spacing: 0) {
                    // Icon and Service Info
                    VStack(spacing: 12) {
                        // Animated Icon
                        ZStack {
                            Circle()
                                .fill(action.color.opacity(0.1))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: action.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(action.color)
                                .scaleEffect(isAnimating ? 1.0 : 0.8)
                                .opacity(isAnimating ? 1.0 : 0)
                        }
                        .padding(.top, 20)
                        
                        // Service Name
                        Text(subscription.name ?? "Subscription")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        // Action Title
                        Text(action.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        // Message
                        Text(action.message)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Design.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Additional Info
                        if action == .cancel {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .medium))
                                Text("You'll save \(SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice))/month")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(Design.Colors.success)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Design.Colors.success.opacity(0.1))
                            )
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Divider
                    Rectangle()
                        .fill(Design.Colors.border.opacity(0.3))
                        .frame(height: 1)
                    
                    // Action Buttons
                    HStack(spacing: 0) {
                        // Go Back Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                HapticManager.shared.playSelection()
                                onCancel()
                            }
                        }) {
                            Text("Go Back")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Design.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Vertical Divider
                        Rectangle()
                            .fill(Design.Colors.border.opacity(0.3))
                            .frame(width: 1)
                            .frame(height: 48)
                        
                        // Confirm Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                HapticManager.shared.playSuccess()
                                onConfirm()
                            }
                        }) {
                            Text(action.confirmText)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(action.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
                )
                .frame(width: 280)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 25,
                    x: 0,
                    y: 10
                )
                
                Spacer()
            }
            .scaleEffect(isAnimating ? 1.0 : 0.9)
            .opacity(isAnimating ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
        }
    }
}

