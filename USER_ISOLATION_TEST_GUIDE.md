# User Isolation Test Guide

## Overview
This guide helps verify that all user preferences, settings, and data are properly isolated between different users on the same device.

## Test Setup
You'll need at least 2 test user accounts:
- User A: test1@example.com
- User B: test2@example.com

## Test Scenarios

### 1. Theme Preferences Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Appearance
3. Change theme to Dark
4. Logout
5. Login as User B
6. Check Settings → Appearance

**Expected Result:** 
- User B should see the default theme (System), NOT Dark

### 2. Currency Settings Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Currency
3. Change currency to EUR (€)
4. Logout
5. Login as User B
6. Check Settings → Currency

**Expected Result:**
- User B should see their default currency (based on location or USD), NOT EUR

### 3. Trial Length Preferences Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Default Trial Length
3. Change to 7 days
4. Logout
5. Login as User B
6. Check Settings → Default Trial Length

**Expected Result:**
- User B should see 30 days (default), NOT 7 days

### 4. Display Preferences Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Display
3. Enable Compact Mode
4. Disable Show Trial Logos
5. Logout
6. Login as User B
7. Check Settings → Display

**Expected Result:**
- User B should have:
  - Compact Mode: OFF (default)
  - Show Trial Logos: ON (default)

### 5. Notification Settings Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Notifications
3. Enable Quiet Hours (10 PM - 8 AM)
4. Logout
5. Login as User B
6. Check Settings → Notifications

**Expected Result:**
- User B should have Quiet Hours disabled (default)

### 6. Premium Status Isolation
**Steps:**
1. Login as User A (with premium subscription)
2. Verify premium features are available
3. Logout
4. Login as User B (free user)
5. Check premium status

**Expected Result:**
- User B should NOT have premium features
- User B should see upgrade options

### 7. Onboarding Status Isolation
**Steps:**
1. Create new User C account
2. Complete onboarding
3. Logout
4. Create new User D account
5. Login as User D

**Expected Result:**
- User D should see onboarding screens
- User D's onboarding completion shouldn't affect User C

### 8. Subscription Data Isolation
**Steps:**
1. Login as User A
2. Add subscriptions: Netflix, Spotify, Disney+
3. Logout
4. Login as User B
5. Check subscription list

**Expected Result:**
- User B should see NO subscriptions from User A
- User B should only see their own subscriptions

### 9. Analytics Preferences Isolation
**Steps:**
1. Login as User A
2. Go to Settings → Privacy
3. Disable Analytics
4. Logout
5. Login as User B
6. Check Settings → Privacy

**Expected Result:**
- User B should have Analytics enabled (default)

### 10. Quick User Switch Test
**Steps:**
1. Login as User A
2. Set theme to Dark, currency to EUR
3. Logout
4. Login as User B
5. Set theme to Light, currency to GBP
6. Logout
7. Login as User A again

**Expected Result:**
- User A should still have Dark theme and EUR currency
- Settings should persist per user

## Verification Checklist

- [ ] Theme preferences don't leak between users
- [ ] Currency settings are user-specific
- [ ] Trial length defaults are isolated
- [ ] Display preferences are per-user
- [ ] Notification settings don't cross users
- [ ] Premium status is correctly isolated
- [ ] Onboarding tracks per user
- [ ] Subscription data is completely isolated
- [ ] Analytics preferences are user-specific
- [ ] Settings persist correctly when switching users

## Implementation Status

### ✅ Completed
- Created `UserSpecificPreferences` class for user isolation
- Updated `AuthenticationWrapperView` to use user preferences
- Updated `ContentView` to use user preferences
- Updated `OnboardingView` to use user preferences
- Created migration helper `AppPreferencesMigration`
- Subscription data already filtered by userID

### ⚠️ In Progress
- Migrating all views from `AppPreferences.shared` to `UserSpecificPreferences`
- Testing all isolation scenarios

### 📝 Notes
- All preferences are now stored with user-specific keys (e.g., `user_12345_theme`)
- When a user logs out, preferences reset to defaults
- When a user logs back in, their preferences are restored
- The system maintains backward compatibility during migration