//
//  SuccessToastView.swift
//  kansyl
//
//  Success toast notification for positive actions
//

import SwiftUI

struct SuccessToastView: View {
    let message: String
    let savedAmount: String?
    @Binding var isShowing: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Design.Colors.success)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Message content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        if let savedAmount = savedAmount {
                            Text("You saved \(savedAmount)/month! 🎉")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Design.Colors.success)
                        }
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Colors.surface)
                        .shadow(
                            color: Design.Colors.success.opacity(0.2),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .scaleEffect(isAnimating ? 1.0 : 0.95)
                .onAppear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAnimating = true
                    }
                    
                    // Auto dismiss after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var showSuccessToast = false
    @Published var toastMessage = ""
    @Published var savedAmount: String? = nil
    
    private init() {}
    
    func showSuccess(message: String, savedAmount: String? = nil) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.savedAmount = savedAmount
            self.showSuccessToast = true
        }
    }
    
    func hideToast() {
        DispatchQueue.main.async {
            self.showSuccessToast = false
        }
    }
}