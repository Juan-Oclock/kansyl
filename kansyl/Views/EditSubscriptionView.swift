//
//  EditSubscriptionView.swift
//  kansyl
//
//  Created on 9/16/25.
//

import SwiftUI
import CoreData

struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var subscriptionStore: SubscriptionStore
    @ObservedObject private var appPreferences = AppPreferences.shared
    
    let subscription: Subscription
    
    // Form state - initialized with existing subscription data
    @State private var serviceName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var monthlyPrice: Double
    @State private var notes: String
    @State private var selectedLogo: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingSaveAlert = false
    @State private var saveError: String?
    
    // UI state
    @State private var isFormValid = true
    
    init(subscription: Subscription, subscriptionStore: SubscriptionStore) {
        self.subscription = subscription
        self.subscriptionStore = subscriptionStore
        
        // Initialize state with existing subscription data
        _serviceName = State(initialValue: subscription.name ?? "")
        _startDate = State(initialValue: subscription.startDate ?? Date())
        _endDate = State(initialValue: subscription.endDate ?? Date())
        _monthlyPrice = State(initialValue: subscription.monthlyPrice)
        _notes = State(initialValue: subscription.notes ?? "")
        _selectedLogo = State(initialValue: subscription.serviceLogo ?? "app.badge")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                modernHeader
                    .zIndex(1)
                
                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Service Name Section
                        serviceNameSection
                        
                        // Logo Selection Section
                        logoSection
                        
                        // Date & Price Section
                        dateAndPriceSection
                        
                        // Notes Section
                        notesSection
                        
                        // Bottom spacing for button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 20)
                }
                .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                
                // Fixed bottom button
                VStack(spacing: 0) {
                    Divider()
                        .background(Design.Colors.border)
                    
                    saveButton
                        .padding(20)
                        .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                }
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage) { image in
                selectedImage = image
                selectedLogo = "custom_uploaded_logo"
            }
        }
        .alert("Save Changes", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveChanges()
            }
        } message: {
            Text("Are you sure you want to save these changes?")
        }
    }
    
    // MARK: - Header
    private var modernHeader: some View {
        HStack {
            // Cancel Button
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Design.Colors.primary)
            }
            
            Spacer()
            
            // Title
            Text("Edit Subscription")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
            
            // Invisible placeholder for symmetry
            Text("Cancel")
                .font(.system(size: 17, weight: .regular))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
    }
    
    // MARK: - Service Name Section
    private var serviceNameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Name")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                Image(systemName: "tv")
                    .foregroundColor(Design.Colors.textSecondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Service name", text: $serviceName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Design.Colors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Service Logo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Button("Change") {
                    showingImagePicker = true
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Design.Colors.primary)
            }
            .padding(.horizontal, 20)
            
            // Current Logo Display
            HStack(spacing: 16) {
                // Logo Preview
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    if selectedLogo == "custom_uploaded_logo", let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else {
                        Image.bundleImage(selectedLogo, fallbackSystemName: "app.badge")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Logo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text(selectedLogo == "custom_uploaded_logo" ? "Custom image" : "System logo")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Date & Price Section
    private var dateAndPriceSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Subscription Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Start Date
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .frame(width: 24)
                    
                    Text("Start Date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Design.Colors.success)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                
                // End Date
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .frame(width: 24)
                    
                    Text("End Date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Design.Colors.success)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                
                // Monthly Price
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .frame(width: 24)
                    
                    Text("Monthly Price")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(appPreferences.currencySymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textSecondary)
                        
                        TextField("0.00", value: $monthlyPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes (Optional)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.textTertiary)
                
                TextField("Add any notes about this subscription", text: $notes)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Design.Colors.textPrimary)
                    .lineLimit(3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: { showingSaveAlert = true }) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Save Changes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Design.Colors.success,
                        Design.Colors.success.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Design.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid)
        .scaleEffect(isFormValid ? 1.0 : 0.98)
        .opacity(isFormValid ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        // Update the subscription with new values
        subscription.name = serviceName.isEmpty ? subscription.name : serviceName
        subscription.startDate = startDate
        subscription.endDate = endDate
        subscription.monthlyPrice = monthlyPrice
        subscription.notes = notes.isEmpty ? nil : notes
        
        // Handle logo update
        if selectedLogo == "custom_uploaded_logo", let uploadedImage = selectedImage {
            if let savedImagePath = saveImageToDocuments(uploadedImage, serviceName: serviceName) {
                subscription.serviceLogo = savedImagePath
            }
        } else {
            subscription.serviceLogo = selectedLogo
        }
        
        do {
            try subscriptionStore.viewContext.save()
            
            // Update notifications
            NotificationManager.shared.removeNotifications(for: subscription)
            NotificationManager.shared.scheduleNotifications(for: subscription)
            
            // Update calendar event
            CalendarManager.shared.addOrUpdateEvent(for: subscription)
            
            // Analytics - using existing event
            AnalyticsManager.shared.track(.subscriptionAdded, properties: AnalyticsProperties(
                source: "edit_modal",
                subscriptionName: serviceName
            ))
            
            // Haptic feedback
            HapticManager.shared.playButtonTap()
            
            dismiss()
        } catch {
            saveError = error.localizedDescription
            print("Error updating subscription: \(error)")
        }
    }
    
    private func saveImageToDocuments(_ image: UIImage, serviceName: String) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileName = "\(serviceName.replacingOccurrences(of: " ", with: "_"))_logo_\(UUID().uuidString).jpg"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName // Return just the filename, not the full path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

// MARK: - Preview
struct EditSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let subscription = Subscription(context: context)
        subscription.name = "Netflix"
        subscription.startDate = Date()
        subscription.endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        subscription.monthlyPrice = 15.99
        subscription.serviceLogo = "netflix-logo"
        subscription.status = "active"
        
        return EditSubscriptionView(
            subscription: subscription,
            subscriptionStore: SubscriptionStore(context: context)
        )
    }
}