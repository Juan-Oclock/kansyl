//
//  BulkSubscriptionManagementView.swift
//  kansyl
//
//  Created on 9/13/25.
//

import SwiftUI
import CoreData

struct BulkSubscriptionManagementView: View {
    let subscriptionStore: SubscriptionStore
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Bulk Subscription Management")
            }
            .navigationTitle("Manage Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}