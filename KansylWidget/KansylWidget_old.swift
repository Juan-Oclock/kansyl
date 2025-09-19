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
struct TrialWidgetEntry: TimelineEntry {
    let date: Date
    let upcomingTrials: [TrialInfo]
    let totalSavings: Double
    let activeTrialCount: Int
    let configuration: ConfigurationIntent
}

struct TrialInfo: Identifiable {
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
struct TrialWidgetProvider: IntentTimelineProvider {
    typealias Intent = ConfigurationIntent
    typealias Entry = TrialWidgetEntry
    
    func placeholder(in context: Context) -> TrialWidgetEntry {
        TrialWidgetEntry(
            date: Date(),
            upcomingTrials: sampleTrials(),
            totalSavings: 127.50,
            activeTrialCount: 3,
            configuration: ConfigurationIntent()
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TrialWidgetEntry) -> Void) {
        let entry = loadCurrentData(for: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<TrialWidgetEntry>) -> Void) {
        let currentDate = Date()
        let entry = loadCurrentData(for: configuration)
        
        // Update timeline every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // MARK: - Data Loading
    private func loadCurrentData(for configuration: ConfigurationIntent) -> TrialWidgetEntry {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Trial> = Trial.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", TrialStatus.active.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trial.endDate, ascending: true)]
        request.fetchLimit = 5
        
        do {
            let trials = try context.fetch(request)
            let upcomingTrials = trials.compactMap { trial -> TrialInfo? in
                guard let id = trial.id,
                      let name = trial.name,
                      let endDate = trial.endDate else { return nil }
                
                return TrialInfo(
                    id: id,
                    name: name,
                    endDate: endDate,
                    monthlyPrice: trial.monthlyPrice,
                    serviceLogo: trial.serviceLogo ?? ""
                )
            }
            
            // Calculate total savings
            let savingsRequest: NSFetchRequest<Trial> = Trial.fetchRequest()
            savingsRequest.predicate = NSPredicate(format: "status == %@", TrialStatus.canceled.rawValue)
            let canceledTrials = try context.fetch(savingsRequest)
            let totalSavings = canceledTrials.reduce(0) { $0 + $1.monthlyPrice }
            
            // Get active trial count
            let countRequest: NSFetchRequest<Trial> = Trial.fetchRequest()
            countRequest.predicate = NSPredicate(format: "status == %@", TrialStatus.active.rawValue)
            let activeCount = try context.count(for: countRequest)
            
            return TrialWidgetEntry(
                date: Date(),
                upcomingTrials: upcomingTrials,
                totalSavings: totalSavings,
                activeTrialCount: activeCount,
                configuration: configuration
            )
        } catch {
            // Debug: print("Widget data fetch error: \(error)")
            return TrialWidgetEntry(
                date: Date(),
                upcomingTrials: [],
                totalSavings: 0,
                activeTrialCount: 0,
                configuration: configuration
            )
        }
    }
    
    private func sampleTrials() -> [TrialInfo] {
        [
            TrialInfo(
                id: UUID(),
                name: "Netflix",
                endDate: Date().addingTimeInterval(86400 * 2),
                monthlyPrice: 15.99,
                serviceLogo: "netflix"
            ),
            TrialInfo(
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
    let entry: TrialWidgetEntry
    
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
            if let nextTrial = entry.upcomingTrials.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nextTrial.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if nextTrial.daysRemaining <= 0 {
                        Text("Ends Today!")
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    } else {
                        Text("\(nextTrial.daysRemaining) days left")
                            .font(.caption)
                            .foregroundColor(nextTrial.isEndingSoon ? .orange : .secondary)
                    }
                    
                    Text("$\(String(format: "%.2f", nextTrial.monthlyPrice))/mo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No active trials")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Label("\(entry.activeTrialCount)", systemImage: "list.bullet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(String(format: "%.0f", entry.totalSavings)) saved")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

// Medium Widget View
struct MediumWidgetView: View {
    let entry: TrialWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Side - Trials List
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text("Ending Soon")
                        .font(.headline)
                }
                
                if entry.upcomingTrials.isEmpty {
                    Text("No active trials")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    ForEach(entry.upcomingTrials.prefix(3)) { trial in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trial.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text("\(trial.daysRemaining)d left")
                                    .font(.caption2)
                                    .foregroundColor(trial.isEndingSoon ? .orange : .secondary)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", trial.monthlyPrice))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Right Side - Stats
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.activeTrialCount)")
                        .font(.title2)
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.0f", entry.totalSavings))")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Link(destination: URL(string: "kansyl://add-trial")!) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

// Large Widget View
struct LargeWidgetView: View {
    let entry: TrialWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kansyl")
                        .font(.title2)
                        .bold()
                    Text("\(entry.activeTrialCount) active trials")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", entry.totalSavings))")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                    Text("saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Trials List
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming Trials")
                    .font(.headline)
                
                if entry.upcomingTrials.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            Text("No trials ending soon!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(entry.upcomingTrials) { trial in
                        HStack {
                            // Service Icon Placeholder
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(trial.name.prefix(1))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trial.name)
                                    .font(.subheadline)
                                    .bold()
                                HStack(spacing: 8) {
                                    Label("\(trial.daysRemaining) days", systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(trial.isEndingSoon ? .orange : .secondary)
                                    Text("$\(String(format: "%.2f", trial.monthlyPrice))/mo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if trial.isEndingSoon {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Link(destination: URL(string: "kansyl://add-trial")!) {
                    Label("Add Trial", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Link(destination: URL(string: "kansyl://view-all")!) {
                    Label("View All", systemImage: "list.bullet")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

// MARK: - Widget Background Extension
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(color, for: .widget)
        } else {
            return self.background(color)
        }
    }
}

// MARK: - Widget Configuration
@main
struct KansylWidget: Widget {
    let kind: String = "KansylWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: TrialWidgetProvider()
        ) { entry in
            KansylWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Trial Tracker")
        .description("Keep track of your free trials and savings")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct KansylWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TrialWidgetEntry
    
    var body: some View {
        switch family {
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

// MARK: - Widget Preview
struct KansylWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KansylWidgetEntryView(entry: TrialWidgetEntry(
                date: Date(),
                upcomingTrials: [
                    TrialInfo(id: UUID(), name: "Netflix", endDate: Date().addingTimeInterval(86400 * 2), monthlyPrice: 15.99, serviceLogo: ""),
                    TrialInfo(id: UUID(), name: "Spotify", endDate: Date().addingTimeInterval(86400 * 5), monthlyPrice: 9.99, serviceLogo: "")
                ],
                totalSavings: 127.50,
                activeTrialCount: 3,
                configuration: ConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")
            
            KansylWidgetEntryView(entry: TrialWidgetEntry(
                date: Date(),
                upcomingTrials: [
                    TrialInfo(id: UUID(), name: "Netflix", endDate: Date().addingTimeInterval(86400 * 2), monthlyPrice: 15.99, serviceLogo: ""),
                    TrialInfo(id: UUID(), name: "Spotify", endDate: Date().addingTimeInterval(86400 * 5), monthlyPrice: 9.99, serviceLogo: "")
                ],
                totalSavings: 127.50,
                activeTrialCount: 3,
                configuration: ConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
            
            KansylWidgetEntryView(entry: TrialWidgetEntry(
                date: Date(),
                upcomingTrials: [
                    TrialInfo(id: UUID(), name: "Netflix", endDate: Date().addingTimeInterval(86400 * 2), monthlyPrice: 15.99, serviceLogo: ""),
                    TrialInfo(id: UUID(), name: "Spotify", endDate: Date().addingTimeInterval(86400 * 5), monthlyPrice: 9.99, serviceLogo: "")
                ],
                totalSavings: 127.50,
                activeTrialCount: 3,
                configuration: ConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}
