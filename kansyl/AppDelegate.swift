//
//  AppDelegate.swift
//  kansyl
//
//  Created on 9/12/25.
//

import UIKit
import UserNotifications
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Register for notification actions when subscriptions are updated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionActionNotification(_:)),
            name: Notification.Name("SubscriptionActionFromNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSubscriptionNotification(_:)),
            name: Notification.Name("OpenSubscriptionFromNotification"),
            object: nil
        )
        
        return true
    }
    
    @objc private func handleSubscriptionActionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let subscriptionId = userInfo["subscriptionId"] as? String,
              let actionRaw = userInfo["action"] as? String,
              let action = NotificationManager.SubscriptionAction(rawValue: actionRaw) else {
            return
        }
        
        // Handle the subscription action
        DispatchQueue.main.async {
            let context = PersistenceController.shared.container.viewContext
            let subscriptionStore = SubscriptionStore(context: context)
            
            // Find the subscription
            let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", subscriptionId)
            
            do {
                if let subscription = try context.fetch(request).first {
                    switch action {
                    case .cancel:
                        subscriptionStore.updateSubscriptionStatus(subscription, status: .canceled)
                    case .keep:
                        subscriptionStore.updateSubscriptionStatus(subscription, status: .kept)
                    }
                }
            } catch {
                // Debug: print("Error handling subscription action: \(error)")
            }
        }
    }
    
    @objc private func handleOpenSubscriptionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let subscriptionId = userInfo["subscriptionId"] as? String else {
            return
        }
        
        // Post a notification to open the subscription detail view
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToSubscription"),
            object: nil,
            userInfo: ["subscriptionId": subscriptionId]
        )
    }
}
