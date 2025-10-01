# Anonymous Mode Implementation Guide

**Created**: 2025-10-01  
**Status**: Ready to implement  
**Estimated Time**: 4-6 hours

---

## 📋 Overview

This document outlines the complete implementation of the hybrid anonymous mode feature, allowing users to try Kansyl without an account while preserving their data when they sign up.

---

## ✅ Completed

1. **UserStateManager.swift** - Created ✅
   - Manages anonymous vs authenticated states
   - Tracks subscription limits
   - Handles data migration logic

---

## 🔧 Files to Modify

### 1. **AuthenticationWrapperView.swift**
**Changes needed:**
- Allow access to main app even if not authenticated but in anonymous mode
- Update logic to check `UserStateManager.shared.isAnonymousMode`

**Current logic:**
```swift
if !deviceHasCompletedOnboarding {
    OnboardingView(...)
} else if authManager.isAuthenticated {
    ContentView()
} else {
    LoginView()
}
```

**New logic:**
```swift
if !deviceHasCompletedOnboarding {
    OnboardingView(...)
} else if authManager.isAuthenticated || UserStateManager.shared.isAnonymousMode {
    ContentView()  // Allow anonymous users too!
} else {
    LoginView()
}
```

---

### 2. **LoginView.swift**
**Changes needed:**
- Add "Continue Without Account" section at bottom
- Add warning box about data not being saved
- Add confirmation alert before continuing anonymously

**UI additions:**
```swift
// After sign-in buttons, before footer:

// Divider
HStack {
    Rectangle().frame(height: 1)
    Text("or").foregroundColor(.secondary)
    Rectangle().frame(height: 1)
}
.padding(.horizontal)

// Anonymous mode section
VStack(spacing: 12) {
    Text("Try without an account")
        .font(.subheadline)
        .foregroundColor(.secondary)
    
    // Warning box
    HStack(alignment: .top, spacing: 12) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Data won't be saved")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Without an account, your subscriptions won't sync or backup. You can create an account later.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
    
    // Continue button
    Button(action: {
        showingAnonymousWarning = true
    }) {
        Text("Continue Without Account")
            .font(.subheadline)
            .foregroundColor(.blue)
    }
}

// Alert
.alert("Continue Without Account?", isPresented: $showingAnonymousWarning) {
    Button("Go Back", role: .cancel) { }
    Button("Continue") {
        continueAnonymously()
    }
} message: {
    Text("You can track up to 5 subscriptions without an account. Your data will only be stored on this device.\n\nYou can create an account later to save your data.")
}
```

**Function to add:**
```swift
private func continueAnonymously() {
    HapticManager.shared.playButtonTap()
    UserStateManager.shared.enableAnonymousMode()
    // App will automatically show ContentView due to AuthenticationWrapperView logic
}
```

---

### 3. **Create SubscriptionLimitPrompt.swift** (New File)
**Purpose:** Show when user hits 5-subscription limit

**Full file:**
```swift
import SwiftUI

struct SubscriptionLimitPromptView: View {
    @EnvironmentObject private var authManager: SupabaseAuthManager
    @EnvironmentObject private var userStateManager: UserStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignIn = false
    @State private var showingPremium = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                // Title and subtitle
                VStack(spacing: 8) {
                    Text("You're using Kansyl!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You've added \(userStateManager.subscriptionCount) subscriptions")
                        .foregroundColor(.secondary)
                }
                
                // Warning about data loss (for anonymous users)
                if userStateManager.userState == .anonymous {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Your data isn't saved yet. Create an account to save your subscriptions and add more.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // CTAs
                VStack(spacing: 12) {
                    if userStateManager.userState == .anonymous {
                        // Primary: Create Free Account
                        Button(action: { showingSignIn = true }) {
                            VStack(spacing: 4) {
                                Text("Create Free Account")
                                    .font(.headline)
                                Text("Save your 5 subscriptions")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Secondary: Upgrade to Premium
                    Button(action: { showingPremium = true }) {
                        VStack(spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(.headline)
                            Text("Unlimited + AI scanning - $2.99/mo")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Tertiary: Maybe later
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
            }
            .padding()
            .navigationTitle("Subscription Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSignIn) {
                LoginView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingPremium) {
                PremiumFeaturesView()
            }
        }
    }
}
```

---

### 4. **Modify Add Subscription Logic**
**Location:** Wherever subscriptions are added (likely `AddSubscriptionView` or similar)

**Add this check:**
```swift
// Before allowing user to add subscription
func attemptToAddSubscription() {
    // Check if user can add more
    if !UserStateManager.shared.canAddSubscription() {
        let limitStatus = UserStateManager.shared.checkSubscriptionLimit()
        
        switch limitStatus {
        case .needsAccount:
            // Show prompt to create account
            showingLimitPrompt = true
        case .needsPremium:
            // Show premium upgrade
            showingPremiumUpgrade = true
        case .allowed:
            // Continue with add
            break
        }
        return
    }
    
    // Proceed with adding subscription
    actuallyAddSubscription()
}
```

---

### 5. **Update SupabaseAuthManager.swift**
**Add migration trigger after sign-in:**

```swift
// After successful sign-in (in signIn, signUp, or Google sign-in methods)
func onAuthenticationSuccess(userID: String) async {
    // Check if there's anonymous data to migrate
    if UserStateManager.shared.isAnonymousMode {
        do {
            try await UserStateManager.shared.migrateAnonymousDataToAccount(
                viewContext: PersistenceController.shared.container.viewContext,
                newUserID: userID
            )
            
            // Show success message
            await MainActor.run {
                showMigrationSuccess()
            }
        } catch {
            // Show error but don't block sign-in
            print("⚠️ Migration failed: \(error)")
            // User is still signed in, data just didn't migrate
        }
    }
}
```

---

### 6. **Update SettingsView.swift**
**Add anonymous warning banner:**

```swift
// At top of Form, before other sections:
if UserStateManager.shared.isAnonymousMode {
    Section {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Not Backed Up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("You have \(UserStateManager.shared.subscriptionCount) subscriptions that aren't backed up. If you delete the app, you'll lose all your data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: { showingSignIn = true }) {
                Text("Create Account to Save Data")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// Show account status
Section("Account") {
    if UserStateManager.shared.isAnonymousMode {
        HStack {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text("No Account")
                    .fontWeight(.semibold)
                Text("Your data isn't backed up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Create Account") {
                showingSignIn = true
            }
            .buttonStyle(.borderedProminent)
        }
    } else {
        // Existing signed-in account UI
    }
}
```

---

### 7. **Update App Store Copy** (Already done in previous files)
- Updated `APP_STORE_COPY.md` ✅
- Updated `REVIEWER_NOTES.md` ✅

---

## 🧪 Testing Checklist

### Test Scenario 1: Anonymous Flow
- [ ] Open app, complete onboarding
- [ ] Tap "Continue Without Account" on login screen
- [ ] Confirm anonymous mode warning
- [ ] Add 5 subscriptions
- [ ] Try to add 6th - should show limit prompt
- [ ] Check Settings - should show "No Account" warning

### Test Scenario 2: Account Creation from Anonymous
- [ ] In anonymous mode with 5 subscriptions
- [ ] Tap "Create Free Account" from limit prompt
- [ ] Sign in with Google/Apple/Email
- [ ] Verify all 5 subscriptions are still there
- [ ] Verify userID is assigned to subscriptions
- [ ] Verify anonymous mode is disabled
- [ ] Verify Settings shows signed-in state

### Test Scenario 3: Direct Sign-In
- [ ] Open app, complete onboarding
- [ ] Sign in immediately (don't choose anonymous)
- [ ] Add subscriptions
- [ ] Verify they're saved with userID from start

### Test Scenario 4: Migration Error Handling
- [ ] Create network failure scenario
- [ ] Attempt migration
- [ ] Verify graceful error handling
- [ ] Verify local data isn't lost

---

## 📝 Implementation Steps

1. ✅ Create `UserStateManager.swift`
2. ⏳ Modify `AuthenticationWrapperView.swift`
3. ⏳ Update `LoginView.swift` with anonymous option
4. ⏳ Create `SubscriptionLimitPromptView.swift`
5. ⏳ Add limit checking to subscription add flow
6. ⏳ Add migration trigger to `SupabaseAuthManager.swift`
7. ⏳ Update `SettingsView.swift` with warnings
8. ⏳ Test all scenarios
9. ⏳ Update documentation

---

##  Migration Success Alert

**Show this after successful migration:**
```swift
struct MigrationSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptionCount: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Set!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your \(subscriptionCount) subscriptions are now saved and synced.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## ⚠️ Important Notes

1. **Data Safety**: Always backup before migration
2. **Error Handling**: Never lose user's local data, even if migration fails
3. **Clear Messaging**: Users must understand consequences of anonymous mode
4. **Testing**: Thoroughly test migration with various data states
5. **iCloud Sync**: Only enable after user creates account

---

## 🚀 Ready to Implement?

This implementation is designed to be:
- ✅ **Non-breaking**: Doesn't affect existing signed-in users
- ✅ **Reversible**: Can be disabled if issues arise
- ✅ **Tested**: Clear testing scenarios provided
- ✅ **User-friendly**: Clear warnings and smooth UX

**Estimated completion time**: 4-6 hours of focused work

Would you like me to proceed with implementing these changes?
