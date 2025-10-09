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
    @EnvironmentObject private var userStateManager: UserStateManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()
    @State private var showingEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var logoAnimation = false
    @State private var contentAnimation = false
    @State private var buttonAnimation = false
    @State private var showingAnonymousModeAlert = false
    
    // New parameter to control whether to show Continue Without Account
    var hideAnonymousOption: Bool = false
    
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
                                Text("Welcome")
                                    .font(Design.Typography.title2(.semibold))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                Text("Choose how you'd like to continue")
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
                            // Apple Sign In - Real implementation
                            Button(action: {
                                Task {
                                    await handleAppleSignIn()
                                }
                            }) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("Continue with Apple")
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
                    
                    Spacer(minLength: geometry.size.height * 0.06)
                    
                    // Alternative option section
                    VStack(spacing: Design.Spacing.lg) {
                        // Continue Without Account button - Only show if not already in anonymous mode
                        if !hideAnonymousOption && !userStateManager.isAnonymousMode {
                            Button(action: {
                                showingAnonymousModeAlert = true
                            }) {
                                Text("Continue Without Account")
                                    .font(Design.Typography.subheadline(.medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .underline()
                            }
                            .padding(.horizontal, Design.Spacing.xl)
                        }
                        
                        // Terms and Privacy - Modern styling with functional links
                        VStack(spacing: Design.Spacing.xs) {
                            Text("By continuing, you agree to our")
                                .font(Design.Typography.caption(.regular))
                                .foregroundColor(Design.Colors.textSecondary)
                            
                            HStack(spacing: 4) {
                                Button(action: {
                                    if let url = URL(string: "https://raw.githubusercontent.com/juan-oclock/kansyl/main/TERMS_OF_SERVICE.md") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Terms of Service")
                                        .font(Design.Typography.caption(.semibold))
                                        .foregroundColor(Design.Colors.primary)
                                        .underline()
                                }
                                
                                Text("and")
                                    .font(Design.Typography.caption(.regular))
                                    .foregroundColor(Design.Colors.textSecondary)
                                
                                Button(action: {
                                    if let url = URL(string: "https://raw.githubusercontent.com/juan-oclock/kansyl/main/PRIVACY_POLICY.md") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Privacy Policy")
                                        .font(Design.Typography.caption(.semibold))
                                        .foregroundColor(Design.Colors.primary)
                                        .underline()
                                }
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.top, Design.Spacing.sm)
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
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            print("🔍 [LoginView] onChange triggered - isAuthenticated: \(isAuthenticated), isAnonymousMode: \(userStateManager.isAnonymousMode)")
            // Dismiss immediately when authenticated (whether from anonymous mode or not)
            if isAuthenticated {
                print("✅ [LoginView] User authenticated successfully, dismissing login view")
                // Small delay to ensure auth state is fully propagated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEmailLogin) {
            EmailLoginView()
                .environmentObject(authManager)
        }
        .alert("Continue Without Account?", isPresented: $showingAnonymousModeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                Task { @MainActor in
                    print("🔵 [LoginView] User confirmed anonymous mode")
                    userStateManager.enterAnonymousMode()
                    print("🔵 [LoginView] After enterAnonymousMode(), currentUserID = \(SubscriptionStore.currentUserID ?? "nil")")
                }
            }
        } message: {
            Text("Without an account, your subscriptions will only be saved on this device and won't be backed up to the cloud. You can create an account later in Settings.")
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
    
    private func handleAppleSignIn() async {
        print("🍎 [LoginView] handleAppleSignIn called")
        
        // Clear any previous errors
        authManager.errorMessage = nil
        
        do {
            // Use the coordinator to handle the Apple Sign In flow
            let result = try await appleSignInCoordinator.signIn()
            print("✅ [LoginView] Apple Sign In coordinator completed successfully")
            
            // Pass the result to the auth manager
            try await authManager.signInWithApple(
                idToken: result.idToken,
                nonce: result.nonce,
                fullName: result.fullName
            )
            print("✅ [LoginView] Apple Sign In completed successfully")
            // The onChange handler will dismiss the view
        } catch AppleSignInError.cancelled {
            // User cancelled - don't show error
            print("⚠️ [LoginView] User cancelled Apple Sign In")
            authManager.errorMessage = nil
        } catch let error as AppleSignInError {
            // Handle specific Apple Sign In errors with user-friendly messages
            print("❌ [LoginView] Apple Sign In error: \(error.localizedDescription)")
            authManager.errorMessage = error.localizedDescription
        } catch {
            // Handle any other errors
            print("❌ [LoginView] Apple Sign In failed with unexpected error: \(error.localizedDescription)")
            authManager.errorMessage = error.localizedDescription
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await authManager.signInWithGoogle()
            // The onChange handler will dismiss the view
        } catch {
            // Error is handled by the auth manager
        }
    }
}

// MARK: - Email Login View

struct EmailLoginView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var formAnimation = false
    @State private var buttonAnimation = false
    @State private var headerAnimation = false
    
    var body: some View {
        NavigationView {
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
                        // Modern sleek header
                        VStack(spacing: Design.Spacing.xl) {
                            // Close indicator - more subtle
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Design.Colors.border.opacity(0.4))
                                .frame(width: 36, height: 4)
                                .padding(.top, Design.Spacing.md)
                                .scaleEffect(headerAnimation ? 1.0 : 0.8)
                                .opacity(headerAnimation ? 1.0 : 0.0)
                                .animation(Design.Animation.spring.delay(0.1), value: headerAnimation)
                            
                            VStack(spacing: Design.Spacing.md) {
                                Text("Continue with Email")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Design.Colors.primary, Design.Colors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Enter your email and password")
                                    .font(Design.Typography.body(.medium))
                                    .foregroundColor(Design.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                Text("New users will be signed up automatically")
                                    .font(Design.Typography.caption(.regular))
                                    .foregroundColor(Design.Colors.textSecondary.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(formAnimation ? 1.0 : 0.0)
                            .offset(y: formAnimation ? 0 : 20)
                            .animation(Design.Animation.spring.delay(0.3), value: formAnimation)
                        }
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.top, Design.Spacing.lg)
                    
                        Spacer(minLength: geometry.size.height * 0.08)
                    
                    // Sleek modern form
                    VStack(spacing: Design.Spacing.xxl) {
                        // Email field - Sleek styling
                        VStack(alignment: .leading, spacing: Design.Spacing.md) {
                            Text("Email")
                                .font(Design.Typography.callout(.semibold))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .font(Design.Typography.body(.medium))
                                .foregroundColor(Design.Colors.textPrimary)
                                .tint(Design.Colors.primary)
                                .padding(.horizontal, Design.Spacing.lg)
                                .padding(.vertical, Design.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.xl)
                                        .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : .white)
                                        .shadow(
                                            color: Design.Colors.textPrimary.opacity(0.05),
                                            radius: 8,
                                            x: 0,
                                            y: 2
                                        )
                                )
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password field - Sleek styling
                        VStack(alignment: .leading, spacing: Design.Spacing.md) {
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
                                .foregroundColor(Design.Colors.textPrimary)
                                .tint(Design.Colors.primary)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showingPassword.toggle()
                                    }
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Design.Colors.textSecondary)
                                        .scaleEffect(showingPassword ? 1.1 : 1.0)
                                }
                            }
                            .padding(.horizontal, Design.Spacing.lg)
                            .padding(.vertical, Design.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.xl)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : .white)
                                    .shadow(
                                        color: Design.Colors.textPrimary.opacity(0.05),
                                        radius: 8,
                                        x: 0,
                                        y: 2
                                    )
                            )
                            .textContentType(.password)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.xl)
                    .opacity(formAnimation ? 1.0 : 0.0)
                    .offset(y: formAnimation ? 0 : 30)
                    .animation(Design.Animation.spring.delay(0.5), value: formAnimation)
                
                    Spacer(minLength: geometry.size.height * 0.08)
                    
                    // Sleek continue button
                    Button(action: {
                        Task {
                            await handleEmailAuth()
                        }
                    }) {
                        HStack(spacing: Design.Spacing.sm) {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(colorScheme == .dark ? Color(hex: "0A0A0A") : .white)
                            }
                            
                            Text(authManager.isLoading ? "Processing..." : "Continue")
                                .font(Design.Typography.headline(.semibold))
                                .foregroundColor(colorScheme == .dark ? Color(hex: "0A0A0A") : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Design.Colors.primary, Design.Colors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Design.Radius.xl)
                        .shadow(
                            color: Design.Colors.primary.opacity(0.3),
                            radius: 16,
                            x: 0,
                            y: 8
                        )
                        .scaleEffect(buttonAnimation ? 1.0 : 0.95)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                        .animation(Design.Animation.spring.delay(0.7), value: buttonAnimation)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .padding(.horizontal, Design.Spacing.xl)
                
                    Spacer(minLength: Design.Spacing.lg)
                    
                    // Sleek error message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(Design.Typography.callout(.medium))
                            .foregroundColor(Design.Colors.danger)
                            .padding(.horizontal, Design.Spacing.lg)
                            .padding(.vertical, Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.lg)
                                    .fill(Design.Colors.danger.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Design.Radius.lg)
                                            .stroke(Design.Colors.danger.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.xl)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                // Staggered animation sequence for smooth entrance
                withAnimation {
                    headerAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        formAnimation = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        buttonAnimation = true
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            // Dismiss when user successfully authenticates
            if isAuthenticated {
                print("✅ [EmailLoginView] User authenticated, dismissing email login sheet")
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Intelligent email authentication - tries sign-in first, then sign-up if user doesn't exist
    private func handleEmailAuth() async {
        print("📧 [EmailLoginView] handleEmailAuth called with email: \(email)")
        
        // Clear any previous errors
        await MainActor.run {
            authManager.errorMessage = nil
        }
        
        do {
            // First, try to sign in
            print("📧 [EmailLoginView] Attempting sign in...")
            try await authManager.signIn(email: email, password: password)
            print("✅ [EmailLoginView] Sign in successful! Parent LoginView will handle navigation.")
            // Success! The parent LoginView's onChange(of: authManager.isAuthenticated) will handle dismissal and navigation
        } catch {
            print("❌ [EmailLoginView] Sign in failed: \(error.localizedDescription)")
            // If sign-in failed, check if it's because user doesn't exist
            let errorMsg = error.localizedDescription.lowercased()
            
            if errorMsg.contains("invalid") || errorMsg.contains("not found") || errorMsg.contains("no user") || errorMsg.contains("credentials") {
                print("🔄 [EmailLoginView] User doesn't exist, attempting sign-up...")
                // User doesn't exist, try to create account
                do {
                    // Attempt sign-up with the provided credentials
                    try await authManager.signUp(email: email, password: password, fullName: "")
                    print("✅ [EmailLoginView] Sign-up successful! Attempting auto sign-in...")
                    
                    // After sign-up, try to sign in automatically
                    // Note: Some systems require email verification first
                    try await authManager.signIn(email: email, password: password)
                    print("✅ [EmailLoginView] Auto sign-in successful! Parent LoginView will handle navigation.")
                    // Success! The parent LoginView's onChange(of: authManager.isAuthenticated) will handle dismissal and navigation
                } catch {
                    print("❌ [EmailLoginView] Sign-up or auto sign-in failed: \(error.localizedDescription)")
                    // Sign-up or auto sign-in failed
                    // The error message is already set by authManager
                    // Show a helpful message if it's about email verification
                    if error.localizedDescription.lowercased().contains("confirm") || 
                       error.localizedDescription.lowercased().contains("verification") {
                        await MainActor.run {
                            authManager.errorMessage = "Account created! Please check your email to verify your account, then sign in."
                        }
                    }
                }
            } else {
                print("❌ [EmailLoginView] Other error: \(error.localizedDescription)")
            }
            // Otherwise, the error is already displayed via authManager.errorMessage
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
