# Apple Developer Account Setup Guide for Kansyl

**App Name**: Kansyl - Free Trial Reminder  
**Bundle ID**: `com.juan-oclock.kansyl.kansyl`  
**Date**: October 2, 2025  
**Status**: Apple Developer Program APPROVED ✅

---

## Overview

Now that your Apple Developer Program membership is approved, you need to complete several setup tasks in the Apple Developer Portal and App Store Connect. This guide walks you through each step.

---

## Step 1: Access Apple Developer Portal & App Store Connect

### Apple Developer Portal
1. Go to: https://developer.apple.com/account/
2. Sign in with your Apple ID
3. Verify you see "Apple Developer Program" membership active

### App Store Connect
1. Go to: https://appstoreconnect.apple.com/
2. Sign in with the same Apple ID
3. You should now have access to all features

---

## Step 2: Complete Tax and Banking Information

### Navigate to Agreements, Tax, and Banking
1. In **App Store Connect**, click your name (top right)
2. Select **Agreements, Tax, and Banking**
3. Complete each section:

#### Agreements
- [ ] Review and accept the **Paid Applications Agreement**
- [ ] Review and accept the **Free Applications Agreement** (if available)
- [ ] Note: You must accept these before you can submit apps

#### Banking
- [ ] Click **Set Up** under Banking
- [ ] Enter your bank account information for receiving payments (if offering paid apps/IAP)
- [ ] Provide account holder name, bank name, account number, routing number
- [ ] Note: Even for free apps, it's good to have this set up for future

#### Tax Forms
- [ ] Click **Set Up** under Tax Forms
- [ ] Complete U.S. Tax Forms (W-9 if US-based, W-8BEN if international)
- [ ] Answer questions about your tax status
- [ ] Digital signature required
- [ ] Note: Required even for free apps

**Expected Time**: 15-20 minutes

---

## Step 3: Create App ID (Identifier)

### In Apple Developer Portal
1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click the **"+"** button (top left)
3. Select **App IDs**, then click **Continue**
4. Select **App**, then click **Continue**

### Configure Your App ID
1. **Description**: `Kansyl - Free Trial Reminder`
2. **Bundle ID**: Select **Explicit**
3. Enter: `com.juan-oclock.kansyl.kansyl`
4. **Capabilities**: Enable the following:
   - [x] **Push Notifications** (for trial reminders)
   - [x] **App Groups** (for Share Extension)
   - [x] **Associated Domains** (for Universal Links - optional)
   - [ ] **CloudKit** (optional - if you want cloud sync later)
   - [ ] **Sign in with Apple** (optional - you're using Google auth)

5. Click **Continue**
6. Review and click **Register**

**Bundle ID Status**: 🎯 Will be `com.juan-oclock.kansyl.kansyl`

---

## Step 4: Create App Groups (for Share Extension)

Your app has a Share Extension (`KansylShareExtension`) that needs to share data with the main app.

### Create App Group
1. In Apple Developer Portal, go to: https://developer.apple.com/account/resources/identifiers/list/applicationGroup
2. Click the **"+"** button
3. Select **App Groups**, click **Continue**
4. **Description**: `Kansyl App Group`
5. **Identifier**: `group.com.juan-oclock.kansyl`
6. Click **Continue**, then **Register**

### Associate App Group with App ID
1. Go back to your App ID: `com.juan-oclock.kansyl.kansyl`
2. Click **Edit**
3. Find **App Groups** and click **Configure**
4. Select `group.com.juan-oclock.kansyl`
5. Click **Save**

### Create App ID for Share Extension
1. Repeat the App ID creation process for the Share Extension
2. **Description**: `Kansyl Share Extension`
3. **Bundle ID**: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`
4. **Capabilities**: Enable **App Groups**
5. Configure App Groups to use `group.com.juan-oclock.kansyl`
6. Click **Register**

---

## Step 5: Create Distribution Certificate

### Generate Certificate Signing Request (CSR)
1. Open **Keychain Access** on your Mac (Applications > Utilities)
2. Menu: **Keychain Access** > **Certificate Assistant** > **Request a Certificate from a Certificate Authority**
3. Enter your email address
4. Enter your name
5. Select **Saved to disk**
6. Click **Continue**
7. Save as `CertificateSigningRequest.certSigningRequest`

### Create Distribution Certificate
1. In Apple Developer Portal, go to: https://developer.apple.com/account/resources/certificates/list
2. Click the **"+"** button
3. Select **Apple Distribution** (under Software)
4. Click **Continue**
5. Upload the CSR file you just created
6. Click **Continue**
7. Download the certificate
8. Double-click the downloaded certificate to install it in Keychain Access

**Note**: Keep this certificate safe! You'll need it for all future builds.

---

## Step 6: Create Push Notifications Key (APNs)

For push notifications, Apple now recommends using an APNs Auth Key instead of certificates.

### Create APNs Key
1. In Apple Developer Portal, go to: https://developer.apple.com/account/resources/authkeys/list
2. Click the **"+"** button
3. **Key Name**: `Kansyl Push Notifications Key`
4. Enable **Apple Push Notifications service (APNs)**
5. Click **Continue**
6. Click **Register**
7. **Download the key** (you can only download it once!)
8. Save it securely as `AuthKey_XXXXXXXXXX.p8`
9. Note the **Key ID** (10 characters, e.g., `ABC123DEFG`)
10. Note your **Team ID** (found in your account settings)

### Important
- ⚠️ **Save this key securely!** You can only download it once
- You'll need the Key ID and Team ID for your backend push notification service
- Store in a secure location (password manager recommended)

---

## Step 7: Create App Store Provisioning Profile

### Create Profile
1. In Apple Developer Portal, go to: https://developer.apple.com/account/resources/profiles/list
2. Click the **"+"** button
3. Select **App Store** (under Distribution)
4. Click **Continue**
5. Select your App ID: `com.juan-oclock.kansyl.kansyl`
6. Click **Continue**
7. Select the Distribution Certificate you just created
8. Click **Continue**
9. **Profile Name**: `Kansyl App Store Distribution`
10. Click **Generate**
11. Download and double-click to install

### Create Profile for Share Extension
1. Repeat the process for the Share Extension
2. Select App ID: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`
3. **Profile Name**: `Kansyl Share Extension App Store Distribution`
4. Download and install

---

## Step 8: Update Xcode Project Configuration

Now that certificates and profiles are created, update your Xcode project:

### Open Xcode
1. Open `kansyl.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **kansyl** target

### Signing & Capabilities
1. Select the **Signing & Capabilities** tab
2. **Automatically manage signing**: ✅ Keep enabled (recommended)
3. **Team**: Select your Apple Developer Program team
4. **Bundle Identifier**: Verify it's `com.juan-oclock.kansyl.kansyl`
5. Xcode should automatically:
   - Download provisioning profiles
   - Configure signing certificate
   - Enable capabilities

### Enable Capabilities
Click **+ Capability** and add:
1. **Push Notifications**
2. **App Groups**
   - Click **+** under App Groups
   - Add `group.com.juan-oclock.kansyl`

### Update Entitlements File
The file at `kansyl/kansyl.entitlements` currently has capabilities commented out.

**I'll help you update this file in the next step!**

### Configure Share Extension Target
1. Select the **KansylShareExtension** target
2. Go to **Signing & Capabilities**
3. Set the same team
4. Verify Bundle ID: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`
5. Add **App Groups** capability
6. Add the same group: `group.com.juan-oclock.kansyl`

---

## Step 9: Verification Checklist

Before proceeding, verify:

### Apple Developer Portal
- [x] ✅ Apple Developer Program membership active
- [ ] App ID created: `com.juan-oclock.kansyl.kansyl`
- [ ] App ID created: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`
- [ ] App Group created: `group.com.juan-oclock.kansyl`
- [ ] Distribution Certificate created and installed
- [ ] Push Notifications Key created and saved
- [ ] App Store provisioning profiles created and installed

### App Store Connect
- [ ] Agreements accepted
- [ ] Tax forms completed
- [ ] Banking information entered (if applicable)

### Xcode
- [ ] Team selected in project settings
- [ ] Automatic signing working
- [ ] Push Notifications capability enabled
- [ ] App Groups capability configured
- [ ] Share Extension configured

---

## Step 10: Next Steps

Once all the above is complete, you're ready to:

1. ✅ **Update entitlements file** (we'll do this next)
2. ✅ **Create App Store Connect listing** (Section 2 of checklist)
3. ✅ **Configure app metadata** (description, screenshots, etc.)
4. ✅ **Build and upload to TestFlight**
5. ✅ **Submit for review**

---

## Troubleshooting

### "No signing certificate found"
- Make sure you downloaded and installed the Distribution Certificate
- Check Keychain Access to verify it's installed
- Try restarting Xcode

### "No provisioning profile found"
- Download profiles from Developer Portal
- Double-click to install them
- Or let Xcode automatically manage signing

### "App ID already exists"
- Someone else may have registered that Bundle ID
- You'll need to choose a different Bundle ID
- Update your Xcode project with the new Bundle ID

### "Team not found"
- Sign out and back into Xcode with your Apple ID
- Go to Xcode > Preferences > Accounts
- Add your Apple Developer account

---

## Important URLs

- **Apple Developer Portal**: https://developer.apple.com/account/
- **App Store Connect**: https://appstoreconnect.apple.com/
- **Certificates**: https://developer.apple.com/account/resources/certificates/list
- **Identifiers**: https://developer.apple.com/account/resources/identifiers/list
- **Profiles**: https://developer.apple.com/account/resources/profiles/list
- **Keys**: https://developer.apple.com/account/resources/authkeys/list

---

## Support

If you encounter issues:
- **Apple Developer Support**: https://developer.apple.com/contact/
- **Phone**: 1-800-633-2152 (US)
- **Developer Forums**: https://developer.apple.com/forums/

---

**Good luck! The setup process takes about 30-45 minutes if everything goes smoothly.** 🚀

Once you complete these steps, come back and we'll proceed with updating your Xcode configuration and creating the App Store Connect listing!
