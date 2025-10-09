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
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    
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
    @State private var saveError: String?
    @State private var subscriptionType: SubscriptionType
    @State private var showingAmountWarning = false
    @State private var isAmountInvalid = false
    
    // Focus states for keyboard management
    @FocusState private var isServiceNameFocused: Bool
    @FocusState private var isPriceFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
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
        _subscriptionType = State(initialValue: SubscriptionType(rawValue: subscription.subscriptionType ?? "paid") ?? .paid)
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        // Dismiss whichever field is currently focused
                        isServiceNameFocused = false
                        isPriceFocused = false
                        isNotesFocused = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage) { image in
                selectedImage = image
                selectedLogo = "custom_uploaded_logo"
            }
        }
        .alert("Amount Required", isPresented: $showingAmountWarning) {
            Button("OK", role: .cancel) {
                isPriceFocused = true
            }
        } message: {
            Text("Please enter an amount greater than \(userPreferences.currencySymbol)0 for \(subscriptionType.displayName) subscriptions.")
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
                    .focused($isServiceNameFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isServiceNameFocused ? Design.Colors.primary : Color.clear, lineWidth: isServiceNameFocused ? 2 : 0)
            )
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
                        Text(userPreferences.currencySymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textSecondary)
                        
                        TextField("0.00", value: $monthlyPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($isPriceFocused)
                            .onChange(of: monthlyPrice) { _ in
                                isAmountInvalid = false
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isAmountInvalid ? Color.red : (isPriceFocused ? Design.Colors.primary : Color.clear), lineWidth: (isAmountInvalid || isPriceFocused) ? 2 : 0)
                )
                
                // Subscription Type Picker
                HStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .frame(width: 24)
                    
                    Text("Subscription Type")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach([SubscriptionType.trial, SubscriptionType.paid, SubscriptionType.promotional], id: \.self) { type in
                            Button(action: { subscriptionType = type }) {
                                Text(type.displayName)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(subscriptionType.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Design.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(subscriptionType.badgeColor.opacity(0.1))
                        .cornerRadius(8)
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
                    .focused($isNotesFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isNotesFocused ? Design.Colors.primary : Color.clear, lineWidth: isNotesFocused ? 2 : 0)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            // Dismiss keyboard first
            isServiceNameFocused = false
            isPriceFocused = false
            isNotesFocused = false
            // Then save
            saveChanges()
        }) {
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
        // Remove disabled state to always allow saving
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        print("[EditSubscription] Starting save...")
        print("[EditSubscription] Current subscription type: \(subscription.subscriptionType ?? "nil")")
        print("[EditSubscription] New subscription type to save: \(subscriptionType.rawValue)")
        
        // Validate amount for Premium and Promo types
        if (subscriptionType == .paid || subscriptionType == .promotional) && monthlyPrice <= 0 {
            isAmountInvalid = true
            showingAmountWarning = true
            HapticManager.shared.playError()
            return
        }
        
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
        
        // Update subscription type
        subscription.subscriptionType = subscriptionType.rawValue
        subscription.isTrial = (subscriptionType == .trial)
        if subscriptionType == .trial {
            subscription.trialEndDate = endDate
        }
        print("[EditSubscription] Updated subscription.subscriptionType to: \(subscription.subscriptionType ?? "nil")")
        print("[EditSubscription] Updated subscription.isTrial to: \(subscription.isTrial)")
        
        // Use the subscription store's save method instead of direct Core Data save
        subscriptionStore.saveContext()
        print("[EditSubscription] Changes saved successfully")
        
        // Refresh the subscription list to reflect changes
        subscriptionStore.fetchSubscriptions()
        
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
        
        print("[EditSubscription] Dismissing modal...")
        // Dismiss the modal after all updates
        dismiss()
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
            // Debug: // Debug: print("Error saving image: \(error)")
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