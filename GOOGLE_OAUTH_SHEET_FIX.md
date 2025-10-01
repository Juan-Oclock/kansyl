# Google OAuth Sheet Presentation Fix

## Problem

Google sign-in worked perfectly when LoginView was the main view, but broke when LoginView was presented as a **sheet** from PremiumFeatureView.

## Root Cause

When `ASWebAuthenticationSession` is created, it needs a `presentationContextProvider` that points to the view controller that will present the authentication browser.

### Before the fix:
```swift
let rootViewController = windowScene.windows.first?.rootViewController
let contextProvider = AuthPresentationContextProvider(rootViewController: rootViewController)
```

This worked fine when LoginView was the root view, but when LoginView is presented as a sheet:
- `rootViewController` points to the base view controller (the main app)
- The authentication browser tries to present from the base controller
- But LoginView is a sheet **on top** of that controller
- iOS gets confused about the presentation hierarchy
- The OAuth callback fails to return to the correct view

### Visual representation:
```
[Window]
  └─ [Root View Controller] ← OAuth tried to present from here
       └─ [Premium Feature View]
            └─ [LoginView Sheet] ← But we're actually here!
```

## Solution

Find the **topmost presented view controller** in the hierarchy:

```swift
// Find the topmost presented view controller
var topController = rootViewController
while let presented = topController.presentedViewController {
    topController = presented
}

let contextProvider = AuthPresentationContextProvider(rootViewController: topController)
```

Now the presentation hierarchy is correct:
```
[Window]
  └─ [Root View Controller]
       └─ [Premium Feature View]
            └─ [LoginView Sheet] ← OAuth presents from here!
```

## Changes Made

**File**: `kansyl/Managers/SupabaseAuthManager.swift`

- Lines 336-348: Updated to find topmost view controller
- Added logging to show which controller is being used
- OAuth browser now presents from the correct location

## Testing

### Scenario 1: LoginView as Root (Already worked)
- User taps "Sign In" from onboarding
- LoginView is the main view
- Google OAuth works ✅

### Scenario 2: LoginView as Sheet (Now fixed!)
- User hits subscription limit
- Premium screen appears
- Taps "Upgrade to Premium"
- "Sign In Required" alert
- Taps "Sign In"
- **LoginView presented as sheet**
- Taps "Continue with Google"
- **OAuth should now work!** ✅

## Console Output

You should see this in the logs when Google sign-in is triggered:
```
🔍 [SupabaseAuthManager] Using topmost controller: UIHostingController<LoginView>
```

This confirms it's using the sheet's hosting controller, not the root.

## Why This Matters

This is a common iOS issue when dealing with:
- Modal presentations (sheets, full screen covers)
- OAuth flows (ASWebAuthenticationSession, SFAuthenticationSession)
- Any authentication that needs to present a browser

The fix ensures OAuth works correctly regardless of how LoginView is presented:
- ✅ As root view (onboarding)
- ✅ As sheet (from premium upgrade)
- ✅ As full screen cover (if used elsewhere)

## Related iOS Concepts

- **View Controller Hierarchy**: iOS maintains a tree of presented view controllers
- **Presentation Context**: Who presents the modal needs to be clear
- **ASWebAuthenticationSession**: Needs proper context to present Safari view
- **Sheet Presentation**: Changes the view controller hierarchy

## Alternative Solutions Considered

1. **Dismiss sheet before OAuth**: Would work but bad UX
2. **Use full screen cover instead of sheet**: Overkill
3. **Custom OAuth flow**: Too complex
4. **This solution**: Simple, elegant, handles all cases ✅

## Summary

The fix was simple but crucial: **Always use the topmost presented view controller** for OAuth flows. This ensures the authentication browser is presented from the correct location in the view hierarchy, allowing the callback to work properly.

Google sign-in should now work perfectly whether LoginView is the main view or a sheet! 🎉
