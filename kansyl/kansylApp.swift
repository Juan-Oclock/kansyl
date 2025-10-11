//
//  kansylApp.swift
//  kansyl
//
//  Fixed version with proper async initialization
//

import SwiftUI
import CoreData

@main
struct kansylApp: App {
    // Use @StateObject for lazy initialization - these won't initialize until first accessed
    @StateObject private var appState = AppState()

    // UI state properties
    @State private var shouldShowAddSubscription = false
    @State private var serviceToAdd: String?
    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var toastMessage = ""
    @State private var lastProcessedActivityID: String? = nil
    @State private var isProcessingShortcut = false

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isInitializing {
                    // Show loading screen while services initialize
                    LoadingView()
                } else if let error = appState.initializationError {
                    // Show error screen if initialization failed
                    InitializationErrorView(error: error, retryAction: {
                        Task {
                            await appState.initialize()
                        }
                    })
                } else {
                    // Main app view - only shown after successful initialization
                    AuthenticationWrapperView()
                        .environmentObject(appState.authManager)
                        .environment(\.managedObjectContext, appState.viewContext)
                        .onContinueUserActivity("com.kansyl.addTrial") { userActivity in
                            DispatchQueue.main.async {
                                handleAddTrialActivity(userActivity)
                            }
                        }
                        .onContinueUserActivity("com.kansyl.quickAddTrial") { userActivity in
                            DispatchQueue.main.async {
                                handleQuickAddTrialActivity(userActivity)
                            }
                        }
                        .onContinueUserActivity("com.kansyl.checkTrials") { userActivity in
                            DispatchQueue.main.async {
                                handleCheckTrialsActivity(userActivity)
                            }
                        }
                        .onOpenURL { url in
                            print("🔗 [kansylApp] ========== onOpenURL TRIGGERED ==========")
                            print("🔗 [kansylApp] Full URL: \(url.absoluteString)")
                            print("🔍 [kansylApp] URL scheme: \(url.scheme ?? "none")")
                            print("🔍 [kansylApp] URL host: \(url.host ?? "none")")
                            print("🔍 [kansylApp] URL path: \(url.path)")
                            if url.scheme == "kansyl" {
                                // Check if this is an import request from Share Extension
                                if url.host == "import" {
                                    print("📥 [kansylApp] ✅ Detected import request from Share Extension")
                                    print("📥 [kansylApp] Triggering immediate import...")

                                    // Import immediately with priority
                                    Task(priority: .high) {
                                        // Ensure user has a userID first
                                        if SubscriptionStore.currentUserID == nil || SubscriptionStore.currentUserID?.isEmpty == true {
                                            print("⚠️ [kansylApp] No user ID set, enabling anonymous mode first")
                                            await MainActor.run {
                                                UserStateManager.shared.enableAnonymousMode()
                                            }
                                        }

                                        // Now import the pending subscriptions
                                        await appState.checkPendingSubscriptions()

                                        // Show success feedback
                                        await MainActor.run {
                                            HapticManager.shared.playSuccess()
                                        }
                                    }
                                } else {
                                    print("✅ [kansylApp] Scheme matches 'kansyl', handling OAuth callback")
                                    Task {
                                        await handleOAuthCallback(url: url)
                                    }
                                }
                            } else {
                                print("⚠️ [kansylApp] URL scheme doesn't match 'kansyl', ignoring")
                            }
                            print("🔗 [kansylApp] ========================================")
                        }
                        .sheet(isPresented: $shouldShowAddSubscription) {
                            if appState.isFullyLoaded {
                                AddSubscriptionView(
                                    subscriptionStore: appState.subscriptionStore,
                                    prefilledServiceName: serviceToAdd
                                )
                                .environment(\.managedObjectContext, appState.viewContext)
                            }
                        }
                        .overlay(
                            Group {
                                if showSuccessToast {
                                    ToastView(message: toastMessage, isError: false)
                                } else if showErrorToast {
                                    ToastView(message: toastMessage, isError: true)
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                showErrorToast = false
                                            }
                                        }
                                }
                            }
                        )
                }
            }
            .onAppear {
                // Initialize app state asynchronously
                Task {
                    await appState.initialize()
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didReceiveMemoryWarningNotification
            )) { _ in
                // Handle memory warning
                appState.handleMemoryWarning()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShareImportErrorLimitReached"))) { note in
                if let msg = note.userInfo?["message"] as? String {
                    toastMessage = msg
                } else {
                    toastMessage = "Import blocked: Free limit reached (5). Sign in or upgrade to Premium."
                }
                showErrorToast = true
                HapticManager.shared.playError()
            }

            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Import any items shared via the Share Extension when app returns to foreground
                print("📱 [kansylApp] App entering foreground - checking for pending share extension items")
                Task {
                    // Ensure user has a userID if not set
                    if SubscriptionStore.currentUserID == nil || SubscriptionStore.currentUserID?.isEmpty == true {
                        if !appState.authManager.isAuthenticated {
                            print("⚠️ [kansylApp] No user ID on foreground, auto-enabling anonymous mode")
                            await MainActor.run {
                                UserStateManager.shared.enableAnonymousMode()
                            }
                        }
                    }
                    await appState.checkPendingSubscriptions()
                }
            }
            // Remove the didBecomeActive listener to prevent duplicate imports
            // We already check on:
            // 1. URL scheme (kansyl://import)
            // 2. App entering foreground
            // 3. App fully loaded
            // That's enough!
            .onChange(of: appState.isFullyLoaded) { loaded in
                if loaded {
                    // Check ONCE when app finishes loading
                    print("✅ [kansylApp] App fully loaded - single check for pending share extension items")
                    Task {
                        // Add a small delay to prevent race conditions
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await appState.checkPendingSubscriptions()
                    }
                }
            }
        }
    }

    // MARK: - OAuth Handler
    private func handleOAuthCallback(url: URL) async {
        print("🔄 [kansylApp] handleOAuthCallback called with URL: \(url)")
        do {
            print("📡 [kansylApp] Calling authManager.handleOAuthCallback...")
            try await appState.authManager.handleOAuthCallback(url: url)
            print("✅ [kansylApp] OAuth callback handled successfully")
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } catch {
            print("❌ [kansylApp] OAuth callback failed: \(error.localizedDescription)")
            print("❌ [kansylApp] Error type: \(type(of: error))")
            await MainActor.run {
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }

    // MARK: - User Activity Handlers
    private func handleAddTrialActivity(_ userActivity: NSUserActivity) {
        let activityID = userActivity.persistentIdentifier ?? UUID().uuidString
        guard lastProcessedActivityID != activityID else { return }
        lastProcessedActivityID = activityID

        // Check subscription limit against current count (applies to all non-premium users)
        let currentCount_add = appState.subscriptionStore.allSubscriptions.count
        if !PremiumManager.shared.canAddMoreSubscriptions(currentCount: currentCount_add) {
            toastMessage = "Subscription limit reached (\(PremiumManager.freeSubscriptionLimit) max). Sign in or upgrade to Premium."
            showErrorToast = true
            return
        }

        var serviceName: String?

        if let userInfo = userActivity.userInfo,
           let name = userInfo["serviceName"] as? String {
            serviceName = name
        } else if let title = userActivity.title {
            let patterns = [
                "Add (.+) Trial",
                "Add (.+) trial",
                "add (.+) trial",
                "Add (.+)"
            ]

            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)),
                   let range = Range(match.range(at: 1), in: title) {
                    serviceName = String(title[range])
                    break
                }
            }
        }

        let finalServiceName = serviceName ?? "Netflix"
        serviceToAdd = finalServiceName
        shouldShowAddSubscription = true
    }

    private func handleQuickAddTrialActivity(_ userActivity: NSUserActivity) {
        let activityID = userActivity.persistentIdentifier ?? UUID().uuidString
        guard lastProcessedActivityID != activityID else { return }
        guard !isProcessingShortcut else { return }

        guard let userInfo = userActivity.userInfo,
              let serviceName = userInfo["serviceName"] as? String else {
            return
        }

        isProcessingShortcut = true
        lastProcessedActivityID = activityID

        // Only process if app is fully loaded
        guard appState.isFullyLoaded else {
            isProcessingShortcut = false
            return
        }

        // Check subscription limit against current count (applies to all non-premium users)
        let currentCount_quick = appState.subscriptionStore.allSubscriptions.count
        if !PremiumManager.shared.canAddMoreSubscriptions(currentCount: currentCount_quick) {
            DispatchQueue.main.async { [self] in
                toastMessage = "Cannot add subscription: Limit reached (\(PremiumManager.freeSubscriptionLimit) max). Sign in or upgrade to Premium."
                showErrorToast = true
                isProcessingShortcut = false

                // Provide haptic feedback for error
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
            return
        }

        let fiveSecondsAgo = Date().addingTimeInterval(-5)
        let recentSubscriptions = appState.subscriptionStore.allSubscriptions.filter { subscription in
            subscription.name == serviceName &&
            (subscription.startDate ?? Date.distantPast) >= fiveSecondsAgo
        }

        if !recentSubscriptions.isEmpty {
            isProcessingShortcut = false
            return
        }

        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        if appState.subscriptionStore.addSubscription(
            name: serviceName,
            startDate: Date(),
            endDate: endDate,
            monthlyPrice: getDefaultPriceForService(serviceName),
            serviceLogo: getServiceLogo(serviceName),
            notes: nil,
            addToCalendar: false
        ) != nil {
            DispatchQueue.main.async { [self] in
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                toastMessage = "\(serviceName) trial added successfully!"
                showSuccessToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccessToast = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isProcessingShortcut = false
                }

                NotificationCenter.default.post(
                    name: NSNotification.Name("SubscriptionAddedViaShortcut"),
                    object: nil,
                    userInfo: ["serviceName": serviceName]
                )
            }
        } else {
            // Add failed (likely due to free limit enforced at data layer)
            DispatchQueue.main.async { [self] in
                toastMessage = "Cannot add subscription: Limit reached (\(PremiumManager.freeSubscriptionLimit) max). Sign in or upgrade to Premium."
                showErrorToast = true
                isProcessingShortcut = false

                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }

    private func handleCheckTrialsActivity(_ userActivity: NSUserActivity) {
        guard appState.isFullyLoaded else { return }

        // Get all active subscriptions for current user
        let activeSubscriptions = appState.subscriptionStore.allSubscriptions.filter {
            $0.status == SubscriptionStatus.active.rawValue
        }

        // Filter for trials ending soon (within 7 days)
        let endingSoon = activeSubscriptions.filter { subscription in
            guard let endDate = subscription.endDate else { return false }
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return daysRemaining >= 0 && daysRemaining <= 7
        }

        // Create meaningful message based on subscription status
        let message: String
        let isWarning: Bool

        if activeSubscriptions.isEmpty {
            message = "You have no active subscriptions"
            isWarning = false
        } else if !endingSoon.isEmpty {
            let names = endingSoon.prefix(3).compactMap { $0.name }.joined(separator: ", ")
            if endingSoon.count == 1 {
                message = "\(names) ends soon!"
            } else if endingSoon.count <= 3 {
                message = "\(endingSoon.count) subscriptions ending soon: \(names)"
            } else {
                message = "\(endingSoon.count) subscriptions ending soon"
            }
            isWarning = true
        } else {
            message = "All \(activeSubscriptions.count) subscription\(activeSubscriptions.count == 1 ? " is" : "s are") active"
            isWarning = false
        }

        // Display toast message to user
        DispatchQueue.main.async { [self] in
            toastMessage = message
            if isWarning {
                showErrorToast = true
                HapticManager.shared.playWarning()
            } else {
                showSuccessToast = true
                HapticManager.shared.playSuccess()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showSuccessToast = false
                showErrorToast = false
            }
        }

        print("📊 [Siri Shortcut] Check trials: \(message)")
    }

    private func getDefaultPriceForService(_ serviceName: String) -> Double {
        switch serviceName.lowercased() {
        case "netflix": return 15.99
        case "spotify": return 9.99
        case "disney+", "disney plus": return 7.99
        case "amazon prime": return 14.99
        case "apple tv+", "apple tv plus": return 6.99
        case "hulu": return 7.99
        default: return 9.99
        }
    }

    private func getServiceLogo(_ serviceName: String) -> String {
        switch serviceName.lowercased() {
        case "netflix": return "netflix-logo"
        case "spotify": return "spotify-logo"
        case "disney+", "disney plus": return "sparkles"
        case "amazon prime": return "cart.fill"
        case "apple tv+", "apple tv plus": return "appletv-logo"
        case "apple music": return "apple-logo"
        case "hulu": return "h.square.fill"
        default: return "app.badge"
        }
    }
}

// MARK: - App State Manager
@MainActor
class AppState: ObservableObject {
    @Published var isInitializing = true
    @Published var isFullyLoaded = false
    @Published var initializationError: String?

    // Lazy-loaded services
    lazy var authManager = SupabaseAuthManager.shared
    lazy var persistenceController = PersistenceController.shared
    lazy var notificationManager = NotificationManager.shared
    lazy var appPreferences = AppPreferences.shared
    lazy var themeManager = ThemeManager.shared
    lazy var subscriptionStore = SubscriptionStore.shared

    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    func initialize() async {
        AppLogger.debug("Starting async initialization...", emoji: "🚀", category: "AppState")

        // Reset error state
        initializationError = nil
        isInitializing = true

        do {
            // Initialize services in background with error handling
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Initialize Core Data (critical)
                group.addTask { [weak self] in
                    await self?.initializePersistence()
                }

                // Initialize Auth (can be deferred)
                group.addTask { [weak self] in
                    await self?.initializeAuth()
                }

                // Initialize other services (non-critical)
                group.addTask { [weak self] in
                    await self?.initializeServices()
                }

                // Wait for all initialization to complete
                try await group.waitForAll()
            }

            // Setup notifications after services are ready
            await setupNotifications()

            // Check for pending subscriptions from Share Extension
            await checkPendingSubscriptions()

            // Mark as fully loaded
            await MainActor.run {
                self.isFullyLoaded = true
                self.isInitializing = false
                AppLogger.success("Initialization complete", category: "AppState")
            }

        } catch {
            await MainActor.run {
                self.initializationError = error.localizedDescription
                self.isInitializing = false
                AppLogger.error("Initialization failed: \(error)", category: "AppState")
            }
        }
    }

    // Exposed method to import items from the Share Extension on demand (e.g., app foreground)
    func importPendingFromShareExtension() async {
        await checkPendingSubscriptions()
    }

    private func initializePersistence() async {
        AppLogger.debug("Initializing Core Data...", emoji: "📦", category: "AppState")
        // Core Data initialization is already lazy in PersistenceController
        _ = persistenceController.container

        #if DEBUG
        // Verify Core Data integrity (DEBUG ONLY - moved to background)
        Task.detached(priority: .background) {
            let integrity = CoreDataReset.shared.verifyDataIntegrity()
            if !integrity.isValid {
                AppLogger.warning("Core Data integrity issues detected", category: "AppState")
                for issue in integrity.issues {
                    AppLogger.log("  - \(issue)", category: "AppState")
                }
            }

            // Debug: Print all existing subscriptions (DEBUG ONLY - moved to background)
            CoreDataReset.shared.debugPrintAllSubscriptions()
        }
        #endif

        AppLogger.success("Core Data initialized", category: "AppState")
    }

    private func initializeAuth() async {
        AppLogger.debug("Initializing Auth...", emoji: "🔐", category: "AppState")
        // Auth manager initialization is already safe
        _ = authManager
        // Check session without blocking
        await authManager.checkExistingSession()
        AppLogger.success("Auth initialized", category: "AppState")
    }

    private func initializeServices() async {
        AppLogger.debug("Initializing services...", emoji: "⚙️", category: "AppState")

        // Initialize services that don't block
        _ = appPreferences
        _ = themeManager

        // Initialize subscription store with current user
        let userID = authManager.currentUser?.id.uuidString
        AppLogger.log("Setting subscription store userID to: \(userID ?? "nil")", category: "AppState")
        subscriptionStore.updateCurrentUser(userID: userID)

        // Defer heavy operations
        Task.detached {
            // These can happen in background after app loads
            await self.subscriptionStore.costEngine.refreshMetrics()
        }

        AppLogger.success("Services initialized", category: "AppState")
    }

    private func setupNotifications() async {
        AppLogger.debug("Setting up notifications...", emoji: "🔔", category: "AppState")
        notificationManager.setupNotificationCategories()
        notificationManager.requestNotificationPermission()
        AppLogger.success("Notifications configured", category: "AppState")
    }

    // Track if we're already processing to prevent duplicates
    private var isProcessingPendingSubscriptions = false

    // MARK: - Pending Subscriptions from Share Extension
    func checkPendingSubscriptions() async {
        // Prevent multiple simultaneous processing
        guard !isProcessingPendingSubscriptions else {
            print("⚠️ [AppState] Already processing pending subscriptions, skipping")
            return
        }

        isProcessingPendingSubscriptions = true
        defer { isProcessingPendingSubscriptions = false }

        print("🔵 [AppState] checkPendingSubscriptions() called at \(Date())")

        // Try the new storage first
        let pending = PendingSubscriptionStorage.shared.getPendingSubscriptions()
        print("🔵 [AppState] PendingSubscriptionStorage: \(pending.count) items")

        // Don't check old storage to avoid duplicates - just use the new one
        // The Share Extension already saves to both as backup

        guard !pending.isEmpty else {
            print("⚠️ [AppState] No pending subscriptions found")
            return
        }

        print("🎆 [AppState] Found \(pending.count) pending subscription(s) to process!")

        // Ensure we have a userID before attempting to create subscriptions
        guard let currentUserID = SubscriptionStore.currentUserID, !currentUserID.isEmpty else {
            print("⚠️ [AppState] No userID set. Deferring import and leaving pending items intact.")
            print("ℹ️ [AppState] Tip: Enable Anonymous Mode or sign in before importing.")
            return
        }
        print("✅ [AppState] currentUserID available: \(currentUserID)")

        AppLogger.log("📥 Found \(pending.count) pending subscription(s) from Share Extension", category: "AppState")
        print("📥 [AppState] Processing \(pending.count) pending subscription(s)...")

        await MainActor.run {
            var createdIndices: [Int] = []
            for (index, dataDict) in pending.enumerated() {
                if createSubscriptionFromSharedData(dataDict) {
                    createdIndices.append(index)
                }
            }

            // Remove only successfully created items
            if !createdIndices.isEmpty {
                if createdIndices.count == pending.count {
                    print("🗑️ [AppState] All pending items processed. Clearing all pending subscriptions.")
                    PendingSubscriptionStorage.shared.clearPendingSubscriptions()
                    SharedSubscriptionManager.shared.clearPendingSubscriptions()
                } else {
                    print("🗑️ [AppState] Processed \(createdIndices.count)/\(pending.count). Partial clear not implemented yet.")
                    // For now, clear all if any were successful
                    PendingSubscriptionStorage.shared.clearPendingSubscriptions()
                    SharedSubscriptionManager.shared.clearPendingSubscriptions()
                }
            } else {
                print("⚠️ [AppState] No items were created. Leaving pending items for later.")
            }
        }
    }

    @discardableResult
    private func createSubscriptionFromSharedData(_ dataDict: [String: Any]) -> Bool {
        print("🔄 [AppState] createSubscriptionFromSharedData called")
        print("   Data keys: \(dataDict.keys.sorted().joined(separator: ", "))")

        // Convert dictionary back to subscription data
        let serviceName = dataDict["serviceName"] as? String ?? "Unknown Service"
        let trialDuration = dataDict["trialDuration"] as? Int
        let price = dataDict["price"] as? Double
        let currency = dataDict["currency"] as? String ?? "USD"
        let confirmationNumber = dataDict["confirmationNumber"] as? String

        print("   Service: \(serviceName)")
        if let price = price {
            print("   Price: \(price)")
        } else {
            print("   Price: nil")
        }
        if let duration = trialDuration {
            print("   Duration: \(duration) days")
        } else {
            print("   Duration: nil days")
        }

        // Calculate dates first
        var startDate = Date()
        if let timestamp = dataDict["startDate"] as? TimeInterval {
            startDate = Date(timeIntervalSince1970: timestamp)
        }

        var endDate = Date()
        if let timestamp = dataDict["endDate"] as? TimeInterval {
            endDate = Date(timeIntervalSince1970: timestamp)
        } else if let duration = trialDuration {
            endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
        } else {
            // Default to 30 days if no end date or duration provided
            endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate) ?? Date()
        }

        print("   Start date: \(startDate)")
        print("   End date: \(endDate)")

        // Check if we already have this EXACT subscription (prevent duplicates)
        // Match on service name, price, AND date range to be more precise
        print("🔍 [AppState] Checking for duplicates among \(subscriptionStore.allSubscriptions.count) existing subscriptions")

        let existingSubscriptions = subscriptionStore.allSubscriptions.filter { subscription in
            // Check basic match
            guard subscription.name == serviceName else { return false }

            print("   Found matching name: \(subscription.name ?? "Unknown")")
            print("     Existing dates: \(subscription.startDate?.description ?? "nil") to \(subscription.endDate?.description ?? "nil")")
            print("     New dates: \(startDate) to \(endDate)")
            print("     Existing price: \(subscription.monthlyPrice), New price: \(price ?? 0)")

            // Check price if available (allow small floating point differences)
            if let subscriptionPrice = price {
                guard abs(subscription.monthlyPrice - subscriptionPrice) < 0.01 else {
                    print("     ❌ Price mismatch")
                    return false
                }
            }

            // Check date overlap - if the dates are very similar (within 1 day), consider it a duplicate
            guard let subStartDate = subscription.startDate, let subEndDate = subscription.endDate else {
                print("     ❌ Subscription has missing dates")
                return false
            }

            let startDateDiff = abs(subStartDate.timeIntervalSince(startDate))
            let endDateDiff = abs(subEndDate.timeIntervalSince(endDate))

            print("     Start date diff: \(startDateDiff) seconds")
            print("     End date diff: \(endDateDiff) seconds")

            // If dates are within 24 hours of each other, likely a duplicate
            let isDuplicate = startDateDiff < 86400 && endDateDiff < 86400
            print("     Is duplicate? \(isDuplicate)")

            return isDuplicate
        }

        if !existingSubscriptions.isEmpty {
            print("⚠️ [AppState] Exact duplicate subscription found for \(serviceName) with same dates, skipping")

            // Still notify the UI, but indicate it's a duplicate
            print("📢 [AppState] Posting SubscriptionAddedFromEmail notification for duplicate: \(serviceName)")
            NotificationCenter.default.post(
                name: NSNotification.Name("SubscriptionAddedFromEmail"),
                object: nil,
                userInfo: [
                    "serviceName": serviceName,
                    "isDuplicate": true,
                    "id": existingSubscriptions.first?.id?.uuidString ?? ""
                ]
            )
            print("✅ [AppState] Duplicate notification posted successfully")

            return true // Return true because it's technically "successful" - we have the subscription
        }

        print("✅ [AppState] No duplicate found, proceeding to create new subscription")

        // Determine billing cycle string from trial duration
        let billingCycleString: String
        if let duration = trialDuration {
            switch duration {
            case 7:
                billingCycleString = "weekly"
            case 14:
                billingCycleString = "biweekly"
            case 30, 31:
                billingCycleString = "monthly"
            case 90:
                billingCycleString = "quarterly"
            case 180:
                billingCycleString = "semiannually"
            case 365, 366:
                billingCycleString = "yearly"
            default:
                billingCycleString = "monthly"
            }
        } else {
            billingCycleString = "monthly"
        }

        // Create notes with confirmation number and original currency if available
        var notes: String?
        if let confirmation = confirmationNumber {
            notes = "Confirmation: \(confirmation)"
            if currency != UserSpecificPreferences.shared.currencyCode {
                notes = (notes ?? "") + "\nOriginal currency: \(currency)"
            }
        } else if currency != UserSpecificPreferences.shared.currencyCode {
            notes = "Original currency: \(currency)"
        }

        // Add subscription to store
        let subscription = subscriptionStore.addSubscription(
            name: serviceName,
            startDate: startDate,
            endDate: endDate,
            monthlyPrice: price ?? 0.0,
            serviceLogo: getServiceLogo(serviceName),
            notes: notes,
            addToCalendar: false,
            billingCycle: billingCycleString,
            originalCurrency: currency != UserSpecificPreferences.shared.currencyCode ? currency : nil,
            originalAmount: currency != UserSpecificPreferences.shared.currencyCode ? (price ?? 0.0) : nil
        )

        if let subscription = subscription {
            AppLogger.success("✅ Created subscription from email: \(serviceName)", category: "AppState")

            // Show success feedback
            HapticManager.shared.playSuccess()

            // Post notification that subscription was added
            print("📢 [AppState] Posting SubscriptionAddedFromEmail notification for: \(serviceName)")
            NotificationCenter.default.post(
                name: NSNotification.Name("SubscriptionAddedFromEmail"),
                object: nil,
                userInfo: [
                    "serviceName": serviceName,
                    "isDuplicate": false,
                    "id": subscription.id?.uuidString ?? ""
                ]
            )
            print("✅ [AppState] Notification posted successfully")
            return true
        } else {
            AppLogger.error("Failed to create subscription from email: \(serviceName)", category: "AppState")
            // Notify UI that import was blocked (likely due to free limit)
            NotificationCenter.default.post(
                name: Notification.Name("ShareImportErrorLimitReached"),
                object: nil,
                userInfo: [
                    "message": "Import blocked: Free limit reached (5). Sign in or upgrade to Premium."
                ]
            )
            return false
        }
    }

    // MARK: - Helper Methods
    private func getServiceLogo(_ serviceName: String) -> String {
        switch serviceName.lowercased() {
        case "netflix": return "netflix-logo"
        case "spotify": return "spotify-logo"
        case "disney+", "disney plus": return "sparkles"
        case "amazon prime": return "cart.fill"
        case "apple tv+", "apple tv plus": return "appletv-logo"
        case "apple music": return "apple-logo"
        case "hulu": return "h.square.fill"
        default: return "app.badge"
        }
    }

    func handleMemoryWarning() {
        AppLogger.warning("Memory warning received - clearing caches", category: "AppState")

        // Clear any in-memory caches
        subscriptionStore.clearCaches()

        // Clear image caches if any (future implementation)
        // ImageCache.shared.clearMemoryCache()

        // Force Core Data to clear cached objects
        viewContext.refreshAllObjects()

        AppLogger.success("Caches cleared", category: "AppState")
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Design.Colors.background,
                    Design.Colors.background.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                BrandSpinner(size: 88)

                Text("Kansyl")
                    .font(Design.Typography.title(.bold))
                    .foregroundStyle(Design.Colors.Gradients.shinyText)

                Text("Preparing your experience")
                    .font(Design.Typography.subheadline())
                    .foregroundColor(Design.Colors.textSecondary)
            }
            .padding()
        }
    }
}

// MARK: - Brand Spinner
struct BrandSpinner: View {
    var size: CGFloat = 88
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Design.Colors.border.opacity(0.4), lineWidth: 8)

            Circle()
                .trim(from: 0.15, to: 1.0)
                .stroke(
                    Design.Colors.Gradients.brand,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: spin)

            Circle()
                .fill(Design.Colors.primary.opacity(0.08))
                .frame(width: size - 36, height: size - 36)
                .blur(radius: 10)
        }
        .frame(width: size, height: size)
        .onAppear { spin = true }
    }
}

// MARK: - Error View
struct InitializationErrorView: View {
    let error: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Initialization Error")
                .font(.title)
                .fontWeight(.bold)

            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))

                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isError ? Color.red : Color.green)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: true)
        .zIndex(1000)
    }
}
