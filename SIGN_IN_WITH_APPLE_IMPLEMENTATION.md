# Sign in with Apple Implementation Guide

**Date**: October 3, 2025  
**Status**: ✅ IMPLEMENTED  
**App**: Kansyl - Free Trial Reminder

---

## Overview

Sign in with Apple is now fully implemented in Kansyl. This document describes the implementation, how to test it, and what to configure in the Apple Developer Portal.

---

## What Was Implemented

### 1. ✅ Entitlement Enabled
**File**: `kansyl/kansyl.entitlements`

The Sign in with Apple entitlement has been uncommented:

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### 2. ✅ AppleSignInCoordinator Created
**File**: `kansyl/Helpers/AppleSignInCoordinator.swift`

A new coordinator class handles the entire Apple Sign In flow:

**Features**:
- Generates cryptographically secure nonce for security
- Creates SHA256 hash of nonce
- Handles `ASAuthorizationController` delegate callbacks
- Provides presentation context for the authorization UI
- Extracts identity token and user information
- Handles user cancellation gracefully

**Key Methods**:
- `signIn()` - Starts the Apple Sign In flow
- `generateNonce()` - Creates secure random nonce
- `sha256()` - Hashes the nonce for Apple's requirements

### 3. ✅ SupabaseAuthManager Updated
**File**: `kansyl/Managers/SupabaseAuthManager.swift`

Enhanced the `signInWithApple()` method to:

**Features**:
- Accept `PersonNameComponents` for full name
- Handle anonymous mode migration (just like Google & Email auth)
- Create or load user profile
- Update SubscriptionStore with new user ID
- Comprehensive logging for debugging

**Anonymous Mode Migration**:
```swift
// Check if user was in anonymous mode BEFORE updating anything
let wasInAnonymousMode = UserStateManager.shared.isAnonymousMode
let anonymousUserID = UserStateManager.shared.getAnonymousUserID()

// Migrate anonymous data if user was anonymous
if wasInAnonymousMode {
    try await UserStateManager.shared.migrateAnonymousDataToAccount(
        viewContext: PersistenceController.shared.container.viewContext,
        newUserID: response.user.id.uuidString
    )
}
```

### 4. ✅ LoginView Updated
**File**: `kansyl/Views/Auth/LoginView.swift`

Replaced the placeholder Apple Sign In button with real implementation:

**Changes**:
- Added `@StateObject private var appleSignInCoordinator`
- Updated `handleAppleSignIn()` to use the real coordinator
- Handles cancellation gracefully (no error shown)
- Passes full name to auth manager for profile creation

---

## How Apple Sign In Works

### Flow Diagram

```
User taps "Continue with Apple"
        ↓
LoginView.handleAppleSignIn() called
        ↓
AppleSignInCoordinator.signIn() initiates flow
        ↓
Apple's authentication UI appears
        ↓
User authenticates with Face ID / Touch ID / Password
        ↓
Apple returns identity token + nonce + user info
        ↓
AppleSignInCoordinator validates and returns result
        ↓
SupabaseAuthManager.signInWithApple() processes token
        ↓
Check if user was in anonymous mode
        ↓
If yes: Migrate anonymous subscriptions to new account
        ↓
Update SubscriptionStore with new user ID
        ↓
Create or load user profile
        ↓
User is authenticated and enters app
```

### Security Features

1. **Nonce Generation**: 
   - Cryptographically secure random string (32 characters)
   - Uses `SecRandomCopyBytes` for true randomness
   - Prevents replay attacks

2. **Nonce Hashing**: 
   - SHA256 hash sent to Apple
   - Original nonce used to verify response
   - Ensures authenticity of Apple's response

3. **Token Validation**: 
   - Identity token is JWT signed by Apple
   - Supabase validates the token server-side
   - Prevents tampering

---

## Apple Developer Portal Configuration

### Prerequisites
- ✅ Apple Developer Program membership ($99/year)
- ✅ App ID created: `com.juan-oclock.kansyl.kansyl`

### Step 1: Enable Sign in with Apple Capability

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Select your App ID: `com.juan-oclock.kansyl.kansyl`
3. Click **Edit**
4. Scroll to **Sign In with Apple**
5. Check the box to enable it
6. Click **Edit** next to Sign In with Apple
7. Select **Enable as a primary App ID**
8. Click **Save**
9. Click **Continue** and **Save** again

### Step 2: Update Provisioning Profiles

After enabling the capability, you need to regenerate provisioning profiles:

1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Find your profiles:
   - `Kansyl App Store Distribution`
   - `Kansyl Development` (if you have one)
3. Delete the old profiles
4. Click **+** to create new ones
5. Select **App Store** (or **Development**)
6. Select your App ID: `com.juan-oclock.kansyl.kansyl`
7. Select your certificate
8. Generate and download
9. Double-click to install in Xcode

### Step 3: Xcode Configuration

1. Open `kansyl.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **kansyl** target
4. Go to **Signing & Capabilities** tab
5. Verify **Sign In with Apple** capability is listed
6. If not, click **+ Capability** and add it
7. Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)

---

## Testing Sign in with Apple

### Test on Real Device (Recommended)

1. **Build and run on a physical device**:
   ```bash
   # Connect your iPhone
   # Select your device in Xcode
   # Press Cmd+R to build and run
   ```

2. **Sign out of your Apple ID in Settings**:
   - Go to Settings → Apple ID → Sign Out
   - This allows you to test the full sign-in flow

3. **Test the flow**:
   - Open Kansyl
   - Tap "Continue with Apple"
   - Sign in with your Apple ID
   - Authorize the app
   - Verify you're logged in successfully

4. **Test anonymous mode migration**:
   - Delete the app
   - Reinstall
   - Tap "Continue Without Account"
   - Add a subscription
   - Sign out (if signed in)
   - Tap "Continue with Apple"
   - Verify subscription was migrated to your account

### Test on Simulator (Limited)

**Note**: Sign in with Apple on simulator has limitations:
- Must be signed into an Apple ID in Simulator settings
- May not work on all simulator versions
- Real device testing is strongly recommended

1. **Use iOS 15+ simulator**
2. **Sign in to iCloud**:
   - Open Settings app in simulator
   - Tap "Sign in to your iPhone"
   - Enter your Apple ID
3. **Test the app**:
   - Run Kansyl
   - Tap "Continue with Apple"
   - Follow the flow

### What to Test

- [ ] **First-time user**: New account creation works
- [ ] **Returning user**: Existing account sign-in works
- [ ] **User cancellation**: Cancelling doesn't show error
- [ ] **Anonymous migration**: Subscriptions migrate when signing in from anonymous mode
- [ ] **Email retrieval**: Email is captured on first sign-in
- [ ] **Name retrieval**: Full name is captured on first sign-in (only on first auth)
- [ ] **Error handling**: Network errors show appropriate messages
- [ ] **UI responsiveness**: Button states update correctly
- [ ] **Session persistence**: User stays logged in after app restart

---

## Debugging Tips

### Enable Verbose Logging

All key operations are logged with emoji prefixes:

- 🍎 = Apple Sign In coordinator
- 🔐 = Security (nonce generation)
- 📝 = Authorization request
- 🚀 = Flow start
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning (e.g., cancellation)

### View Logs in Xcode

1. Run the app from Xcode
2. Open the Debug Console (Cmd+Shift+Y)
3. Filter logs by searching for emoji: `🍎`

### Common Issues and Solutions

#### Issue: "Sign in with Apple failed: The operation couldn't be completed"

**Solution**: 
- Ensure you're signed into iCloud on the device/simulator
- Verify the entitlement is enabled
- Check provisioning profile is up to date

#### Issue: "Missing identity token"

**Solution**:
- This is an Apple-side issue
- Try signing out and back in to iCloud
- Restart the device

#### Issue: Button does nothing when tapped

**Solution**:
- Check Xcode console for error logs
- Verify entitlement is in `kansyl.entitlements`
- Ensure capability is in Xcode project
- Clean build folder and rebuild

#### Issue: "Unable to find presentation context"

**Solution**:
- This should be handled by `AppleSignInCoordinator`
- Check that the app has an active window
- Verify you're not presenting from a dismissed view

---

## Privacy & User Experience

### What Data is Collected

When a user signs in with Apple, Kansyl receives:

1. **Always provided**:
   - Unique user ID (opaque identifier from Apple)
   - Identity token (for Supabase authentication)

2. **Provided on first sign-in only**:
   - Email address (may be private relay email: `random@privaterelay.appleid.com`)
   - Full name (if user approves sharing)

3. **Never provided**:
   - Password (handled by Apple)
   - Birthday, payment info, or other personal data

### User Privacy Options

Apple allows users to:
- **Hide email**: Use a private relay email (e.g., `abc123@privaterelay.appleid.com`)
- **Share email**: Use their real email address
- **Share name**: Provide their full name to the app
- **Hide name**: Don't share their name

**Important**: Email and name are only provided on the **first authentication**. Subsequent sign-ins don't include this data.

### Supabase Integration

Supabase handles:
- Validating the identity token from Apple
- Creating or retrieving the user account
- Managing the session
- Storing user metadata

---

## Comparison with Google Sign In

| Feature | Google OAuth | Sign in with Apple |
|---------|-------------|-------------------|
| Email always provided | ✅ Yes | ❌ No (can be hidden) |
| Name always provided | ✅ Yes | ❌ No (only first time) |
| Avatar URL provided | ✅ Yes | ❌ No |
| Requires browser | ✅ Yes (ASWebAuthenticationSession) | ❌ No (native UI) |
| User experience | Opens web view | Native iOS prompt |
| Security | OAuth 2.0 flow | Apple's secure enclave |
| Privacy | Standard | Enhanced (email relay) |

---

## Future Enhancements

### Potential Improvements

1. **Quick Sign In**:
   - Use `ASAuthorizationAppleIDButton` (Apple's official button)
   - More native iOS look and feel

2. **Credential Management**:
   - Support password autofill
   - Store credentials in iOS Keychain

3. **Account Linking**:
   - Allow users to link Apple ID to existing email accounts
   - Merge data when linking accounts

4. **Profile Updates**:
   - Allow users to update name/email in app settings
   - Sync changes back to Supabase

---

## Code References

### Key Files

1. **Entitlements**: `kansyl/kansyl.entitlements`
2. **Coordinator**: `kansyl/Helpers/AppleSignInCoordinator.swift`
3. **Auth Manager**: `kansyl/Managers/SupabaseAuthManager.swift` (lines 297-391)
4. **Login View**: `kansyl/Views/Auth/LoginView.swift` (lines 12-322)

### Related Documentation

- See `SIMPLIFIED_LOGIN_FLOW.md` for overall login architecture
- See `ANONYMOUS_MODE_IMPLEMENTATION_SUMMARY.md` for migration details
- See `APPLE_DEVELOPER_SETUP_GUIDE.md` for Apple Developer Portal setup

---

## Testing Checklist

Before submitting to App Store:

- [ ] Sign in with Apple works on real device
- [ ] First-time users can create accounts
- [ ] Returning users can sign in
- [ ] Anonymous mode migration works
- [ ] User cancellation handled gracefully
- [ ] Error messages are user-friendly
- [ ] Loading states show correctly
- [ ] Session persists after app restart
- [ ] Works on iOS 15, 16, 17, 18+
- [ ] Works on iPhone 8 and newer
- [ ] Works in both light and dark mode
- [ ] Accessibility labels are present
- [ ] VoiceOver works correctly

---

## Rollback Plan

If issues arise in production:

1. **Disable the button temporarily**:
   ```swift
   // In LoginView.swift
   .disabled(true)
   .opacity(0.5)
   ```

2. **Show maintenance message**:
   ```swift
   authManager.errorMessage = "Sign in with Apple is temporarily unavailable. Please use Email or Google sign-in."
   ```

3. **Revert entitlement** (requires new build):
   ```xml
   <!-- Comment out in kansyl.entitlements -->
   <!--
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   -->
   ```

---

## Success Metrics

Track these metrics to measure adoption:

1. **Authentication method distribution**:
   - % Apple Sign In
   - % Google Sign In
   - % Email Sign In
   - % Anonymous Mode

2. **Conversion rates**:
   - Apple Sign In success rate
   - Anonymous → Apple Sign In conversion

3. **User experience**:
   - Average time to complete Apple Sign In
   - Error rate
   - Cancellation rate

---

## App Store Review Notes

When submitting to App Store, include:

> **Sign in with Apple Implementation**
>
> Kansyl now supports Sign in with Apple as a primary authentication method, in compliance with App Store Guidelines.
>
> Users can:
> - Sign in with Apple ID (primary method)
> - Sign in with Google (alternative)
> - Sign in with Email (alternative)
> - Continue without account (anonymous mode)
>
> Sign in with Apple is fully integrated with our secure authentication system powered by Supabase. User privacy is protected, and email relay is supported.

---

## Status

✅ **Implementation Complete**  
✅ **Code Reviewed**  
🔄 **Testing in Progress**  
⏳ **Pending App Store Submission**

---

**Last Updated**: October 3, 2025  
**Implemented by**: Juan-O'Clock  
**Next Steps**: Test on real device → Submit to App Store
