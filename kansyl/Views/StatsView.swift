//
//  StatsView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @StateObject private var achievementSystem = AchievementSystem()
    @State private var selectedTab = 0
    @State private var showingAllAchievements = false
    @State private var animateHeroMetric = false
    @State private var animateCards = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Modern Header with Hero Metric
                        modernHeroSection
                            .padding(.top, 6)
                        
                        // Sleek Tab Selector
                        modernTabSelector
                            .padding(.top, 32)
                            .padding(.horizontal, 20)
                        
                        // Content based on selected tab
                        if selectedTab == 0 {
                            modernOverviewContent
                        } else {
                            modernAchievementsContent
                        }
                        
                        // Bottom spacing for tab bar
                        Color.clear.frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAllAchievements) {
                AllAchievementsView(achievementSystem: achievementSystem)
            }
            .onAppear {
                subscriptionStore.fetchSubscriptions()
                subscriptionStore.costEngine.refreshMetrics()
                updateAchievementProgress()
                withAnimation(Design.Animation.spring.delay(0.1)) {
                    animateHeroMetric = true
                }
                withAnimation(Design.Animation.spring.delay(0.3)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Modern Hero Section
    private var modernHeroSection: some View {
        VStack(spacing: 0) {
            // Title
            Text("Stats")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Design.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            
            // Hero Card
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "0F172A"),
                        Color(hex: "1E293B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 20) {
                    // Label
                    Text("TOTAL SAVINGS")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    // Amount with animation
                    Text(SharedCurrencyFormatter.formatPrice(subscriptionStore.costEngine.metrics.actualSavings))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(animateHeroMetric ? 1.0 : 0.8)
                        .opacity(animateHeroMetric ? 1.0 : 0)
                    
                    // Subtitle
                    Text("saved this year")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.9))
                    
                    // Waste Prevention Badge
                    if subscriptionStore.costEngine.metrics.totalAnnualWaste > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.checkmark.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Preventing \(SharedCurrencyFormatter.formatPrice(subscriptionStore.costEngine.metrics.totalAnnualWaste)) in waste")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "22C55E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    }
                }
                .padding(.vertical, 32)
            }
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .scaleEffect(animateHeroMetric ? 1.0 : 0.95)
            .opacity(animateHeroMetric ? 1.0 : 0)
        }
    }
    
    // MARK: - Modern Tab Selector
    private var modernTabSelector: some View {
        HStack(spacing: 0) {
            // Overview Tab
            Button(action: { 
                withAnimation(Design.Animation.smooth) {
                    selectedTab = 0
                }
            }) {
                VStack(spacing: 8) {
                    Text("Overview")
                        .font(.system(size: 15, weight: selectedTab == 0 ? .semibold : .regular))
                        .foregroundColor(selectedTab == 0 ? Design.Colors.textPrimary : Design.Colors.textSecondary)
                    
                    // Indicator line
                    Rectangle()
                        .fill(selectedTab == 0 ? Color(hex: "22C55E") : Color.clear)
                        .frame(height: 2)
                        .cornerRadius(1)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Achievements Tab
            Button(action: { 
                withAnimation(Design.Animation.smooth) {
                    selectedTab = 1
                }
            }) {
                VStack(spacing: 8) {
                    Text("Achievements")
                        .font(.system(size: 15, weight: selectedTab == 1 ? .semibold : .regular))
                        .foregroundColor(selectedTab == 1 ? Design.Colors.textPrimary : Design.Colors.textSecondary)
                    
                    // Indicator line
                    Rectangle()
                        .fill(selectedTab == 1 ? Color(hex: "22C55E") : Color.clear)
                        .frame(height: 2)
                        .cornerRadius(1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 2)
        .background(
            Rectangle()
                .fill(Design.Colors.border.opacity(0.3))
                .frame(height: 1)
                .offset(y: 19)
        )
    }
    
    // MARK: - Modern Overview Content
    private var modernOverviewContent: some View {
        VStack(spacing: 24) {
            // Stats Grid with modern cards
            modernStatsGrid
            
            // Monthly Trend Chart
            modernMonthlyChart
            
            // Comparison Insights
            if let previousPeriodSavings = calculatePreviousPeriodSavings() {
                modernComparisonCard(currentSavings: subscriptionStore.costEngine.metrics.actualSavings,
                                   previousSavings: previousPeriodSavings)
            }
        }
    }
    
    private var modernStatsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Active Subscriptions Card
                ModernStatCard(
                    icon: "clock.fill",
                    title: "Active",
                    value: "\(subscriptionStore.activeSubscriptions.count)",
                    subtitle: "subscriptions",
                    backgroundColor: Color(hex: "EFF6FF"),
                    iconColor: Color(hex: "3B82F6")
                )
                .scaleEffect(animateCards ? 1.0 : 0.9)
                .opacity(animateCards ? 1.0 : 0)
                .animation(Design.Animation.spring.delay(0.1), value: animateCards)
                
                // Canceled Card
                let canceledCount = subscriptionStore.allSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }.count
                ModernStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Saved",
                    value: "\(canceledCount)",
                    subtitle: "canceled",
                    backgroundColor: Color(hex: "F0FDF4"),
                    iconColor: Color(hex: "22C55E")
                )
                .scaleEffect(animateCards ? 1.0 : 0.9)
                .opacity(animateCards ? 1.0 : 0)
                .animation(Design.Animation.spring.delay(0.2), value: animateCards)
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Risk Score Card
                ModernStatCard(
                    icon: "shield.fill",
                    title: "Risk",
                    value: subscriptionStore.costEngine.wasteRiskLevel.displayName,
                    subtitle: "level",
                    backgroundColor: riskBackgroundColor,
                    iconColor: riskIconColor
                )
                .scaleEffect(animateCards ? 1.0 : 0.9)
                .opacity(animateCards ? 1.0 : 0)
                .animation(Design.Animation.spring.delay(0.3), value: animateCards)
                
                // Monthly Savings Card
                ModernStatCard(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly",
                    value: SharedCurrencyFormatter.formatPriceCompact(subscriptionStore.costEngine.currentMonthlySavings),
                    subtitle: "saved",
                    backgroundColor: Color(hex: "FEF3C7"),
                    iconColor: Color(hex: "F59E0B")
                )
                .scaleEffect(animateCards ? 1.0 : 0.9)
                .opacity(animateCards ? 1.0 : 0)
                .animation(Design.Animation.spring.delay(0.4), value: animateCards)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var riskBackgroundColor: Color {
        switch subscriptionStore.costEngine.wasteRiskLevel.displayName.lowercased() {
        case "low":
            return Color(hex: "F0FDF4")
        case "medium":
            return Color(hex: "FEF3C7")
        case "high", "very high":
            return Color(hex: "FEE2E2")
        default:
            return Color(hex: "F3F4F6")
        }
    }
    
    private var riskIconColor: Color {
        switch subscriptionStore.costEngine.wasteRiskLevel.displayName.lowercased() {
        case "low":
            return Color(hex: "22C55E")
        case "medium":
            return Color(hex: "F59E0B")
        case "high", "very high":
            return Color(hex: "EF4444")
        default:
            return Color(hex: "9CA3AF")
        }
    }
    
    private var modernMonthlyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Trend")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    Text("Your savings performance")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                
                Spacer()
                
                // Chart type toggle (optional)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.buttonPrimary)
            }
            .padding(.horizontal, 20)
            
            let monthlyData = generateMonthlyData()
            let hasData = monthlyData.contains { $0.savings > 0 || $0.waste > 0 }
            
            ZStack {
                // Modern Line Chart
                ModernLineChart(monthlyData: monthlyData)
                    .padding(.horizontal, 20)
                    .scaleEffect(animateCards ? 1.0 : 0.95)
                    .opacity(animateCards ? 1.0 : 0)
                    .animation(Design.Animation.spring.delay(0.5), value: animateCards)
                
                // Empty state overlay
                if !hasData {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.flattrend.xyaxis")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Design.Colors.textTertiary)
                        Text("No data yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                        Text("Start tracking subscriptions to see trends")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Design.Colors.textTertiary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .opacity(animateCards ? 1.0 : 0)
                    .animation(Design.Animation.spring.delay(0.6), value: animateCards)
                }
            }
        }
    }
    
    private func modernComparisonCard(currentSavings: Double, previousSavings: Double) -> some View {
        let percentageChange = previousSavings > 0 ? Int(((currentSavings - previousSavings) / previousSavings) * 100) : 0
        let isPositive = currentSavings >= previousSavings
        
        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VS. LAST PERIOD")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.0)
                        .foregroundColor(Design.Colors.textTertiary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("\(abs(percentageChange))%")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundColor(isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                    
                    Text(isPositive ? "Great progress!" : "Keep tracking")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(SharedCurrencyFormatter.formatPrice(currentSavings))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("was \(SharedCurrencyFormatter.formatPrice(previousSavings))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Design.Colors.textTertiary)
                }
            }
            .padding(20)
        }
        .background(Design.Colors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0)
        .animation(Design.Animation.spring.delay(0.6), value: animateCards)
    }
    
    // MARK: - Modern Achievements Content
    private var modernAchievementsContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                nextAchievementSection
                recentUnlocksSection
                allAchievementsSection
                totalPointsCard
                Spacer(minLength: 20)
            }
        }
    }
    
    @ViewBuilder
    private var nextAchievementSection: some View {
        if let nextAchievement = achievementSystem.nextAchievement {
            ModernAchievementProgress(achievement: nextAchievement)
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)
        }
    }
    
    @ViewBuilder
    private var recentUnlocksSection: some View {
        if !achievementSystem.recentUnlocks.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent Unlocks")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievementSystem.recentUnlocks.indices, id: \.self) { index in
                            let achievement = achievementSystem.recentUnlocks[index]
                            ModernAchievementBadge(
                                achievement: achievement,
                                isUnlocked: true
                            )
                            .scaleEffect(animateCards ? 1.0 : 0.8)
                            .opacity(animateCards ? 1.0 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.1),
                                value: animateCards
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var allAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Achievements")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Text("\(achievementSystem.unlockedAchievements.count) of \(achievementSystem.achievements.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Design.Colors.textSecondary)
            }
            .padding(.horizontal, 20)
            
            achievementsGrid
            
            if achievementSystem.achievements.count > 12 {
                viewAllButton
            }
        }
    }
    
    private var achievementsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            ForEach(achievementSystem.achievements.prefix(12)) { achievement in
                achievementBadgeItem(for: achievement)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func achievementBadgeItem(for achievement: Achievement) -> some View {
        let isUnlocked = achievementSystem.unlockedAchievements.contains { $0.id == achievement.id }
        let index = achievementSystem.achievements.firstIndex { $0.id == achievement.id } ?? 0
        
        return ModernAchievementBadge(
            achievement: achievement,
            isUnlocked: isUnlocked
        )
        .scaleEffect(animateCards ? 1.0 : 0.8)
        .opacity(animateCards ? 1.0 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.05),
            value: animateCards
        )
    }
    
    private var viewAllButton: some View {
        Button(action: { showingAllAchievements = true }) {
            HStack(spacing: 8) {
                Text("View All Achievements")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Design.Colors.buttonPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Design.Colors.buttonPrimary.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var totalPointsCard: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Points")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Text("\(achievementSystem.totalPoints)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                }
            }
            
            Spacer()
            
            // Rank Badge
            VStack(spacing: 4) {
                Text("RANK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundColor(Design.Colors.textTertiary)
                
                Text(getRankText(points: achievementSystem.totalPoints))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Design.Colors.buttonPrimary)
            }
        }
        .padding(20)
        .background(Design.Colors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 20)
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateCards)
    }
    
    // MARK: - Helper Methods
    private func generateMonthlyData() -> [MonthData] {
        // Get the last 6 months of data from actual subscriptions
        let calendar = Calendar.current
        let today = Date()
        var monthlyData: [MonthData] = []
        
        // Generate data for the last 6 months
        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) else {
                continue
            }
            
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            // Calculate savings and waste for this month
            var monthlySavings: Double = 0
            var monthlyWaste: Double = 0
            
            // Get subscriptions that were canceled in this month
            let canceledInMonth = subscriptionStore.allSubscriptions.filter { subscription in
                guard let endDate = subscription.endDate else { return false }
                return subscription.status == SubscriptionStatus.canceled.rawValue &&
                       endDate >= monthStart && endDate < monthEnd
            }
            
            // Calculate savings from canceled subscriptions
            for subscription in canceledInMonth {
                let monthlyCost = subscription.monthlyPrice ?? 0
                // Calculate months saved (from cancellation to what would have been renewal)
                if let startDate = subscription.startDate,
                   let endDate = subscription.endDate {
                    let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 30
                    let monthsSaved = max(1, daysBetween / 30)
                    monthlySavings += monthlyCost * Double(monthsSaved)
                }
            }
            
            // Calculate waste from active subscriptions that haven't been used
            let activeInMonth = subscriptionStore.allSubscriptions.filter { subscription in
                guard let startDate = subscription.startDate else { return false }
                let isActive = subscription.status == SubscriptionStatus.active.rawValue
                return isActive && startDate <= monthEnd
            }
            
            // Simple waste calculation: estimate based on subscription age and lack of notes
            for subscription in activeInMonth {
                // Consider waste if subscription is older than 14 days with no notes (likely unused)
                if let startDate = subscription.startDate {
                    let daysActive = calendar.dateComponents([.day], from: startDate, to: monthEnd).day ?? 0
                    if daysActive > 14 && (subscription.notes?.isEmpty ?? true) {
                        let monthlyPrice = subscription.monthlyPrice ?? 0
                        monthlyWaste += monthlyPrice * 0.5 // Estimate 50% waste for potentially unused subscriptions
                    }
                }
            }
            
            // Format month name
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: monthDate)
            
            // Add to monthly data
            monthlyData.append(MonthData(
                month: monthName,
                savings: max(0, monthlySavings),
                waste: max(0, monthlyWaste)
            ))
        }
        
        // If no real data exists yet, return flat line (all zeros)
        if monthlyData.isEmpty || monthlyData.allSatisfy({ $0.savings == 0 && $0.waste == 0 }) {
            // Return actual month names with zero values for a flat line
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            var emptyData: [MonthData] = []
            for monthOffset in (0..<6).reversed() {
                if let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) {
                    let monthName = formatter.string(from: monthDate)
                    emptyData.append(MonthData(month: monthName, savings: 0, waste: 0))
                }
            }
            return emptyData.isEmpty ? monthlyData : emptyData
        }
        
        return monthlyData
    }
    
    private func calculatePreviousPeriodSavings() -> Double? {
        // Calculate savings from the previous 6-month period
        let calendar = Calendar.current
        let today = Date()
        
        // Get date 6 months ago
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today),
              let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: today) else {
            return nil
        }
        
        // Calculate savings from subscriptions canceled in the previous period
        let previousPeriodCanceled = subscriptionStore.allSubscriptions.filter { subscription in
            guard let endDate = subscription.endDate else { return false }
            return subscription.status == SubscriptionStatus.canceled.rawValue &&
                   endDate >= twelveMonthsAgo && endDate < sixMonthsAgo
        }
        
        var previousSavings: Double = 0
        for subscription in previousPeriodCanceled {
            let monthlyPrice = subscription.monthlyPrice ?? 0
            previousSavings += monthlyPrice * 6 // Rough estimate for 6 months
        }
        
        // Return nil if no historical data exists
        return previousSavings > 0 ? previousSavings : nil
    }
    
    private func updateAchievementProgress() {
        let canceledCount = subscriptionStore.allSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }.count
        let totalSavings = subscriptionStore.costEngine.metrics.actualSavings
        let wastePercent = Int((1 - subscriptionStore.costEngine.metrics.wasteRiskScore) * 100)
        
        // Calculate actual streak (days since last missed trial end)
        let currentStreak = calculateCurrentStreak()
        
        // Calculate early bird cancellations (canceled within 7 days)
        let earlyBirdCount = calculateEarlyCancellations()
        
        // Check if last month was perfect (all trials canceled on time)
        let hadPerfectMonth = checkPerfectMonth()
        
        achievementSystem.updateProgress(
            trialsCanceled: canceledCount,
            totalSavings: totalSavings,
            currentStreak: currentStreak,
            trialsManaged: subscriptionStore.allSubscriptions.count,
            wastePreventedPercent: wastePercent,
            earlyBirdCount: earlyBirdCount,
            hadPerfectMonth: hadPerfectMonth
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        // Calculate consecutive days of managing trials without missing any
        let calendar = Calendar.current
        let today = Date()
        var streakDays = 0
        
        // Get all subscriptions sorted by end date
        let sortedSubs = subscriptionStore.allSubscriptions
            .filter { $0.endDate != nil }
            .sorted { ($0.endDate ?? Date()) > ($1.endDate ?? Date()) }
        
        // Check for any missed cancellations in recent history
        for subscription in sortedSubs {
            guard let endDate = subscription.endDate else { continue }
            
            // If a trial expired without being canceled, streak is broken
            if endDate < today && subscription.status != SubscriptionStatus.canceled.rawValue {
                break
            }
            
            // Count days since the oldest properly managed trial
            let days = calendar.dateComponents([.day], from: endDate, to: today).day ?? 0
            streakDays = max(streakDays, days)
        }
        
        return min(streakDays, 30) // Cap at 30 for achievement purposes
    }
    
    private func calculateEarlyCancellations() -> Int {
        // Count subscriptions canceled within 7 days of starting
        let calendar = Calendar.current
        
        return subscriptionStore.allSubscriptions.filter { subscription in
            guard let startDate = subscription.startDate,
                  let endDate = subscription.endDate,
                  subscription.status == SubscriptionStatus.canceled.rawValue else {
                return false
            }
            
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return daysBetween <= 7
        }.count
    }
    
    private func checkPerfectMonth() -> Bool {
        // Check if all trials in the last month were canceled before expiration
        let calendar = Calendar.current
        let today = Date()
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today) else {
            return false
        }
        
        // Get all subscriptions that ended in the last month
        let lastMonthSubs = subscriptionStore.allSubscriptions.filter { subscription in
            guard let endDate = subscription.endDate else { return false }
            return endDate >= oneMonthAgo && endDate <= today
        }
        
        // If no subscriptions in last month, not a perfect month
        if lastMonthSubs.isEmpty {
            return false
        }
        
        // Check if all were canceled (not expired)
        return lastMonthSubs.allSatisfy { $0.status == SubscriptionStatus.canceled.rawValue }
    }
    
    private func getRankText(points: Int) -> String {
        if points >= 1000 {
            return "Expert"
        } else if points >= 500 {
            return "Advanced"
        } else {
            return "Beginner"
        }
    }
}

// MARK: - Modern Achievement Components
struct ModernAchievementProgress: View {
    let achievement: Achievement
    let animationDelay: Double = 0
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text("NEXT ACHIEVEMENT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundColor(Design.Colors.textTertiary)
                
                Spacer()
                
                Text("\(achievement.progressPercentage)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(achievement.color.color)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Achievement Info
            HStack(spacing: 16) {
                // Badge
                ZStack {
                    Circle()
                        .fill(achievement.color.color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(achievement.color.color)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text(achievement.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(achievement.color.color)
                        .frame(
                            width: animateProgress ? geometry.size.width * achievement.progress : 0,
                            height: 6
                        )
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(animationDelay),
                            value: animateProgress
                        )
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Design.Colors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 2)
        .onAppear {
            animateProgress = true
        }
    }
}

struct ModernAchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    var size: CGFloat = 70
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [achievement.color.color, achievement.color.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: size, height: size)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : Color.gray.opacity(0.5))
            }
            
            Text(achievement.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isUnlocked ? Design.Colors.textPrimary : Design.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: size)
        }
    }
}

// MARK: - Modern Supporting Views
struct ModernStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let backgroundColor: Color
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .cornerRadius(10)
                .padding(.bottom, 12)
            
            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Design.Colors.textTertiary)
                .padding(.bottom, 4)
            
            // Value
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Design.Colors.textPrimary)
                .padding(.bottom, 2)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Design.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Design.Colors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ComparisonCard: View {
    let currentSavings: Double
    let previousSavings: Double
    
    var percentageChange: Int {
        guard previousSavings > 0 else { return 0 }
        return Int(((currentSavings - previousSavings) / previousSavings) * 100)
    }
    
    var isPositive: Bool {
        currentSavings >= previousSavings
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs. Last Period")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text("\(abs(percentageChange))%")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(isPositive ? .green : .red)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(currentSavings))")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("$\(Int(previousSavings)) last period")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AllAchievementsView: View {
    @ObservedObject var achievementSystem: AchievementSystem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 24) {
                    ForEach(achievementSystem.achievements) { achievement in
                        AchievementBadgeView(
                            achievement: achievement,
                            size: .medium
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("All Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(SubscriptionStore.shared)
    }
}
