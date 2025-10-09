//
//  ShareExtensionHandler.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import SwiftUI

class ShareExtensionHandler: ObservableObject {
    
    @Published var parsedData: EmailParser.ParsedTrialData?
    @Published var isProcessing = false
    @Published var error: Error?
    
    private let emailParser = EmailParser()
    
    // MARK: - Process Shared Content
    func processSharedContent(_ items: [NSExtensionItem]) {
        isProcessing = true
        error = nil
        
        for item in items {
            guard let attachments = item.attachments else { continue }
            
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    handleText(provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    handleURL(provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.html.identifier) {
                    handleHTML(provider)
                }
            }
        }
    }
    
    // MARK: - Handle Text Content
    private func handleText(_ provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                if let text = item as? String {
                    self?.parseText(text)
                } else if let error = error {
                    self?.error = error
                }
                self?.isProcessing = false
            }
        }
    }
    
    // MARK: - Handle URL Content
    private func handleURL(_ provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                if let url = item as? URL {
                    self?.parseURL(url)
                } else if let error = error {
                    self?.error = error
                }
                self?.isProcessing = false
            }
        }
    }
    
    // MARK: - Handle HTML Content
    private func handleHTML(_ provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.html.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                if let html = item as? String {
                    // Strip HTML tags and parse as text
                    let text = self?.stripHTML(html) ?? ""
                    self?.parseText(text)
                } else if let error = error {
                    self?.error = error
                }
                self?.isProcessing = false
            }
        }
    }
    
    // MARK: - Parse Methods
    private func parseText(_ text: String) {
        parsedData = emailParser.parseEmail(text)
        
        // If parsing failed, try to extract basic info
        if parsedData?.isValid != true {
            parsedData = extractBasicInfo(from: text)
        }
    }
    
    private func parseURL(_ url: URL) {
        // First try to parse from URL
        if let data = emailParser.parseFromURL(url) {
            parsedData = data
            return
        }
        
        // If URL parsing failed, try to fetch content
        fetchContent(from: url)
    }
    
    // MARK: - Helper Methods
    private func stripHTML(_ html: String) -> String {
        let pattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: html.utf16.count)
        let text = regex?.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "") ?? html
        return text
    }
    
    private func extractBasicInfo(from text: String) -> EmailParser.ParsedTrialData {
        var data = EmailParser.ParsedTrialData()
        
        // Try to find any service name
        let services = ["Netflix", "Spotify", "Disney+", "Amazon Prime", "Apple TV+", "Hulu", "HBO Max", "YouTube Premium"]
        for service in services {
            if text.lowercased().contains(service.lowercased()) {
                data.serviceName = service
                break
            }
        }
        
        // Try to find any duration
        if text.contains("7 day") {
            data.trialDuration = 7
        } else if text.contains("14 day") {
            data.trialDuration = 14
        } else if text.contains("30 day") || text.contains("month") {
            data.trialDuration = 30
        }
        
        // Default to today's date
        data.startDate = Date()
        if let duration = data.trialDuration {
            data.endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date())
        }
        
        return data
    }
    
    private func fetchContent(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let content = String(data: data, encoding: .utf8) {
                    self?.parseText(content)
                } else if let error = error {
                    self?.error = error
                }
                self?.isProcessing = false
            }
        }
        task.resume()
    }
    
    // MARK: - Save Subscription
    func saveSubscription(to context: NSManagedObjectContext) -> Bool {
        guard let data = parsedData, data.isValid else { return false }
        
        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = data.serviceName
        subscription.startDate = data.startDate ?? Date()
        subscription.endDate = data.endDate ?? Calendar.current.date(byAdding: .day, value: data.trialDuration ?? 30, to: Date())
        subscription.monthlyPrice = data.price ?? 0
        subscription.status = SubscriptionStatus.active.rawValue
        
        // Add confirmation number as note if available
        if let confirmationNumber = data.confirmationNumber {
            subscription.notes = "Confirmation: \(confirmationNumber)"
        }
        
        // Try to match with service template
        if let serviceName = data.serviceName,
           let template = ServiceTemplateManager.shared.templates.first(where: { $0.name == serviceName }) {
            subscription.serviceLogo = template.logoName
            if subscription.monthlyPrice == 0 {
                subscription.monthlyPrice = template.monthlyPrice
            }
        } else {
            subscription.serviceLogo = "questionmark.circle"
        }
        
        do {
            try context.save()
            
            // Schedule notifications
            NotificationManager.shared.scheduleNotifications(for: subscription)
            
            return true
        } catch {
            self.error = error
            return false
        }
    }
}

// MARK: - Share Extension View
struct ShareExtensionView: View {
    @StateObject private var handler = ShareExtensionHandler()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSaveConfirmation = false
    @State private var editedServiceName = ""
    @State private var editedDuration = 30
    @State private var editedStartDate = Date()
    @State private var showingLimitAlert = false

    let extensionContext: NSExtensionContext?

    var body: some View {
        NavigationView {
            if handler.isProcessing {
                ProgressView("Processing shared content...")
                    .padding()
            } else if let parsedData = handler.parsedData {
                Form {
                    Section(header: Text("Subscription Details")) {
                        HStack {
                            Text("Service")
                            Spacer()
                            TextField("Service Name", text: $editedServiceName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Stepper("\(editedDuration) days", value: $editedDuration, in: 1...365)
                        }
                        
                        DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
                        
                        if let price = parsedData.price {
                            HStack {
                                Text("Price")
                                Spacer()
                                Text(String(format: "$%.2f/month", price))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let confirmationNumber = parsedData.confirmationNumber {
                            HStack {
                                Text("Confirmation")
                                Spacer()
                                Text(confirmationNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: saveSubscription) {
                            Label("Add to Kansyl", systemImage: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: cancel) {
                            Label("Cancel", systemImage: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Add Subscription")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    editedServiceName = parsedData.serviceName ?? ""
                    editedDuration = parsedData.trialDuration ?? 30
                    editedStartDate = parsedData.startDate ?? Date()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Could not parse subscription information")
                        .font(.headline)
                    
                    Text("The shared content doesn't appear to contain subscription confirmation details.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Close", action: cancel)
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("Subscription Added"),
                message: Text("The subscription has been added to Kansyl successfully."),
                dismissButton: .default(Text("OK")) {
                    completeRequest()
                }
            )
        }
        .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Free users can add up to 5 subscriptions. Open Kansyl to sign in or upgrade to Premium to add more.")
        }
    }

    private func saveSubscription() {
        // Update parsed data with edited values
        handler.parsedData?.serviceName = editedServiceName
        handler.parsedData?.trialDuration = editedDuration
        handler.parsedData?.startDate = editedStartDate
        handler.parsedData?.endDate = Calendar.current.date(byAdding: .day, value: editedDuration, to: editedStartDate)

        let context = PersistenceController.shared.container.viewContext

        // Enforce free-tier limit in extension to prevent bypass
        let countRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        countRequest.resultType = .countResultType
        let currentCount = (try? context.count(for: countRequest)) ?? 0
        if currentCount >= 5 { // Free limit
            showingLimitAlert = true
            return
        }

        if handler.saveSubscription(to: context) {
            showingSaveConfirmation = true
        }
    }
    
    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "com.kansyl.share", code: 0, userInfo: nil))
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
