//
//  SubscriptionTypeBadge.swift
//  kansyl
//
//  Created on 9/29/25.
//

import SwiftUI
import CoreData

struct SubscriptionTypeBadge: View {
    @ObservedObject var subscription: Subscription
    @Environment(\.colorScheme) var colorScheme
    
    var subscriptionType: SubscriptionType {
        if let typeString = subscription.subscriptionType,
           let type = SubscriptionType(rawValue: typeString) {
            return type
        }
        // Default to paid if no type is explicitly set
        return .paid
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: subscriptionType.icon)
                .font(.system(size: 10, weight: .semibold))
            
            Text(subscriptionType.shortDisplayName)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                gradient: Gradient(colors: subscriptionType.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(6)
        .shadow(color: subscriptionType.badgeColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// Compact version for smaller spaces
struct CompactSubscriptionTypeBadge: View {
    @ObservedObject var subscription: Subscription
    
    var subscriptionType: SubscriptionType {
        if let typeString = subscription.subscriptionType,
           let type = SubscriptionType(rawValue: typeString) {
            return type
        }
        // Default to paid if no type is set
        return .paid
    }
    
    var body: some View {
        Image(systemName: subscriptionType.icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(6)
            .background(
                Circle()
                    .fill(subscriptionType.badgeColor)
            )
            .shadow(color: subscriptionType.badgeColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// Inline text badge for lists
struct InlineSubscriptionTypeBadge: View {
    @ObservedObject var subscription: Subscription
    
    var subscriptionType: SubscriptionType {
        // Always use the explicitly set type if available
        if let typeString = subscription.subscriptionType,
           let type = SubscriptionType(rawValue: typeString) {
            print("[Badge] Using saved type: \(type.rawValue) for \(subscription.name ?? "")")
            return type
        }
        // Only fall back if no type is set at all
        print("[Badge] WARNING: No subscription type set for \(subscription.name ?? ""), using fallback")
        return .paid  // Default to paid instead of checking isTrial
    }
    
    var body: some View {
        Text(subscriptionType.shortDisplayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(subscriptionType.badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(subscriptionType.badgeColor.opacity(0.15))
            )
    }
}

// Preview Provider
struct SubscriptionTypeBadge_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample subscriptions
        let trialSub = Subscription(context: context)
        trialSub.name = "Netflix"
        trialSub.subscriptionType = SubscriptionType.trial.rawValue
        trialSub.isTrial = true
        
        let paidSub = Subscription(context: context)
        paidSub.name = "Spotify"
        paidSub.subscriptionType = SubscriptionType.paid.rawValue
        paidSub.isTrial = false
        
        let promoSub = Subscription(context: context)
        promoSub.name = "Disney+"
        promoSub.subscriptionType = SubscriptionType.promotional.rawValue
        promoSub.isTrial = false
        
        return VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Standard Badge")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    SubscriptionTypeBadge(subscription: trialSub)
                    SubscriptionTypeBadge(subscription: paidSub)
                    SubscriptionTypeBadge(subscription: promoSub)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Compact Badge")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    CompactSubscriptionTypeBadge(subscription: trialSub)
                    CompactSubscriptionTypeBadge(subscription: paidSub)
                    CompactSubscriptionTypeBadge(subscription: promoSub)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Inline Badge")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    InlineSubscriptionTypeBadge(subscription: trialSub)
                    InlineSubscriptionTypeBadge(subscription: paidSub)
                    InlineSubscriptionTypeBadge(subscription: promoSub)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}