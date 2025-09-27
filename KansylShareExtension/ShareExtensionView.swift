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
    
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    init(inputItems: [NSExtensionItem], onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._inputItems = State(initialValue: inputItems)
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if emailParser.isProcessing {
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
                },
                trailing: Button("Done") {
                    saveTrial()
                }
                .disabled(emailParser.parsedData?.isValid != true)
            )
        }
        .onAppear {
            print("🚀 [ShareExtensionView] onAppear called with \(inputItems.count) input items")
            
            // Add a timeout to prevent infinite processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
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
                if let serviceName = data.serviceName {
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundColor(.blue)
                        Text("Service:")
                        Spacer()
                        Text(serviceName)
                            .fontWeight(.semibold)
                    }
                }
                
                if let duration = data.trialDuration {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("Trial Duration:")
                        Spacer()
                        Text("\(duration) days")
                            .fontWeight(.semibold)
                    }
                }
                
                if let price = data.price {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.green)
                        Text("Price:")
                        Spacer()
                        Text("$\(String(format: "%.2f", price))")
                            .fontWeight(.semibold)
                    }
                }
                
                if let endDate = data.endDate {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.red)
                        Text("Trial Ends:")
                        Spacer()
                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Text("Tap 'Done' to add this subscription to Kansyl")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var waitingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Ready to Parse")
                .font(.headline)
            
            Text("Processing shared content...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    private func saveTrial() {
        // For demo purposes, just show success and complete
        // In a real implementation, you'd save to shared container or pass data back to main app
        print("✅ Would save subscription: \(emailParser.parsedData?.serviceName ?? "Unknown")")
        onComplete()
    }
}

// MARK: - Preview
struct ShareExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareExtensionView(
            inputItems: [],
            onComplete: {},
            onCancel: {}
        )
    }
}
