# Google OAuth Sign-In Setup

## Current Issue

When testing "Continue with Google" on the iOS Simulator, the authentication flow opens the browser but then returns to the sign-in page without successfully signing in.

## Root Causes

There are several possible reasons for this issue:

### 1. **Supabase Google OAuth Not Configured**
   - Google OAuth needs to be set up in your Supabase dashboard
   - Required: Google Client ID and Client Secret
   - Required: Authorized redirect URIs

### 2. **iOS Simulator Limitations**
   - OAuth flows can be unreliable on simulator
   - Browser session state may not persist properly
   - Keychain access can be restricted

### 3. **Redirect URI Configuration**
   - The callback URL `kansyl://auth-callback` must be registered in:
     - Supabase Auth settings
     - Google Cloud Console OAuth credentials
     - Your app's Info.plist (✅ Already configured)

## Quick Solution: Use Email Sign-In for Testing

For simulator testing, **email sign-in** is more reliable:

1. Tap **"Continue with Email"** instead of Google
2. Enter any email (e.g., `test@example.com`)
3. Enter any password (e.g., `password123`)
4. The app will create an account or sign in

## Setting Up Google OAuth (For Production)

### Step 1: Configure in Supabase Dashboard

1. Go to https://app.supabase.com
2. Select your project (kansyl)
3. Go to **Authentication** → **Providers**
4. Find **Google** provider
5. Enable it and configure:
   - **Google Client ID**: From Google Cloud Console
   - **Google Client Secret**: From Google Cloud Console
   - **Authorized Redirect URI**: Copy the Supabase provided URL

### Step 2: Configure in Google Cloud Console

1. Go to https://console.cloud.google.com
2. Select or create a project
3. Go to **APIs & Services** → **Credentials**
4. Create **OAuth 2.0 Client ID** for iOS:
   - Application type: **iOS**
   - Bundle ID: `com.juan-oclock.kansyl`
   - OR create Web application type for Supabase:
     - Authorized JavaScript origins: Your Supabase project URL
     - Authorized redirect URIs: 
       - `https://yjkuhkgjivyzrwcplzqw.supabase.co/auth/v1/callback`
       - `kansyl://auth-callback`

### Step 3: Update Supabase Configuration

Add the Google credentials to Supabase:
- Client ID
- Client Secret  
- Save settings

## Testing Google OAuth

### On Simulator (Unreliable):
- May work intermittently
- Browser might not return to app properly
- **Recommendation**: Use email sign-in for simulator testing

### On Real Device (Recommended):
1. Build and install on physical iPhone
2. Ensure device has internet connection
3. Tap "Continue with Google"
4. Should open Safari/in-app browser
5. Sign in with your Google account
6. Should redirect back to app successfully

## Alternative: Testing Without Google OAuth

Since you're testing the **premium purchase authentication flow**, you don't actually need Google OAuth working. You can:

1. **Use Email Sign-In**:
   - Tap "Continue with Email"
   - Create a test account
   - Test the premium flow

2. **Skip Sign-In** (for other testing):
   - Tap "Continue Without Account"
   - Stay in anonymous mode
   - Test that premium purchase shows "Sign In Required" alert

## Code Changes Needed (If Configuring Google OAuth)

None! The code is already set up correctly:
- ✅ URL scheme configured in Info.plist
- ✅ OAuth callback handler in kansylApp.swift
- ✅ Google sign-in method in SupabaseAuthManager
- ✅ Proper error handling

## Debugging OAuth Issues

If Google OAuth still doesn't work after configuration:

1. **Check Console Logs**:
   ```
   OAuth callback failed: [error message]
   ```

2. **Verify Redirect URI Match**:
   - Supabase dashboard
   - Google Cloud Console
   - Must match exactly (including scheme and path)

3. **Test OAuth URL Generation**:
   - Add logging in `signInWithGoogle()` method
   - Print the `authURL` to verify it's correct

4. **Check Supabase Auth Settings**:
   - Ensure Google provider is enabled
   - Check for any error messages in Supabase logs

## Current State of Your App

✅ **What's Working**:
- Authentication requirement for premium purchases
- Sign-in alerts and flows
- Email authentication
- Anonymous mode
- OAuth URL scheme configuration

⏳ **What Needs Setup** (Optional for testing):
- Google OAuth credentials in Supabase dashboard
- Google Cloud Console OAuth setup

## Recommendation for Testing

For testing the premium authentication flow:

1. **Use Email Sign-In** - Most reliable on simulator
2. Create a test account: `test@example.com` / `password123`
3. Test the full premium purchase flow
4. Verify authentication requirement works correctly

Once the premium flow is working, you can set up Google OAuth for production later.

## Summary

The Google OAuth issue is expected and doesn't block testing. Use email sign-in instead, which is more reliable on the simulator and sufficient for testing the premium purchase authentication flow.
