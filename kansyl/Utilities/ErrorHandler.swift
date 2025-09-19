//
//  ErrorHandler.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

// MARK: - Error Types
enum KansylError: LocalizedError, Identifiable {
    case trialLimitReached
    case notificationPermissionDenied
    case networkError(String)
    case dataError(String)
    case purchaseError(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .trialLimitReached:
            return "trialLimitReached"
        case .notificationPermissionDenied:
            return "notificationPermissionDenied"
        case .networkError(let message):
            return "networkError_\(message)"
        case .dataError(let message):
            return "dataError_\(message)"
        case .purchaseError(let message):
            return "purchaseError_\(message)"
        case .unknown(let message):
            return "unknown_\(message)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .trialLimitReached:
            return "Trial Limit Reached"
        case .notificationPermissionDenied:
            return "Notification Permission Required"
        case .networkError:
            return "Network Error"
        case .dataError:
            return "Data Error"
        case .purchaseError:
            return "Purchase Error"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .trialLimitReached:
            return "You've reached the maximum number of free trials. Upgrade to Premium to add unlimited trials."
        case .notificationPermissionDenied:
            return "Please enable notifications in Settings to receive trial reminders."
        case .networkError(let message):
            return message
        case .dataError(let message):
            return message
        case .purchaseError(let message):
            return message
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .trialLimitReached:
            return "Tap 'Upgrade' to unlock Premium features"
        case .notificationPermissionDenied:
            return "Go to Settings > Kansyl > Notifications"
        case .networkError:
            return "Check your internet connection and try again"
        case .dataError:
            return "Try restarting the app"
        case .purchaseError:
            return "Try again or contact support"
        case .unknown:
            return "Please try again"
        }
    }
    
    var icon: String {
        switch self {
        case .trialLimitReached:
            return "crown.fill"
        case .notificationPermissionDenied:
            return "bell.slash.fill"
        case .networkError:
            return "wifi.slash"
        case .dataError:
            return "exclamationmark.triangle.fill"
        case .purchaseError:
            return "creditcard.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlert: ViewModifier {
    @Binding var error: KansylError?
    var primaryAction: (() -> Void)?
    var secondaryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text(error.errorDescription ?? "Error"),
                    message: Text(error.failureReason ?? "An unexpected error occurred"),
                    primaryButton: .default(Text(primaryButtonText(for: error))) {
                        handlePrimaryAction(for: error)
                    },
                    secondaryButton: .cancel()
                )
            }
    }
    
    private func primaryButtonText(for error: KansylError) -> String {
        switch error {
        case .trialLimitReached:
            return "Upgrade"
        case .notificationPermissionDenied:
            return "Open Settings"
        default:
            return "OK"
        }
    }
    
    private func handlePrimaryAction(for error: KansylError) {
        switch error {
        case .trialLimitReached:
            primaryAction?()
        case .notificationPermissionDenied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            primaryAction?()
        }
    }
}

extension View {
    func errorAlert(_ error: Binding<KansylError?>, primaryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, primaryAction: primaryAction))
    }
}

// MARK: - Error Banner View
struct ErrorBanner: View {
    let error: KansylError
    let dismiss: () -> Void
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .font(.title3)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "Error")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let reason = error.failureReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red)
        )
        .shadow(radius: 10)
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onAppear {
            withAnimation(.spring()) {
                isShowing = true
            }
            
            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Error Logging
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private init() {}
    
    func log(_ error: Error, context: String? = nil) {
        #if DEBUG
        // Debug: print("🔴 Error: \(error.localizedDescription)")
        if context != nil {
            // Debug: print("   Context: \(context!)")
        }
        // Debug: print("   Stack: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n          "))")
        #endif
        
        // In production, you would send this to a crash reporting service
        // Example: Crashlytics.crashlytics().record(error: error)
    }
    
    func logWarning(_ message: String) {
        #if DEBUG
        // Debug: print("⚠️ Warning: \(message)")
        #endif
    }
    
    func logInfo(_ message: String) {
        #if DEBUG
        // Debug: print("ℹ️ Info: \(message)")
        #endif
    }
}

// MARK: - Result Extensions
extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var isFailure: Bool {
        !isSuccess
    }
    
    var errorValue: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
