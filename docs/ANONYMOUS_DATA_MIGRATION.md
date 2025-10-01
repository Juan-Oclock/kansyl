# Anonymous Data Migration Implementation

## Overview
This document explains the implementation of automatic data migration when an anonymous user signs in to create an account. This ensures that subscriptions created while using the app anonymously are preserved and migrated to the user's authenticated account.

## Problem Statement
Previously, when an anonymous user created subscriptions and then signed in with Google, email/password, or other authentication methods, their anonymous subscriptions would be lost. This happened because:

1. Anonymous users had a temporary UUID assigned as their `userID`
2. After authentication, a new Supabase user ID was assigned
3. The old anonymous subscriptions remained linked to the temporary UUID
4. The new authenticated user would start with zero subscriptions

## Solution
We implemented automatic data migration that:
1. Detects when a user was in anonymous mode before authentication
2. Migrates all anonymous subscriptions to the new authenticated user ID
3. Disables anonymous mode after migration
4. Updates the `SubscriptionStore.currentUserID` only after migration completes

## Implementation Details

### Key Components

#### 1. UserStateManager.migrateAnonymousDataToAccount()
This method handles the actual data migration:
- Located in: `kansyl/Managers/UserStateManager.swift`
- Fetches all subscriptions with the anonymous user ID
- Updates their `userID` to the new authenticated user ID
- Saves changes to Core Data
- Disables anonymous mode

```swift
func migrateAnonymousDataToAccount(
    viewContext: NSManagedObjectContext,
    newUserID: String
) async throws
```

#### 2. SupabaseAuthManager Updates
Migration logic was added to all authentication methods:

##### Google OAuth Sign-In (handleOAuthCallback)
- Lines 455-478 in `SupabaseAuthManager.swift`
- Checks if user was in anonymous mode before OAuth callback processing
- Migrates data if anonymous user ID exists
- Updates `SubscriptionStore.currentUserID` after migration

##### Email/Password Sign-In
- Lines 257-277 in `SupabaseAuthManager.swift`
- Similar migration logic as OAuth
- Migrates data before exiting anonymous mode

##### Email/Password Sign-Up
- Lines 213-233 in `SupabaseAuthManager.swift`
- Migrates data during account creation
- Ensures new accounts preserve anonymous subscriptions

### Migration Flow

```
1. User creates subscriptions anonymously
   └── Subscriptions stored with temporary UUID

2. User chooses to sign in/sign up
   └── Authentication flow initiated

3. Authentication succeeds
   ├── Check: Was user in anonymous mode?
   │   ├── YES: Get anonymous user ID
   │   │   ├── Fetch all subscriptions with anonymous ID
   │   │   ├── Update subscriptions to new authenticated ID
   │   │   ├── Save to Core Data
   │   │   └── Disable anonymous mode
   │   └── NO: Simply exit anonymous mode
   │
   └── Update SubscriptionStore.currentUserID (after migration)
```

## Testing the Implementation

### Test Case 1: Google Sign-In with Anonymous Data
1. Skip sign-in to enter anonymous mode
2. Create 2-3 subscriptions
3. Go to Settings → Sign in with Google
4. Complete Google OAuth flow
5. **Expected**: All anonymous subscriptions are preserved

### Test Case 2: Email/Password Sign-In with Anonymous Data
1. Skip sign-in to enter anonymous mode
2. Create 2-3 subscriptions
3. Go to Settings → Sign in with email/password
4. Complete sign-in
5. **Expected**: All anonymous subscriptions are preserved

### Test Case 3: Email/Password Sign-Up with Anonymous Data
1. Skip sign-in to enter anonymous mode
2. Create 2-3 subscriptions
3. Go to Settings → Create account with email/password
4. Complete sign-up
5. **Expected**: All anonymous subscriptions are preserved

### Verification Steps
After each test case:
1. Check Console logs for migration messages:
   - `🔄 [SupabaseAuthManager] User was in anonymous mode, migrating data...`
   - `✅ [SupabaseAuthManager] Anonymous data migration completed`
   - `📦 [UserStateManager] Found X subscriptions to migrate`
   - `✅ [UserStateManager] Successfully migrated X subscriptions`

2. Verify subscriptions appear in the app's subscription list
3. Verify subscription count matches pre-authentication count

## Debug Logging
The implementation includes comprehensive logging at each step:

- Migration start/completion in `SupabaseAuthManager`
- Subscription count and details in `UserStateManager`
- `SubscriptionStore.currentUserID` updates
- Anonymous mode state changes

Search for these log prefixes in Xcode console:
- `[SupabaseAuthManager]`
- `[UserStateManager]`

## Error Handling
- Migration errors are caught and logged but don't block authentication
- If migration fails, the user is still authenticated successfully
- Failed migrations are logged with `❌` prefix for easy debugging

## Edge Cases Handled

1. **No Anonymous Data**: If user was not in anonymous mode, migration is skipped
2. **No Anonymous ID**: If anonymous mode flag is set but no ID exists, migration is skipped
3. **Empty Subscriptions**: If no anonymous subscriptions exist, migration completes immediately
4. **Migration Failure**: Authentication continues even if migration fails (logged as error)

## Future Improvements

Potential enhancements:
1. Sync migrated subscriptions to Supabase backend (if applicable)
2. Add UI feedback during migration process
3. Implement retry logic for failed migrations
4. Add analytics tracking for migration success/failure rates

## Related Files
- `kansyl/Managers/SupabaseAuthManager.swift` - Authentication and OAuth handling
- `kansyl/Managers/UserStateManager.swift` - Anonymous mode and migration logic
- `kansyl/Stores/SubscriptionStore.swift` - Subscription storage and user ID management
- `kansyl/Views/Auth/LoginView.swift` - Authentication UI

## Build Status
✅ Implementation complete and building successfully
✅ All authentication methods updated with migration logic
✅ Comprehensive debug logging added
✅ No compilation errors

---
**Last Updated**: January 2025
**Status**: Complete and Ready for Testing
