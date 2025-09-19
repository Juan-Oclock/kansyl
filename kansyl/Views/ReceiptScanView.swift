//
//  ReceiptScanView.swift
//  kansyl
//
//  AI-powered receipt scanning view
//

import SwiftUI
import UIKit
import PhotosUI
import AVFoundation

struct ReceiptScanView: View {
    @ObservedObject var subscriptionStore: SubscriptionStore
    @StateObject private var receiptScanner = ReceiptScanner()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedImage: UIImage?
    @State private var showingCameraPicker = false
    @State private var showingPhotoLibraryPicker = false
    @State private var parsedReceiptData: ReceiptScanner.ParsedReceiptData?
    @State private var showingConfirmation = false
    @State private var showingCameraUnavailableAlert = false
    @State private var cameraInitialized = false
    
    // Completion handler
    var onSave: ((Subscription?) -> Void)? = nil
    
    // Helper to detect if running on simulator
    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        // Debug: // Debug: print("📱 Detected: Running on iOS Simulator")
        return true
        #else
        // Debug: // Debug: print("📱 Detected: Running on real device")
        return false
        #endif
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                receiptScanHeader
                
                // Main content
                if receiptScanner.isProcessing {
                    processingView
                } else if let image = selectedImage, parsedReceiptData == nil {
                    imagePreviewView(image: image)
                } else if let parsedData = parsedReceiptData {
                    receiptConfirmationView(data: parsedData)
                } else {
                    initialScanView
                }
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .sheet(isPresented: $showingCameraPicker) {
                DirectImagePickerView(
                    isPresented: $showingCameraPicker,
                    sourceType: .camera,
                    onImageSelected: { image in
                        selectedImage = image
                        Task {
                            await processImage(image)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingPhotoLibraryPicker) {
                DirectImagePickerView(
                    isPresented: $showingPhotoLibraryPicker,
                    sourceType: .photoLibrary,
                    onImageSelected: { image in
                        selectedImage = image
                        Task {
                            await processImage(image)
                        }
                    }
                )
            }
            .alert("Receipt Scan Error", isPresented: .constant(receiptScanner.errorMessage != nil)) {
                Button("OK") {
                    receiptScanner.errorMessage = nil
                }
                Button("Retry") {
                    if let image = selectedImage {
                        Task {
                            await processImage(image)
                        }
                    }
                }
            } message: {
                Text(receiptScanner.errorMessage ?? "")
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("Use Photo Library") {
                    showingPhotoLibraryPicker = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(isRunningOnSimulator 
                    ? "Camera is not available in the iOS Simulator. Please use photo library or test on a physical device."
                    : "Camera access is not available. Please check your camera permissions in Settings.")
            }
            .sheet(isPresented: $showingConfirmation) {
                if let data = parsedReceiptData {
                    ReceiptConfirmationSheet(
                        receiptData: data,
                        subscriptionStore: subscriptionStore,
                        isPresented: $showingConfirmation,
                        onSave: { subscription in
                            // Debug: // Debug: print("🎉 ReceiptScanView: Subscription added successfully, dismissing view")
                            // Call the original onSave callback if provided
                            onSave?(subscription)
                            // Dismiss the entire receipt scan view
                            dismiss()
                        }
                    )
                }
            }
            .onAppear {
                // Pre-initialize camera availability check
                initializeCameraAvailability()
            }
        }
    }
    
    // MARK: - Header
    private var receiptScanHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(Design.Colors.primary)
            
            Spacer()
            
            Text("Scan Receipt")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
    }
    
    // MARK: - Initial Scan View
    private var initialScanView: some View {
        VStack(spacing: 32) {
            // Icon and title
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Design.Colors.primary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Design.Colors.primary)
                }
                
                VStack(spacing: 8) {
                    Text("Scan Your Receipt")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("Take a photo or select from your library to automatically detect subscription information")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.top, 60)
            
            // Action buttons
            VStack(spacing: 16) {
                // Camera button
                Button(action: {
                    // Debug: // Debug: print("🔘 Camera button tapped")
                    // Debug: // Debug: print("📱 isRunningOnSimulator: \(isRunningOnSimulator)")
                    // Debug: // Debug: print("📷 Camera available: \(UIImagePickerController.isSourceTypeAvailable(.camera))")
                    
                    if isRunningOnSimulator {
                        // On simulator, use photo library
                        // Debug: // Debug: print("📱 Simulator detected, using photo library")
                        showingPhotoLibraryPicker = true
                    } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        // On real device with camera available
                        // Debug: // Debug: print("📷 Camera available, requesting access")
                        requestCameraAccess()
                    } else {
                        // Debug: // Debug: print("⚠️ Camera not available, showing alert")
                        // Camera not available, show alert instead of automatic fallback
                        showingCameraUnavailableAlert = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isRunningOnSimulator ? "photo" : "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(isRunningOnSimulator ? "Choose Photo (Simulator)" : "Take Photo")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Design.Colors.primary)
                    .cornerRadius(12)
                }
                
                // Photo library button
                Button(action: {
                    // Debug: // Debug: print("📚 Photo Library button tapped")
                    
                    // Show photo library picker directly
                    showingPhotoLibraryPicker = true
                    // Debug: // Debug: print("📸 Showing photo library picker")
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Choose from Library")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(Design.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated scanning indicator
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Design.Colors.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Design.Colors.primary, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(receiptScanner.isProcessing ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: receiptScanner.isProcessing)
                }
                
                VStack(spacing: 8) {
                    Text("Analyzing Receipt")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("Our AI is scanning for subscription information...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Design.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Image Preview
    private func imagePreviewView(image: UIImage) -> some View {
        VStack(spacing: 24) {
            // Image preview
            VStack(spacing: 16) {
                Text("Receipt Preview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Try Different Image") {
                    selectedImage = nil
                    parsedReceiptData = nil
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Design.Colors.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(10)
                
                Button("Analyze Receipt") {
                    Task {
                        await processImage(image)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Design.Colors.primary)
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Receipt Confirmation View
    private func receiptConfirmationView(data: ReceiptScanner.ParsedReceiptData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    if data.isSubscription {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Subscription Detected!")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("No Subscription Found")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                    
                    Text("Confidence: \(Int(data.confidence * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                .padding(.top, 20)
                
                if data.isSubscription {
                    // Detected information
                    VStack(spacing: 16) {
                        detailRow(title: "Service", value: data.serviceName ?? "Unknown")
                        
                        if let amount = data.amount {
                            // Show converted amount if conversion occurred
                            if let originalAmount = data.originalAmount,
                               let originalCurrency = data.originalCurrency,
                               originalCurrency != data.currency {
                                detailRow(title: "Amount", value: "\(data.currency ?? "USD") \(String(format: "%.2f", amount))")
                                detailRow(title: "Original", value: "\(originalCurrency) \(String(format: "%.2f", originalAmount))")
                            } else {
                                detailRow(title: "Amount", value: "\(data.currency ?? "USD") \(String(format: "%.2f", amount))")
                            }
                        }
                        
                        if let subscriptionType = data.subscriptionType {
                            detailRow(title: "Billing", value: subscriptionType.capitalized)
                        }
                        
                        if let date = data.date {
                            detailRow(title: "Date", value: DateFormatter.mediumStyle.string(from: date))
                        }
                        
                        if let receiptNumber = data.receiptNumber {
                            detailRow(title: "Receipt #", value: receiptNumber)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Add subscription button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Add to Subscriptions")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Design.Colors.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Try again button
                Button("Scan Another Receipt") {
                    selectedImage = nil
                    parsedReceiptData = nil
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Design.Colors.textSecondary)
                .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Detail Row
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Design.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Design.Colors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Design.Colors.surfaceSecondary)
        .cornerRadius(10)
    }
    
    // MARK: - Process Image
    private func processImage(_ image: UIImage) async {
        let result = await receiptScanner.scanReceipt(from: image)
        
        DispatchQueue.main.async {
            self.parsedReceiptData = result
        }
    }
    
    // MARK: - Camera Initialization
    private func initializeCameraAvailability() {
        // Pre-check camera availability and permissions on appear
        if !isRunningOnSimulator && UIImagePickerController.isSourceTypeAvailable(.camera) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Debug: // Debug: print("🎬 Camera pre-check - Status: \(status.rawValue)")
            
            // Pre-warm camera if already authorized
            if status == .authorized {
                cameraInitialized = true
                // Debug: // Debug: print("✅ Camera pre-initialized and ready")
            } else if status == .notDetermined {
                // Don't request permission yet, but mark as available
                // Debug: // Debug: print("🔔 Camera available but permission not determined")
            }
        }
    }
    
    // MARK: - Camera Permissions
    private func requestCameraAccess() {
        // Debug: // Debug: print("📸 ReceiptScanView: Requesting camera access...")
        
        // Check if we're on simulator first
        if isRunningOnSimulator {
            // Debug: // Debug: print("📱 ReceiptScanView: Running on simulator, showing alert")
            showingCameraUnavailableAlert = true
            return
        }
        
        // Check if camera source type is available
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Debug: // Debug: print("📷 ReceiptScanView: Camera source type not available")
            showingCameraUnavailableAlert = true
            return
        }
        
          
        // Check current permission status
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        // Debug: // Debug: print("🔐 ReceiptScanView: Camera auth status: \(cameraAuthStatus.rawValue)")
        
        // Handle camera permissions
        switch cameraAuthStatus {
        case .authorized:
            // Camera access already granted, open immediately
            // Debug: // Debug: print("✅ Camera already authorized, opening immediately")
            DispatchQueue.main.async {
                // Debug: // Debug: print("📷 Opening camera picker directly")
                self.showingCameraPicker = true
            }
            
        case .notDetermined:
            // Request camera permission
            // Debug: // Debug: print("🔔 Requesting camera permission...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Debug: // Debug: print("✅ Camera permission granted by user")
                        // Debug: // Debug: print("📷 Opening camera picker after permission granted")
                        self.showingCameraPicker = true
                    } else {
                        // Debug: // Debug: print("❌ Camera permission denied by user")
                        self.showingCameraUnavailableAlert = true
                    }
                }
            }
            
        case .denied, .restricted:
            // Camera access denied or restricted, show alert
            // Debug: // Debug: print("🚫 Camera access denied or restricted")
            DispatchQueue.main.async {
                self.showingCameraUnavailableAlert = true
            }
            
        @unknown default:
            // Unknown case, show alert
            // Debug: // Debug: print("❓ Unknown camera permission state")
            DispatchQueue.main.async {
                self.showingCameraUnavailableAlert = true
            }
        }
    }
    
    // This function is now integrated into requestCameraAccess
    // Keeping for backward compatibility if needed
    private func handleCameraPermission(status: AVAuthorizationStatus) {
        // Deprecated - functionality moved to requestCameraAccess
        // Debug: // Debug: print("⚠️ handleCameraPermission called - this is deprecated")
        requestCameraAccess()
    }
}

// MARK: - Receipt Confirmation Sheet
struct ReceiptConfirmationSheet: View {
    let receiptData: ReceiptScanner.ParsedReceiptData
    @ObservedObject var subscriptionStore: SubscriptionStore
    @Binding var isPresented: Bool
    
    @StateObject private var receiptScanner = ReceiptScanner()
    @State private var isCreating = false
    
    var onSave: ((Subscription?) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Confirm Subscription Details")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.top, 20)
                
                // Details preview
                VStack(spacing: 12) {
                    if let serviceName = receiptData.serviceName {
                        Text(serviceName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Design.Colors.textPrimary)
                    }
                    
                    if let amount = receiptData.amount {
                        let billingPeriod = formatBillingPeriod(receiptData.subscriptionType)
                        
                        // Show converted amount (primary display)
                        Text("\(receiptData.currency ?? "USD") \(String(format: "%.2f", amount))\(billingPeriod)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Design.Colors.success)
                        
                        // Show original amount if converted
                        if let originalAmount = receiptData.originalAmount,
                           let originalCurrency = receiptData.originalCurrency,
                           originalCurrency != receiptData.currency {
                            VStack(spacing: 4) {
                                Text("Original: \(originalCurrency) \(String(format: "%.2f", originalAmount))\(billingPeriod)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                Text("Converted to \(receiptData.currency ?? "USD") for tracking")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Design.Colors.textTertiary)
                            }
                        }
                    }
                    
                    if let subscriptionType = receiptData.subscriptionType {
                        Text("Billing: \(subscriptionType.capitalized)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                    
                    if let date = receiptData.date {
                        Text("Start Date: \(DateFormatter.mediumStyle.string(from: date))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Design.Colors.surfaceSecondary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await createSubscription()
                        }
                    }) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(isCreating ? "Adding..." : "Add Subscription")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Design.Colors.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isCreating)
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createSubscription() async {
        // Debug: // Debug: print("🔄 ReceiptConfirmationSheet: Creating subscription...")
        isCreating = true
        
        let subscription = receiptScanner.createSubscriptionFromReceipt(receiptData, subscriptionStore: subscriptionStore)
        
        DispatchQueue.main.async {
            self.isCreating = false
            
            // Debug: // Debug: print("✅ ReceiptConfirmationSheet: Subscription created successfully")
            // Refresh the subscription store to ensure the new subscription appears
            self.subscriptionStore.fetchSubscriptions()
            
            // Call the onSave callback if provided
            self.onSave?(subscription)
            
            // Dismiss the sheet
            self.isPresented = false
        }
    }
    
    private func formatBillingPeriod(_ subscriptionType: String?) -> String {
        guard let type = subscriptionType else { return "/month" }
        
        switch type.lowercased() {
        case "yearly", "annual":
            return "/year"
        case "quarterly":
            return "/quarter"
        case "weekly":
            return "/week"
        case "monthly":
            return "/month"
        case "semi-annual", "biannual":
            return "/6 months"
        default:
            return "/month"
        }
    }
}

  // MARK: - Direct Image Picker View (Bypasses SwiftUI State Issues)
struct DirectImagePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        // Debug: // Debug: print("🎬 DirectImagePickerView: Creating picker with sourceType: \(sourceType == .camera ? "camera" : "photoLibrary")")
        
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Set source type immediately and directly
        picker.sourceType = sourceType
        // Debug: // Debug: print("✅ Direct setting picker source to: \(sourceType == .camera ? "camera" : "photoLibrary")")
        
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image"]
        
        // Force immediate source type update
        DispatchQueue.main.async {
            picker.sourceType = sourceType
            // Debug: // Debug: print("🔄 Forcing picker source type update to: \(sourceType == .camera ? "camera" : "photoLibrary")")
        }
        
        // Debug: // Debug: print("📷 Final picker source type: \(picker.sourceType == .camera ? "camera" : "photoLibrary")")
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Ensure the picker stays updated with the correct source type
        DispatchQueue.main.async {
            if uiViewController.sourceType != sourceType {
                // Debug: // Debug: print("🔄 Correcting picker source type from \(uiViewController.sourceType == .camera ? "camera" : "photoLibrary") to \(sourceType == .camera ? "camera" : "photoLibrary")")
                uiViewController.sourceType = sourceType
            }
        }
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: DirectImagePickerView
        
        init(_ parent: DirectImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Ensure correct source type was used
            // Debug: // Debug: print("📸 Picker finished with sourceType: \(picker.sourceType == .camera ? "camera" : "photoLibrary")")
            
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImageSelected(originalImage)
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Debug: // Debug: print("🚫 Picker cancelled with sourceType: \(picker.sourceType == .camera ? "camera" : "photoLibrary")")
            parent.isPresented = false
        }
    }
}

// MARK: - DateFormatter Extension
fileprivate extension DateFormatter {
    static let mediumStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
