import Foundation
import Supabase
import Auth
import Combine
import SwiftUI

/// Comprehensive authentication manager using Supabase
/// Provides authentication + user database management with real-time sync
@MainActor
class SupabaseAuthManager: ObservableObject {
    static let shared = SupabaseAuthManager()
    
    // MARK: - Supabase Client
    private var supabase: SupabaseClient
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var authStateSubscription: AnyCancellable?
    private var profileSubscription: AnyCancellable?
    
    // MARK: - User Models
    struct User: Codable, Identifiable {
        let id: UUID
        let email: String?
        let emailConfirmedAt: Date?
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case emailConfirmedAt = "email_confirmed_at"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    struct UserProfile: Codable, Identifiable {
        let id: UUID
        let email: String?
        let fullName: String?
        let avatarUrl: String?
        let notificationSettings: NotificationSettings?
        let preferences: UserPreferences?
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
            case notificationSettings = "notification_settings"
            case preferences
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
        
        struct NotificationSettings: Codable {
            let enabled: Bool
            let trialReminders: Bool
            let weeklyDigest: Bool
            let quietHoursStart: String?
            let quietHoursEnd: String?
            
            enum CodingKeys: String, CodingKey {
                case enabled
                case trialReminders = "trial_reminders"
                case weeklyDigest = "weekly_digest"
                case quietHoursStart = "quiet_hours_start"
                case quietHoursEnd = "quiet_hours_end"
            }
        }
        
        struct UserPreferences: Codable {
            let currency: String
            let theme: String
            let language: String
            
            static let defaultPreferences = UserPreferences(
                currency: "USD",
                theme: "auto",
                language: "en"
            )
        }
    }
    
    // MARK: - Initialization
    init() {
        print("🚀 [SupabaseAuthManager] Initializing...")
        
        // Initialize with real Supabase configuration for authentication to work
        do {
            // Use real configuration from SupabaseConfig
            guard let supabaseURL = URL(string: SupabaseConfig.shared.url) else {
                print("⚠️ [SupabaseAuthManager] Invalid Supabase URL, using demo mode")
                self.supabase = SupabaseClient(
                    supabaseURL: URL(string: "https://demo.supabase.co")!,
                    supabaseKey: "demo-key"
                )
                self.isAuthenticated = false
                self.currentUser = nil
                self.userProfile = nil
                self.isLoading = false
                self.errorMessage = nil
                return
            }
            
            // Create real Supabase client
            self.supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: SupabaseConfig.shared.anonKey
            )
            
            print("✅ [SupabaseAuthManager] Initialized with real Supabase connection")
            print("📍 [SupabaseAuthManager] URL: \(supabaseURL)")
            
        } catch {
            print("⚠️ [SupabaseAuthManager] Failed to initialize, using demo mode")
            // Fallback to demo mode if configuration fails
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://demo.supabase.co")!,
                supabaseKey: "demo-key"
            )
        }
        
        // Set initial state - not authenticated
        self.isAuthenticated = false
        self.currentUser = nil
        self.userProfile = nil
        self.isLoading = false
        self.errorMessage = nil
        
        // Check for existing session after a short delay (non-blocking)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await self.checkExistingSession()
            }
        }
    }
    // initializeRealConnection removed - we now initialize with real config from the start
    
    // MARK: - Session Management
    
    func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .signedIn:
            if let session = session {
                self.currentUser = convertAuthUser(session.user)
                self.isAuthenticated = true
                Task {
                    await self.loadUserProfile()
                }
            }
            
        case .signedOut:
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
            
        case .tokenRefreshed:
            // Session refreshed, no additional action needed
            break
            
        default:
            break
        }
    }
    
    func checkExistingSession() async {
        do {
            let session = try await supabase.auth.session
            let user = session.user
            await MainActor.run {
                self.currentUser = self.convertAuthUser(user)
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.errorMessage = nil
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up with email and password
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            _ = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            
            // Profile will be created automatically by database trigger
            // Note: User will need to confirm email before they can sign in
            
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            throw SupabaseAuthError.signUpFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Auth state listener will handle the rest
            
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            throw SupabaseAuthError.signInFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Apple ID
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            // Create profile if this is a new user
            let user = response.user
            if userProfile == nil {
                let fullName: String?
                if case let .string(name) = user.userMetadata["full_name"] {
                    fullName = name
                } else {
                    fullName = nil
                }
                try await createUserProfile(
                    userId: user.id,
                    email: user.email,
                    fullName: fullName
                )
            }
            
        } catch {
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            throw SupabaseAuthError.appleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Google using OAuth flow
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Get Google OAuth URL from Supabase
            let url = try supabase.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "kansyl://auth-callback")
            )
            
            // Open the OAuth URL in Safari
            await UIApplication.shared.open(url)
            
        } catch {
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
            throw SupabaseAuthError.googleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Google using ID token (for GoogleSignIn SDK integration)
    func signInWithGoogle(idToken: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )
            
            // Create profile if this is a new user
            let user = response.user
            if userProfile == nil {
                let fullName: String?
                if case let .string(name) = user.userMetadata["full_name"] {
                    fullName = name
                } else {
                    fullName = nil
                }
                try await createUserProfile(
                    userId: user.id,
                    email: user.email,
                    fullName: fullName
                )
            }
            
        } catch {
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
            throw SupabaseAuthError.googleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Handle OAuth callback URL (called from SceneDelegate or App)
    func handleOAuthCallback(url: URL) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.session(from: url)
            
            await MainActor.run {
                self.currentUser = self.convertAuthUser(session.user)
                self.isAuthenticated = true
            }
            
            await loadUserProfile()
            
        } catch {
            errorMessage = "OAuth authentication failed: \(error.localizedDescription)"
            throw SupabaseAuthError.googleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Sign out
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            
            // Manually clean up state since we don't have auth state listener
            await MainActor.run {
                self.currentUser = nil
                self.userProfile = nil
                self.isAuthenticated = false
                self.errorMessage = nil
            }
            
            // Clear user-specific data from stores
            SubscriptionStore.shared.updateCurrentUser(userID: nil)
            UserSpecificPreferences.shared.setCurrentUser(nil)
            
            print("✅ [SupabaseAuthManager] User signed out successfully")
            
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            throw SupabaseAuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = "Password reset failed: \(error.localizedDescription)"
            throw SupabaseAuthError.passwordResetFailed(error.localizedDescription)
        }
    }
    
    // MARK: - User Profile Management
    
    private func loadUserProfile() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.userProfile = profile
            }
            
        } catch {
            // Debug: print("Failed to load user profile: \(error.localizedDescription)")
        }
    }
    
    private func createUserProfile(userId: UUID, email: String?, fullName: String?) async throws {
        let profile = UserProfile(
            id: userId,
            email: email,
            fullName: fullName,
            avatarUrl: nil,
            notificationSettings: UserProfile.NotificationSettings(
                enabled: true,
                trialReminders: true,
                weeklyDigest: true,
                quietHoursStart: "22:00",
                quietHoursEnd: "08:00"
            ),
            preferences: UserProfile.UserPreferences.defaultPreferences,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
        
        await MainActor.run {
            self.userProfile = profile
        }
    }
    
    /// Update user profile
    func updateUserProfile(_ updates: UserProfile) async throws {
        guard let userId = currentUser?.id else {
            throw SupabaseAuthError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("profiles")
                .update(updates)
                .eq("id", value: userId)
                .execute()
            
            await MainActor.run {
                self.userProfile = updates
            }
            
        } catch {
            errorMessage = "Profile update failed: \(error.localizedDescription)"
            throw SupabaseAuthError.profileUpdateFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    func convertAuthUser(_ authUser: Auth.User) -> User {
        return User(
            id: authUser.id,
            email: authUser.email,
            emailConfirmedAt: authUser.emailConfirmedAt,
            createdAt: authUser.createdAt,
            updatedAt: authUser.updatedAt
        )
    }
    
    /// Get the current user's ID (useful for database queries)
    var currentUserId: UUID? {
        return currentUser?.id
    }
    
    /// Check if email is verified
    var isEmailVerified: Bool {
        return currentUser?.emailConfirmedAt != nil
    }
    
    /// Handle errors by setting the error message
    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
    }
}

// MARK: - Authentication Errors
enum SupabaseAuthError: LocalizedError {
    case notAuthenticated
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case appleSignInFailed(String)
    case googleSignInFailed(String)
    case passwordResetFailed(String)
    case profileUpdateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google Sign In failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .profileUpdateFailed(let message):
            return "Profile update failed: \(message)"
        }
    }
}