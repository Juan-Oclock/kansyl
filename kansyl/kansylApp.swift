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
                            if url.scheme == "kansyl" {
                                Task {
                                    await handleOAuthCallback(url: url)
                                }
                            }
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
                                    ToastView(message: toastMessage)
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
        }
    }
    
    // MARK: - OAuth Handler
    private func handleOAuthCallback(url: URL) async {
        do {
            try await appState.authManager.handleOAuthCallback(url: url)
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } catch {
            print("OAuth callback failed: \(error.localizedDescription)")
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
            isProcessingShortcut = false
        }
    }
    
    private func handleCheckTrialsActivity(_ userActivity: NSUserActivity) {
        guard appState.isFullyLoaded else { return }
        
        let request = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.active.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        
        do {
            let subscriptions = try appState.viewContext.fetch(request)
            let endingSoon = subscriptions.filter { subscription in
                guard let endDate = subscription.endDate else { return false }
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                return daysRemaining <= 7
            }
            
            if !endingSoon.isEmpty {
                print("You have \(endingSoon.count) subscription(s) ending soon")
            }
        } catch {
            print("Error checking subscriptions: \(error)")
        }
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
        print("🚀 [AppState] Starting async initialization...")
        
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
            
            // Mark as fully loaded
            await MainActor.run {
                self.isFullyLoaded = true
                self.isInitializing = false
                print("✅ [AppState] Initialization complete")
            }
            
        } catch {
            await MainActor.run {
                self.initializationError = error.localizedDescription
                self.isInitializing = false
                print("❌ [AppState] Initialization failed: \(error)")
            }
        }
    }
    
    private func initializePersistence() async {
        print("📦 [AppState] Initializing Core Data...")
        // Core Data initialization is already lazy in PersistenceController
        _ = persistenceController.container
        print("✅ [AppState] Core Data initialized")
    }
    
    private func initializeAuth() async {
        print("🔐 [AppState] Initializing Auth...")
        // Auth manager initialization is already safe
        _ = authManager
        // Check session without blocking
        await authManager.checkExistingSession()
        print("✅ [AppState] Auth initialized")
    }
    
    private func initializeServices() async {
        print("⚙️ [AppState] Initializing services...")
        
        // Initialize services that don't block
        _ = appPreferences
        _ = themeManager
        
        // Initialize subscription store with current user
        subscriptionStore.updateCurrentUser(userID: authManager.currentUser?.id.uuidString)
        
        // Defer heavy operations
        Task.detached {
            // These can happen in background after app loads
            await self.subscriptionStore.costEngine.refreshMetrics()
        }
        
        print("✅ [AppState] Services initialized")
    }
    
    private func setupNotifications() async {
        print("🔔 [AppState] Setting up notifications...")
        notificationManager.setupNotificationCategories()
        notificationManager.requestNotificationPermission()
        print("✅ [AppState] Notifications configured")
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.badge")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Text("Kansyl")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(1.5)
                .padding(.top)
        }
        .onAppear {
            isAnimating = true
        }
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
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
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