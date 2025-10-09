//
//  ShareExtensionView.swift
//  KansylShareExtension
//
//  Created on 9/12/25.
//

import SwiftUI

struct ShareExtensionView: View {
    @StateObject private var emailParser = EmailParserDemo()
    @State private var inputItems: [NSExtensionItem]
    @State private var hasSaved = false // Add flag to prevent multiple saves
    @State private var isOpeningApp = false // Show loading state when opening app
    @State private var showCompletionMessage = false // Show completion message
    @State private var showingLimitAlert = false // Free limit reached alert

    let extensionContext: NSExtensionContext?
    let onComplete: () -> Void
    let onCancel: () -> Void

    init(inputItems: [NSExtensionItem], extensionContext: NSExtensionContext?, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._inputItems = State(initialValue: inputItems)
        self.extensionContext = extensionContext
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if showCompletionMessage {
                    completionView
                } else if emailParser.isProcessing {
                    processsingView
                } else if let error = emailParser.error {
                    errorView(error)
                } else if let parsedData = emailParser.parsedData, parsedData.isValid {
                    successView(parsedData)
                } else {
                    waitingView
                }
            }
            .padding()
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                }
                .disabled(isOpeningApp),
                trailing: Group {
                    if isOpeningApp {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Opening...")
                                .font(.footnote)
                        }
                    } else {
                        Button("Done") {
                            saveTrial()
                        }
                        .disabled(emailParser.parsedData?.isValid != true)
                    }
                }
            )
            .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Free users can add up to 5 subscriptions. Open Kansyl to sign in or upgrade to Premium to add more.")
            }
        }
        .onAppear {
            print("🚀 [ShareExtensionView] onAppear called with \(inputItems.count) input items")

            // Debug: Print all input items details
            for (index, item) in inputItems.enumerated() {
                print("[ShareExtensionView] Item \(index):")
                if let userInfo = item.userInfo {
                    for (key, value) in userInfo {
                        print("  - \(key): \(type(of: value))")
                    }
                }
                print("  - Attachments: \(item.attachments?.count ?? 0)")
            }

            // Add a timeout to prevent infinite processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                if emailParser.isProcessing {
                    print("⏰ [ShareExtensionView] Processing timeout - force stopping")
                    emailParser.forceStopProcessing()
                }
            }

            // Process the shared content when view appears
            if !inputItems.isEmpty {
                print("📤 [ShareExtensionView] Processing shared content...")
                emailParser.processSharedContent(inputItems)
            } else {
                print("⚠️ [ShareExtensionView] No input items to process")
                // If no input items, show an error
                emailParser.error = NSError(domain: "ShareExtension", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No content was shared to parse"
                ])
            }
        }
    }

    // MARK: - Views
    private var processsingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)

            Text("Parsing email content...")
                .font(.headline)

            Text("Looking for subscription details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Could not parse content")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                emailParser.processSharedContent(inputItems)
            }
            .buttonStyle(.bordered)
        }
    }

    private func successView(_ data: EmailParser.ParsedTrialData) -> some View {
        VStack(spacing: 20) {
            // Success indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Found Subscription Details!")
                .font(.title2.bold())

            // Parsed data preview
            VStack(alignment: .leading, spacing: 12) {
                row(icon: "app.fill", label: "Service:", value: data.serviceName)

                let durationText = data.trialDuration != nil ? "\(data.trialDuration!) days" : nil
                row(icon: "calendar", label: "Trial Duration:", value: durationText, iconColor: .orange)

                let priceText: String? = {
                    if let p = data.price { return "$\(String(format: "%.2f", p))" }
                    return nil
                }()
                row(icon: "dollarsign.circle", label: "Price:", value: priceText, iconColor: .green)

                let endText: String? = {
                    if let d = data.endDate { return d.formatted(date: .abbreviated, time: .omitted) }
                    return nil
                }()
                row(icon: "bell", label: "Trial Ends:", value: endText, iconColor: .red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Text("Tap 'Done' to add this subscription to Kansyl")
                .font(.caption)

                .multilineTextAlignment(.center)
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("No Subscription Information Found")
                .font(.headline)

            Text("The shared content doesn't appear to contain subscription or trial information that Kansyl can detect.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Try sharing:")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Subscription confirmation emails")
                }
                HStack {
                    Image(systemName: "safari.fill")
                    Text("Service signup or trial pages")
                }
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Text with subscription details")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Subscription Saved!")
                .font(.title2.bold())

            Text("Open Kansyl to view your new subscription")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Visual hint
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text("Switch to Kansyl app")
                        .font(.callout)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Actions
    private func saveTrial() {
        print("🔵 [ShareExtensionView] saveTrial() called at \(Date())")

        // Prevent multiple saves
        guard !hasSaved else {
            print("⚠️ [ShareExtensionView] Already saved, preventing duplicate")
            onComplete()
            return
        }

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        guard let parsedData = emailParser.parsedData else {
            print("❌ [ShareExtensionView] Cannot save - parsedData is nil")
            onComplete() // Still close the extension
            return
        }

        guard parsedData.isValid else {
            print("❌ [ShareExtensionView] Cannot save - parsed data is not valid")

            print("   Service: \(parsedData.serviceName ?? "nil")")
            print("   Duration: \(parsedData.trialDuration?.description ?? "nil")")
            print("   Price: \(parsedData.price?.description ?? "nil")")
            onComplete() // Still close the extension
            return
        }

        // Convert parsed data to dictionary for sharing
        var dataDict: [String: Any] = [:]

        // Debug: Log what dates we're about to save
        print("🔍 [ShareExtensionView] About to save parsed data:")
        print("   Raw startDate: \(parsedData.startDate?.description ?? "nil")")
        print("   Raw endDate: \(parsedData.endDate?.description ?? "nil")")

        // If no start date was parsed, use today
        let actualStartDate = parsedData.startDate ?? Date()
        var actualEndDate = parsedData.endDate
        // Check free-tier limit via App Group shared defaults (best effort)
        if let defaults = UserDefaults(suiteName: "group.com.juan-oclock.kansyl") {
            let currentCount = defaults.integer(forKey: "currentSubscriptionCount")
            let isPremium = defaults.bool(forKey: "isPremium")
            let freeLimit = defaults.integer(forKey: "freeLimit")
            if !isPremium && freeLimit > 0 && currentCount >= freeLimit {
                // Show alert and do not save
                showingLimitAlert = true
                return
            }
        }


        // If we have a duration but no end date, calculate it
        if actualEndDate == nil, let duration = parsedData.trialDuration {
            actualEndDate = Calendar.current.date(byAdding: .day, value: duration, to: actualStartDate)
            print("   Calculated end date from duration: \(actualEndDate?.description ?? "nil")")
        }

        // If still no end date, default to 30 days from start
        if actualEndDate == nil {
            actualEndDate = Calendar.current.date(byAdding: .day, value: 30, to: actualStartDate)
            print("   Defaulted to 30-day trial ending: \(actualEndDate?.description ?? "nil")")
        }

        if let serviceName = parsedData.serviceName {
            dataDict["serviceName"] = serviceName
        }
        if let duration = parsedData.trialDuration {
            dataDict["trialDuration"] = duration
        }
        if let price = parsedData.price {
            dataDict["price"] = price
        }
        if let currency = parsedData.currency {
            dataDict["currency"] = currency
        }

        // Always save the calculated dates
        dataDict["startDate"] = actualStartDate.timeIntervalSince1970
        print("   Saving startDate timestamp: \(actualStartDate.timeIntervalSince1970) (\(actualStartDate))")

        if let endDate = actualEndDate {
            dataDict["endDate"] = endDate.timeIntervalSince1970
            print("   Saving endDate timestamp: \(endDate.timeIntervalSince1970) (\(endDate))")
        }
        if let confirmationNumber = parsedData.confirmationNumber {
            dataDict["confirmationNumber"] = confirmationNumber
        }
        if let emailAddress = parsedData.emailAddress {
            dataDict["emailAddress"] = emailAddress
        }

        print("🔾 [ShareExtensionView] About to save to shared container...")
        print("   Service: \(parsedData.serviceName ?? "Unknown")")
        print("   Data dict keys: \(dataDict.keys.joined(separator: ", "))")

        // Mark as saved immediately to prevent double-saving
        hasSaved = true

        // Show loading state while opening app
        isOpeningApp = true

        // Use the new storage mechanism that works better
        PendingSubscriptionStorage.shared.savePendingSubscription(dataDict)

        print("✅ [ShareExtensionView] Saved subscription using PendingSubscriptionStorage")
        print("   Service: \(parsedData.serviceName ?? "Unknown")")

        // Debug print to verify
        PendingSubscriptionStorage.shared.debugPrint()

        // DON'T save to SharedSubscriptionManager to avoid duplicates
        // The main app will only check PendingSubscriptionStorage now

        // Show success message
        print("✅ [ShareExtensionView] Subscription saved successfully!")
        print("   Service: \(parsedData.serviceName ?? "Unknown")")

        // Play success haptic
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)

        // Show completion message
        isOpeningApp = false
        showCompletionMessage = true

        // Auto-close after showing the message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.onComplete()
        }
    }
    // Helper row for parsed values
    @ViewBuilder
    private func row(icon: String, label: String, value: String?, iconColor: Color = .blue) -> some View {
        let hasValue = (value != nil && !(value ?? "").isEmpty)
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(label)
            Spacer()
            Text(hasValue ? (value ?? "") : "Not detected")
                .fontWeight(hasValue ? .semibold : .regular)
                .foregroundColor(hasValue ? .primary : .secondary)
        }
    }
}

// MARK: - Preview
struct ShareExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareExtensionView(
            inputItems: [],
            extensionContext: nil,
            onComplete: {},
            onCancel: {}
        )
    }
}
