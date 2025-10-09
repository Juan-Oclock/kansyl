//
//  ExportDataView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @ObservedObject private var userStateManager = UserStateManager.shared
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    let context: NSManagedObjectContext
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    @State private var exportedSubscriptionCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Your subscription data will be exported as JSON format that you can save or share.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    generateExportData()
                    showingShareSheet = true
                }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportFileURL {
                    ShareSheet(activityItems: [fileURL], onDismiss: {
                        // Show success message and auto-close after share sheet dismisses
                        showingSuccessAlert = true
                    })
                }
            }
            .alert("Export Successful", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {
                    // Add haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    // Auto-dismiss the export view
                    dismiss()
                }
            } message: {
                Text("Successfully exported \(exportedSubscriptionCount) subscription\(exportedSubscriptionCount == 1 ? "" : "s") to JSON file.")
            }
            .alert("Export Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onDisappear {
                cleanupTempFile()
            }
        }
    }
    
    private func cleanupTempFile() {
        if let fileURL = exportFileURL {
            try? FileManager.default.removeItem(at: fileURL)
            print("🗑️ [ExportDataView] Cleaned up temporary export file")
        }
    }
    
    private func generateExportData() {
        // Use SubscriptionStore which already handles user filtering correctly
        let subscriptions = subscriptionStore.allSubscriptions
        
        // Determine user type for metadata
        let userType: String
        if authManager.isAuthenticated {
            userType = "authenticated"
            print("📤 [ExportDataView] Exporting data for authenticated user")
        } else if userStateManager.isAnonymousMode {
            userType = "anonymous"
            print("📤 [ExportDataView] Exporting data for anonymous user")
        } else {
            userType = "unknown"
            print("📤 [ExportDataView] Exporting data (user type unknown)")
        }
        
        print("📤 [ExportDataView] Found \(subscriptions.count) subscriptions to export")
        
        // Check if no subscriptions found
        if subscriptions.isEmpty {
            print("⚠️ [ExportDataView] No subscriptions found for user")
            errorMessage = "No subscriptions found to export. Add some subscriptions first."
            showingErrorAlert = true
            return
        }
        
        do {
            let exportSubscriptions = subscriptions.map { subscription in
                [
                    "id": subscription.id?.uuidString ?? "",
                    "name": subscription.name ?? "",
                    "startDate": subscription.startDate?.ISO8601Format() ?? "",
                    "endDate": subscription.endDate?.ISO8601Format() ?? "",
                    "monthlyPrice": subscription.monthlyPrice,
                    "billingAmount": subscription.billingAmount,
                    "billingCycle": subscription.billingCycle ?? "monthly",
                    "serviceLogo": subscription.serviceLogo ?? "",
                    "status": subscription.status ?? "",
                    "notes": subscription.notes ?? "",
                    "subscriptionType": subscription.subscriptionType ?? "trial",
                    "isTrial": subscription.isTrial,
                    "originalCurrency": subscription.originalCurrency ?? "",
                    "originalAmount": subscription.originalAmount,
                    "exchangeRate": subscription.exchangeRate
                ] as [String: Any]
            }
            
            let exportDict = [
                "exportDate": Date().ISO8601Format(),
                "appVersion": "1.0.0",
                "userType": userType,
                "subscriptionsCount": subscriptions.count,
                "subscriptions": exportSubscriptions
            ] as [String: Any]
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            
            // Save to temporary file
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            let fileName = "kansyl_export_\(timestamp).json"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            exportFileURL = fileURL
            exportedSubscriptionCount = subscriptions.count
            
            print("✅ [ExportDataView] Successfully generated export data for \(userType) user")
            print("📊 [ExportDataView] Export saved to: \(fileURL.path)")
            print("📊 [ExportDataView] Export size: \(jsonData.count) bytes")
            
        } catch {
            print("❌ [ExportDataView] Error exporting data: \(error.localizedDescription)")
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var onDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Set completion handler to trigger onDismiss
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onDismiss?()
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportDataView_Previews: PreviewProvider {
    static var previews: some View {
        ExportDataView(context: PersistenceController.preview.container.viewContext)
    }
}
