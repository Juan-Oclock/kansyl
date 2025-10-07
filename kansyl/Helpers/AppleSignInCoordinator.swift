//
//  AppleSignInCoordinator.swift
//  kansyl
//
//  Created by Juan Oclock on 10/3/25.
//  Coordinates Sign in with Apple authentication flow
//

import Foundation
import AuthenticationServices
import CryptoKit

/// Coordinates the Sign in with Apple authentication flow
/// Handles ASAuthorizationController delegate callbacks and communicates with SupabaseAuthManager
@MainActor
class AppleSignInCoordinator: NSObject, ObservableObject {
    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    
    struct AppleSignInResult {
        let idToken: String
        let nonce: String
        let fullName: PersonNameComponents?
        let email: String?
    }
    
    /// Start Sign in with Apple authentication flow
    func signIn() async throws -> AppleSignInResult {
        print("🍎 [AppleSignInCoordinator] Starting Sign in with Apple flow")
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Generate a random nonce for security
            let nonce = generateNonce()
            self.currentNonce = nonce
            
            print("🔐 [AppleSignInCoordinator] Generated nonce")
            
            // Create the Apple ID request
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            print("📝 [AppleSignInCoordinator] Created authorization request with scopes: fullName, email")
            
            // Create and configure the authorization controller
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            print("🚀 [AppleSignInCoordinator] Performing authorization request")
            controller.performRequests()
        }
    }
    
    // MARK: - Nonce Generation
    
    /// Generate a cryptographically secure random nonce
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Create SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ [AppleSignInCoordinator] Authorization completed successfully")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ [AppleSignInCoordinator] Failed to get Apple ID credential")
            continuation?.resume(throwing: AppleSignInError.invalidCredential)
            continuation = nil
            return
        }
        
        print("📧 [AppleSignInCoordinator] User ID: \(appleIDCredential.user)")
        if let email = appleIDCredential.email {
            print("📧 [AppleSignInCoordinator] Email: \(email)")
        }
        if let fullName = appleIDCredential.fullName {
            print("👤 [AppleSignInCoordinator] Full name: \(fullName.givenName ?? "") \(fullName.familyName ?? "")")
        }
        
        guard let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            print("❌ [AppleSignInCoordinator] Failed to get identity token")
            continuation?.resume(throwing: AppleSignInError.missingToken)
            continuation = nil
            return
        }
        
        print("🎫 [AppleSignInCoordinator] Got identity token")
        
        guard let nonce = currentNonce else {
            print("❌ [AppleSignInCoordinator] Missing nonce")
            continuation?.resume(throwing: AppleSignInError.missingNonce)
            continuation = nil
            return
        }
        
        print("✅ [AppleSignInCoordinator] Nonce verified")
        
        let result = AppleSignInResult(
            idToken: idTokenString,
            nonce: nonce,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )
        
        print("🎉 [AppleSignInCoordinator] Sign in completed successfully")
        continuation?.resume(returning: result)
        continuation = nil
        currentNonce = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ [AppleSignInCoordinator] Authorization failed with error: \(error)")
        print("❌ [AppleSignInCoordinator] Error details: \(error.localizedDescription)")
        
        // Check if user cancelled
        if let authError = error as? ASAuthorizationError {
            print("❌ [AppleSignInCoordinator] ASAuthorizationError code: \(authError.code.rawValue)")
            
            switch authError.code {
            case .canceled:
                print("⚠️ [AppleSignInCoordinator] User cancelled Sign in with Apple")
                continuation?.resume(throwing: AppleSignInError.cancelled)
            case .unknown:
                print("❌ [AppleSignInCoordinator] Unknown authorization error")
                continuation?.resume(throwing: AppleSignInError.unknownError)
            case .invalidResponse:
                print("❌ [AppleSignInCoordinator] Invalid response from Apple")
                continuation?.resume(throwing: AppleSignInError.invalidResponse)
            case .notHandled:
                print("❌ [AppleSignInCoordinator] Authorization not handled")
                continuation?.resume(throwing: AppleSignInError.notHandled)
            case .failed:
                print("❌ [AppleSignInCoordinator] Authorization failed")
                continuation?.resume(throwing: AppleSignInError.authorizationFailed)
            @unknown default:
                print("❌ [AppleSignInCoordinator] Unexpected authorization error: \(authError.code.rawValue)")
                continuation?.resume(throwing: error)
            }
        } else {
            print("❌ [AppleSignInCoordinator] Non-ASAuthorizationError: \(type(of: error))")
            continuation?.resume(throwing: error)
        }
        
        continuation = nil
        currentNonce = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for presenting the authorization UI
        // Updated for iOS 26+ compatibility
        print("🪟 [AppleSignInCoordinator] Finding presentation window...")
        print("📱 [AppleSignInCoordinator] iOS Version: \(UIDevice.current.systemVersion)")
        
        let scenes = UIApplication.shared.connectedScenes
        print("🔍 [AppleSignInCoordinator] Found \(scenes.count) connected scenes")
        
        let windowScenes = scenes.compactMap { $0 as? UIWindowScene }
        print("🔍 [AppleSignInCoordinator] Found \(windowScenes.count) window scenes")
        
        // Try to find the active key window first
        if let keyWindow = windowScenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            print("✅ [AppleSignInCoordinator] Found key window for presentation")
            return keyWindow
        }
        
        // Fall back to the first window that is visible
        if let visibleWindow = windowScenes
            .flatMap({ $0.windows })
            .first(where: { !$0.isHidden }) {
            print("⚠️ [AppleSignInCoordinator] Using first visible window (no key window found)")
            return visibleWindow
        }
        
        // Last resort: return any window
        if let anyWindow = windowScenes.first?.windows.first {
            print("⚠️ [AppleSignInCoordinator] Using first available window")
            return anyWindow
        }
        
        // Create emergency window if absolutely necessary
        print("❌ [AppleSignInCoordinator] No windows found, creating emergency window")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        return window
    }
}

// MARK: - Error Types

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingToken
    case missingNonce
    case cancelled
    case unknownError
    case invalidResponse
    case notHandled
    case authorizationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received. Please try again."
        case .missingToken:
            return "Failed to get identity token from Apple. Please try again."
        case .missingNonce:
            return "Security nonce is missing. Please try again."
        case .cancelled:
            return "Sign in with Apple was cancelled"
        case .unknownError:
            return "An unknown error occurred. Please try again."
        case .invalidResponse:
            return "Invalid response from Apple. Please check your internet connection and try again."
        case .notHandled:
            return "Sign in request was not handled. Please try again."
        case .authorizationFailed:
            return "Authorization failed. Please make sure you're signed in to iCloud and try again."
        }
    }
}
