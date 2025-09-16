//
//  ConfigurationIntent.swift
//  KansylWidget
//
//  Created on 9/12/25.
//

import WidgetKit
import AppIntents

// MARK: - Configuration Intent
struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description = IntentDescription("Configure your trial tracker widget")
    
    @Parameter(title: "Display Mode", default: .upcomingTrials)
    var displayMode: WidgetDisplayMode
    
    @Parameter(title: "Show Savings", default: true)
    var showSavings: Bool
    
    @Parameter(title: "Alert Threshold", default: 3)
    var alertThresholdDays: Int
}

// MARK: - Display Mode
enum WidgetDisplayMode: String, AppEnum {
    case upcomingTrials = "upcoming"
    case recentlyCanceled = "canceled"
    case statistics = "stats"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Display Mode")
    static var caseDisplayRepresentations: [WidgetDisplayMode: DisplayRepresentation] = [
        .upcomingTrials: "Upcoming Trials",
        .recentlyCanceled: "Recently Canceled",
        .statistics: "Statistics Only"
    ]
}
