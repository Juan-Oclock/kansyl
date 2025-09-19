//
//  LoginView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//  Modern sleek login design
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSignUp = false
    @State private var showingEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var logoAnimation = false
    @State private var contentAnimation = false
    @State private var buttonAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Design.Colors.background,
                        Design.Colors.background.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer(minLength: geometry.size.height * 0.08)
                    
                    // Modern app branding
                    VStack(spacing: Design.Spacing.xxl) {
                        // Sleek logo and title
                        VStack(spacing: Design.Spacing.lg) {
                            Text("Kansyl")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Design.Colors.primary, Design.Colors.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .scaleEffect(logoAnimation ? 1.0 : 0.8)
                                .opacity(logoAnimation ? 1.0 : 0.0)
                                .animation(Design.Animation.spring.delay(0.2), value: logoAnimation)
                            
                            VStack(spacing: Design.Spacing.sm) {
                                Text("Welcome back")
                                    .font(Design.Typography.title2(.semibold))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                Text("Sign in to continue tracking your subscriptions")
                                    .font(Design.Typography.callout(.medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(contentAnimation ? 1.0 : 0.0)
                            .offset(y: contentAnimation ? 0 : 20)
                            .animation(Design.Animation.spring.delay(0.5), value: contentAnimation)
                        }
                        
                        // Modern authentication options
                        VStack(spacing: Design.Spacing.lg) {
                            // Apple Sign In - Modern styling
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result)
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 56)
                            .cornerRadius(Design.Radius.lg)
                            .shadow(
                                color: Design.Colors.textPrimary.opacity(0.1),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            
                            // Google Sign In - Modern styling
                            Button(action: {
                                Task {
                                    await handleGoogleSignIn()
                                }
                            }) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("Continue with Google")
                                        .font(Design.Typography.headline(.semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(.white)
                                )
                                .cornerRadius(Design.Radius.lg)
                                .shadow(
                                    color: Design.Colors.textPrimary.opacity(0.1),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            }
                            
                            // Email Sign In - Modern styling
                            Button(action: {
                                showingEmailLogin = true
                            }) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("Continue with Email")
                                        .font(Design.Typography.headline(.semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(.white)
                                )
                                .cornerRadius(Design.Radius.lg)
                                .shadow(
                                    color: Design.Colors.textPrimary.opacity(0.1),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            }
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                        .offset(y: buttonAnimation ? 0 : 30)
                        .animation(Design.Animation.spring.delay(0.8), value: buttonAnimation)
                        
                    }
                    
                    Spacer(minLength: geometry.size.height * 0.08)
                    
                    // Modern loading and error states
                    VStack(spacing: Design.Spacing.lg) {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(height: 40)
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(Design.Typography.callout(.medium))
                                .foregroundColor(Design.Colors.danger)
                                .padding(.horizontal, Design.Spacing.xl)
                                .padding(.vertical, Design.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.sm)
                                        .fill(Design.Colors.danger.opacity(0.1))
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.xl)
                    
                    Spacer(minLength: geometry.size.height * 0.05)
                    
                    // Modern sign up section
                    VStack(spacing: Design.Spacing.lg) {
                        // Elegant divider
                        HStack(spacing: Design.Spacing.md) {
                            Rectangle()
                                .fill(Design.Colors.border.opacity(0.5))
                                .frame(height: 1)
                            
                            Text("New to Kansyl?")
                                .font(Design.Typography.caption(.medium))
                                .foregroundColor(Design.Colors.textSecondary)
                                .padding(.horizontal, Design.Spacing.sm)
                            
                            Rectangle()
                                .fill(Design.Colors.border.opacity(0.5))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        
                        // Sign up button
                        Button(action: {
                            showingSignUp = true
                        }) {
                            Text("Create Account")
                                .font(Design.Typography.headline(.semibold))
                                .foregroundColor(Design.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .stroke(Design.Colors.primary.opacity(0.3), lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: Design.Radius.lg)
                                                .fill(Design.Colors.primary.opacity(0.05))
                                        )
                                )
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        
                        // Terms and Privacy - Modern styling
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(Design.Typography.caption(.regular))
                            .foregroundColor(Design.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.xl)
                    }
                    .opacity(buttonAnimation ? 1.0 : 0.0)
                    .animation(Design.Animation.spring.delay(1.2), value: buttonAnimation)
                    
                    Spacer(minLength: Design.Spacing.xl)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
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
    
    private func startAnimationSequence() {
        // Stagger animations for smooth entrance
        withAnimation {
            logoAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                contentAnimation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                buttonAnimation = true
            }
        }
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
        case .failure(_):
            // Apple Sign In failed - error is handled by auth manager
            return
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var formAnimation = false
    @State private var buttonAnimation = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Modern header
                    VStack(spacing: Design.Spacing.lg) {
                        // Close indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Design.Colors.border)
                            .frame(width: 40, height: 6)
                            .padding(.top, Design.Spacing.sm)
                        
                        VStack(spacing: Design.Spacing.sm) {
                            Text("Sign In")
                                .font(Design.Typography.title2(.bold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            Text("Enter your credentials to access your account")
                                .font(Design.Typography.callout(.medium))
                                .foregroundColor(Design.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(formAnimation ? 1.0 : 0.0)
                        .offset(y: formAnimation ? 0 : 20)
                        .animation(Design.Animation.spring.delay(0.2), value: formAnimation)
                    }
                    .padding(.horizontal, Design.Spacing.xl)
                    .padding(.top, Design.Spacing.md)
                
                    Spacer(minLength: geometry.size.height * 0.05)
                    
                    // Modern form
                    VStack(spacing: Design.Spacing.xl) {
                        // Email field - Modern styling
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Email")
                                .font(Design.Typography.callout(.semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .font(Design.Typography.body(.medium))
                                .padding(.horizontal, Design.Spacing.lg)
                                .padding(.vertical, Design.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Design.Radius.lg)
                                                .stroke(Design.Colors.border.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password field - Modern styling
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Password")
                                .font(Design.Typography.callout(.semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            HStack(spacing: Design.Spacing.md) {
                                Group {
                                    if showingPassword {
                                        TextField("Enter your password", text: $password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                    }
                                }
                                .font(Design.Typography.body(.medium))
                                
                                Button(action: {
                                    showingPassword.toggle()
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Design.Colors.textSecondary)
                                }
                            }
                            .padding(.horizontal, Design.Spacing.lg)
                            .padding(.vertical, Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.lg)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Design.Radius.lg)
                                            .stroke(Design.Colors.border.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .textContentType(.password)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.xl)
                    .opacity(formAnimation ? 1.0 : 0.0)
                    .offset(y: formAnimation ? 0 : 30)
                    .animation(Design.Animation.spring.delay(0.4), value: formAnimation)
                
                    Spacer(minLength: geometry.size.height * 0.05)
                    
                    // Modern sign in button
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
                        HStack(spacing: Design.Spacing.sm) {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                            }
                            
                            Text(authManager.isLoading ? "Signing In..." : "Sign In")
                                .font(Design.Typography.headline(.semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Design.Colors.buttonPrimary, Design.Colors.buttonPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Design.Radius.lg)
                        .shadow(
                            color: Design.Colors.buttonPrimary.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                        .scaleEffect(buttonAnimation ? 1.0 : 0.95)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                        .animation(Design.Animation.spring.delay(0.6), value: buttonAnimation)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .padding(.horizontal, Design.Spacing.xl)
                
                    
                    // Modern error message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(Design.Typography.callout(.medium))
                            .foregroundColor(Design.Colors.danger)
                            .padding(.horizontal, Design.Spacing.lg)
                            .padding(.vertical, Design.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.sm)
                                    .fill(Design.Colors.danger.opacity(0.1))
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.xl)
                    }
                    
                    Spacer()
                }
            }
            .background(Design.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        formAnimation = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        buttonAnimation = true
                    }
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
