# Kansyl App - Quick Reference Card

## 📱 App Identifiers

### Bundle IDs
- **Main App**: `com.juan-oclock.kansyl.kansyl`
- **Share Extension**: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`

### App Group
- **Identifier**: `group.com.juan-oclock.kansyl`
- **Description**: Kansyl App Group
- **Purpose**: Share data between main app and Share Extension

### App Information
- **App Name**: Kansyl
- **Subtitle**: Never Miss a Free Trial
- **Category**: Productivity (Primary) / Finance (Secondary option)
- **Price**: Free
- **Minimum iOS**: 15.0
- **Supported Devices**: iPhone & iPad

---

## 🔐 Certificates & Keys

### Distribution Certificate
- **Type**: Apple Distribution
- **Purpose**: Sign app for App Store submission
- **Location**: Keychain Access > My Certificates
- **Note**: Keep private key safe!

### Push Notifications Key
- **Type**: APNs Auth Key (.p8 file)
- **Key Name**: Kansyl Push Notifications Key
- **Format**: `AuthKey_XXXXXXXXXX.p8`
- **Note**: Download only once - save securely!
- **Required Info**:
  - Key ID (10 characters)
  - Team ID (from Apple Developer account)

---

## 🎯 Capabilities Required

### Main App (kansyl)
- [x] Push Notifications
- [x] App Groups (`group.com.juan-oclock.kansyl`)
- [ ] Associated Domains (optional - for Universal Links)
- [ ] CloudKit (optional - for future cloud sync)
- [ ] Sign in with Apple (optional - using Google auth currently)

### Share Extension (KansylShareExtension)
- [x] App Groups (`group.com.juan-oclock.kansyl`)

---

## 🔗 Important URLs

### Your App URLs
- **Website**: https://kansyl.juan-oclock.com
- **Privacy Policy**: https://kansyl.juan-oclock.com/privacy
- **Terms of Service**: https://kansyl.juan-oclock.com/terms
- **Support Email**: (add your email here)

### Apple URLs
- **Developer Portal**: https://developer.apple.com/account/
- **App Store Connect**: https://appstoreconnect.apple.com/
- **Certificates**: https://developer.apple.com/account/resources/certificates/list
- **Identifiers**: https://developer.apple.com/account/resources/identifiers/list
- **Profiles**: https://developer.apple.com/account/resources/profiles/list
- **Keys**: https://developer.apple.com/account/resources/authkeys/list

---

## 📄 Privacy Descriptions (Already Configured)

### NSUserNotificationsUsageDescription
"Kansyl sends you timely reminders before your free trials end, helping you avoid unwanted charges."

### NSCameraUsageDescription
"Kansyl needs access to your camera to scan receipts and automatically detect subscription information using AI."

### NSPhotoLibraryUsageDescription
"Kansyl needs access to your photo library to let you add custom logos for your subscriptions and scan receipt images for AI-powered subscription detection."

### NSCalendarUsageDescription
"Kansyl needs access to your calendar to create reminders for your trial end dates. This helps ensure you never forget to cancel unwanted subscriptions."

---

## 🔧 Version Information

### Current Build
- **Version**: 1.0
- **Build**: 1
- **Release Type**: Initial Release

### For Next Submission
- Increment build number (e.g., Build 2)
- Keep version 1.0 for initial release
- Update "What's New" for future versions

---

## 📊 Data Collection Summary (for Privacy Label)

### Data Linked to User
- **Email Address**: Yes (for authentication via Supabase Google auth)
- **Subscription Data**: Yes (user-entered trial information, stored locally)

### Data NOT Collected
- Name
- Physical Address
- Phone Number
- Payment Information
- Purchase History (beyond what user manually tracks)
- Precise Location
- Browsing History

### Tracking
- **Used for Tracking**: NO
- **Third-party Analytics**: NO (unless you add analytics)

---

## 🎨 App Store Metadata

### Keywords (Draft - max 100 characters)
```
free trial,subscription,reminder,tracker,trials,money,savings,notifications,budgeting
```
**Character count**: 89/100 ✅

### Promotional Text (Draft - max 170 characters)
```
Track unlimited free trials, get smart reminders, and save money. Join thousands who never miss a trial deadline!
```
**Character count**: 114/170 ✅

### Release Notes (v1.0)
```
Initial release! Track your free trials, get timely reminders, and never get charged unexpectedly again.

Features:
• Lightning-fast trial entry
• Smart notifications before trials end
• Beautiful, intuitive interface
• Privacy-focused local storage
• Siri Shortcuts support
```

---

## 🔒 Security Notes

### API Keys (Already Secured)
- **Location**: `Config.private.xcconfig`
- **Services**: DeepSeek, Supabase
- **Status**: ✅ Not hardcoded in source

### Backend Services
- **Authentication**: Supabase (Google OAuth)
- **Receipt Scanning**: DeepSeek AI
- **Data Storage**: Local + Supabase

---

## ✅ Pre-Submission Checklist

### Web Tasks (Do in Browser)
- [ ] Accept agreements in App Store Connect
- [ ] Complete tax forms
- [ ] Enter banking information
- [ ] Create App ID: `com.juan-oclock.kansyl.kansyl`
- [ ] Create App ID: `com.juan-oclock.kansyl.kansyl.KansylShareExtension`
- [ ] Create App Group: `group.com.juan-oclock.kansyl`
- [ ] Create Distribution Certificate
- [ ] Create Push Notifications Key
- [ ] Create App Store provisioning profiles

### Xcode Tasks (Do After Web Setup)
- [ ] Update entitlements file (use `kansyl.entitlements.READY`)
- [ ] Select team in project settings
- [ ] Enable Push Notifications capability
- [ ] Configure App Groups capability
- [ ] Configure Share Extension
- [ ] Fix compiler warnings
- [ ] Run and pass tests

### Content Tasks
- [ ] Create screenshots (6.7", 6.5", 5.5")
- [ ] Write app description
- [ ] Finalize keywords
- [ ] Create app icon (if not done)
- [ ] Prepare reviewer notes

---

## 📞 Support Contacts

### Apple Support
- **Developer Support**: https://developer.apple.com/contact/
- **Phone**: 1-800-633-2152 (US)
- **App Review**: Use Resolution Center in App Store Connect

### Third-Party Services
- **Supabase Support**: support@supabase.io
- **DeepSeek Support**: (check their documentation)

---

**Last Updated**: October 2, 2025  
**Status**: Ready for Developer Portal setup 🚀
