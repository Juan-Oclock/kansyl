//
//  kansylApp.swift
//  kansyl
//
//  Created by Juan Oclock on 9/12/25.
//

import SwiftUI

@main
struct kansylApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    let notificationManager = NotificationManager.shared
    let appPreferences = AppPreferences.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var supabaseAuth = SupabaseAuthManager.shared
    @State private var shouldShowAddSubscription = false
    @State private var serviceToAdd: String?
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    @State private var lastProcessedActivityID: String? = nil
    @State private var isProcessingShortcut = false
    
    var body: some Scene {
        WindowGroup {
            AuthenticationWrapperView()
                .environmentObject(supabaseAuth)
                .onAppear {
                    notificationManager.setupNotificationCategories()
                    notificationManager.requestNotificationPermission()
                    
                    // Initialize cost engine with initial data
                    SubscriptionStore.shared.costEngine.refreshMetrics()
                }
                .onContinueUserActivity("com.kansyl.addTrial") { userActivity in
                    // Debounce to prevent duplicate calls
                    DispatchQueue.main.async {
                        handleAddTrialActivity(userActivity)
                    }
                }
                .onContinueUserActivity("com.kansyl.quickAddTrial") { userActivity in
                    // Debounce to prevent duplicate calls  
                    DispatchQueue.main.async {
                        handleQuickAddTrialActivity(userActivity)
                    }
                }
                .onContinueUserActivity("com.kansyl.checkTrials") { userActivity in
                    DispatchQueue.main.async {
                        handleCheckTrialsActivity(userActivity)
                    }
                }
                .sheet(isPresented: $shouldShowAddSubscription) {
                    AddSubscriptionView(
                        subscriptionStore: SubscriptionStore.shared,
                        prefilledServiceName: serviceToAdd
                    )
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
                .overlay(
                    Group {
                        if showSuccessToast {
                            VStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                    
                                    Text(toastMessage)
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
                            .zIndex(1000)
                        }
                    }
                    .animation(.spring(), value: showSuccessToast)
                )
        }
    }
    
    // MARK: - User Activity Handlers
    
    private func handleAddTrialActivity(_ userActivity: NSUserActivity) {
        // Prevent duplicate processing
        let activityID = userActivity.persistentIdentifier ?? UUID().uuidString
        guard lastProcessedActivityID != activityID else {
            // Debug: // Debug: print("Add trial activity already processed: \(activityID)")
            return
        }
        lastProcessedActivityID = activityID
        
        // Try to extract service name from userInfo first
        var serviceName: String?
        
        if let userInfo = userActivity.userInfo,
           let name = userInfo["serviceName"] as? String {
            serviceName = name
        } else if let title = userActivity.title {
            // Try to extract service name from the activity title
            // Pattern: "Add [ServiceName] Trial" or just "Add [ServiceName]"
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
        
        // If we still don't have a service name, check if Siri passed it via the interaction
        if serviceName == nil,
           let interaction = userActivity.interaction,
           let intentResponse = interaction.intentResponse,
           let responseUserActivity = intentResponse.userActivity,
           let responseUserInfo = responseUserActivity.userInfo,
           let name = responseUserInfo["serviceName"] as? String {
            serviceName = name
        }
        
        // Default to a generic prompt if no service name found
        let finalServiceName = serviceName ?? "Netflix" // Default to Netflix if nothing specified
        
        // For adding a trial, show the AddSubscriptionView with prefilled service name
        serviceToAdd = finalServiceName
        shouldShowAddSubscription = true
    }
    
    private func handleQuickAddTrialActivity(_ userActivity: NSUserActivity) {
        // Prevent duplicate processing
        let activityID = userActivity.persistentIdentifier ?? UUID().uuidString
        guard lastProcessedActivityID != activityID else {
            // Debug: // Debug: print("Activity already processed: \(activityID)")
            return
        }
        
        // Prevent concurrent processing
        guard !isProcessingShortcut else {
            // Debug: // Debug: print("Already processing another shortcut")
            return
        }
        
        guard let userInfo = userActivity.userInfo,
              let serviceName = userInfo["serviceName"] as? String else {
            return
        }
        
        // Mark as processing
        isProcessingShortcut = true
        lastProcessedActivityID = activityID
        
        // Check for existing subscription with same name added recently (within last 5 seconds)
        let fiveSecondsAgo = Date().addingTimeInterval(-5)
        let recentSubscriptions = SubscriptionStore.shared.allSubscriptions.filter { subscription in
            subscription.name == serviceName && 
            (subscription.startDate ?? Date.distantPast) >= fiveSecondsAgo
        }
        
        if !recentSubscriptions.isEmpty {
            // Debug: // Debug: print("Duplicate subscription detected for \(serviceName), skipping")
            isProcessingShortcut = false
            return
        }
        
        // For quick add, create via the shared SubscriptionStore so userID and refresh logic are handled
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        if SubscriptionStore.shared.addSubscription(
            name: serviceName,
            startDate: Date(),
            endDate: endDate,
            monthlyPrice: getDefaultPriceForService(serviceName),
            serviceLogo: getServiceLogo(serviceName),
            notes: nil,
            addToCalendar: false
        ) != nil {
            // Show success feedback
            DispatchQueue.main.async { [self] in
                // Trigger haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Show toast notification
                toastMessage = "\(serviceName) trial added successfully!"
                showSuccessToast = true
                
                // Hide toast after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccessToast = false
                }
                
                // Reset processing flag after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isProcessingShortcut = false
                }
                
                // Post a notification that the subscription was added
                NotificationCenter.default.post(
                    name: NSNotification.Name("SubscriptionAddedViaShortcut"),
                    object: nil,
                    userInfo: ["serviceName": serviceName]
                )
            }
        } else {
            // Debug: // Debug: print("Error: Failed to quick-add subscription via SubscriptionStore (missing userID?)")
            isProcessingShortcut = false
        }
    }
    
    private func handleCheckTrialsActivity(_ userActivity: NSUserActivity) {
        // This would typically navigate to a view showing trial status
        // For now, we'll just print the status
        let context = persistenceController.container.viewContext
        let request = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.active.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        
        do {
            let subscriptions = try context.fetch(request)
            let endingSoon = subscriptions.filter { subscription in
                guard let endDate = subscription.endDate else { return false }
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                return daysRemaining <= 7
            }
            
            if !endingSoon.isEmpty {
                // Could show an alert or navigate to a specific view
                // Debug: // Debug: print("You have \(endingSoon.count) subscription(s) ending soon")
            }
        } catch {
            // Debug: // Debug: print("Error checking subscriptions: \(error)")
        }
    }
    
    private func getDefaultPriceForService(_ serviceName: String) -> Double {
        // Return default prices for common services
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
        // Return appropriate logo for service
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
