//
//  AnalyticsManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import StoreKit
import os.log

// MARK: - Analytics Event Types
enum AnalyticsEvent: String {
    // Subscription Management
    case subscriptionAdded = "subscription_added"
    case subscriptionCanceled = "subscription_canceled"
    case subscriptionKept = "subscription_kept"
    case subscriptionExpired = "subscription_expired"
    case subscriptionDeleted = "subscription_deleted"
    
    // User Actions
    case appOpened = "app_opened"
    case notificationScheduled = "notification_scheduled"
    case notificationTapped = "notification_tapped"
    case widgetTapped = "widget_tapped"
    case achievementUnlocked = "achievement_unlocked"
    case dataExported = "data_exported"
    case sharingCompleted = "sharing_completed"
    
    // Premium Features
    case premiumPurchased = "premium_purchased"
    case premiumRestored = "premium_restored"
    case premiumCanceled = "premium_canceled"
    
    // Performance
    case appLaunched = "app_launched"
    case syncCompleted = "sync_completed"
    case errorOccurred = "error_occurred"
}

// MARK: - Analytics Properties
struct AnalyticsProperties {
    var trialCount: Int?
    var savingsAmount: Double?
    var source: String?
    var errorType: String?
    var duration: TimeInterval?
    var success: Bool?
    var subscriptionId: String?
    var subscriptionName: String?
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        if let trialCount = trialCount { dict["trial_count"] = trialCount }
        if let savingsAmount = savingsAmount { dict["savings_amount"] = savingsAmount }
        if let source = source { dict["source"] = source }
        if let errorType = errorType { dict["error_type"] = errorType }
        if let duration = duration { dict["duration"] = duration }
        if let success = success { dict["success"] = success }
        if let subscriptionId = subscriptionId { dict["subscription_id"] = subscriptionId }
        if let subscriptionName = subscriptionName { dict["subscription_name"] = subscriptionName }
        return dict
    }
}

// MARK: - Analytics Manager
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let logger = Logger(subsystem: "com.kansyl.app", category: "Analytics")
    private let userDefaults = UserDefaults.standard
    
    @Published var isAnalyticsEnabled: Bool {
        didSet {
            userDefaults.set(isAnalyticsEnabled, forKey: "analytics_enabled")
            if !isAnalyticsEnabled {
                clearAnalyticsData()
            }
        }
    }
    
    @Published var crashReportingEnabled: Bool {
        didSet {
            userDefaults.set(crashReportingEnabled, forKey: "crash_reporting_enabled")
        }
    }
    
    // Usage Statistics (Privacy-Compliant)
    @Published private(set) var usageStats = UsageStatistics()
    
    private init() {
        self.isAnalyticsEnabled = userDefaults.bool(forKey: "analytics_enabled")
        self.crashReportingEnabled = userDefaults.bool(forKey: "crash_reporting_enabled")
        loadUsageStats()
        loadRawCrashReports()  // Load any crash reports from previous sessions
        setupCrashReporting()
    }
    
    // MARK: - Event Tracking
    func track(_ event: AnalyticsEvent, properties: AnalyticsProperties? = nil) {
        guard isAnalyticsEnabled else { return }
        
        // Log event locally (privacy-compliant)
        // Event tracking is enabled
        
        // Update local statistics
        updateLocalStats(for: event, properties: properties)
        
        // Store anonymized event data
        storeAnonymizedEvent(event, properties: properties)
    }
    
    // MARK: - Performance Monitoring
    func startPerformanceTracking(for operation: String) -> PerformanceTracker {
        return PerformanceTracker(operation: operation, manager: self)
    }
    
    // MARK: - Crash Reporting
    private func setupCrashReporting() {
        guard crashReportingEnabled else { return }
        
        // Set up exception handler
        NSSetUncaughtExceptionHandler { exception in
            AnalyticsManager.handleExceptionStatic(exception)
        }
        
        // Install signal handlers using static functions
        AnalyticsManager.installSignalHandlers()
    }
    
    // Static signal handlers that don't capture context
    private static func installSignalHandlers() {
        signal(SIGABRT, signalHandler)
        signal(SIGILL, signalHandler)
        signal(SIGSEGV, signalHandler)
        signal(SIGFPE, signalHandler)
        signal(SIGBUS, signalHandler)
        signal(SIGPIPE, signalHandler)
    }
    
    // Static signal handler function
    private static let signalHandler: @convention(c) (Int32) -> Void = { signalNumber in
        let signalName: String
        switch signalNumber {
        case SIGABRT: signalName = "SIGABRT"
        case SIGILL: signalName = "SIGILL"
        case SIGSEGV: signalName = "SIGSEGV"
        case SIGFPE: signalName = "SIGFPE"
        case SIGBUS: signalName = "SIGBUS"
        case SIGPIPE: signalName = "SIGPIPE"
        default: signalName = "Unknown signal \(signalNumber)"
        }
        
        // Store crash info directly to UserDefaults since we can't use instance methods
        let crashInfo = [
            "type": "Signal",
            "name": signalName,
            "reason": "Signal received: \(signalName)",
            "timestamp": Date().ISO8601Format(),
            "call_stack": Thread.callStackSymbols
        ] as [String : Any]
        
        // Append to existing crash reports
        let userDefaults = UserDefaults.standard
        var reports = userDefaults.array(forKey: "crash_reports_raw") as? [[String: Any]] ?? []
        reports.append(crashInfo)
        userDefaults.set(reports, forKey: "crash_reports_raw")
        userDefaults.synchronize()
        
        // Re-raise the signal to ensure proper app termination
        signal(signalNumber, SIG_DFL)
        raise(signalNumber)
    }
    
    // Static exception handler
    private static func handleExceptionStatic(_ exception: NSException) {
        let crashInfo = [
            "type": "Exception",
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "",
            "timestamp": Date().ISO8601Format(),
            "call_stack": exception.callStackSymbols
        ] as [String : Any]
        
        // Store directly to UserDefaults
        let userDefaults = UserDefaults.standard
        var reports = userDefaults.array(forKey: "crash_reports_raw") as? [[String: Any]] ?? []
        reports.append(crashInfo)
        userDefaults.set(reports, forKey: "crash_reports_raw")
        userDefaults.synchronize()
    }
    
    // Instance method to handle exceptions (can be called after static handler)
    private func handleException(_ exception: NSException) {
        guard crashReportingEnabled else { return }
        
        let crashInfo = CrashInfo(
            type: "Exception",
            name: exception.name.rawValue,
            reason: exception.reason,
            callStack: exception.callStackSymbols,
            timestamp: Date()
        )
        
        storeCrashReport(crashInfo)
    }
    
    // Load crash reports that were stored by static handlers
    private func loadRawCrashReports() {
        let userDefaults = UserDefaults.standard
        guard let rawReports = userDefaults.array(forKey: "crash_reports_raw") as? [[String: Any]] else {
            return
        }
        
        // Convert raw reports to CrashInfo and store properly
        for rawReport in rawReports {
            if let type = rawReport["type"] as? String,
               let name = rawReport["name"] as? String,
               let callStack = rawReport["call_stack"] as? [String] {
                
                let crashInfo = CrashInfo(
                    type: type,
                    name: name,
                    reason: rawReport["reason"] as? String,
                    callStack: callStack,
                    timestamp: Date()
                )
                storeCrashReport(crashInfo)
            }
        }
        
        // Clear raw reports after processing
        userDefaults.removeObject(forKey: "crash_reports_raw")
    }
    
    // MARK: - Local Statistics
    private func updateLocalStats(for event: AnalyticsEvent, properties: AnalyticsProperties?) {
        switch event {
        case .subscriptionAdded:
            usageStats.totalSubscriptionsAdded += 1
        case .subscriptionCanceled:
            usageStats.totalSubscriptionsCanceled += 1
            if let savings = properties?.savingsAmount {
                usageStats.totalSavings += savings
            }
        case .subscriptionKept:
            usageStats.totalSubscriptionsKept += 1
        case .achievementUnlocked:
            usageStats.achievementsUnlocked += 1
        case .appOpened:
            usageStats.appOpenCount += 1
            usageStats.lastActiveDate = Date()
        case .notificationScheduled:
            usageStats.notificationsScheduled += 1
        case .premiumPurchased:
            usageStats.isPremiumUser = true
        default:
            break
        }
        
        saveUsageStats()
    }
    
    // MARK: - Data Management
    private func storeAnonymizedEvent(_ event: AnalyticsEvent, properties: AnalyticsProperties?) {
        // Store only anonymized, aggregated data
        let anonymizedEvent = AnonymizedEvent(
            event: event.rawValue,
            timestamp: Date(),
            properties: properties?.dictionary ?? [:],
            sessionId: getCurrentSessionId()
        )
        
        // Store in UserDefaults (limited to last 100 events)
        var events = getStoredEvents()
        events.append(anonymizedEvent)
        if events.count > 100 {
            events.removeFirst(events.count - 100)
        }
        
        if let encoded = try? JSONEncoder().encode(events) {
            userDefaults.set(encoded, forKey: "anonymized_events")
        }
    }
    
    private func getStoredEvents() -> [AnonymizedEvent] {
        guard let data = userDefaults.data(forKey: "anonymized_events"),
              let events = try? JSONDecoder().decode([AnonymizedEvent].self, from: data) else {
            return []
        }
        return events
    }
    
    private func storeCrashReport(_ crashInfo: CrashInfo) {
        // Store crash report for later submission
        var reports = getCrashReports()
        reports.append(crashInfo)
        
        if let encoded = try? JSONEncoder().encode(reports) {
            userDefaults.set(encoded, forKey: "crash_reports")
        }
    }
    
    private func getCrashReports() -> [CrashInfo] {
        guard let data = userDefaults.data(forKey: "crash_reports"),
              let reports = try? JSONDecoder().decode([CrashInfo].self, from: data) else {
            return []
        }
        return reports
    }
    
    // MARK: - Session Management
    private func getCurrentSessionId() -> String {
        if let sessionId = userDefaults.string(forKey: "current_session_id") {
            return sessionId
        } else {
            let newSessionId = UUID().uuidString
            userDefaults.set(newSessionId, forKey: "current_session_id")
            return newSessionId
        }
    }
    
    func startNewSession() {
        let sessionId = UUID().uuidString
        userDefaults.set(sessionId, forKey: "current_session_id")
        track(.appLaunched)
    }
    
    // MARK: - Privacy
    func clearAnalyticsData() {
        userDefaults.removeObject(forKey: "anonymized_events")
        userDefaults.removeObject(forKey: "crash_reports")
        userDefaults.removeObject(forKey: "usage_statistics")
        userDefaults.removeObject(forKey: "current_session_id")
        usageStats = UsageStatistics()
        logger.info("Analytics data cleared")
    }
    
    func exportAnalyticsData() -> String {
        let events = getStoredEvents()
        let crashes = getCrashReports()
        
        let exportData: [String: Any] = [
            "usage_statistics": usageStats.dictionary,
            "events": events.map { $0.dictionary },
            "crash_reports": crashes.map { $0.dictionary },
            "export_date": Date().ISO8601Format()
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    // MARK: - App Store Review
    func requestAppStoreReview() {
        // Only request if user has completed certain actions
        guard usageStats.totalSubscriptionsCanceled >= 3 || usageStats.appOpenCount >= 10 else { return }
        
        if #available(iOS 14.0, *) {
            // Use the scene-based API for iOS 14+
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                track(.appOpened, properties: AnalyticsProperties(source: "review_requested"))
            }
        }
    }
    
    // MARK: - Persistence
    private func loadUsageStats() {
        guard let data = userDefaults.data(forKey: "usage_statistics"),
              let stats = try? JSONDecoder().decode(UsageStatistics.self, from: data) else {
            return
        }
        usageStats = stats
    }
    
    private func saveUsageStats() {
        if let encoded = try? JSONEncoder().encode(usageStats) {
            userDefaults.set(encoded, forKey: "usage_statistics")
        }
    }
}

// MARK: - Supporting Types
struct UsageStatistics: Codable {
    var totalSubscriptionsAdded: Int = 0
    var totalSubscriptionsCanceled: Int = 0
    var totalSubscriptionsKept: Int = 0
    var totalSavings: Double = 0
    var achievementsUnlocked: Int = 0
    var appOpenCount: Int = 0
    var notificationsScheduled: Int = 0
    var isPremiumUser: Bool = false
    var lastActiveDate: Date = Date()
    
    var dictionary: [String: Any] {
        return [
            "total_subscriptions_added": totalSubscriptionsAdded,
            "total_subscriptions_canceled": totalSubscriptionsCanceled,
            "total_subscriptions_kept": totalSubscriptionsKept,
            "total_savings": totalSavings,
            "achievements_unlocked": achievementsUnlocked,
            "app_open_count": appOpenCount,
            "notifications_scheduled": notificationsScheduled,
            "is_premium_user": isPremiumUser,
            "last_active_date": lastActiveDate.ISO8601Format()
        ]
    }
}

struct AnonymizedEvent: Codable {
    let event: String
    let timestamp: Date
    let properties: [String: Any]
    let sessionId: String
    
    var dictionary: [String: Any] {
        return [
            "event": event,
            "timestamp": timestamp.ISO8601Format(),
            "properties": properties,
            "session_id": sessionId
        ]
    }
    
    enum CodingKeys: String, CodingKey {
        case event, timestamp, properties, sessionId
    }
    
    init(event: String, timestamp: Date, properties: [String: Any], sessionId: String) {
        self.event = event
        self.timestamp = timestamp
        self.properties = properties
        self.sessionId = sessionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(String.self, forKey: .event)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        
        if let data = try? container.decode(Data.self, forKey: .properties),
           let props = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            properties = props
        } else {
            properties = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sessionId, forKey: .sessionId)
        
        if let data = try? JSONSerialization.data(withJSONObject: properties) {
            try container.encode(data, forKey: .properties)
        }
    }
}

struct CrashInfo: Codable {
    let type: String
    let name: String
    let reason: String?
    let callStack: [String]
    let timestamp: Date
    
    var dictionary: [String: Any] {
        return [
            "type": type,
            "name": name,
            "reason": reason ?? "",
            "call_stack": callStack,
            "timestamp": timestamp.ISO8601Format()
        ]
    }
}

// MARK: - Performance Tracker
class PerformanceTracker {
    private let operation: String
    private let startTime: Date
    private weak var manager: AnalyticsManager?
    
    init(operation: String, manager: AnalyticsManager) {
        self.operation = operation
        self.startTime = Date()
        self.manager = manager
    }
    
    func complete(success: Bool = true) {
        let duration = Date().timeIntervalSince(startTime)
        manager?.track(.syncCompleted, properties: AnalyticsProperties(
            source: operation,
            duration: duration,
            success: success
        ))
    }
}
