//
//  AchievementBadgeView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    let size: BadgeSize
    @State private var isPressed = false
    @State private var showShareSheet = false
    
    enum BadgeSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 80
            case .large: return 100
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge
            ZStack {
                // Background circle
                Circle()
                    .fill(achievement.isUnlocked ? 
                          achievement.color.color.opacity(0.2) : 
                          Color.gray.opacity(0.1))
                    .frame(width: size.dimension, height: size.dimension)
                
                // Progress ring for locked achievements
                if !achievement.isUnlocked && achievement.progress > 0 {
                    ProgressRing(
                        progress: achievement.progress,
                        color: achievement.color.color
                    )
                    .frame(width: size.dimension - 8, height: size.dimension - 8)
                }
                
                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: size.iconSize))
                    .foregroundColor(achievement.isUnlocked ? 
                                   achievement.color.color : 
                                   Color.gray.opacity(0.4))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Lock overlay for locked achievements
                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size.iconSize * 0.4))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.gray))
                        .offset(x: size.dimension * 0.3, y: -size.dimension * 0.3)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            
            // Title
            if size != .small {
                Text(achievement.title)
                    .font(size.fontSize)
                    .fontWeight(.medium)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: size.dimension + 20)
            }
            
            // Progress percentage for locked achievements
            if !achievement.isUnlocked && achievement.progress > 0 && size != .small {
                Text("\(achievement.progressPercentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            if achievement.isUnlocked {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    showShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [AchievementSystem().shareableText(for: achievement)])
        }
    }
}

