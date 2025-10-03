import Foundation
import Supabase
import Auth
import Combine
import SwiftUI
import AuthenticationServices

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
        // Use real configuration from SupabaseConfig
        if let supabaseURL = URL(string: SupabaseConfig.shared.url) {
            // Create real Supabase client
            self.supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: SupabaseConfig.shared.anonKey
            )
            
            print("✅ [SupabaseAuthManager] Initialized with real Supabase connection")
            print("📍 [SupabaseAuthManager] URL: \(supabaseURL)")
        } else {
            print("⚠️ [SupabaseAuthManager] Invalid Supabase URL, using demo mode")
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
                
                // Update SubscriptionStore's userID
                SubscriptionStore.currentUserID = session.user.id.uuidString
                print("✅ [SupabaseAuthManager] SubscriptionStore userID updated to: \(session.user.id.uuidString)")
                
                Task {
                    await self.loadUserProfile()
                }
            }
            
        case .signedOut:
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
            
            // Clear SubscriptionStore's userID on sign out
            SubscriptionStore.currentUserID = nil
            print("✅ [SupabaseAuthManager] SubscriptionStore userID cleared")
            
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
                
                // Update SubscriptionStore's userID
                SubscriptionStore.currentUserID = user.id.uuidString
                print("✅ [SupabaseAuthManager] Existing session found, SubscriptionStore userID set to: \(user.id.uuidString)")
            }
            
            // Load user profile after setting authentication state
            await loadUserProfile()
            
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.userProfile = nil
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
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            
            // Check if user was in anonymous mode BEFORE updating anything
            let wasInAnonymousMode = UserStateManager.shared.isAnonymousMode
            let anonymousUserID = UserStateManager.shared.getAnonymousUserID()
            
            // Migrate anonymous data if user was anonymous
            if wasInAnonymousMode {
                if anonymousUserID != nil {
                    print("🔄 [SupabaseAuthManager] User was in anonymous mode, migrating data during signup...")
                    do {
                        try await UserStateManager.shared.migrateAnonymousDataToAccount(
                            viewContext: PersistenceController.shared.container.viewContext,
                            newUserID: response.user.id.uuidString
                        )
                        print("✅ [SupabaseAuthManager] Anonymous data migration completed during signup")
                    } catch {
                        print("❌ [SupabaseAuthManager] Migration failed during signup: \(error.localizedDescription)")
                        // Continue anyway - don't block signup
                        // Still need to disable anonymous mode even if migration failed
                        UserStateManager.shared.exitAnonymousMode()
                    }
                } else {
                    // User was in anonymous mode but no ID exists - just exit anonymous mode
                    print("⚠️ [SupabaseAuthManager] User was in anonymous mode but no ID found during signup, exiting anonymous mode")
                    UserStateManager.shared.exitAnonymousMode()
                }
            }
            
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
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Check if user was in anonymous mode BEFORE updating anything
            let wasInAnonymousMode = UserStateManager.shared.isAnonymousMode
            let anonymousUserID = UserStateManager.shared.getAnonymousUserID()
            
            // Migrate anonymous data if user was anonymous
            if wasInAnonymousMode {
                if anonymousUserID != nil {
                    print("🔄 [SupabaseAuthManager] User was in anonymous mode, migrating data during sign-in...")
                    do {
                        try await UserStateManager.shared.migrateAnonymousDataToAccount(
                            viewContext: PersistenceController.shared.container.viewContext,
                            newUserID: response.user.id.uuidString
                        )
                        print("✅ [SupabaseAuthManager] Anonymous data migration completed during sign-in")
                    } catch {
                        print("❌ [SupabaseAuthManager] Migration failed during sign-in: \(error.localizedDescription)")
                        // Continue anyway - don't block sign-in
                        // Still need to disable anonymous mode even if migration failed
                        UserStateManager.shared.exitAnonymousMode()
                    }
                } else {
                    // User was in anonymous mode but no ID exists - just exit anonymous mode
                    print("⚠️ [SupabaseAuthManager] User was in anonymous mode but no ID found during sign-in, exiting anonymous mode")
                    UserStateManager.shared.exitAnonymousMode()
                }
            }
            
            // Auth state listener will handle the rest
            
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            throw SupabaseAuthError.signInFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Apple ID
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents? = nil) async throws {
        print("🍎 [SupabaseAuthManager] signInWithApple called")
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false
            print("🏁 [SupabaseAuthManager] signInWithApple completed")
        }
        
        do {
            print("📡 [SupabaseAuthManager] Calling Supabase signInWithIdToken for Apple...")
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            print("✅ [SupabaseAuthManager] Supabase Apple sign-in successful")
            print("👤 [SupabaseAuthManager] User ID: \(response.user.id)")
            print("📧 [SupabaseAuthManager] User email: \(response.user.email ?? "none")")
            
            // Check if user was in anonymous mode BEFORE updating anything
            let wasInAnonymousMode = UserStateManager.shared.isAnonymousMode
            let anonymousUserID = UserStateManager.shared.getAnonymousUserID()
            
            await MainActor.run {
                self.currentUser = self.convertAuthUser(response.user)
                self.isAuthenticated = true
                print("✅ [SupabaseAuthManager] Updated currentUser and isAuthenticated = true")
            }
            
            // Migrate anonymous data if user was anonymous
            if wasInAnonymousMode {
                if anonymousUserID != nil {
                    print("🔄 [SupabaseAuthManager] User was in anonymous mode, migrating data...")
                    do {
                        try await UserStateManager.shared.migrateAnonymousDataToAccount(
                            viewContext: PersistenceController.shared.container.viewContext,
                            newUserID: response.user.id.uuidString
                        )
                        print("✅ [SupabaseAuthManager] Anonymous data migration completed")
                    } catch {
                        print("❌ [SupabaseAuthManager] Migration failed: \(error.localizedDescription)")
                        // Continue anyway - don't block authentication
                        // Still need to disable anonymous mode even if migration failed
                        UserStateManager.shared.exitAnonymousMode()
                    }
                } else {
                    // User was in anonymous mode but no ID exists - just exit anonymous mode
                    print("⚠️ [SupabaseAuthManager] User was in anonymous mode but no ID found, exiting anonymous mode")
                    UserStateManager.shared.exitAnonymousMode()
                }
            }
            
            await MainActor.run {
                // Update SubscriptionStore's userID AFTER migration
                SubscriptionStore.currentUserID = response.user.id.uuidString
                print("✅ [SupabaseAuthManager] SubscriptionStore userID updated to: \(response.user.id.uuidString)")
            }
            
            // Load or create user profile
            print("📋 [SupabaseAuthManager] Loading user profile...")
            await loadUserProfile()
            
            // If profile doesn't exist, create it
            if userProfile == nil {
                print("📋 [SupabaseAuthManager] Profile not found, creating new profile...")
                let user = response.user
                let fullNameString: String?
                if let fullName = fullName {
                    fullNameString = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                } else if case let .string(name) = user.userMetadata["full_name"] {
                    fullNameString = name
                } else {
                    fullNameString = nil
                }
                
                do {
                    try await createUserProfile(
                        userId: user.id,
                        email: user.email,
                        fullName: fullNameString
                    )
                    print("✅ [SupabaseAuthManager] User profile created")
                } catch {
                    // Profile might have been created by database trigger or by another session
                    print("⚠️ [SupabaseAuthManager] Profile creation failed (may already exist): \(error.localizedDescription)")
                    // Try loading again
                    await loadUserProfile()
                }
            } else {
                print("✅ [SupabaseAuthManager] User profile loaded successfully")
            }
            
        } catch {
            print("❌ [SupabaseAuthManager] Apple Sign In failed: \(error.localizedDescription)")
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            throw SupabaseAuthError.appleSignInFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Google using OAuth flow with in-app browser
    @MainActor
    func signInWithGoogle() async throws {
        print("🚀 [SupabaseAuthManager] signInWithGoogle() called")
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false
            print("🏁 [SupabaseAuthManager] signInWithGoogle() completed, isLoading = false")
        }
        
        do {
            // Get Google OAuth URL from Supabase
            // Using kansyl://auth-callback to avoid showing supabase.co in dialog
            print("📡 [SupabaseAuthManager] Getting OAuth URL from Supabase...")
            let authURL = try supabase.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "kansyl://auth-callback")
            )
            print("✅ [SupabaseAuthManager] Got OAuth URL: \(authURL)")
            
            // Use a continuation to handle the async callback
            print("⏳ [SupabaseAuthManager] Creating ASWebAuthenticationSession...")
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                // Create and configure the authentication session
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "kansyl"
                ) { [weak self] callbackURL, error in
                    print("📞 [SupabaseAuthManager] ASWebAuthenticationSession callback received")
                    
                    if let error = error {
                        print("❌ [SupabaseAuthManager] OAuth error: \(error)")
                        print("❌ [SupabaseAuthManager] Error code: \((error as NSError).code)")
                        print("❌ [SupabaseAuthManager] Error domain: \((error as NSError).domain)")
                        
                        // Check if the user cancelled
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            print("⚠️ [SupabaseAuthManager] User cancelled authentication")
                            continuation.resume(throwing: SupabaseAuthError.googleSignInFailed("Authentication cancelled by user"))
                        } else {
                            print("❌ [SupabaseAuthManager] Authentication failed: \(error.localizedDescription)")
                            continuation.resume(throwing: SupabaseAuthError.googleSignInFailed(error.localizedDescription))
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        print("❌ [SupabaseAuthManager] No callback URL received")
                        continuation.resume(throwing: SupabaseAuthError.googleSignInFailed("No callback URL received"))
                        return
                    }
                    
                    print("✅ [SupabaseAuthManager] Received callback URL: \(callbackURL)")
                    print("🔍 [SupabaseAuthManager] Callback scheme: \(callbackURL.scheme ?? "none")")
                    print("🔍 [SupabaseAuthManager] Callback host: \(callbackURL.host ?? "none")")
                    print("🔍 [SupabaseAuthManager] Callback path: \(callbackURL.path)")
                    print("🔍 [SupabaseAuthManager] Callback query: \(callbackURL.query ?? "none")")
                    
                    // Handle the OAuth callback
                    Task { @MainActor [weak self] in
                        do {
                            print("🔄 [SupabaseAuthManager] Handling OAuth callback...")
                            try await self?.handleOAuthCallback(url: callbackURL)
                            print("✅ [SupabaseAuthManager] OAuth callback handled successfully")
                            continuation.resume()
                        } catch {
                            print("❌ [SupabaseAuthManager] OAuth callback handling failed: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Configure presentation for iOS 13+
                session.prefersEphemeralWebBrowserSession = false
                
                // Get the topmost view controller (important for sheets!)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    continuation.resume(throwing: SupabaseAuthError.googleSignInFailed("Unable to find presentation context"))
                    return
                }
                
                // Find the topmost presented view controller
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                
                print("🔍 [SupabaseAuthManager] Using topmost controller: \(type(of: topController))")
                
                let contextProvider = AuthPresentationContextProvider(rootViewController: topController)
                session.presentationContextProvider = contextProvider
                
                // Start the authentication session
                print("🚀 [SupabaseAuthManager] Starting ASWebAuthenticationSession...")
                if !session.start() {
                    print("❌ [SupabaseAuthManager] Failed to start authentication session")
                    continuation.resume(throwing: SupabaseAuthError.googleSignInFailed("Failed to start authentication session"))
                } else {
                    print("✅ [SupabaseAuthManager] Authentication session started successfully")
                }
            }
            
        } catch {
            print("❌ [SupabaseAuthManager] signInWithGoogle failed: \(error)")
            print("❌ [SupabaseAuthManager] Error type: \(type(of: error))")
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
            throw error
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
        print("🔄 [SupabaseAuthManager] handleOAuthCallback called with URL: \(url)")
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false
            print("🏁 [SupabaseAuthManager] handleOAuthCallback completed")
        }
        
        do {
            print("📡 [SupabaseAuthManager] Creating session from callback URL...")
            let session = try await supabase.auth.session(from: url)
            print("✅ [SupabaseAuthManager] Session created successfully")
            print("👤 [SupabaseAuthManager] User ID: \(session.user.id)")
            print("📧 [SupabaseAuthManager] User email: \(session.user.email ?? "none")")
            
            // Check if user was in anonymous mode BEFORE updating anything
            let wasInAnonymousMode = UserStateManager.shared.isAnonymousMode
            let anonymousUserID = UserStateManager.shared.getAnonymousUserID()
            
            await MainActor.run {
                self.currentUser = self.convertAuthUser(session.user)
                self.isAuthenticated = true
                print("✅ [SupabaseAuthManager] Updated currentUser and isAuthenticated = true")
            }
            
            // Migrate anonymous data if user was anonymous
            if wasInAnonymousMode {
                if anonymousUserID != nil {
                    print("🔄 [SupabaseAuthManager] User was in anonymous mode, migrating data...")
                    do {
                        try await UserStateManager.shared.migrateAnonymousDataToAccount(
                            viewContext: PersistenceController.shared.container.viewContext,
                            newUserID: session.user.id.uuidString
                        )
                        print("✅ [SupabaseAuthManager] Anonymous data migration completed")
                    } catch {
                        print("❌ [SupabaseAuthManager] Migration failed: \(error.localizedDescription)")
                        // Continue anyway - don't block authentication
                        // Still need to disable anonymous mode even if migration failed
                        UserStateManager.shared.exitAnonymousMode()
                    }
                } else {
                    // User was in anonymous mode but no ID exists - just exit anonymous mode
                    print("⚠️ [SupabaseAuthManager] User was in anonymous mode but no ID found, exiting anonymous mode")
                    UserStateManager.shared.exitAnonymousMode()
                }
            }
            
            await MainActor.run {
                // Update SubscriptionStore's userID AFTER migration
                SubscriptionStore.currentUserID = session.user.id.uuidString
                print("✅ [SupabaseAuthManager] SubscriptionStore userID updated to: \(session.user.id.uuidString)")
            }
            
            print("📋 [SupabaseAuthManager] Loading user profile...")
            await loadUserProfile()
            print("✅ [SupabaseAuthManager] User profile loaded")
            
        } catch {
            print("❌ [SupabaseAuthManager] handleOAuthCallback failed: \(error)")
            print("❌ [SupabaseAuthManager] Error description: \(error.localizedDescription)")
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