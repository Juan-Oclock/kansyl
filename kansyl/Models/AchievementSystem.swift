//
//  AchievementSystem.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import SwiftUI

// MARK: - Achievement Definition
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color.RGBValues
    let requirement: AchievementRequirement
    var unlockedDate: Date?
    var progress: Double = 0.0
    
    var isUnlocked: Bool {
        unlockedDate != nil
    }
    
    var progressPercentage: Int {
        Int(min(progress * 100, 100))
    }
    
    struct Color: Codable {
        struct RGBValues: Codable {
            let red: Double
            let green: Double
            let blue: Double
            
            var color: SwiftUI.Color {
                SwiftUI.Color(red: red, green: green, blue: blue)
            }
        }
    }
}

// MARK: - Achievement Requirements
enum AchievementRequirement: Codable {
    case trialsCanceled(count: Int)
    case moneySaved(amount: Double)
    case streakDays(days: Int)
    case trialsManaged(count: Int)
    case wastePreventedPercent(percent: Int)
    case earlyBird(count: Int) // Cancel before halfway through trial
    case perfectMonth // No forgotten trials in a month
    
    var targetValue: Double {
        switch self {
        case .trialsCanceled(let count): return Double(count)
        case .moneySaved(let amount): return amount
        case .streakDays(let days): return Double(days)
        case .trialsManaged(let count): return Double(count)
        case .wastePreventedPercent(let percent): return Double(percent)
        case .earlyBird(let count): return Double(count)
        case .perfectMonth: return 1.0
        }
    }
}

// MARK: - Achievement System
class AchievementSystem: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentUnlocks: [Achievement] = []
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "kansyl_achievements"
    
    init() {
        loadAchievements()
    }
    
    // MARK: - Achievement Definitions
    private var allAchievements: [Achievement] {
        [
            Achievement(
                id: "first_cancel",
                title: "First Step",
                description: "Cancel your first trial",
                icon: "star.fill",
                color: Achievement.Color.RGBValues(red: 1.0, green: 0.8, blue: 0.0),
                requirement: .trialsCanceled(count: 1)
            ),
            Achievement(
                id: "trial_master_5",
                title: "Trial Master",
                description: "Cancel 5 trials successfully",
                icon: "trophy.fill",
                color: Achievement.Color.RGBValues(red: 1.0, green: 0.84, blue: 0.0),
                requirement: .trialsCanceled(count: 5)
            ),
            Achievement(
                id: "trial_master_10",
                title: "Trial Champion",
                description: "Cancel 10 trials successfully",
                icon: "crown.fill",
                color: Achievement.Color.RGBValues(red: 0.96, green: 0.76, blue: 0.0),
                requirement: .trialsCanceled(count: 10)
            ),
            Achievement(
                id: "savings_25",
                title: "Quarter Saver",
                description: "Save $25 from canceled trials",
                icon: "dollarsign.circle.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.8, blue: 0.0),
                requirement: .moneySaved(amount: 25)
            ),
            Achievement(
                id: "savings_100",
                title: "Century Saver",
                description: "Save $100 from canceled trials",
                icon: "banknote.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.7, blue: 0.0),
                requirement: .moneySaved(amount: 100)
            ),
            Achievement(
                id: "savings_500",
                title: "Savings Expert",
                description: "Save $500 from canceled trials",
                icon: "creditcard.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.6, blue: 0.0),
                requirement: .moneySaved(amount: 500)
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Check trials for 7 days straight",
                icon: "flame.fill",
                color: Achievement.Color.RGBValues(red: 1.0, green: 0.4, blue: 0.0),
                requirement: .streakDays(days: 7)
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Check trials for 30 days straight",
                icon: "flame.circle.fill",
                color: Achievement.Color.RGBValues(red: 1.0, green: 0.3, blue: 0.0),
                requirement: .streakDays(days: 30)
            ),
            Achievement(
                id: "early_bird_3",
                title: "Early Bird",
                description: "Cancel 3 trials in their first half",
                icon: "sunrise.fill",
                color: Achievement.Color.RGBValues(red: 1.0, green: 0.6, blue: 0.2),
                requirement: .earlyBird(count: 3)
            ),
            Achievement(
                id: "perfect_month",
                title: "Perfect Month",
                description: "No forgotten trials for a full month",
                icon: "checkmark.seal.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.5, blue: 1.0),
                requirement: .perfectMonth
            ),
            Achievement(
                id: "waste_prevented_50",
                title: "Waste Warrior",
                description: "Prevent 50% of potential waste",
                icon: "leaf.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.7, blue: 0.3),
                requirement: .wastePreventedPercent(percent: 50)
            ),
            Achievement(
                id: "waste_prevented_75",
                title: "Efficiency Expert",
                description: "Prevent 75% of potential waste",
                icon: "leaf.circle.fill",
                color: Achievement.Color.RGBValues(red: 0.0, green: 0.6, blue: 0.2),
                requirement: .wastePreventedPercent(percent: 75)
            )
        ]
    }
    
    // MARK: - Progress Tracking
    func updateProgress(
        trialsCanceled: Int,
        totalSavings: Double,
        currentStreak: Int,
        trialsManaged: Int,
        wastePreventedPercent: Int,
        earlyBirdCount: Int,
        hadPerfectMonth: Bool
    ) {
        for (index, achievement) in achievements.enumerated() {
            let oldProgress = achievement.progress
            var newProgress: Double = 0.0
            
            switch achievement.requirement {
            case .trialsCanceled(let target):
                newProgress = Double(trialsCanceled) / Double(target)
            case .moneySaved(let target):
                newProgress = totalSavings / target
            case .streakDays(let target):
                newProgress = Double(currentStreak) / Double(target)
            case .trialsManaged(let target):
                newProgress = Double(trialsManaged) / Double(target)
            case .wastePreventedPercent(let target):
                newProgress = Double(wastePreventedPercent) / Double(target)
            case .earlyBird(let target):
                newProgress = Double(earlyBirdCount) / Double(target)
            case .perfectMonth:
                newProgress = hadPerfectMonth ? 1.0 : 0.0
            }
            
            achievements[index].progress = min(newProgress, 1.0)
            
            // Check for new unlocks
            if oldProgress < 1.0 && newProgress >= 1.0 && achievement.unlockedDate == nil {
                achievements[index].unlockedDate = Date()
                recentUnlocks.append(achievements[index])
                
                // Keep only last 3 recent unlocks
                if recentUnlocks.count > 3 {
                    recentUnlocks.removeFirst()
                }
            }
        }
        
        saveAchievements()
    }
    
    // MARK: - Persistence
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            // Initialize with default achievements
            achievements = allAchievements
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    // MARK: - Computed Properties
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    var totalPoints: Int {
        unlockedAchievements.count * 100
    }
    
    var nextAchievement: Achievement? {
        lockedAchievements
            .filter { $0.progress > 0 }
            .sorted { $0.progress > $1.progress }
            .first
    }
    
    // MARK: - Sharing
    func shareableText(for achievement: Achievement) -> String {
        "I just unlocked '\(achievement.title)' in Kansyl! \(achievement.description) 🎉"
    }
}
