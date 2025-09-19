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
    let context: NSManagedObjectContext
    @State private var exportData = ""
    @State private var showingShareSheet = false
    
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
                ShareSheet(activityItems: [exportData])
            }
        }
    }
    
    private func generateExportData() {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        
        do {
            let subscriptions = try context.fetch(request)
            let exportSubscriptions = subscriptions.map { subscription in
                [
                    "id": subscription.id?.uuidString ?? "",
                    "name": subscription.name ?? "",
                    "startDate": subscription.startDate?.ISO8601Format() ?? "",
                    "endDate": subscription.endDate?.ISO8601Format() ?? "",
                    "monthlyPrice": subscription.monthlyPrice,
                    "serviceLogo": subscription.serviceLogo ?? "",
                    "status": subscription.status ?? "",
                    "notes": subscription.notes ?? ""
                ]
            }
            
            let exportDict = [
                "exportDate": Date().ISO8601Format(),
                "appVersion": "1.0.0",
                "subscriptions": exportSubscriptions
            ] as [String: Any]
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            exportData = String(data: jsonData, encoding: .utf8) ?? ""
            
        } catch {
            // Debug: print("Error exporting data: \(error)")
            exportData = "Error generating export data"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportDataView_Previews: PreviewProvider {
    static var previews: some View {
        ExportDataView(context: PersistenceController.preview.container.viewContext)
    }
}
