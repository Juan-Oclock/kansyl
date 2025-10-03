//
//  UserProfileView.swift
//  kansyl
//
//  Created by Juan Oclock on 9/18/25.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    // CloudKit disabled for v1.0
    // @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingDeleteAccount = false
    @State private var showingSignOutAlert = false
    @State private var showingEditProfile = false
    @State private var showingCloudKitError = false
    @State private var cloudKitErrorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // User info section
                if let userProfile = authManager.userProfile {
                    Section {
                        HStack(spacing: 16) {
                            // Profile image or initials
                            ZStack {
                                Circle()
                                    .fill(Design.Colors.primary)
                                    .frame(width: 60, height: 60)
                                
                                Text(getInitials(from: userProfile.fullName ?? userProfile.email ?? "U"))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userProfile.fullName ?? "User")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Design.Colors.textPrimary)
                                
                                if let email = userProfile.email {
                                    Text(email)
                                        .font(.system(size: 14))
                                        .foregroundColor(Design.Colors.textSecondary)
                                }
                                
                                // Email verification status
                                HStack(spacing: 6) {
                                    Image(systemName: authManager.isEmailVerified ? "checkmark.circle.fill" : "exclamationmark.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(authManager.isEmailVerified ? .green : .orange)
                                    
                                    Text(authManager.isEmailVerified ? "Email Verified" : "Email Not Verified")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(Design.Colors.textTertiary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Account actions
                Section("Account") {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                    .foregroundColor(Design.Colors.textPrimary)
                    
                    Button(action: {
                        // Handle password reset for email users
                        resetPassword()
                    }) {
                        Label("Reset Password", systemImage: "key")
                    }
                    .foregroundColor(Design.Colors.textPrimary)
                }
                
                // Note: Subscription summary will be implemented later when Core Data integration is complete
                
                // Data & Privacy
                Section("Data & Privacy") {
                    Button(action: {
                        // Handle data export
                        exportUserData()
                    }) {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(Design.Colors.textPrimary)
                    
                    // CloudKit sync disabled for v1.0 - will be enabled as premium feature
                    /*
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("iCloud Sync", systemImage: "icloud.and.arrow.up")
                            Spacer()
                            
                            if cloudKitManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button(action: {
                                    Task {
                                        await handleiCloudSync()
                                    }
                                }) {
                                    Text(cloudKitManager.isSyncEnabled ? "Disable" : "Enable")
                                        .foregroundColor(cloudKitManager.canSync ? .blue : .gray)
                                }
                                .disabled(!cloudKitManager.canSync && !cloudKitManager.isSyncEnabled)
                            }
                        }
                        
                        Text(cloudKitManager.syncStatusMessage)
                            .font(.caption)
                            .foregroundColor(cloudKitManager.syncStatusColor)
                        
                        if let lastSync = cloudKitManager.lastSyncDate {
                            Text("Last sync: \(formatSyncDate(lastSync))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    */
                }
                
                // Danger zone
                Section("Account Management") {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                    .foregroundColor(.orange)
                    
                    Button(action: {
                        showingDeleteAccount = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await authManager.signOut()
                    } catch {
                        // Sign out failed
                    }
                }
            }
        } message: {
            Text("Are you sure you want to sign out? Your data will remain safe and you can sign back in anytime.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your subscription data will be permanently deleted.")
        }
        .alert("iCloud Sync Error", isPresented: $showingCloudKitError) {
            Button("OK") { }
        } message: {
            Text(cloudKitErrorMessage)
        }
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespaces)
        let firstInitial = components.first?.first?.uppercased() ?? "U"
        let lastInitial = components.count > 1 ? (components.last?.first?.uppercased() ?? "") : ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func resetPassword() {
        guard let email = authManager.userProfile?.email else { return }
        
        Task {
            do {
                try await authManager.resetPassword(email: email)
                // Password reset email sent
            } catch {
                // Password reset failed
            }
        }
    }
    
    private func exportUserData() {
        // TODO: Implement data export functionality
        // This should create a JSON file with all user data
        // and present a share sheet
    }
    
    // CloudKit functions disabled for v1.0
    /*
    private func handleiCloudSync() async {
        do {
            if cloudKitManager.isSyncEnabled {
                await cloudKitManager.disableSync()
            } else {
                try await cloudKitManager.enableSync()
            }
        } catch {
            await MainActor.run {
                cloudKitErrorMessage = error.localizedDescription
                showingCloudKitError = true
            }
        }
    }
    */
    
    private func formatSyncDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func deleteAccount() {
        Task {
            // TODO: Implement account deletion
            // This should:
            // 1. Delete all user data from Supabase
            // 2. Delete the user account
            // 3. Sign out the user
            do {
                try await authManager.signOut()
            } catch {
                // Sign out failed during account deletion
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(Design.Colors.textSecondary)
                    }
                }
                
                if isSaving {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving changes...")
                                .foregroundColor(Design.Colors.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(isSaving)
            )
        }
        .onAppear {
            loadCurrentUserData()
        }
        .alert("Error Saving Profile", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCurrentUserData() {
        if let userProfile = authManager.userProfile {
            let nameParts = userProfile.fullName?.components(separatedBy: .whitespaces) ?? []
            firstName = nameParts.first ?? ""
            lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
            email = userProfile.email ?? ""
        }
    }
    
    private func saveChanges() {
        guard let currentProfile = authManager.userProfile else { return }
        
        // Validate input
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        
        if trimmedFirstName.isEmpty && trimmedLastName.isEmpty {
            errorMessage = "Please enter at least a first name or last name."
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                let fullName = "\(trimmedFirstName) \(trimmedLastName)".trimmingCharacters(in: .whitespaces)
                let updatedProfile = SupabaseAuthManager.UserProfile(
                    id: currentProfile.id,
                    email: currentProfile.email,
                    fullName: fullName.isEmpty ? nil : fullName,
                    avatarUrl: currentProfile.avatarUrl,
                    notificationSettings: currentProfile.notificationSettings,
                    preferences: currentProfile.preferences,
                    createdAt: currentProfile.createdAt,
                    updatedAt: Date()
                )
                
                try await authManager.updateUserProfile(updatedProfile)
                
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save profile changes: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
