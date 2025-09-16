//
//  NotificationExtensions.swift
//  kansyl
//
//  Created to handle custom notifications for subscription events
//

import Foundation

extension Notification.Name {
    /// Posted when a subscription is successfully added from any source in the app
    static let subscriptionAdded = Notification.Name("subscriptionAdded")
}