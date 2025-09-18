//
//  SignUpView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var agreeToTerms = false
    
    private var isValidForm: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        isValidEmail(email) &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        Text("Join Kansyl to never miss a trial deadline")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Name fields
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                TextField("First name", text: $firstName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.givenName)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                TextField("Last name", text: $lastName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.familyName)
                            }
                        }
                        
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
                            
                            if !email.isEmpty && !isValidEmail(email) {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            HStack {
                                if showingPassword {
                                    TextField("Create a password", text: $password)
                                } else {
                                    SecureField("Create a password", text: $password)
                                }
                                
                                Button(action: {
                                    showingPassword.toggle()
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                                        .foregroundColor(Design.Colors.textSecondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                            
                            if !password.isEmpty && password.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Design.Colors.textPrimary)
                            
                            HStack {
                                if showingConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                }
                                
                                Button(action: {
                                    showingConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(Design.Colors.textSecondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Terms agreement
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreeToTerms.toggle()
                            }) {
                                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(agreeToTerms ? Design.Colors.primary : Design.Colors.textSecondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                Text("By creating an account, you agree to our terms and conditions.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Design.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Sign up button
                    Button(action: {
                        Task {
                            do {
                                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                try await authManager.signUp(email: email, password: password, fullName: fullName)
                                // Note: With Supabase, user needs to verify email before signing in
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                // Error is handled by the auth manager's errorMessage property
                            }
                        }
                    }) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isValidForm ? Design.Colors.buttonPrimary : Design.Colors.textTertiary)
                            .cornerRadius(12)
                    }
                    .disabled(!isValidForm || authManager.isLoading)
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
                    
                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(Design.Colors.textSecondary)
                        Button("Sign in") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(Design.Colors.primary)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .font(.system(size: 16))
                    .padding(.bottom, 32)
                }
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
