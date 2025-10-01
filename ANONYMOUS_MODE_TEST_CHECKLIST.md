# Anonymous Mode UserID - Testing Checklist

## Issue Fixed
Removed `@MainActor` from `UserStateManager` which was preventing synchronous setting of `SubscriptionStore.shared.currentUserID`.

## What to Look For in Console

### When Clicking "Continue Without Account":
```
🔵 [LoginView] User confirmed anonymous mode
✅ [UserStateManager] Anonymous mode enabled with ID: [UUID-HERE]
✅ [UserStateManager] SubscriptionStore userID set to: [UUID-HERE]
✅ [UserStateManager] Verification - SubscriptionStore.shared.currentUserID = [UUID-HERE]
🔵 [LoginView] After enterAnonymousMode(), currentUserID = [UUID-HERE]
```

### When Adding a Subscription:
```
[SubscriptionStore] Adding subscription: Netflix for userID: [UUID-HERE]
✅ [SubscriptionStore] Successfully added subscription
```

**NOT:**
```
❌ [SubscriptionStore] Adding subscription: Netflix for userID: nil
❌ No userID found, cannot add subscription
```

## Manual Testing Steps

### Test 1: Enter Anonymous Mode
1. ✅ Launch app
2. ✅ Skip onboarding (if needed)
3. ✅ Click "Continue Without Account"
4. ✅ Click "Continue" on alert
5. ✅ Check console for userID logs
6. ✅ Verify you see the main app screen

### Test 2: Add Subscription
1. ✅ Click "+" to add subscription
2. ✅ Select a service (e.g., Netflix)
3. ✅ Click "Add Subscription"
4. ✅ Check console logs - should see userID (not nil)
5. ✅ Verify subscription appears in list
6. ✅ NO blank modal should appear

### Test 3: Add Multiple Subscriptions
1. ✅ Add 2-3 more subscriptions
2. ✅ Each should save successfully
3. ✅ All should appear in list
4. ✅ Check console - each should have a userID

### Test 4: App Restart
1. ✅ Force quit the app
2. ✅ Relaunch app
3. ✅ Check console for "Restored anonymous mode with ID: [UUID]"
4. ✅ Verify all previous subscriptions still appear
5. ✅ Add another subscription
6. ✅ Should save successfully

### Test 5: Hit Subscription Limit
1. ✅ Add 5 subscriptions total
2. ✅ Try to add 6th subscription
3. ✅ Should see subscription limit prompt
4. ✅ Options: Create Account / Sign In / Maybe Later

## Debug If Still Not Working

If you still see `userID: nil`, check:

1. **Console Logs:**
   - Do you see "✅ [UserStateManager] Anonymous mode enabled"?
   - Do you see "✅ [UserStateManager] SubscriptionStore userID set to"?
   - What does the verification log show?

2. **Xcode:**
   - Clean build folder (Cmd + Shift + K)
   - Rebuild (Cmd + B)
   - Restart Simulator/Device

3. **Breakpoints:**
   - Set breakpoint in `UserStateManager.enableAnonymousMode()` line 80
   - Step through and check `SubscriptionStore.shared.currentUserID`

4. **Print Statements:**
   - In `SubscriptionStore.addSubscription()`, add:
     ```swift
     print("🔍 [DEBUG] currentUserID = \(currentUserID ?? "nil")")
     print("🔍 [DEBUG] SubscriptionStore.shared.currentUserID = \(SubscriptionStore.shared.currentUserID ?? "nil")")
     ```

## Expected Behavior Summary

✅ **Anonymous mode sets userID immediately**  
✅ **Subscriptions can be added without errors**  
✅ **Subscriptions persist across restarts**  
✅ **Limit of 5 subscriptions enforced**  
✅ **Smooth transition to authenticated mode**  

## Files Modified

1. `UserStateManager.swift`:
   - Removed `@MainActor` annotation
   - Made currentUserID setting synchronous
   - Added verification logging

2. `LoginView.swift`:
   - Wrapped enterAnonymousMode in Task for safety
   - Added debug logging

3. `SupabaseAuthManager.swift`:
   - Sets currentUserID on sign-in
   - Clears currentUserID on sign-out
