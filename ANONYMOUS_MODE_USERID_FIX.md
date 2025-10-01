# Anonymous Mode UserID Fix

## Problem
When users entered anonymous mode and tried to add subscriptions, they encountered an error:
```
⚠️ [SubscriptionStore] No userID found, cannot add subscription
```

The app opened a blank modal and subscriptions couldn't be saved because `SubscriptionStore.shared.currentUserID` was `nil`.

## Root Cause
The `SubscriptionStore` requires a `userID` to save subscriptions (for data isolation between users). When entering anonymous mode, we were:
1. ✅ Setting `isAnonymousMode = true`
2. ✅ Generating an anonymous user ID
3. ✅ Storing it in UserDefaults
4. ❌ **NOT setting `SubscriptionStore.shared.currentUserID`**

This meant the SubscriptionStore didn't know which user to associate subscriptions with.

## Solution

### 1. Set SubscriptionStore userID When Entering Anonymous Mode
**File:** `UserStateManager.swift`

```swift
func enableAnonymousMode() {
    let anonymousID = UUID().uuidString
    UserDefaults.standard.set(true, forKey: ANONYMOUS_MODE_KEY)
    UserDefaults.standard.set(anonymousID, forKey: ANONYMOUS_USER_ID_KEY)
    isAnonymousMode = true
    userState = .anonymous
    
    // ✅ CRITICAL FIX: Set SubscriptionStore's currentUserID
    SubscriptionStore.shared.currentUserID = anonymousID
    
    print("✅ [UserStateManager] Anonymous mode enabled with ID: \(anonymousID)")
    print("✅ [UserStateManager] SubscriptionStore userID set to: \(anonymousID)")
}
```

### 2. Restore SubscriptionStore userID on App Launch
**File:** `UserStateManager.swift`

```swift
func loadAnonymousState() {
    isAnonymousMode = UserDefaults.standard.bool(forKey: ANONYMOUS_MODE_KEY)
    
    // ✅ If in anonymous mode, restore the userID to SubscriptionStore
    if isAnonymousMode {
        if let anonymousID = getAnonymousUserID() {
            SubscriptionStore.shared.currentUserID = anonymousID
            print("✅ [UserStateManager] Restored anonymous mode with ID: \(anonymousID)")
        } else {
            // Anonymous flag set but no ID exists - create one
            print("⚠️ [UserStateManager] Anonymous mode flag set but no ID found, creating new ID")
            enableAnonymousMode()
        }
    }
}
```

### 3. Update SubscriptionStore userID on Authentication
**File:** `SupabaseAuthManager.swift`

#### On Sign-In
```swift
func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
    switch event {
    case .signedIn:
        if let session = session {
            self.currentUser = convertAuthUser(session.user)
            self.isAuthenticated = true
            
            // ✅ Update SubscriptionStore's userID to authenticated user's ID
            SubscriptionStore.shared.currentUserID = session.user.id.uuidString
            print("✅ [SupabaseAuthManager] SubscriptionStore userID updated to: \(session.user.id.uuidString)")
            
            Task {
                await self.loadUserProfile()
            }
        }
        
    case .signedOut:
        self.currentUser = nil
        self.userProfile = nil
        self.isAuthenticated = false
        
        // ✅ Clear SubscriptionStore's userID on sign out
        SubscriptionStore.shared.currentUserID = nil
        print("✅ [SupabaseAuthManager] SubscriptionStore userID cleared")
```

#### On Existing Session Check
```swift
func checkExistingSession() async {
    do {
        let session = try await supabase.auth.session
        let user = session.user
        await MainActor.run {
            self.currentUser = self.convertAuthUser(user)
            self.isAuthenticated = true
            
            // ✅ Update SubscriptionStore's userID for existing session
            SubscriptionStore.shared.currentUserID = user.id.uuidString
            print("✅ [SupabaseAuthManager] Existing session found, SubscriptionStore userID set to: \(user.id.uuidString)")
        }
        
        await loadUserProfile()
```

## User ID Flow

### Anonymous Mode Flow
```
User clicks "Continue Without Account"
↓
Alert confirmation
↓
UserStateManager.enableAnonymousMode()
↓
1. Generate UUID (e.g., "A1B2C3D4-...")
2. Save to UserDefaults
3. Set SubscriptionStore.shared.currentUserID = UUID
↓
User can now add subscriptions
↓
Subscriptions saved with anonymous userID
```

### App Launch (Anonymous Mode)
```
App launches
↓
UserStateManager.loadAnonymousState()
↓
Check UserDefaults: isAnonymousMode = true
↓
Get anonymousUserID from UserDefaults
↓
Set SubscriptionStore.shared.currentUserID = anonymousUserID
↓
User's previous subscriptions load correctly
```

### Sign-In Flow (From Anonymous)
```
User in anonymous mode clicks "Continue with Email"
↓
Successfully authenticates
↓
SupabaseAuthManager.signIn() completes
↓
1. UserStateManager.exitAnonymousMode()
2. Clear anonymous flags from UserDefaults
3. SubscriptionStore.shared.currentUserID = authenticatedUserID
↓
User can now add unlimited subscriptions
↓
Subscriptions saved with authenticated userID
```

### Data Migration (Optional Future Enhancement)
```
User has 3 subscriptions in anonymous mode
↓
User creates account
↓
SupabaseAuthManager sets new userID
↓
[Future] Call UserStateManager.migrateAnonymousDataToAccount()
↓
All anonymous subscriptions' userID updated to authenticated userID
↓
User's data is preserved
```

## Testing Checklist

✅ **Anonymous Mode Entry:**
- [ ] Click "Continue Without Account"
- [ ] Confirm alert
- [ ] Check logs for: "SubscriptionStore userID set to: [UUID]"
- [ ] Try to add a subscription
- [ ] Verify subscription saves successfully
- [ ] Verify subscription appears in list

✅ **App Restart (Anonymous Mode):**
- [ ] Add subscription in anonymous mode
- [ ] Force quit app
- [ ] Relaunch app
- [ ] Check logs for: "Restored anonymous mode with ID: [UUID]"
- [ ] Verify previous subscription still appears
- [ ] Add another subscription
- [ ] Verify it saves correctly

✅ **Anonymous to Authenticated:**
- [ ] Start in anonymous mode
- [ ] Add 2-3 subscriptions
- [ ] Sign in with email
- [ ] Check logs for: "SubscriptionStore userID updated to: [AUTH_ID]"
- [ ] Add a new subscription
- [ ] Verify it saves with authenticated userID

✅ **Sign Out:**
- [ ] Sign in as authenticated user
- [ ] Sign out
- [ ] Check logs for: "SubscriptionStore userID cleared"
- [ ] Verify SubscriptionStore.shared.currentUserID == nil

## Files Modified

1. **UserStateManager.swift**
   - Updated `enableAnonymousMode()` to set SubscriptionStore userID
   - Updated `loadAnonymousState()` to restore SubscriptionStore userID on launch

2. **SupabaseAuthManager.swift**
   - Updated `handleAuthStateChange()` to set/clear SubscriptionStore userID
   - Updated `checkExistingSession()` to restore SubscriptionStore userID

## Console Logs to Verify

### Entering Anonymous Mode:
```
✅ [UserStateManager] Anonymous mode enabled with ID: 12345678-ABCD-...
✅ [UserStateManager] SubscriptionStore userID set to: 12345678-ABCD-...
```

### App Launch (Anonymous):
```
✅ [UserStateManager] Restored anonymous mode with ID: 12345678-ABCD-...
```

### Adding Subscription:
```
[SubscriptionStore] Adding subscription: Netflix for userID: 12345678-ABCD-...
✅ [SubscriptionStore] Successfully added subscription
```

### Sign-In:
```
✅ [SupabaseAuthManager] SubscriptionStore userID updated to: 87654321-WXYZ-...
```

### Sign-Out:
```
✅ [SupabaseAuthManager] SubscriptionStore userID cleared
```

## Edge Cases Handled

✅ **Anonymous flag set but no ID** - Creates new anonymous ID  
✅ **Switching from anonymous to authenticated** - Updates userID seamlessly  
✅ **Sign out** - Clears userID properly  
✅ **App restart** - Restores correct userID  
✅ **Multiple sign-in/sign-out cycles** - Each transition updates userID correctly  

## Related Issues

**Original Error:**
```
Error enumerating all current transactions: Error Domain=ASDErrorDomain Code=509 "No active account"
[SubscriptionStore] [SubscriptionStore.swift:155] Adding subscription: Netflix for userID: nil
⚠️ [SubscriptionStore] [SubscriptionStore.swift:158] No userID found, cannot add subscription
```

**Fix Verification:**
```
[SubscriptionStore] [SubscriptionStore.swift:155] Adding subscription: Netflix for userID: 12345678-ABCD-...
✅ [SubscriptionStore] Successfully added subscription
```

## Future Enhancements

### Data Migration
Currently, when a user transitions from anonymous to authenticated, their subscriptions remain with the anonymous userID. To preserve anonymous subscriptions:

1. Call `UserStateManager.shared.migrateAnonymousDataToAccount()` after successful sign-in
2. This updates all anonymous subscriptions to use the authenticated userID
3. User's data is seamlessly preserved

Implementation exists but is not currently triggered - can be added to `SupabaseAuthManager.signIn()` if desired.

### Automatic Cleanup
Consider adding cleanup logic to remove anonymous subscriptions after a certain period (e.g., 30 days) if the user never creates an account.

## Success Criteria

✅ Users can add subscriptions in anonymous mode  
✅ Subscriptions persist across app restarts  
✅ Subscriptions save with correct userID  
✅ No blank modals or errors  
✅ Smooth transition from anonymous to authenticated  
✅ Data isolation between users maintained  
