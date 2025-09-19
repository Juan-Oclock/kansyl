//
//  LoginView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @State private var showingSignUp = false
    @State private var showingEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Design.Colors.background,
                        Design.Colors.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // App branding
                        VStack(spacing: 16) {
                            // App icon or logo
                            Image(systemName: "creditcard.and.123")
                                .font(.system(size: 80, weight: .thin))
                                .foregroundColor(Design.Colors.primary)
                            
                            VStack(spacing: 8) {
                                Text("Welcome to Kansyl")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                Text("Never forget to cancel a trial again")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 60)
                        
                        // Authentication options
                        VStack(spacing: 16) {
                            // Apple Sign In
                            SignInWithAppleButton(.signIn) { request in
                                // Configure the request
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result)
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)
                            
                            // Google Sign In
                            Button(action: {
                                Task {
                                    await handleGoogleSignIn()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            // Email Sign In
                            Button(action: {
                                showingEmailLogin = true
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Continue with Email")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Design.Colors.buttonPrimary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Loading state
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                        }
                        
                        // Error message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 32)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign up link
                        VStack(spacing: 16) {
                            HStack {
                                Rectangle()
                                    .fill(Design.Colors.border)
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                
                                Rectangle()
                                    .fill(Design.Colors.border)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 32)
                            
                            Button(action: {
                                showingSignUp = true
                            }) {
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(Design.Colors.textSecondary)
                                    Text("Sign up")
                                        .foregroundColor(Design.Colors.primary)
                                        .fontWeight(.semibold)
                                }
                                .font(.system(size: 16))
                            }
                        }
                        
                        Spacer(minLength: 32)
                        
                        // Terms and Privacy
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Design.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEmailLogin) {
            EmailLoginView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
        .disabled(authManager.isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let identityToken = appleIDCredential.identityToken,
                      let tokenString = String(data: identityToken, encoding: .utf8) else {
                    return
                }
                
                do {
                    // For Apple Sign In, we need to use the identity token and nonce
                    // For now, we'll use a simple nonce. In production, you should generate a proper nonce.
                    let nonce = UUID().uuidString
                    try await authManager.signInWithApple(idToken: tokenString, nonce: nonce)
                } catch {
                    // Error is handled by the auth manager
                }
            }
        case .failure(let error):
            // Debug: print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    private func handleGoogleSignIn() async {
        // Google Sign In is temporarily disabled until GoogleSignIn SDK is properly configured
        authManager.errorMessage = "Google Sign In is temporarily unavailable. Please use Apple Sign In or Email."
    }
}

// MARK: - Email Login View

struct EmailLoginView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Sign In")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                    
                    Text("Enter your email and password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                }
                .padding(.top, 32)
                
                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        HStack {
                            if showingPassword {
                                TextField("Enter your password", text: $password)
                            } else {
                                SecureField("Enter your password", text: $password)
                            }
                            
                            Button(action: {
                                showingPassword.toggle()
                            }) {
                                Image(systemName: showingPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Design.Colors.textSecondary)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                    }
                }
                .padding(.horizontal, 32)
                
                // Sign in button
                Button(action: {
                    Task {
                        do {
                            try await authManager.signIn(email: email, password: password)
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            // Error is handled by the auth manager's errorMessage property
                        }
                    }
                }) {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Design.Colors.buttonPrimary)
                        .cornerRadius(12)
                }
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                .padding(.horizontal, 32)
                
                // Loading
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
                
                // Error message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .background(Design.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
