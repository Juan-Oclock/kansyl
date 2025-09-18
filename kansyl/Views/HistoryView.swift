//
//  HistoryView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: false)],
        predicate: NSPredicate(format: "status != %@", SubscriptionStatus.active.rawValue),
        animation: .default
    )
    private var pastSubscriptions: FetchedResults<Subscription>
    
    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showingSubscriptionDetail = false
    @State private var selectedSubscription: Subscription?
    @FocusState private var isSearchFocused: Bool
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case canceled = "Saved"
        case kept = "Kept"
        case expired = "Expired"
        
        var icon: String {
            switch self {
            case .all: return "clock.arrow.circlepath"
            case .canceled: return "checkmark.circle.fill"
            case .kept: return "creditcard.fill"
            case .expired: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .canceled: return .green
            case .kept: return .blue
            case .expired: return .red
            }
        }
    }
    
    // Group subscriptions by month
    private var groupedSubscriptions: [(key: String, subscriptions: [Subscription])] {
        let filtered = filteredSubscriptions
        let grouped = Dictionary(grouping: filtered) { subscription -> String in
            guard let endDate = subscription.endDate else { return "Unknown" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: endDate)
        }
        
        return grouped.sorted { first, second in
            // Sort by date descending
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date1 = formatter.date(from: first.key) ?? Date.distantPast
            let date2 = formatter.date(from: second.key) ?? Date.distantPast
            return date1 > date2
        }.map { (key: $0.key, subscriptions: $0.value) }
    }
    
    private var filteredSubscriptions: [Subscription] {
        var subscriptions = Array(pastSubscriptions)
        
        // Apply status filter
        if selectedFilter != .all {
            subscriptions = subscriptions.filter { subscription in
                switch selectedFilter {
                case .canceled:
                    return subscription.status == SubscriptionStatus.canceled.rawValue
                case .kept:
                    return subscription.status == SubscriptionStatus.kept.rawValue
                case .expired:
                    return subscription.status == SubscriptionStatus.expired.rawValue
                case .all:
                    return true
                }
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            subscriptions = subscriptions.filter { subscription in
                subscription.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return subscriptions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header - similar to ModernSubscriptionsView
                customHeader
                    .background(Design.Colors.background)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HistoryFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                icon: filter.icon,
                                color: filter.color,
                                isSelected: selectedFilter == filter,
                                count: countForFilter(filter)
                            ) {
                                withAnimation(.spring()) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Main Content
                if pastSubscriptions.isEmpty {
                    EmptyHistoryView()
                } else if groupedSubscriptions.isEmpty {
                    NoResultsView(searchText: searchText, filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedSubscriptions, id: \.key) { month, subscriptions in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Month Header
                                    HStack {
                                        Text(month)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        // Month Summary
                                        Text(monthSummary(for: subscriptions))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Subscriptions for this month
                                    ForEach(subscriptions) { subscription in
                                        HistorySubscriptionRow(subscription: subscription)
                                            .onTapGesture {
                                                selectedSubscription = subscription
                                                showingSubscriptionDetail = true
                                            }
                                    }
                                }
                            }
                            
                            // Bottom padding to ensure last item is fully visible above tab bar
                            Color.clear.frame(height: 100)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedSubscription) { subscription in
                ZStack {
                    // Theme-aware overlay background - much darker for better focus
                    (colorScheme == .dark ? Color.black.opacity(0.85) : Color.black.opacity(0.8))
                        .ignoresSafeArea()
                    
                    SubscriptionDetailView(subscription: subscription, subscriptionStore: SubscriptionStore(context: viewContext))
                }
            }
        }
    }
    
    private func countForFilter(_ filter: HistoryFilter) -> Int {
        switch filter {
        case .all:
            return pastSubscriptions.count
        case .canceled:
            return pastSubscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }.count
        case .kept:
            return pastSubscriptions.filter { $0.status == SubscriptionStatus.kept.rawValue }.count
        case .expired:
            return pastSubscriptions.filter { $0.status == SubscriptionStatus.expired.rawValue }.count
        }
    }
    
    private func monthSummary(for subscriptions: [Subscription]) -> String {
        let saved = subscriptions.filter { $0.status == SubscriptionStatus.canceled.rawValue }
            .reduce(0) { $0 + $1.monthlyPrice }
        let kept = subscriptions.filter { $0.status == SubscriptionStatus.kept.rawValue }.count
        let expired = subscriptions.filter { $0.status == SubscriptionStatus.expired.rawValue }.count
        
        var summary: [String] = []
        if saved > 0 {
            summary.append("Saved \(AppPreferences.shared.formatPrice(saved))")
        }
        if kept > 0 {
            summary.append("\(kept) kept")
        }
        if expired > 0 {
            summary.append("\(expired) expired")
        }
        
        return summary.joined(separator: " • ")
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("History")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Design.Colors.textSecondary.opacity(0.7))
                        .font(.system(size: 14))
                    
                    TextField("Search past subscriptions", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(Design.Colors.textPrimary)
                        .focused($isSearchFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isSearchFocused = false
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Design.Colors.primary)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Design.Colors.textSecondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Design.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSearchFocused ? Design.Colors.primary : Color.gray.opacity(0.15), lineWidth: isSearchFocused ? 2 : 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}

// MARK: - History Subscription Row
struct HistorySubscriptionRow: View {
    let subscription: Subscription
    @Environment(\.managedObjectContext) private var viewContext
    
    private var subscriptionStore: SubscriptionStore {
        SubscriptionStore(context: viewContext)
    }
    @State private var showingDeleteAlert = false
    @State private var offset: CGSize = .zero
    @State private var swipeState: SwipeState = .none
    @State private var isDragging = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum SwipeState {
        case none
        case swiping
        case showingActions
    }
    
    private var statusColor: Color {
        switch subscription.status {
        case SubscriptionStatus.canceled.rawValue:
            return .green
        case SubscriptionStatus.kept.rawValue:
            return .blue
        case SubscriptionStatus.expired.rawValue:
            return .red
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch subscription.status {
        case SubscriptionStatus.canceled.rawValue:
            return "Saved"
        case SubscriptionStatus.kept.rawValue:
            return "Kept"
        case SubscriptionStatus.expired.rawValue:
            return "Expired"
        default:
            return "Unknown"
        }
    }
    
    // Calculate opacity for chevron based on swipe progress
    private var chevronOpacity: Double {
        let progress = abs(offset.width) / 100
        return max(0, 1 - progress * 1.5) // Fade out as user swipes
    }
    
    // Calculate opacity for delete button based on swipe progress
    private var deleteButtonOpacity: Double {
        let progress = abs(offset.width) / 100
        return min(1, progress * 1.2) // Fade in as user swipes
    }
    
    @ViewBuilder
    private var logoBackground: some View {
        ZStack {
            // White background circle - consistent with ModernSubscriptionsView
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: colorScheme == .dark ? 4 : 2, x: 0, y: 1)
                .overlay(
                    // Add subtle border for better definition
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 0.5)
                )
            
            // Content on top of white background
            if let serviceLogo = subscription.serviceLogo {
                // Check if it's a custom uploaded image
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    // Custom uploaded image - smaller size to show white background
                    Image.bundleImage(serviceLogo, fallbackSystemName: getFallbackSystemName())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                } else {
                    // Try to load bundled service logo first
                    let logoImage = Image.bundleImage(serviceLogo, fallbackSystemName: getFallbackSystemName())
                    
                    // Check if we're using a fallback SF Symbol
                    if isUsingSFSymbolFallback(serviceLogo) {
                        // SF Symbol - don't resize, use font sizing
                        logoImage
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(getLogoColor())
                    } else {
                        // Actual image asset - resize it
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                    }
                }
            } else {
                // Use SF Symbol fallback or text
                Image(systemName: getFallbackSystemName())
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(getLogoColor())
            }
        }
    }
    
    // Helper function to get appropriate SF Symbol fallback based on service name
    private func getFallbackSystemName() -> String {
        guard let name = subscription.name?.lowercased() else { return "app.badge" }
        
        // Service-specific SF Symbols
        if name.contains("apple") || name.contains("icloud") {
            return "applelogo"
        } else if name.contains("music") {
            return "music.note"
        } else if name.contains("tv") || name.contains("netflix") || name.contains("hulu") || name.contains("disney") {
            return "tv.fill"
        } else if name.contains("spotify") || name.contains("pandora") {
            return "music.note.list"
        } else if name.contains("youtube") {
            return "play.rectangle.fill"
        } else if name.contains("game") || name.contains("xbox") || name.contains("playstation") || name.contains("nintendo") {
            return "gamecontroller.fill"
        } else if name.contains("dropbox") || name.contains("google drive") || name.contains("onedrive") {
            return "icloud.fill"
        } else if name.contains("notion") || name.contains("evernote") {
            return "note.text"
        } else if name.contains("slack") || name.contains("discord") || name.contains("teams") {
            return "message.fill"
        } else if name.contains("zoom") || name.contains("skype") {
            return "video.fill"
        } else if name.contains("adobe") {
            return "paintbrush.fill"
        } else if name.contains("microsoft") || name.contains("office") {
            return "square.grid.2x2.fill"
        } else if name.contains("fitness") || name.contains("peloton") || name.contains("gym") {
            return "figure.run"
        } else if name.contains("headspace") || name.contains("calm") || name.contains("meditation") {
            return "brain.head.profile"
        } else {
            return "app.badge"
        }
    }
    
    // Check if we're using an SF Symbol fallback (if UIImage can't load the asset)
    private func isUsingSFSymbolFallback(_ logoName: String) -> Bool {
        return UIImage.bundleImage(named: logoName) == nil
    }
    
    // Get appropriate color for logo - all logos should be black
    private func getLogoColor() -> Color {
        // All logos should be black for consistency
        return Color.black
    }
    
    private var serviceColor: Color {
        // All logos should be black for consistency
        // This is kept for potential future use but currently returns black
        return Color.black
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background delete action container
            HStack(spacing: 0) {
                Spacer()
                
                // Delete Button
                Button(action: {
                    withAnimation(Design.Animation.spring) {
                        showingDeleteAlert = true
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Delete")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .opacity(deleteButtonOpacity)
                .scaleEffect(deleteButtonOpacity > 0.5 ? 1 : 0.8)
                .animation(Design.Animation.smooth, value: deleteButtonOpacity)
            }
            .cornerRadius(12)
            
            // Main card content
            HStack(spacing: 12) {
                // Service Icon with white circle background
                logoBackground
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name ?? "Unknown")
                        .font(.headline)
                    
                    HStack {
                        Text(statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/mo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let endDate = subscription.endDate {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(endDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                    .opacity(chevronOpacity)
                    .animation(Design.Animation.smooth, value: chevronOpacity)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .offset(x: offset.width)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { value in
                        // Only respond to horizontal swipes
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        guard horizontalAmount > verticalAmount * 1.5 else { return }
                        
                        isDragging = true
                        
                        // Only allow left swipe (negative translation)
                        if value.translation.width < -20 {
                            // Smooth elastic resistance at the end
                            let resistance = value.translation.width < -100 ? 0.5 : 1.0
                            let newOffset = max(value.translation.width * resistance, -120)
                            
                            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 1, blendDuration: 0)) {
                                offset = CGSize(width: newOffset, height: 0)
                            }
                            
                            if value.translation.width < -60 {
                                // Light haptic when reaching delete threshold
                                if swipeState != .showingActions {
                                    HapticManager.shared.playSelection()
                                    swipeState = .showingActions
                                }
                            } else {
                                swipeState = .swiping
                            }
                        } else if swipeState == .showingActions {
                            // Allow swipe right to close when actions are showing
                            let newOffset = min(value.translation.width - 100, 0)
                            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 1, blendDuration: 0)) {
                                offset = CGSize(width: newOffset, height: 0)
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        withAnimation(Design.Animation.spring) {
                            if value.translation.width < -60 {
                                // Show delete button with snap effect
                                offset = CGSize(width: -100, height: 0)
                                swipeState = .showingActions
                            } else {
                                // Reset position with bounce
                                offset = .zero
                                swipeState = .none
                            }
                        }
                    }
            )
        }
        .padding(.horizontal)
        .simultaneousGesture(DragGesture()) // Allow vertical scroll to work simultaneously
        .alert("Delete Subscription?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                // Reset swipe position when canceling
                withAnimation(Design.Animation.spring) {
                    offset = .zero
                    swipeState = .none
                }
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    subscriptionStore.deleteSubscription(subscription)
                    HapticManager.shared.playSuccess()
                }
            }
        } message: {
            Text("This will permanently delete this subscription from your history. This action cannot be undone.")
        }
    }
}

// MARK: - Supporting Views
struct FilterPill: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? (color == .primary ? (colorScheme == .dark ? .black : .white) : .white) : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? (color == .primary ? (colorScheme == .dark ? .white : color) : color) : color.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your past subscriptions will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoResultsView: View {
    let searchText: String
    let filter: HistoryView.HistoryFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)
            
            Group {
                if !searchText.isEmpty {
                    Text("No subscriptions matching '\(searchText)'")
                } else {
                    Text("No \(filter.rawValue.lowercased()) subscriptions")
                }
            }
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Subscription Detail View Stub
struct SubscriptionDetailView: View {
    let subscription: Subscription
    let subscriptionStore: SubscriptionStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        detailLogoBackground
                        
                        VStack(alignment: .leading) {
                            Text(subscription.name ?? "Unknown")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(AppPreferences.shared.formatPrice(subscription.monthlyPrice))/month")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(hex: "252525") : Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Status", value: subscription.status ?? "Unknown")
                        DetailRow(label: "Start Date", value: subscription.startDate?.formatted(date: .long, time: .omitted) ?? "Unknown")
                        DetailRow(label: "End Date", value: subscription.endDate?.formatted(date: .long, time: .omitted) ?? "Unknown")
                        
                        if let notes = subscription.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(hex: "252525") : Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationTitle("Subscription Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .halfHeightDetent()
    }
    
    @ViewBuilder
    private var detailLogoBackground: some View {
        ZStack {
            // White background circle - consistent with other views
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: colorScheme == .dark ? 4 : 2, x: 0, y: 1)
                .overlay(
                    // Add subtle border for better definition
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 0.5)
                )
            
            // Content on top of white background
            if let serviceLogo = subscription.serviceLogo {
                // Check if it's a custom uploaded image
                if serviceLogo.contains("_logo_") && (serviceLogo.hasSuffix(".jpg") || serviceLogo.hasSuffix(".png")) {
                    // Custom uploaded image - smaller size to show white background
                    Image.bundleImage(serviceLogo, fallbackSystemName: getDetailFallbackSystemName())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    // Try to load bundled service logo first
                    let logoImage = Image.bundleImage(serviceLogo, fallbackSystemName: getDetailFallbackSystemName())
                    
                    // Check if we're using a fallback SF Symbol
                    if UIImage.bundleImage(named: serviceLogo) == nil {
                        // SF Symbol - don't resize, use font sizing
                        logoImage
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(getDetailLogoColor())
                    } else {
                        // Actual image asset - resize it
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    }
                }
            } else {
                // Use SF Symbol fallback
                Image(systemName: getDetailFallbackSystemName())
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(getDetailLogoColor())
            }
        }
    }
    
    // Helper function for detail view fallback system name
    private func getDetailFallbackSystemName() -> String {
        guard let name = subscription.name?.lowercased() else { return "app.badge" }
        
        // Service-specific SF Symbols (same as row view)
        if name.contains("apple") || name.contains("icloud") {
            return "applelogo"
        } else if name.contains("music") {
            return "music.note"
        } else if name.contains("tv") || name.contains("netflix") || name.contains("hulu") || name.contains("disney") {
            return "tv.fill"
        } else if name.contains("spotify") || name.contains("pandora") {
            return "music.note.list"
        } else if name.contains("youtube") {
            return "play.rectangle.fill"
        } else if name.contains("game") || name.contains("xbox") || name.contains("playstation") || name.contains("nintendo") {
            return "gamecontroller.fill"
        } else if name.contains("dropbox") || name.contains("google drive") || name.contains("onedrive") {
            return "icloud.fill"
        } else if name.contains("notion") || name.contains("evernote") {
            return "note.text"
        } else if name.contains("slack") || name.contains("discord") || name.contains("teams") {
            return "message.fill"
        } else if name.contains("zoom") || name.contains("skype") {
            return "video.fill"
        } else if name.contains("adobe") {
            return "paintbrush.fill"
        } else if name.contains("microsoft") || name.contains("office") {
            return "square.grid.2x2.fill"
        } else if name.contains("fitness") || name.contains("peloton") || name.contains("gym") {
            return "figure.run"
        } else if name.contains("headspace") || name.contains("calm") || name.contains("meditation") {
            return "brain.head.profile"
        } else {
            return "app.badge"
        }
    }
    
    // Get appropriate color for detail logo - all logos should be black
    private func getDetailLogoColor() -> Color {
        // All logos should be black for consistency
        return Color.black
    }
    
    private var detailServiceColor: Color {
        // All logos should be black for consistency
        // This is kept for potential future use but currently returns black
        return Color.black
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}