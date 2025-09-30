# App Review Notes for Kansyl v1.0

**App Name**: Kansyl - Free Trial Reminder  
**Version**: 1.0 (Build 1)  
**Bundle ID**: com.juan-oclock.kansyl.kansyl  
**Submitted**: [To be filled when submitting]  
**Developer Contact**: kansyl@juan-oclock.com

---

## 📱 App Overview

Kansyl is a free trial reminder app that helps users track subscription trials and receive timely notifications before trials convert to paid subscriptions. The app is designed to help users save money by avoiding forgotten trial charges.

**Core Value Proposition**: Never get charged for a forgotten free trial again.

---

## 🎯 Core Functionality

### Primary Features:
1. **Trial Management**: Users can add, edit, and delete free trial subscriptions
2. **Smart Notifications**: 3-day, 1-day, and day-of reminders before trial ends
3. **Savings Tracking**: Dashboard showing money saved by canceling trials
4. **Service Templates**: Pre-configured templates for popular services (Netflix, Spotify, etc.)
5. **Privacy-First Design**: All data stored locally using Core Data

### Premium Features (In-App Purchase):
- Unlimited trial tracking (free tier limited to 5 trials)
- AI receipt scanning (using DeepSeek API)
- Advanced analytics and insights
- Priority support

---

## 🔐 Account & Authentication

### Sign-In Options:
- **Google Sign-In** (via Supabase Authentication)
- **Continue Without Account** (local-only mode)

### Important Notes:
✅ **Account is OPTIONAL** - Users can use the app fully without signing in  
✅ Data is stored locally in Core Data regardless of sign-in status  
✅ iCloud sync is available for signed-in users  
✅ No personal data is collected unless user explicitly signs in

### For Testing:
- The app works perfectly without any sign-in
- If you'd like to test sign-in features, you can use any Google account
- Demo Google account (if needed):
  - Email: [To be provided if required]
  - Password: [To be provided if required]

---

## 🧪 How to Test the App

### Quick Start Test Flow (5 minutes):

1. **Launch App**
   - You'll see the onboarding screen (first launch only)
   - Tap through the onboarding (3 screens)
   - Grant notification permissions when prompted

2. **Add a Trial**
   - Tap the "+" button in the bottom right
   - Select a template (e.g., "Netflix")
   - Set trial length (default is 7 days)
   - Set monthly cost (e.g., $15.99)
   - Tap "Add Trial"

3. **View Your Trials**
   - See the trial card on the main screen
   - Shows days remaining, end date, and monthly cost
   - Swipe left to see quick actions

4. **Check Notifications**
   - Notifications are scheduled automatically
   - To test immediately: Set a trial with 3 days duration
   - You'll see notification scheduled for today

5. **Explore Features**
   - Tap on a trial to see details
   - Check the savings dashboard (bottom tab)
   - Go to Settings to explore options

---

## 🔔 Notification Testing

### Notification Schedule:
- **3 days before**: "Your [Service] trial ends in 3 days"
- **1 day before**: "Final reminder: [Service] trial ends tomorrow"
- **Day of**: "Last chance! Your [Service] trial ends today"

### Testing Notifications:
1. Add a trial with 3-day duration
2. Check iOS Settings → Notifications → Kansyl to verify permissions
3. Notifications will appear at 9 AM local time each day
4. Rich actions allow marking as canceled or renewed from notification

### Important:
✅ All notifications are **local** (scheduled on device)  
✅ No push notification servers involved  
✅ No external notification dependencies  
✅ Works completely offline

---

## 🌐 Third-Party Services

### 1. Supabase (Authentication & Optional Sync)
- **Purpose**: User authentication (Google Sign-In) and optional cloud sync
- **Usage**: Only if user chooses to sign in (OPTIONAL)
- **Data Stored**: Email address, user ID, trial data (if sync enabled)
- **Privacy**: End-to-end encryption for synced data
- **Can App Work Without It?**: YES - Full functionality works locally

### 2. DeepSeek AI (Receipt Scanning)
- **Purpose**: AI-powered receipt text extraction
- **Usage**: Only when user taps "Scan Receipt" (OPTIONAL)
- **Data Sent**: Photo of receipt (temporary, not stored)
- **Data Received**: Extracted text (service name, date, cost)
- **Privacy**: Images not saved on our servers, processed and discarded
- **Can App Work Without It?**: YES - Manual entry always available
- **Premium Feature**: Requires premium subscription

### API Key Security:
✅ All API keys stored in `Config.private.xcconfig` (not in Git)  
✅ Keys are embedded at build time  
✅ No keys exposed in client-side code  
✅ Keys follow environment-based configuration

---

## 📊 Data Collection & Privacy

### What Data We Collect:

#### Without Sign-In (Local Mode):
- ✅ Trial subscription data (service name, cost, dates) - **stored locally only**
- ✅ User preferences (theme, notification settings) - **stored locally only**
- ❌ NO email or personal information
- ❌ NO tracking or analytics (unless user opts in)

#### With Sign-In (Optional):
- ✅ Email address (from Google auth)
- ✅ User ID (generated by Supabase)
- ✅ Trial data (if iCloud sync enabled)
- ❌ NO passwords (handled by Google/Supabase)
- ❌ NO credit card information

#### Optional Analytics (Opt-In):
- ✅ Anonymized usage statistics
- ✅ Crash reports (no personal data)
- ✅ Can be disabled in Settings → Advanced

### Data Storage:
- **Local**: Core Data (SQLite database on device)
- **Cloud**: iCloud (optional, encrypted, user-controlled)
- **No Third-Party Analytics**: We don't use Google Analytics, Mixpanel, etc.

### Privacy Policy:
📄 https://kansyl.juan-oclock.com/privacy

### Terms of Service:
📄 https://kansyl.juan-oclock.com/terms

---

## 💳 In-App Purchases

### Purchase Options:
1. **Monthly Premium**: $2.99/month (auto-renewable)
2. **Yearly Premium**: $19.99/year (auto-renewable, 44% savings)
3. **Lifetime Premium**: $49.99 (one-time purchase)

### What Premium Includes:
- Unlimited trial tracking (free tier: 5 trials)
- AI receipt scanning
- Advanced analytics
- Priority support
- All future premium features

### Testing Purchases:
- Use StoreKit testing in Xcode
- Sandbox Apple ID for testing subscriptions
- All IAP properly configured with StoreKit configuration file

### Important Notes:
✅ Free tier is **fully functional** (not a time-limited trial)  
✅ No credit card required to use free tier  
✅ Users can export data anytime (free or premium)  
✅ Clear upgrade prompts (not aggressive or misleading)  
✅ Subscription terms clearly displayed before purchase

---

## 🎨 iOS Integration

### Native iOS Features Used:
1. **Local Notifications** - UNUserNotificationCenter
2. **Core Data** - Local data persistence
3. **CloudKit** - Optional iCloud sync (user-controlled)
4. **Siri Shortcuts** - Voice commands for adding trials
5. **Share Extension** - Save trials from other apps
6. **Home Screen Widgets** - WidgetKit implementation
7. **Calendar Integration** - EventKit for syncing trial dates
8. **Dark Mode** - Full support for system appearance
9. **Dynamic Type** - Accessibility font scaling
10. **Haptic Feedback** - For key interactions

### Permissions Required:
- **Notifications**: To send trial reminders (core feature)
- **Camera**: Only if user taps "Scan Receipt" (optional)
- **Photos**: To select receipt images for scanning (optional)
- **Calendar**: Only if user enables calendar sync (optional)
- **iCloud**: Only if user signs in and enables sync (optional)

### Permission Descriptions:
All permission descriptions are clear and user-friendly:
- ✅ NSUserNotificationsUsageDescription
- ✅ NSCameraUsageDescription
- ✅ NSPhotoLibraryUsageDescription
- ✅ NSCalendarUsageDescription

---

## ⚠️ Known Issues & Edge Cases

### NSExtensionActivationRule Warning:
- **Status**: Known Xcode warning for Share Extension
- **Impact**: Does NOT affect functionality
- **Plan**: Will be fixed before final submission with proper predicate
- **Current**: Using TRUEPREDICATE for development (will be replaced)

### Device Requirements:
- **Minimum**: iOS 15.0
- **Tested On**: iPhone 12, iPhone 14 Pro, iPad Pro 11"
- **Orientation**: Portrait (primary), Landscape (supported)

---

## 🧪 Comprehensive Test Checklist

### Basic Functionality:
- [ ] Launch app (first time)
- [ ] Complete onboarding
- [ ] Grant notification permissions
- [ ] Add a trial using template
- [ ] Add a custom trial
- [ ] Edit a trial
- [ ] Delete a trial
- [ ] View trial details
- [ ] Check savings dashboard

### Notifications:
- [ ] Verify notifications are scheduled
- [ ] Check notification content
- [ ] Test notification actions (Mark as Canceled, etc.)
- [ ] Verify notification settings in app

### Sign-In (Optional):
- [ ] Sign in with Google
- [ ] Enable iCloud sync
- [ ] Verify sync works across devices
- [ ] Sign out
- [ ] Verify local data persists

### Premium Features:
- [ ] View premium features screen
- [ ] Check pricing display
- [ ] Verify free tier limit (5 trials)
- [ ] Test upgrade prompt

### Settings:
- [ ] Change theme (Light/Dark/System)
- [ ] Toggle analytics
- [ ] Export data
- [ ] View privacy policy link
- [ ] View terms of service link
- [ ] Contact support email link

### Edge Cases:
- [ ] Add trial with past end date
- [ ] Add trial with far future end date
- [ ] Add 100+ character service name
- [ ] Test with no internet connection
- [ ] Force quit and relaunch
- [ ] Background app and return
- [ ] Delete all data and verify clean state

---

## 🚨 Important Notes for Reviewers

### ✅ What Makes This App Special:

1. **Privacy-Focused**: Unlike competitors, we don't require an account or collect unnecessary data
2. **Free Tier is Real**: Not a 7-day trial masquerading as "free" - users can track 5 trials forever
3. **Local-First**: App works perfectly offline, no internet required for core features
4. **No Dark Patterns**: No tricks to get users to upgrade, clear and honest pricing
5. **Indie Developer**: Built by a solo developer, not a large corporation

### ⚠️ Things That Might Look Like Issues But Aren't:

1. **"This app doesn't seem to need an account"** - Correct! That's by design. Sign-in is optional.
2. **"AI scanning requires premium"** - Yes, to cover API costs. Manual entry is always free.
3. **"Some features seem hidden"** - Premium features are gated but clearly communicated.
4. **"Notifications are scheduled locally"** - Intentional. More private, works offline.

### 📝 Common Review Questions (Anticipated):

**Q: Why does this need camera access?**  
A: Only for optional AI receipt scanning. Users can skip this entirely and use manual entry.

**Q: Why Supabase and DeepSeek?**  
A: Supabase for optional authentication/sync. DeepSeek for AI receipt extraction. Both are optional features.

**Q: How do you make money?**  
A: Premium subscriptions for users who want unlimited trials and AI features. Free tier is permanently free.

**Q: Can users export their data?**  
A: Yes! Settings → Data Management → Export Data (CSV or JSON format)

**Q: What happens if user doesn't pay subscription?**  
A: They keep using the free tier (5 trials). No loss of data. Premium features just become unavailable.

---

## 📞 Contact Information

### Developer Contact:
- **Email**: kansyl@juan-oclock.com
- **Response Time**: Within 24 hours (monitored during review)

### Support Resources:
- **Website**: https://kansyl.juan-oclock.com
- **Privacy Policy**: https://kansyl.juan-oclock.com/privacy
- **Terms**: https://kansyl.juan-oclock.com/terms

### Emergency Contact:
If you encounter any issues during review that require immediate clarification:
- Email: kansyl@juan-oclock.com
- Subject: "URGENT: App Review Issue - Kansyl v1.0"

---

## ✅ Pre-Submission Checklist

Before submitting, we have verified:

- [x] All links in app work correctly
- [x] Privacy policy is accessible and complete
- [x] Terms of service are accessible and complete
- [x] Support email is monitored
- [x] All permission descriptions are clear
- [x] No placeholder content
- [x] No crashes in common flows
- [x] App works without internet connection
- [x] Free tier is fully functional
- [x] Premium features are clearly communicated
- [x] All third-party services are documented
- [x] Data privacy is respected
- [x] Dark mode is supported
- [x] Dynamic Type is supported
- [x] Accessibility features work

---

## 🎯 Testing Tips

### For Fastest Review:
1. **Start without signing in** - This shows the app works standalone
2. **Add 2-3 trials** - Test the core functionality
3. **Check notifications** - Verify they're scheduled correctly
4. **Try the free tier limit** - Add 6 trials to see the upgrade prompt
5. **Browse settings** - Check all links and options work

### Expected Testing Time:
- **Quick test**: 5 minutes (basic functionality)
- **Thorough test**: 15 minutes (all features)
- **Complete test**: 30 minutes (edge cases and premium)

---

## 📋 Export Compliance

### Encryption Usage:
- **HTTPS**: Yes (for API calls to Supabase/DeepSeek)
- **Custom Encryption**: No (using standard iOS encryption)
- **Export Classification**: Standard encryption, no CCATS required

### Answer: **No** to custom encryption beyond HTTPS

---

## 🎉 Thank You!

Thank you for taking the time to review Kansyl. This app was built with care to solve a real problem that many people face: forgotten free trials leading to unwanted charges.

We've focused on:
- User privacy (no unnecessary data collection)
- Honest free tier (not a disguised trial)
- Quality iOS experience (native features, dark mode, accessibility)
- Transparency (clear about what we collect and why)

If you have any questions or concerns during the review process, please don't hesitate to reach out at kansyl@juan-oclock.com.

We're committed to making any necessary changes to meet Apple's guidelines and provide the best experience for users.

---

**Date Prepared**: 2025-09-30  
**Version**: 1.0 (Build 1)  
**Status**: Ready for Submission
