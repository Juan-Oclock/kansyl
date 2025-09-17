//
//  AddSubscriptionView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import CoreData
import UIKit


struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var subscriptionStore: SubscriptionStore
    @ObservedObject private var appPreferences = AppPreferences.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    
    // Optional prefilled service name from Siri Shortcuts
    var prefilledServiceName: String? = nil
    
    // Completion handler
    var onSave: ((Subscription?) -> Void)? = nil
    
    // Form state
    @State private var selectedService: ServiceTemplateData?
    @State private var customServiceName = ""
    @State private var startDate = Date()
    @State private var subscriptionLength: Int = 30  // Default to 30 days
    @State private var customPrice: Double = 0.0
    @State private var notes = ""
    @State private var selectedLogo = "questionmark.circle"
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    // UI state
    @State private var showingCustomService = false
    @State private var searchText = ""
    @State private var showingPremiumRequired = false
    @State private var showingAllServices = false
    @State private var isServiceNameInvalid = false
    @State private var attempts = 0
    @State private var showingDaysPicker = false
    @FocusState private var isFocused: Bool
    
    // Calendar integration
    @State private var showingCalendarPrompt = false
    @State private var savedSubscription: Subscription?
    @AppStorage("calendarIntegrationPreference") private var calendarPref = "ask"
    
    // Service categories
    private let serviceManager = ServiceTemplateManager.shared
    
    var filteredServices: [ServiceTemplateData] {
        if searchText.isEmpty {
            return serviceManager.templates
        } else {
            return serviceManager.templates.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var endDate: Date {
        if subscriptionLength > 0 {
            return Calendar.current.date(byAdding: .day, value: subscriptionLength, to: startDate) ?? startDate
        } else {
            return appPreferences.getDefaultTrialEndDate(from: startDate)
        }
    }
    
    private var effectiveSubscriptionLength: Int {
        if subscriptionLength > 0 {
            return subscriptionLength
        } else {
            // Convert default subscription length to days for display
            let endDate = appPreferences.getDefaultTrialEndDate(from: startDate)
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 30
            return days
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimalist Header
            modernHeader
                .zIndex(1)
            
            // Scrollable Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    if selectedService == nil && !showingCustomService {
                        ServiceSelectionView
                    } else if selectedService != nil {
                        SelectedServiceView
                    } else {
                        CustomServiceView
                    }
                    
                    // Bottom spacing for button
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 20)
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            
            // Fixed bottom button
            if isFormValid {
                VStack(spacing: 0) {
                    Divider()
                        .background(Design.Colors.border)
                    
                    AddSubscriptionButton
                        .padding(20)
                        .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
                }
            }
        }
        .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPremiumRequired) {
            PremiumFeatureView()
        }
        .sheet(isPresented: $showingAllServices) {
            AllServicesSheet(selectedService: $selectedService, 
                           subscriptionLength: $subscriptionLength,
                           customPrice: $customPrice,
                           selectedLogo: $selectedLogo,
                           showingAllServices: $showingAllServices)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage) { image in
                selectedImage = image
                selectedLogo = "custom_uploaded_logo"
            }
        }
        .sheet(isPresented: $showingDaysPicker) {
            DaysPickerSheet(selectedDays: Binding(
                get: { subscriptionLength > 0 ? subscriptionLength : 30 },
                set: { subscriptionLength = $0 }
            ), isPresented: $showingDaysPicker)
        }
        .sheet(isPresented: $showingCalendarPrompt) {
            if let subscription = savedSubscription {
                CalendarPromptView(
                    isPresented: $showingCalendarPrompt,
                    subscription: subscription
                ) {
                    // Add to calendar when user confirms
                    CalendarManager.shared.addOrUpdateEvent(for: subscription)
                }
                .onDisappear {
                    // Complete the flow when calendar prompt is dismissed
                    onSave?(savedSubscription)
                    dismiss()
                }
            }
        }
        .onAppear {
            handlePrefilledService()
        }
    }
    
    // MARK: - Minimalist Header
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
            Text("Add Subscription")
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
    
    private var ServiceSelectionView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Minimalist Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Design.Colors.textSecondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search service", text: $searchText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Design.Colors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Section Header
            HStack {
                Text("Popular Services")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Button("Add Manually") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingCustomService = true
                        HapticManager.shared.playButtonTap()
                    }
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Design.Colors.success)
            }
            .padding(.horizontal, 20)
            
            // 4-Column Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 16) {
                ForEach(Array(filteredServices.prefix(19)), id: \.name) { service in
                    MinimalServiceCard(service: service) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedService = service
                            subscriptionLength = Int(service.defaultSubscriptionLength)
                            customPrice = service.monthlyPrice
                            selectedLogo = service.logoName
                            HapticManager.shared.selection()
                        }
                    }
                }
                
                // Add "More" button if we have more services
                if filteredServices.count > 19 {
                    Button(action: {
                        showingAllServices = true
                        HapticManager.shared.playButtonTap()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Design.Colors.surfaceSecondary)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                            }
                            
                            Text("More")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Design.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Design.Colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Design.Colors.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var SelectedServiceView: some View {
        VStack(spacing: 20) {
            if let service = selectedService {
                // Compact Selected Service Card
                HStack(spacing: 12) {
                    // Service Logo - smaller and cleaner
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        
                        Image.bundleImage(service.logoName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Service Info - compact
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        HStack(spacing: 4) {
                            Text("\(service.defaultSubscriptionLength) days")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Design.Colors.textSecondary)
                            
                            Text("•")
                                .foregroundColor(Design.Colors.textTertiary)
                            
                            Text("\(AppPreferences.shared.formatPrice(customPrice))/mo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Design.Colors.success)
                        }
                    }
                    
                    Spacer()
                    
                    // Compact Change Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedService = nil
                            showingCustomService = false
                            HapticManager.shared.playButtonTap()
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                            .padding(8)
                            .background(Design.Colors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Divider
                Rectangle()
                    .fill(Design.Colors.border)
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                SubscriptionDetailsForm(
                    startDate: $startDate,
                    subscriptionLength: $subscriptionLength,
                    customPrice: $customPrice,
                    notes: $notes
                )
            }
        }
    }
    
    private var CustomServiceView: some View {
        VStack(spacing: 20) {
            // Compact Header
            HStack {
                Text("Custom Service")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingCustomService = false
                        HapticManager.shared.playButtonTap()
                    }
                }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Design.Colors.success)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            VStack(spacing: 16) {
                // Service Name & Logo in one compact row
                HStack(spacing: 12) {
                    // Logo button - compact square
                    Button(action: {
                        showingImagePicker = true
                        HapticManager.shared.playButtonTap()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Design.Colors.surfaceSecondary)
                                .frame(width: 56, height: 56)
                            
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 54, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Design.Colors.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Service name field - takes remaining space
                    TextField("Service name", text: $customServiceName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Design.Colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .background(Design.Colors.surfaceSecondary)
                        .cornerRadius(12)
                        .modifier(InvalidFieldModifier(isInvalid: $isServiceNameInvalid, attempts: attempts))
                        .focused($isFocused)
                        .onChange(of: customServiceName) { _ in
                            isServiceNameInvalid = false
                        }
                }
                .padding(.horizontal, 20)
                
                // Compact date picker
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .frame(width: 24)
                    
                    Text("Starts")
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
                .padding(.horizontal, 20)
                
                // Combined Trial & Price Row with equal columns
                HStack(spacing: 12) {
                    // Trial Length - Button that opens picker modal
                    Button(action: { showingDaysPicker = true }) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Design.Colors.textTertiary)
                                .padding(.leading, 4)
                            
                            Spacer()
                            
                            Text("\(subscriptionLength > 0 ? subscriptionLength : 30)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            Text("days")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Design.Colors.textSecondary)
                                .padding(.trailing, 4)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)
                    
                    // Monthly Price - Full width of column
                    HStack {
                        Text(appPreferences.currencySymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textSecondary)
                            .padding(.leading, 4)
                        
                        TextField("0.00", value: $customPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("/mo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                            .padding(.trailing, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                
                // Optional notes field - expandable
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textTertiary)
                        
                        TextField("Add notes (optional)", text: $notes)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surfaceSecondary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    private var AddSubscriptionButton: some View {
        Button(action: saveSubscription) {
            HStack(spacing: 12) {
                if !premiumManager.canAddMoreTrials(currentCount: subscriptionStore.activeSubscriptions.count) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(!premiumManager.canAddMoreTrials(currentCount: subscriptionStore.activeSubscriptions.count)
                     ? "Upgrade to Add More"
                     : "Add Subscription")
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
                        Color(hex: "0F172A"),
                        Color(hex: "1E293B")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid)
        .scaleEffect(isFormValid ? 1.0 : 0.98)
        .opacity(isFormValid ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
    }
    
    private var isFormValid: Bool {
        if selectedService != nil {
            return true
        } else {
            return !customServiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func saveSubscription() {
        guard isFormValid else {
            isServiceNameInvalid = true
            withAnimation {
                self.attempts += 1
            }
            isFocused = true
            return
        }

        // Check premium limits
        if !premiumManager.canAddMoreTrials(currentCount: subscriptionStore.activeSubscriptions.count) {
            showingPremiumRequired = true
            return
        }
        
        var logo = selectedLogo
        
        // Handle custom uploaded image
        if let uploadedImage = selectedImage {
            if let savedImagePath = saveImageToDocuments(uploadedImage, serviceName: customServiceName) {
                logo = savedImagePath
            }
        }
        
        let serviceName = selectedService?.name ?? customServiceName
        
        // Check calendar preference
        let shouldAddToCalendar = calendarPref == "always"
        let shouldAskAboutCalendar = calendarPref == "ask"
        
        let newSubscription = subscriptionStore.addSubscription(
            name: serviceName,
            startDate: startDate,
            endDate: endDate,
            monthlyPrice: customPrice,
            serviceLogo: logo,
            notes: notes.isEmpty ? nil : notes,
            addToCalendar: shouldAddToCalendar
        )
        
        self.savedSubscription = newSubscription
        
        // Analytics
        AnalyticsManager.shared.track(.subscriptionAdded, properties: AnalyticsProperties(
            source: "custom"
        ))
        
        // Haptic feedback
        HapticManager.shared.playSubscriptionAdded()
        
        // Check if we should ask about calendar
        if shouldAskAboutCalendar {
            showingCalendarPrompt = true
        } else {
            // Complete
            onSave?(newSubscription)
            dismiss()
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
    
    // MARK: - Handle Prefilled Service
    private func handlePrefilledService() {
        guard let serviceName = prefilledServiceName else { return }
        
        // Try to find a matching service template
        if let matchingService = serviceManager.templates.first(where: { 
            $0.name.lowercased() == serviceName.lowercased() 
        }) {
            selectedService = matchingService
            subscriptionLength = Int(matchingService.defaultSubscriptionLength)
            customPrice = matchingService.monthlyPrice
            selectedLogo = matchingService.logoName
        } else {
            // If no template found, use custom service
            showingCustomService = true
            customServiceName = serviceName
            
            // Set default values for known services
            switch serviceName.lowercased() {
            case "netflix":
                customPrice = 15.99
                selectedLogo = "netflix-logo"
            case "spotify":
                customPrice = 9.99
                selectedLogo = "spotify-logo"
            case "disney+", "disney plus":
                customPrice = 7.99
                selectedLogo = "sparkles"
            case "amazon prime":
                customPrice = 14.99
                selectedLogo = "cart.fill"
            case "apple tv+", "apple tv plus":
                customPrice = 6.99
                selectedLogo = "appletv-logo"
            case "apple music":
                customPrice = 10.99
                selectedLogo = "apple-logo"
            case "hulu":
                customPrice = 7.99
                selectedLogo = "h.square.fill"
            default:
                customPrice = 9.99
                selectedLogo = "app.badge"
            }
        }
    }
}

// MARK: - Image Picker for iOS 15 compatibility
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImageSelected(originalImage)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct InvalidFieldModifier: ViewModifier {
    @Binding var isInvalid: Bool
    var attempts: Int

    func body(content: Content) -> some View {
        content
            .background(isInvalid ? Color.red.opacity(0.1) : Design.Colors.surfaceSecondary)
            .modifier(Shake(animatableData: CGFloat(attempts)))
    }
}

// MARK: - Missing Components

struct MinimalServiceCard: View {
    let service: ServiceTemplateData
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    
                    Image.bundleImage(service.logoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                Text(service.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Design.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Design.Colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionDetailsForm: View {
    @Binding var startDate: Date
    @Binding var subscriptionLength: Int
    @Binding var customPrice: Double
    @Binding var notes: String
    
    @ObservedObject private var appPreferences = AppPreferences.shared
    @State private var showingDaysPicker = false
    
    init(startDate: Binding<Date>, subscriptionLength: Binding<Int>, customPrice: Binding<Double>, notes: Binding<String>) {
        self._startDate = startDate
        self._subscriptionLength = subscriptionLength
        self._customPrice = customPrice
        self._notes = notes
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Date picker
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Design.Colors.textSecondary)
                    .frame(width: 24)
                
                Text("Starts")
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
            .background(Design.Colors.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Trial Length and Price
            HStack(spacing: 12) {
                // Trial Length - Button that opens picker modal
                Button(action: { showingDaysPicker = true }) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textTertiary)
                            .padding(.leading, 4)
                        
                        Spacer()
                        
                        Text("\(subscriptionLength > 0 ? subscriptionLength : 30)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        Text("days")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                            .padding(.trailing, 4)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
                
                // Monthly Price
                HStack {
                    Text(appPreferences.currencySymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.textSecondary)
                        .padding(.leading, 4)
                    
                    TextField("0.00", value: $customPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("/mo")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            
            // Notes field
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Design.Colors.textTertiary)
                    
                    TextField("Add notes (optional)", text: $notes)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Design.Colors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingDaysPicker) {
            DaysPickerSheet(selectedDays: Binding(
                get: { subscriptionLength > 0 ? subscriptionLength : 30 },
                set: { subscriptionLength = $0 }
            ), isPresented: $showingDaysPicker)
        }
    }
}

// MARK: - Days Picker Sheet
struct DaysPickerSheet: View {
    @Binding var selectedDays: Int
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var tempSelection: Int
    
    init(selectedDays: Binding<Int>, isPresented: Binding<Bool>) {
        self._selectedDays = selectedDays
        self._isPresented = isPresented
        self._tempSelection = State(initialValue: selectedDays.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Picker
                Picker("Days", selection: $tempSelection) {
                    ForEach(1...365, id: \.self) { day in
                        Text("\(day) \(day == 1 ? "day" : "days")")
                            .font(.system(size: 20, weight: .medium))
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                
                // Common presets
                VStack(spacing: 12) {
                    Text("Quick Select")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                        .padding(.top, 8)
                    
                    HStack(spacing: 12) {
                        PresetButton(title: "7 days", days: 7, selection: $tempSelection)
                        PresetButton(title: "14 days", days: 14, selection: $tempSelection)
                        PresetButton(title: "30 days", days: 30, selection: $tempSelection)
                        PresetButton(title: "90 days", days: 90, selection: $tempSelection)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
            .navigationTitle("Trial Length")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Design.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDays = tempSelection
                        isPresented = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
        }
    }
}

struct PresetButton: View {
    let title: String
    let days: Int
    @Binding var selection: Int
    
    var body: some View {
        Button(action: {
            selection = days
            HapticManager.shared.selection()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selection == days ? .white : Design.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selection == days ? Design.Colors.primary : Design.Colors.surfaceSecondary)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AllServicesSheet: View {
    @Binding var selectedService: ServiceTemplateData?
    @Binding var subscriptionLength: Int
    @Binding var customPrice: Double
    @Binding var selectedLogo: String
    @Binding var showingAllServices: Bool
    
    @State private var searchText = ""
    private let serviceManager = ServiceTemplateManager.shared
    
    var filteredServices: [ServiceTemplateData] {
        if searchText.isEmpty {
            return serviceManager.templates
        } else {
            return serviceManager.templates.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Design.Colors.textSecondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search services", text: $searchText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Design.Colors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Services Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 16) {
                        ForEach(filteredServices, id: \.name) { service in
                            MinimalServiceCard(service: service) {
                                selectedService = service
                                subscriptionLength = Int(service.defaultSubscriptionLength)
                                customPrice = service.monthlyPrice
                                selectedLogo = service.logoName
                                showingAllServices = false
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("All Services")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    showingAllServices = false
                }
            )
        }
    }
}

