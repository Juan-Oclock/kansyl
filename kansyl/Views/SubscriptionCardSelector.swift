//
//  SubscriptionCardSelector.swift
//  kansyl
//
//  Smart selector for choosing the appropriate subscription card based on urgency
//

import SwiftUI
import CoreData

struct SubscriptionCardSelector: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    let isCompactMode: Bool
    
    @AppStorage("preferredCardStyle") private var preferredStyle = CardStyle.smart
    @State private var animateIn = false
    
    init(subscription: Subscription, subscriptionStore: SubscriptionStore, isCompactMode: Bool = false, action: @escaping () -> Void) {
        self.subscription = subscription
        self.subscriptionStore = subscriptionStore
        self.isCompactMode = isCompactMode
        self.action = action
    }
    
    enum CardStyle: String, CaseIterable {
        case smart = "Smart"          // Adaptive based on urgency
        case inline = "Inline"        // Always show inline buttons
        case swipe = "Swipe"         // Always use swipe
        case contextMenu = "Menu"     // Always use context menu
        
        var description: String {
            switch self {
            case .smart: return "Adaptive based on urgency"
            case .inline: return "Always show quick actions"
            case .swipe: return "Swipe for actions"
            case .contextMenu: return "Long press for menu"
            }
        }
        
        var icon: String {
            switch self {
            // Use iOS 15-safe SF Symbols
            case .smart: return "wand.and.rays"
            case .inline: return "bolt.circle"
            case .swipe: return "hand.point.left"
            case .contextMenu: return "ellipsis.circle"
            }
        }
    }
    
    private var daysRemaining: Int {
        subscriptionStore.daysRemaining(for: subscription)
    }
    
    var body: some View {
        Group {
            if isCompactMode {
                // In compact mode, always use simple row card regardless of preference
                SubscriptionRowCard(
                    subscription: subscription,
                    subscriptionStore: subscriptionStore,
                    action: action
                )
            } else {
                switch preferredStyle {
                case .smart:
                    smartCardSelection
                case .inline:
                    EnhancedSubscriptionCard(
                        subscription: subscription,
                        subscriptionStore: subscriptionStore,
                        action: action
                    )
                case .swipe:
                    // Use your existing swipe card or the hybrid one
                    if #available(iOS 16.0, *) {
                        HybridSubscriptionCard(
                            subscription: subscription,
                            subscriptionStore: subscriptionStore,
                            action: action
                        )
                    } else {
                        // Fallback to existing implementation for iOS 15
                        SubscriptionRowCard(
                            subscription: subscription,
                            subscriptionStore: subscriptionStore,
                            action: action
                        )
                    }
                case .contextMenu:
                    ContextMenuSubscriptionCard(
                        subscription: subscription,
                        subscriptionStore: subscriptionStore,
                        action: action
                    )
                }
            }
        }
        .scaleEffect(animateIn ? 1.0 : 0.95)
        .opacity(animateIn ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
    
    @ViewBuilder
    private var smartCardSelection: some View {
        if isCompactMode {
            // Compact mode - always use simple row card with minimal spacing
            SubscriptionRowCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        } else if daysRemaining <= 3 {
            // Most urgent - use inline buttons for immediate action
            EnhancedSubscriptionCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        } else if daysRemaining <= 7 {
            // Moderately urgent - use context menu for cleaner look with options
            ContextMenuSubscriptionCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        } else {
            // Not urgent - use existing simple card
            SubscriptionRowCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        }
    }
}

// MARK: - Settings View for Card Style Selection
struct CardStyleSettingsView: View {
    @AppStorage("preferredCardStyle") private var preferredStyle = SubscriptionCardSelector.CardStyle.smart
    @State private var showingPreview = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions Style")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text("Choose how you want to interact with subscription cards")
                    .font(.system(size: 14))
                    .foregroundColor(Design.Colors.textSecondary)
            }
            
            // Style Options
            VStack(spacing: 12) {
                ForEach(SubscriptionCardSelector.CardStyle.allCases, id: \.self) { style in
                    CardStyleOption(
                        style: style,
                        isSelected: preferredStyle == style,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                preferredStyle = style
                                HapticManager.shared.playSelection()
                            }
                        }
                    )
                }
            }
            
            // Preview Button
            Button(action: { showingPreview = true }) {
                HStack {
                    Image(systemName: "eye")
                        .font(.system(size: 14, weight: .medium))
                    Text("Preview Style")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Design.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Design.Colors.primary.opacity(0.1))
                )
            }
            .sheet(isPresented: $showingPreview) {
                CardStylePreview(selectedStyle: preferredStyle)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
        )
    }
}

// MARK: - Card Style Option Row
struct CardStyleOption: View {
    let style: SubscriptionCardSelector.CardStyle
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    // Neutral background that works in both light/dark without washing out the icon
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
                        )
                    
                    Image(systemName: style.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.textSecondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text(style.description)
                        .font(.system(size: 13))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Sheet
struct CardStylePreview: View {
    let selectedStyle: SubscriptionCardSelector.CardStyle
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mockStore = MockSubscriptionStore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("This shows how your subscriptions will appear with the \(selectedStyle.rawValue) style")
                        .font(.system(size: 14))
                        .foregroundColor(Design.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    // Mock subscription cards
                    VStack(spacing: 12) {
                        ForEach(mockStore.mockSubscriptions) { subscription in
                            PreviewSubscriptionCardSelector(
                                subscription: subscription,
                                subscriptionStore: mockStore,
                                action: {},
                                forcedStyle: selectedStyle
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}

// MARK: - Debug Preview Card
struct DebugPreviewCard: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    let forcedStyle: SubscriptionCardSelector.CardStyle
    
    var body: some View {
        HStack(spacing: 16) {
            // Always show logo for debugging
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                if let serviceLogo = subscription.serviceLogo {
                    Image(systemName: serviceLogo)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                } else {
                    Text(subscription.name?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(subscriptionStore.daysRemaining(for: subscription)) days left")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/mo")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Style indicator
            VStack {
                Text(forcedStyle.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview-specific Subscription Card Selector
struct PreviewSubscriptionCardSelector: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    let action: () -> Void
    let forcedStyle: SubscriptionCardSelector.CardStyle
    
    @State private var animateIn = false
    @ObservedObject private var appPreferences = AppPreferences.shared
    
    var body: some View {
        Group {
            switch forcedStyle {
            case .smart:
                smartCardSelection
            case .inline:
                EnhancedSubscriptionCard(
                    subscription: subscription,
                    subscriptionStore: subscriptionStore,
                    action: action
                )
            case .swipe:
                if #available(iOS 16.0, *) {
                    HybridSubscriptionCard(
                        subscription: subscription,
                        subscriptionStore: subscriptionStore,
                        action: action
                    )
                } else {
                    SubscriptionRowCard(
                        subscription: subscription,
                        subscriptionStore: subscriptionStore,
                        action: action
                    )
                }
            case .contextMenu:
                ContextMenuSubscriptionCard(
                    subscription: subscription,
                    subscriptionStore: subscriptionStore,
                    action: action
                )
            }
        }
        .scaleEffect(animateIn ? 1.0 : 0.95)
        .opacity(animateIn ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
    
    private var daysRemaining: Int {
        subscriptionStore.daysRemaining(for: subscription)
    }
    
    @ViewBuilder
    private var smartCardSelection: some View {
        if daysRemaining <= 3 {
            EnhancedSubscriptionCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        } else if daysRemaining <= 7 {
            ContextMenuSubscriptionCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        } else {
            SubscriptionRowCard(
                subscription: subscription,
                subscriptionStore: subscriptionStore,
                action: action
            )
        }
    }
}

// MARK: - Mock Store for Preview
class MockSubscriptionStore: SubscriptionStore {
    @Published var mockSubscriptions: [Subscription] = []
    private let mockContext: NSManagedObjectContext
    
    override init(context: NSManagedObjectContext? = nil, userID: String? = nil) {
        // Use a child context so we don't persist preview data
        let actualContext = context ?? PersistenceController.shared.container.viewContext
        let child = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        child.parent = actualContext
        self.mockContext = child
        super.init(context: child, userID: userID)
        seed()
    }
    
    private func seed() {
        mockSubscriptions.removeAll()
        
        func make(_ name: String, daysLeft: Int, price: Double, logo: String) {
            let s = Subscription(context: mockContext)
            s.id = UUID()
            s.name = name
            s.startDate = Date()
            s.endDate = Calendar.current.date(byAdding: .day, value: daysLeft, to: Date())
            s.monthlyPrice = price
            s.serviceLogo = logo
            s.status = SubscriptionStatus.active.rawValue
            mockSubscriptions.append(s)
        }
        
        make("Netflix", daysLeft: 1, price: 15.99, logo: "netflix-logo")
        make("Spotify", daysLeft: 5, price: 9.99, logo: "spotify-logo")
        make("Apple TV+", daysLeft: 12, price: 20.99, logo: "appletv-logo")
        make("Apple Music", daysLeft: 3, price: 7.99, logo: "apple-logo")
        
        // Ensure store categories are computed for these new objects
        self.fetchSubscriptions()
    }
}
