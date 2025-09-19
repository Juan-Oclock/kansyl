//
//  CostCalculationEngine.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Data Models

struct SavingsMetrics {
    let totalPotentialWaste: Double
    let actualSavings: Double
    let monthlySpendProjection: Double
    let yearlySpendProjection: Double
    let wasteRiskScore: Double
    let personalizedForgetRate: Double
    
    var totalAnnualWaste: Double {
        totalPotentialWaste
    }
}

struct SubscriptionOutcome {
    let subscriptionId: UUID
    let serviceName: String
    let monthlyPrice: Double
    let outcome: SubscriptionStatus
    let endDate: Date
    let decisionMadeOnTime: Bool
}

// MARK: - Cost Calculation Engine

class CostCalculationEngine: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // Default rates and thresholds
    private let defaultForgetRate: Double = 0.40 // 40% for new users
    private let riskScoreThresholds = (low: 3.0, medium: 6.0, high: 8.0)
    
    @Published var currentMetrics = SavingsMetrics(
        totalPotentialWaste: 0,
        actualSavings: 0,
        monthlySpendProjection: 0,
        yearlySpendProjection: 0,
        wasteRiskScore: 0,
        personalizedForgetRate: 0.40
    )
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        calculateMetrics()
    }
    
    // MARK: - Primary Calculations
    
    func calculateMetrics() {
        let activeSubscriptions = fetchActiveSubscriptions()
        let historicalOutcomes = fetchHistoricalOutcomes()
        
        let personalizedForgetRate = calculatePersonalizedForgetRate(from: historicalOutcomes)
        let totalPotentialWaste = calculatePotentialWaste(activeSubscriptions: activeSubscriptions, forgetRate: personalizedForgetRate)
        let actualSavings = calculateActualSavings(from: historicalOutcomes)
        let monthlyProjection = calculateMonthlySpendProjection(activeSubscriptions: activeSubscriptions, forgetRate: personalizedForgetRate)
        let yearlyProjection = monthlyProjection * 12
        let wasteRiskScore = calculateWasteRiskScore(activeSubscriptions: activeSubscriptions, historicalOutcomes: historicalOutcomes)
        
        DispatchQueue.main.async { [weak self] in
            self?.currentMetrics = SavingsMetrics(
                totalPotentialWaste: totalPotentialWaste,
                actualSavings: actualSavings,
                monthlySpendProjection: monthlyProjection,
                yearlySpendProjection: yearlyProjection,
                wasteRiskScore: wasteRiskScore,
                personalizedForgetRate: personalizedForgetRate
            )
        }
    }
    
    // MARK: - Core Algorithm Implementation
    
    private func calculatePotentialWaste(activeSubscriptions: [Subscription], forgetRate: Double) -> Double {
        let totalMonthlyValue = activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
        // Annual waste = (active subscriptions total monthly cost × 12) × forget rate
        return totalMonthlyValue * 12 * forgetRate
    }
    
    private func calculatePersonalizedForgetRate(from outcomes: [SubscriptionOutcome]) -> Double {
        guard outcomes.count >= 5 else {
            return defaultForgetRate // Use default for new users
        }
        
        let expiredOrKeptCount = outcomes.filter { 
            $0.outcome == .expired || ($0.outcome == .kept && !$0.decisionMadeOnTime)
        }.count
        
        let personalizedRate = Double(expiredOrKeptCount) / Double(outcomes.count)
        
        // Smooth transition between default and personalized rate
        let weight = min(Double(outcomes.count) / 20.0, 1.0) // Full personalization after 20 subscriptions
        return (1.0 - weight) * defaultForgetRate + weight * personalizedRate
    }
    
    private func calculateActualSavings(from outcomes: [SubscriptionOutcome]) -> Double {
        let currentYear = Calendar.current.dateInterval(of: .year, for: Date())!
        
        return outcomes.filter { 
            $0.outcome == .canceled && currentYear.contains($0.endDate)
        }.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    private func calculateMonthlySpendProjection(activeSubscriptions: [Subscription], forgetRate: Double) -> Double {
        let totalMonthlyValue = activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
        return totalMonthlyValue * forgetRate
    }
    
    private func calculateWasteRiskScore(activeSubscriptions: [Subscription], historicalOutcomes: [SubscriptionOutcome]) -> Double {
        var score: Double = 0
        
        // Factor 1: Number of active subscriptions (0-3 points)
        let subscriptionCountScore = min(Double(activeSubscriptions.count) * 0.3, 3.0)
        score += subscriptionCountScore
        
        // Factor 2: Average monthly value (0-2 points)
        let avgMonthlyValue = activeSubscriptions.isEmpty ? 0 : activeSubscriptions.reduce(0, { $0 + $1.monthlyPrice }) / Double(activeSubscriptions.count)
        let valueScore = min(avgMonthlyValue / 25.0, 2.0) // $25+ = max points
        score += valueScore
        
        // Factor 3: Subscriptions ending soon (0-2 points)
        let endingSoonCount = activeSubscriptions.filter { subscription in
            guard let endDate = subscription.endDate else { return false }
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return daysRemaining <= 7
        }.count
        let urgencyScore = min(Double(endingSoonCount) * 0.5, 2.0)
        score += urgencyScore
        
        // Factor 4: Historical forget rate (0-3 points)
        let forgetRateScore = currentMetrics.personalizedForgetRate * 3.0
        score += forgetRateScore
        
        return min(score, 10.0) // Cap at 10
    }
    
    // MARK: - Data Fetching
    
    private func fetchActiveSubscriptions() -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        // Filter by current user and active status
        if let currentUserID = getCurrentUserID() {
            request.predicate = NSPredicate(format: "status == %@ AND userID == %@", SubscriptionStatus.active.rawValue, currentUserID)
        } else {
            // If no user is logged in, return empty array
            return []
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            // Debug: print("Error fetching active subscriptions: \(error)")
            return []
        }
    }
    
    private func fetchHistoricalOutcomes() -> [SubscriptionOutcome] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        // Filter by current user and non-active status
        if let currentUserID = getCurrentUserID() {
            request.predicate = NSPredicate(format: "status != %@ AND userID == %@", SubscriptionStatus.active.rawValue, currentUserID)
        } else {
            // If no user is logged in, return empty array
            return []
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: false)]
        
        do {
            let subscriptions = try viewContext.fetch(request)
            return subscriptions.compactMap { subscription in
                guard let id = subscription.id,
                      let name = subscription.name,
                      let endDate = subscription.endDate,
                      let statusString = subscription.status,
                      let status = SubscriptionStatus(rawValue: statusString) else {
                    return nil
                }
                
                // Determine if decision was made on time
                let decisionMadeOnTime = Calendar.current.dateComponents([.day], from: endDate, to: Date()).day ?? 0 <= 1
                
                return SubscriptionOutcome(
                    subscriptionId: id,
                    serviceName: name,
                    monthlyPrice: subscription.monthlyPrice,
                    outcome: status,
                    endDate: endDate,
                    decisionMadeOnTime: decisionMadeOnTime
                )
            }
        } catch {
            // Debug: print("Error fetching historical outcomes: \(error)")
            return []
        }
    }
    
    // MARK: - User ID Helper
    
    private func getCurrentUserID() -> String? {
        return SubscriptionStore.shared.currentUserID
    }
    
    // MARK: - Analytics Helpers
    
    var metrics: SavingsMetrics {
        currentMetrics
    }
    
    var wasteRiskLevel: (displayName: String, color: Color) {
        let riskData = getRiskLevel()
        return (displayName: riskData.level, color: riskData.color)
    }
    
    var currentMonthlySavings: Double {
        getMonthlySavings()
    }
    
    func getRiskLevel() -> (level: String, color: Color, description: String) {
        let score = currentMetrics.wasteRiskScore
        
        switch score {
        case 0..<riskScoreThresholds.low:
            return ("Low", .green, "You're doing great at managing subscriptions!")
        case riskScoreThresholds.low..<riskScoreThresholds.medium:
            return ("Medium", .orange, "Keep an eye on upcoming subscription endings")
        case riskScoreThresholds.medium..<riskScoreThresholds.high:
            return ("High", .red, "You have several subscriptions ending soon")
        default:
            return ("Very High", .red, "Urgent action needed on multiple subscriptions")
        }
    }
    
    func getMonthlySavings() -> Double {
        let outcomes = fetchHistoricalOutcomes()
        let currentMonth = Calendar.current.dateInterval(of: .month, for: Date())!
        
        return outcomes.filter { 
            $0.outcome == .canceled && currentMonth.contains($0.endDate)
        }.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    func getYearlyProjection() -> (totalSpend: Double, potentialSavings: Double) {
        let activeSubscriptions = fetchActiveSubscriptions()
        let totalIfAllKept = activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice } * 12
        let projectedSpend = currentMetrics.yearlySpendProjection
        let potentialSavings = totalIfAllKept - projectedSpend
        
        return (totalSpend: projectedSpend, potentialSavings: potentialSavings)
    }
    
    func getPersonalizedInsights() -> [String] {
        var insights: [String] = []
        let metrics = currentMetrics
        let activeSubscriptions = fetchActiveSubscriptions()
        
        if metrics.wasteRiskScore > riskScoreThresholds.medium {
            insights.append("You have a high risk of unwanted charges this month")
        }
        
        if activeSubscriptions.count > 5 {
            insights.append("Consider reducing the number of simultaneous subscriptions")
        }
        
        if metrics.personalizedForgetRate > 0.5 {
            insights.append("You tend to keep more subscriptions than average - great job saving!")
        } else {
            insights.append("You're good at canceling subscriptions you don't need")
        }
        
        let endingSoonCount = activeSubscriptions.filter { subscription in
            guard let endDate = subscription.endDate else { return false }
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return daysRemaining <= 3
        }.count
        
        if endingSoonCount > 0 {
            insights.append("\(endingSoonCount) subscription(s) ending in 3 days or less")
        }
        
        return insights
    }
    
    // MARK: - Public Interface for SubscriptionStore Integration
    
    func recordSubscriptionOutcome(subscription: Subscription, newStatus: SubscriptionStatus) {
        // This would be called by SubscriptionStore when updating subscription status
        // Recalculate metrics after status change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.calculateMetrics()
        }
    }
    
    func refreshMetrics() {
        calculateMetrics()
    }
}
