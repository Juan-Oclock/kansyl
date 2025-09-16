//
//  ShareView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct ShareView: View {
    @StateObject private var sharingManager = SharingManager.shared
    @StateObject private var achievementSystem = AchievementSystem()
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @ObservedObject var costEngine: CostCalculationEngine
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingShareSheet = false
    @State private var shareContent: ShareContent?
    @State private var selectedShareType: ShareType = .savings
    @State private var showingExportOptions = false
    @State private var referralCode = ""
    
    enum ShareType: String, CaseIterable {
        case savings = "Savings"
        case achievements = "Achievements"
        case export = "Export Data"
        case referral = "Invite Friends"
        
        var icon: String {
            switch self {
            case .savings: return "dollarsign.circle.fill"
            case .achievements: return "trophy.fill"
            case .export: return "square.and.arrow.up"
            case .referral: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .savings: return .green
            case .achievements: return .yellow
            case .export: return .blue
            case .referral: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Share Type Selector
                    Picker("Share Type", selection: $selectedShareType) {
                        ForEach(ShareType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content based on selected type
                    Group {
                        switch selectedShareType {
                        case .savings:
                            savingsShareView
                        case .achievements:
                            achievementsShareView
                        case .export:
                            exportShareView
                        case .referral:
                            referralShareView
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationTitle("Share & Export")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareSheet) {
                if let content = shareContent {
                    SharingSheet(shareContent: content)
                }
            }
        }
    }
    
    // MARK: - Savings Share View
    private var savingsShareView: some View {
        VStack(spacing: 20) {
            // Stats Card
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Total Saved")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("$\(String(format: "%.2f", costEngine.currentMetrics.actualSavings))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
                
                Text("from canceled subscriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color(hex: "252525") : Color(.systemGray6))
            .cornerRadius(16)
            
            // Share Button
            Button(action: shareSavings) {
                Label("Share My Savings", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Recent Milestones
            if costEngine.currentMetrics.actualSavings >= 100 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Milestones Reached")
                        .font(.headline)
                    
                    ForEach(savingsMilestones, id: \.self) { milestone in
                        if costEngine.currentMetrics.actualSavings >= Double(milestone) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("$\(milestone) saved!")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color(hex: "252525") : Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Achievements Share View
    private var achievementsShareView: some View {
        VStack(spacing: 20) {
            let unlockedAchievements = achievementSystem.achievements.filter { $0.isUnlocked }
            if unlockedAchievements.isEmpty {
                EmptyAchievementsView()
            } else {
                ForEach(unlockedAchievements.prefix(3), id: \.id) { achievement in
                    AchievementShareCard(achievement: achievement) {
                        shareAchievement(achievement)
                    }
                }
                
                if unlockedAchievements.count > 3 {
                    Text("And \(unlockedAchievements.count - 3) more achievements!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Export Share View
    private var exportShareView: some View {
        VStack(spacing: 20) {
            // Export Options
            VStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.headline)
                
                Text("Export all your subscription data as CSV or JSON for backup or analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color(hex: "252525") : Color(.systemGray6))
            .cornerRadius(16)
            
            // Export Buttons
            VStack(spacing: 12) {
                Button(action: exportAllSubscriptions) {
                    Label("Export All Subscriptions", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: exportActiveSubscriptions) {
                    Label("Export Active Subscriptions Only", systemImage: "square.and.arrow.up.on.square")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            
            // Stats
            HStack(spacing: 40) {
                VStack {
                    Text("\(subscriptionStore.allSubscriptions.count)")
                        .font(.title2.bold())
                    Text("Total Subscriptions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(subscriptionStore.activeSubscriptions.count)")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(subscriptionStore.allSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }.count)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    Text("Canceled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Referral Share View
    private var referralShareView: some View {
        VStack(spacing: 20) {
            // Referral Card
            VStack(spacing: 16) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                
                Text("Invite Friends")
                    .font(.headline)
                
                Text("Share Kansyl with friends and they'll get 1 month of Premium features FREE!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Referral Code
                if !referralCode.isEmpty {
                    VStack(spacing: 8) {
                        Text("Your Referral Code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(referralCode)
                            .font(.title2.monospaced().bold())
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            // Share Button
            Button(action: shareReferral) {
                Label("Share Referral Link", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Benefits List
            VStack(alignment: .leading, spacing: 12) {
                Text("Your friends get:")
                    .font(.headline)
                
                BenefitRow(icon: "checkmark.circle.fill", text: "1 month Premium free")
                BenefitRow(icon: "infinity", text: "Unlimited subscription tracking")
                BenefitRow(icon: "bell.badge.fill", text: "Advanced notifications")
                BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Detailed analytics")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .onAppear {
            if referralCode.isEmpty {
                referralCode = generateReferralCode()
            }
        }
    }
    
    // MARK: - Actions
    private func shareSavings() {
        let content = sharingManager.shareSavings(
            amount: costEngine.currentMetrics.actualSavings,
            subscriptionsCount: subscriptionStore.allSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }.count
        )
        shareContent = content
        showingShareSheet = true
        HapticManager.shared.playSuccess()
    }
    
    private func shareAchievement(_ achievement: Achievement) {
        let content = sharingManager.shareAchievement(achievement)
        shareContent = content
        showingShareSheet = true
        HapticManager.shared.playSuccess()
    }
    
    private func exportAllSubscriptions() {
        let content = sharingManager.exportSubscriptionData(subscriptionStore.allSubscriptions)
        shareContent = content
        showingShareSheet = true
        HapticManager.shared.playButtonTap()
    }
    
    private func exportActiveSubscriptions() {
        let content = sharingManager.exportSubscriptionData(subscriptionStore.activeSubscriptions)
        shareContent = content
        showingShareSheet = true
        HapticManager.shared.playButtonTap()
    }
    
    private func shareReferral() {
        let content = sharingManager.shareReferral(referralCode: referralCode)
        shareContent = content
        showingShareSheet = true
        HapticManager.shared.playSuccess()
    }
    
    private func generateReferralCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    // MARK: - Constants
    private let savingsMilestones = [50, 100, 250, 500, 1000, 2500, 5000]
}

// MARK: - Supporting Views
struct AchievementShareCard: View {
    let achievement: Achievement
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                Text("Unlocked \(achievement.unlockedDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Achievements Yet")
                .font(.headline)
            
            Text("Start tracking subscriptions to unlock achievements!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview
struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView(costEngine: CostCalculationEngine(context: PersistenceController.preview.container.viewContext))
            .environmentObject(SubscriptionStore())
    }
}
