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
        
        // Check if user cancelled
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                print("⚠️ [AppleSignInCoordinator] User cancelled Sign in with Apple")
                continuation?.resume(throwing: AppleSignInError.cancelled)
            } else {
                print("❌ [AppleSignInCoordinator] Authorization error code: \(authError.code.rawValue)")
                continuation?.resume(throwing: error)
            }
        } else {
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("⚠️ [AppleSignInCoordinator] Could not find key window, using first window")
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
        
        return window
    }
}

// MARK: - Error Types

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingToken
    case missingNonce
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received"
        case .missingToken:
            return "Failed to get identity token from Apple"
        case .missingNonce:
            return "Security nonce is missing"
        case .cancelled:
            return "Sign in with Apple was cancelled"
        }
    }
}
