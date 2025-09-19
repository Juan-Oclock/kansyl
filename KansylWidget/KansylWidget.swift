//
//  KansylWidget.swift
//  KansylWidget
//
//  Created on 9/12/25.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct SubscriptionWidgetEntry: TimelineEntry {
    let date: Date
    let upcomingSubscriptions: [SubscriptionInfo]
    let totalSavings: Double
    let activeSubscriptionCount: Int
    let configuration: ConfigurationIntent
}

struct SubscriptionInfo: Identifiable {
    let id: UUID
    let name: String
    let endDate: Date
    let monthlyPrice: Double
    let serviceLogo: String
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var isEndingSoon: Bool {
        daysRemaining <= 3
    }
}

// MARK: - Timeline Provider
struct SubscriptionWidgetProvider: IntentTimelineProvider {
    typealias Intent = ConfigurationIntent
    typealias Entry = SubscriptionWidgetEntry
    
    func placeholder(in context: Context) -> SubscriptionWidgetEntry {
        SubscriptionWidgetEntry(
            date: Date(),
            upcomingSubscriptions: sampleSubscriptions(),
            totalSavings: 127.50,
            activeSubscriptionCount: 3,
            configuration: ConfigurationIntent()
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SubscriptionWidgetEntry) -> Void) {
        let entry = loadCurrentData(for: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SubscriptionWidgetEntry>) -> Void) {
        let currentDate = Date()
        let entry = loadCurrentData(for: configuration)
        
        // Update timeline every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // MARK: - Data Loading
    private func loadCurrentData(for configuration: ConfigurationIntent) -> SubscriptionWidgetEntry {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.active.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        request.fetchLimit = 5
        
        do {
            let subscriptions = try context.fetch(request)
            let upcomingSubscriptions = subscriptions.compactMap { subscription -> SubscriptionInfo? in
                guard let id = subscription.id,
                      let name = subscription.name,
                      let endDate = subscription.endDate else { return nil }
                
                return SubscriptionInfo(
                    id: id,
                    name: name,
                    endDate: endDate,
                    monthlyPrice: subscription.monthlyPrice,
                    serviceLogo: subscription.serviceLogo ?? ""
                )
            }
            
            // Calculate total savings
            let savingsRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
            savingsRequest.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.canceled.rawValue)
            let canceledSubscriptions = try context.fetch(savingsRequest)
            let totalSavings = canceledSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
            
            // Get active subscription count
            let countRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
            countRequest.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.active.rawValue)
            let activeCount = try context.count(for: countRequest)
            
            return SubscriptionWidgetEntry(
                date: Date(),
                upcomingSubscriptions: upcomingSubscriptions,
                totalSavings: totalSavings,
                activeSubscriptionCount: activeCount,
                configuration: configuration
            )
        } catch {
            // Debug: // Debug: print("Widget data fetch error: \(error)")
            return SubscriptionWidgetEntry(
                date: Date(),
                upcomingSubscriptions: [],
                totalSavings: 0,
                activeSubscriptionCount: 0,
                configuration: configuration
            )
        }
    }
    
    private func sampleSubscriptions() -> [SubscriptionInfo] {
        [
            SubscriptionInfo(
                id: UUID(),
                name: "Netflix",
                endDate: Date().addingTimeInterval(86400 * 2),
                monthlyPrice: 15.99,
                serviceLogo: "netflix"
            ),
            SubscriptionInfo(
                id: UUID(),
                name: "Spotify",
                endDate: Date().addingTimeInterval(86400 * 5),
                monthlyPrice: 9.99,
                serviceLogo: "spotify"
            )
        ]
    }
}

// MARK: - Widget Views

// Small Widget View
struct SmallWidgetView: View {
    let entry: SubscriptionWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Spacer()
                Text("Kansyl")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Main Content
            if let nextSubscription = entry.upcomingSubscriptions.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nextSubscription.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if nextSubscription.daysRemaining <= 0 {
                        Text("Ends Today!")
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    } else {
                        Text("\(nextSubscription.daysRemaining) days left")
                            .font(.caption)
                            .foregroundColor(nextSubscription.isEndingSoon ? .orange : .secondary)
                    }
                    
                    Text("\(SharedCurrencyFormatter.formatPrice(nextSubscription.monthlyPrice))/mo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No active subscriptions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Label("\(entry.activeSubscriptionCount)", systemImage: "list.bullet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(SharedCurrencyFormatter.formatPriceCompact(entry.totalSavings)) saved")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(ContainerRelativeShape().fill(Color(.systemBackground)))
    }
}

// Medium Widget View
struct MediumWidgetView: View {
    let entry: SubscriptionWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Upcoming Subscriptions")
                        .font(.headline)
                    Text("\(entry.activeSubscriptionCount) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(SharedCurrencyFormatter.formatPriceCompact(entry.totalSavings)) saved")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Divider()
            
            // Subscription List
            if entry.upcomingSubscriptions.isEmpty {
                HStack {
                    Spacer()
                    Text("No active subscriptions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.upcomingSubscriptions.prefix(3)) { subscription in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    if subscription.daysRemaining <= 0 {
                                        Text("Ends Today!")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("\(subscription.daysRemaining)d")
                                            .font(.caption2)
                                            .foregroundColor(subscription.isEndingSoon ? .orange : .secondary)
                                    }
                                    
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(SharedCurrencyFormatter.formatPrice(subscription.monthlyPrice))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if subscription.isEndingSoon {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(ContainerRelativeShape().fill(Color(.systemBackground)))
    }
}

// Large Widget View
struct LargeWidgetView: View {
    let entry: SubscriptionWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Kansyl")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(entry.activeSubscriptionCount) active subscriptions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.0f", entry.totalSavings))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Total Saved")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Subscription List
            if entry.upcomingSubscriptions.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("All clear!")
                        .font(.headline)
                    Text("No active subscriptions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(entry.upcomingSubscriptions) { subscription in
                        HStack {
                            // Service Icon placeholder
                            Circle()
                                .fill(subscription.isEndingSoon ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(subscription.name.prefix(2)))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscription.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 8) {
                                    if subscription.daysRemaining <= 0 {
                                        Label("Ends Today!", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else {
                                        Label("\(subscription.daysRemaining) days", systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundColor(subscription.isEndingSoon ? .orange : .secondary)
                                    }
                                    
                                    Text("$\(String(format: "%.2f", subscription.monthlyPrice))/mo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if subscription.isEndingSoon {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(ContainerRelativeShape().fill(Color(.systemBackground)))
    }
}

// MARK: - Main Widget
struct KansylWidget: Widget {
    let kind: String = "KansylWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: SubscriptionWidgetProvider()
        ) { entry in
            KansylWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Kansyl Subscriptions")
        .description("Keep track of your subscription trials")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct KansylWidgetEntryView: View {
    let entry: SubscriptionWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview
struct KansylWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KansylWidgetEntryView(entry: SubscriptionWidgetEntry(
                date: Date(),
                upcomingSubscriptions: [
                    SubscriptionInfo(
                        id: UUID(),
                        name: "Netflix",
                        endDate: Date().addingTimeInterval(86400 * 2),
                        monthlyPrice: 15.99,
                        serviceLogo: "netflix"
                    ),
                    SubscriptionInfo(
                        id: UUID(),
                        name: "Spotify",
                        endDate: Date().addingTimeInterval(86400 * 5),
                        monthlyPrice: 9.99,
                        serviceLogo: "spotify"
                    )
                ],
                totalSavings: 127.50,
                activeSubscriptionCount: 3,
                configuration: ConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            KansylWidgetEntryView(entry: SubscriptionWidgetEntry(
                date: Date(),
                upcomingSubscriptions: [],
                totalSavings: 250,
                activeSubscriptionCount: 0,
                configuration: ConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}