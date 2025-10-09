//
//  IntentHandler.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Intents
import CoreData
import SwiftUI

// MARK: - Intent Handler
// NOTE: This class will be used once the .intentdefinition file is created in Xcode
// The actual intent types (AddTrialIntent, CheckTrialsIntent, QuickAddTrialIntent) 
// will be auto-generated from the .intentdefinition file

/*
class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // Uncomment once intent types are generated from .intentdefinition
        /*
        switch intent {
        case is AddTrialIntent:
            return AddTrialIntentHandler()
        case is CheckTrialsIntent:
            return CheckTrialsIntentHandler()
        case is QuickAddTrialIntent:
            return QuickAddTrialIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
        */
        return self
    }
}
*/

// MARK: - Example Intent Handler Implementation
// These will be activated once the .intentdefinition file is created

/*
class AddTrialIntentHandler: NSObject {
    
    // This method will handle the AddTrialIntent once it's generated
    func handle(intent: INIntent, completion: @escaping (INIntentResponse) -> Void) {
        // Example implementation - will use actual AddTrialIntent type
        guard let serviceName = "" else { // intent.serviceName
            completion(INIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // Get the service template
        let serviceTemplate = ServiceTemplateManager.shared.templates.first { 
            $0.name.lowercased() == serviceName.lowercased() 
        }
        
        let context = PersistenceController.shared.container.viewContext
        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = serviceName
        subscription.startDate = Date()
        subscription.endDate = serviceTemplate?.getDefaultEndDate() ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        subscription.monthlyPrice = serviceTemplate?.monthlyPrice ?? 0
        subscription.serviceLogo = serviceTemplate?.logoName ?? "questionmark.circle"
        subscription.status = SubscriptionStatus.active.rawValue
        
        do {
            try context.save()
            
            // Schedule notifications
            NotificationManager.shared.scheduleNotifications(for: subscription)
            
            // Create success response
            let response = INIntentResponse(code: .success, userActivity: nil)
            // response.serviceName = serviceName
            // response.endDate = subscription.endDate
            
            completion(response)
        } catch {
            completion(INIntentResponse(code: .failure, userActivity: nil))
        }
    }
}
*/

// MARK: - Helper Methods for Intent Handling
class IntentHandlerHelper {
    
    static func checkSubscriptions() -> String {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", SubscriptionStatus.active.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.endDate, ascending: true)]
        
        do {
            let subscriptions = try context.fetch(request)
            if subscriptions.isEmpty {
                return "You have no active subscriptions."
            } else {
                let endingSoon = subscriptions.filter { subscription in
                    guard let endDate = subscription.endDate else { return false }
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                    return daysRemaining <= 7
                }
                
                if !endingSoon.isEmpty {
                    let subscriptionNames = endingSoon.compactMap { $0.name }.joined(separator: ", ")
                    return "You have \(endingSoon.count) subscription(s) ending soon: \(subscriptionNames)"
                } else {
                    return "You have \(subscriptions.count) active subscription(s). None are ending soon."
                }
            }
        } catch {
            return "Error checking subscriptions."
        }
    }
    
    static func addSubscription(serviceName: String) -> Bool {
        let context = PersistenceController.shared.container.viewContext

        // Enforce subscription limit for Siri Shortcuts
        let countRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        countRequest.resultType = .countResultType
        let currentCount = (try? context.count(for: countRequest)) ?? 0
        if !PremiumManager.shared.canAddMoreSubscriptions(currentCount: currentCount) {
            return false
        }

        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = serviceName
        subscription.startDate = Date()
        subscription.endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        subscription.monthlyPrice = 0
        subscription.serviceLogo = "questionmark.circle"
        subscription.status = SubscriptionStatus.active.rawValue

        do {
            try context.save()
            NotificationManager.shared.scheduleNotifications(for: subscription)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Sample Intent Response Codes
// These enums will be replaced by auto-generated types from .intentdefinition

enum IntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case continueInApp = 2  
    case inProgress = 3
    case success = 4
    case failure = 5
    case failureRequiringAppLaunch = 6
}

// MARK: - Documentation
/*
 Once the .intentdefinition file is created in Xcode:
 
 1. The intent types will be auto-generated:
    - AddTrialIntent
    - CheckTrialsIntent  
    - QuickAddTrialIntent
    
 2. The response types will be auto-generated:
    - AddTrialIntentResponse
    - CheckTrialsIntentResponse
    - QuickAddTrialIntentResponse
    
 3. The handling protocols will be auto-generated:
    - AddTrialIntentHandling
    - CheckTrialsIntentHandling
    - QuickAddTrialIntentHandling
    
 4. Uncomment the IntentHandler class and handler implementations above
 
 5. The IntentHandlerHelper methods can be used within the actual handlers
*/
