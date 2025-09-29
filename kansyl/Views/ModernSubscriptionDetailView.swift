//
//  ModernSubscriptionDetailView.swift
//  kansyl
//
//  Created on 9/13/25.
//

import SwiftUI
import CoreData

struct ModernSubscriptionDetailView: View {
    @ObservedObject var subscription: Subscription
    let subscriptionStore: SubscriptionStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingCancelConfirmation = false
    @State private var animateContent = false
    @State private var refreshTrigger = false
    @State private var triggerConfetti = false
    @State private var showSuccessToast = false
    @State private var successToastMessage = ""
    @State private var successToastAmount = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Background color - dark gray in dark mode
                (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                    .ignoresSafeArea()
                    .frame(height: 0) // Just for background color
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Service Header Card
                        serviceHeaderCard
                            .padding(.horizontal, 20)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0)
                            .id(refreshTrigger) // Force refresh when trigger changes
                        
                        // Modern Details Grid
                        VStack(alignment: .leading, spacing: 20) {
                            sectionTitle("Subscription Details")
                            
                            // Modern Grid Layout
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    // End Date Card
                                    detailCard(
                                        icon: "calendar",
                                        iconColor: Color(hex: "6366F1"),
                                        title: "End Date",
                                        value: formatDate(subscription.endDate),
                                        valueColor: Design.Colors.textPrimary,
                                        backgroundColor: colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface
                                    )
                                    
                                    // Days Left Card
                                    detailCard(
                                        icon: "clock.fill",
                                        iconColor: urgencyColor,
                                        title: "Days Left",
                                        value: "\(daysRemaining)",
                                        valueColor: urgencyColor,
                                        backgroundColor: colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface
                                    )
                                }
                                
                                HStack(spacing: 16) {
                                    // Category Card
                                    let category = ServiceTemplateManager.shared.getTemplateData(for: subscription.name ?? "")?.category ?? "Other"
                                    detailCard(
                                        icon: "tag.fill",
                                        iconColor: Color(hex: "8B5CF6"),
                                        title: "Category",
                                        value: category,
                                        valueColor: Design.Colors.textPrimary,
                                        backgroundColor: colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface
                                    )
                                    
                                    // Monthly Cost Card
                                    detailCard(
                                        icon: "dollarsign.circle.fill",
                                        iconColor: Color(hex: "F59E0B"),
                                        title: "Monthly",
                                        value: SharedCurrencyFormatter.formatPriceCompact(subscription.monthlyPrice),
                                        valueColor: Design.Colors.textPrimary,
                                        backgroundColor: colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface
                                    )
                                }
                                
                                // Subscription Type Card - Full Width
                                let subType = SubscriptionType(rawValue: subscription.subscriptionType ?? "paid") ?? .paid
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                                            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                                        
                                        HStack(spacing: 12) {
                                            // Type Icon
                                            ZStack {
                                                Circle()
                                                    .fill(subType.badgeColor.opacity(0.15))
                                                    .frame(width: 32, height: 32)
                                                
                                                Image(systemName: subType.icon)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(subType.badgeColor)
                                            }
                                            
                                            // Type Info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Subscription Type")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Design.Colors.textSecondary)
                                                
                                                Text(subType.displayName)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(Design.Colors.textPrimary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Type Badge
                                            HStack(spacing: 4) {
                                                Image(systemName: subType.icon)
                                                    .font(.system(size: 10, weight: .semibold))
                                                Text(subType.shortDisplayName.uppercased())
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(subType.badgeColor)
                                            .cornerRadius(8)
                                        }
                                        .padding(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0)
                        .id("details-\(refreshTrigger)") // Force refresh when trigger changes
                        
                        // Notes Section
                        if let notes = subscription.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionTitle("Notes")
                                
                                Text(notes)
                                    .font(.system(size: 15))
                                    .foregroundColor(Design.Colors.textPrimary)
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1.0 : 0)
                        }
                        
                        // Extra spacing for bottom buttons
                        Color.clear.frame(height: 150)
                    }
                    .padding(.top, 20)
                }
                .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                
                // Fixed Action Buttons at Bottom
                VStack(spacing: 12) {
                    // Keep Button - Blue/Primary
                    Button(action: keepSubscription) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Keep Subscription")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Design.Colors.buttonPrimary, Design.Colors.buttonPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Design.Colors.buttonPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // Cancel Button - Green/Success with dark mode support
                    Button(action: { showingCancelConfirmation = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Cancel & Save Money")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1B2538"), Color(hex: "1B2538").opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(
                            color: Color(hex: "1B2538").opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 12)
                .background(
                    // Subtle gradient background for the button area
                    LinearGradient(
                        colors: [
                            (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background).opacity(0.8),
                            (colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1.0 : 0)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                }
                
                // Edit & Delete Menu
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditSubscriptionView(subscription: subscription, subscriptionStore: subscriptionStore)
                    .onDisappear {
                        // Force refresh the subscription data when edit sheet is dismissed
                        DispatchQueue.main.async {
                            viewContext.refresh(subscription, mergeChanges: true)
                            
                            // Trigger UI refresh
                            refreshTrigger.toggle()
                            
                            // Refresh subscription categories in case status changed
                            subscriptionStore.fetchSubscriptions()
                        }
                    }
            }
            .alert("Delete Subscription?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    withAnimation {
                        subscriptionStore.deleteSubscription(subscription)
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete this subscription from your tracking.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateContent = true
                }
            }
        }
        // Full height modal presentation
        .fullHeightDetent()
        .overlay(
            // Confetti effects layer
            ConfettiView(trigger: $triggerConfetti, config: .savings)
                .allowsHitTesting(false)
                .zIndex(1000)
        )
        .overlay(
            // Success toast at the top
            VStack {
                SuccessToastView(
                    message: successToastMessage,
                    savedAmount: successToastAmount,
                    isShowing: $showSuccessToast
                )
                .padding(.top, 50) // Account for status bar
                
                Spacer()
            }
            .zIndex(1002)
        )
        .overlay(
            // Cancel confirmation modal
            Group {
                if showingCancelConfirmation {
                    SubscriptionActionModal(
                        subscription: subscription,
                        action: .cancel,
                        onConfirm: {
                            showingCancelConfirmation = false
                            cancelSubscription()
                        },
                        onCancel: {
                            showingCancelConfirmation = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(999)
                }
            }
        )
    }
    
    // MARK: - Modern Header Card
    private var serviceHeaderCard: some View {
        HStack(spacing: 16) {
            // Compact Service Icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                if let serviceLogo = subscription.serviceLogo {
                    Image.bundleImage(serviceLogo, fallbackSystemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.black)
                } else {
                    Text(subscription.name?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            
            // Service Info
            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name ?? "Unknown Service")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                HStack(spacing: 8) {
                    Text(subscription.status?.capitalized ?? "Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(Design.Colors.textTertiary)
                    
                    Text("\(daysRemaining) days left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(urgencyColor)
                }
            }
            
            Spacer()
            
            // Price Display
            VStack(alignment: .trailing, spacing: 2) {
                Text(SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text("per month")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Design.Colors.textPrimary)
    }
    
    private func detailCard(icon: String, iconColor: Color, title: String, value: String, valueColor: Color, backgroundColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Design.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    
    // MARK: - Helper Methods
    private var daysRemaining: Int {
        guard let endDate = subscription.endDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    private var urgencyColor: Color {
        if daysRemaining <= 3 {
            return Design.Colors.danger
        } else if daysRemaining <= 5 {
            return Design.Colors.warning
        } else {
            return Design.Colors.textSecondary
        }
    }
    
    private var statusColor: Color {
        switch subscription.status {
        case "active":
            return Design.Colors.active
        case "canceled":
            return Design.Colors.success
        case "kept":
            return Design.Colors.kept
        case "expired":
            return Design.Colors.expired
        default:
            return Design.Colors.textSecondary
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    private func cancelSubscription() {
        withAnimation {
            subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
            
            // Trigger confetti celebration for saving money!
            triggerConfetti = true
            
            // Haptic celebration
            HapticManager.shared.playSuccess()
            
            // Show success toast after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                successToastMessage = "Subscription canceled successfully!"
                successToastAmount = SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice)
                showSuccessToast = true
            }
            
            // Dismiss after confetti starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
            
            AnalyticsManager.shared.track(.subscriptionCanceled, properties: AnalyticsProperties(
                subscriptionId: subscription.id?.uuidString ?? "",
                subscriptionName: subscription.name ?? ""
            ))
        }
    }
    
    private func keepSubscription() {
        HapticManager.shared.playSuccess()
        
        withAnimation {
            subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
            dismiss()
            
            AnalyticsManager.shared.track(.subscriptionKept, properties: AnalyticsProperties(
                subscriptionId: subscription.id?.uuidString ?? "",
                subscriptionName: subscription.name ?? ""
            ))
        }
    }
}
