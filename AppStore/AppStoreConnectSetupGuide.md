# App Store Connect Setup Guide - Kansyl

## 📋 Prerequisites Checklist
Before starting, make sure you have:
- [x] Apple Developer Account (APPROVED ✓)
- [x] App metadata ready (`AppStoreMetadata.md`)
- [x] Screenshots ready (6.7" and 6.5" iPhone)
- [x] Reviewer notes prepared (`ReviewerNotes.md`)
- [x] Privacy Policy URL: `https://kansyl.juan-oclock.com/privacy`
- [x] Support URL: `https://kansyl.juan-oclock.com`
- [ ] App built and archived in Xcode (we'll do this later)

---

## PART 1: Create New App in App Store Connect

### Step 1: Access App Store Connect
1. Go to **https://appstoreconnect.apple.com**
2. Sign in with your Apple Developer account
3. Click **"My Apps"**

### Step 2: Create New App
1. Click the **"+" button** (top-left corner)
2. Select **"New App"**
3. Click **"iOS"** as the platform

### Step 3: Fill in Basic Information

**Bundle ID:**
```
com.juan-oclock.kansyl.kansyl
```
⚠️ **Important:** This MUST match exactly what's in your Xcode project!

**App Name:**
```
Kansyl - Subscription Manager
```
(30 characters max - this is what shows in the App Store)

**Primary Language:**
```
English (U.S.)
```

**SKU:**
```
kansyl-ios-v1
```
(This is for your internal tracking - users never see it)

**User Access:**
```
Full Access
```

4. Click **"Create"**

---

## PART 2: App Information Section

### Step 1: Navigate to App Information
1. In the left sidebar, click **"App Information"**

### Step 2: Fill Required Fields

**Subtitle** (30 characters max):
```
Track trials & subscriptions
```

**Privacy Policy URL:**
```
https://kansyl.juan-oclock.com/privacy
```

**Category** (Primary):
```
Finance
```

**Category** (Secondary - optional):
```
Productivity
```

**Content Rights:**
```
☑️ Contains third-party content
```
(Because you use DeepSeek AI for scanning)

**Age Rating:**
- Click **"Edit"** next to Age Rating
- Answer the questionnaire (all "No" for your app)
- Should result in **4+** rating
- Click **"Done"**

3. Click **"Save"** (top-right)

---

## PART 3: Pricing and Availability

### Step 1: Navigate to Pricing and Availability
1. In the left sidebar, click **"Pricing and Availability"**

### Step 2: Set Pricing
**Price:**
```
Free (0 USD)
```

**Availability:**
```
☑️ Make this app available in all territories
```

Or select specific countries if you prefer.

**Pre-Orders:**
```
☐ Do not enable pre-orders
```

**App Distribution Method:**
```
Public
```

3. Click **"Save"**

---

## PART 4: Prepare for Submission

### Step 1: Create Version 1.0
1. In the left sidebar, under **"iOS App"**, you should see **"1.0 Prepare for Submission"**
2. Click on it

### Step 2: Screenshots & App Preview

**iPhone 6.7" Display** (iPhone 15 Pro Max, 16 Pro Max):
- Click **"iPhone 6.7" Display"** 
- Upload all 6 screenshots from:
  ```
  /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots/6.7-inch-iPhone/
  ```
- Order:
  1. 01-Main-List-iPhone-16-Pro-Max.png
  2. 02-AddSubscription-iPhone16ProMax.png
  3. 03-Detail-iPhone16ProMax.png
  4. 04-Notifications-iPhone16ProMax.png
  5. 05-Savings-iPhone16ProMax.png
  6. 06-Settings-iPhone16ProMax.png

**iPhone 6.5" Display** (iPhone 11 Pro Max, XS Max):
- Click **"iPhone 6.5" Display"**
- Upload all 6 screenshots from:
  ```
  /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots/6.5-inch-iPhone/
  ```
- Use same order (01-06)

### Step 3: Promotional Text (Optional)
```
Track all your subscriptions in one place. Never forget a trial ending or renewal date again!
```
(170 characters max - appears above description)

### Step 4: Description
Copy and paste from `AppStoreMetadata.md` (lines 17-78):

```
**Take Control of Your Subscriptions**

Kansyl is your intelligent companion for managing all your subscriptions—free trials, premium services, and promotional offers. Never waste money on forgotten renewals again!

**Key Features:**

📅 **Smart Subscription Management**
- Track free trials, premium subscriptions, and promo offers
- Get timely reminders before renewals and trial endings
- Visual timeline of all upcoming payments
- Quick-add with smart service detection

💰 **Save Money**
- Track savings from canceled subscriptions
- Monitor total monthly and yearly spending
- Get personalized insights on subscription habits
- Identify unused or forgotten services

🏆 **Achievements & Gamification**
- Unlock achievements for smart trial management
- Track your savings milestones
- Build good subscription habits
- Share your savings success with friends

⚡ **Powerful Features**
- Home Screen widgets for at-a-glance info
- Siri Shortcuts for hands-free management
- Share Extension to add subscriptions from any app
- Cloud sync across all your devices
- Dark mode support

📊 **Analytics & Insights**
- Detailed spending analytics
- Trial history and patterns
- Waste prevention score
- Export data in CSV or JSON

🔔 **Smart Notifications**
- Customizable reminder schedule
- Multiple alert timings
- Critical alerts for ending trials
- Silent hours support

**Why Kansyl?**

The average person has 12+ active subscriptions and forgets about 40% of their free trials, leading to hundreds of dollars in unwanted charges yearly. Kansyl helps you:
- Save an average of $200+ per year
- Never miss a cancellation deadline or renewal date
- Track all subscriptions in one place
- Make informed decisions about what to keep or cancel
- Build better financial habits

**Privacy First**
Your data stays on your device. Optional cloud sync keeps your data secure and private. We don't collect or sell your personal information.

**Premium Features (Optional)**
- Unlimited subscription tracking
- Advanced analytics and insights
- Priority support
- Custom notification sounds
- CSV/JSON export

Download Kansyl today and start saving!
```

### Step 5: Keywords
```
trial,subscription,tracker,cancel,reminder,free trial,money,save,budget,finance,subscription manager,trial reminder,subscription tracker,cancel subscriptions
```
(100 characters max - comma-separated, no spaces after commas)

### Step 6: Support URL
```
https://kansyl.juan-oclock.com
```

### Step 7: Marketing URL (Optional)
```
https://kansyl.juan-oclock.com
```

### Step 8: What's New in This Version
```
### Initial Release
- Track free trials, subscriptions, and promotional offers
- Smart notifications for renewals and trial endings
- Home Screen widgets
- Siri Shortcuts integration
- Achievement system
- Savings tracker
- Share Extension
- Cloud sync
- Dark mode support
- Export functionality
```

---

## PART 5: Build Section

**Important:** You'll upload your build later. For now, you can skip this and come back after archiving in Xcode.

Click **"Select a build before you submit your app"** when ready (we'll do this in the next step).

---

## PART 6: General App Information

### App Icon
- Will automatically pull from your uploaded build
- Must be 1024x1024 pixels (Xcode handles this)

### Version
```
1.0
```

### Copyright
```
© 2025 Juan O'Clock
```

### Routing App Coverage File
```
Not applicable (leave blank)
```

---

## PART 7: App Review Information

This is where your reviewer notes go!

### Sign-in Required
```
☐ No (app works without sign-in)
```

### Contact Information
**First Name:**
```
Juan
```

**Last Name:**
```
O'Clock
```

**Phone Number:**
```
[Your phone number with country code]
```
Example: +1-555-123-4567

**Email Address:**
```
support@kansyl.juan-oclock.com
```

### Notes for Review
Paste key sections from `ReviewerNotes.md`:

```
## Overview
Kansyl is a subscription management app that tracks free trials, premium subscriptions, and promotional offers. Works completely offline. No account required.

## How to Test
1. Launch app (no sign-in needed)
2. Add 5 subscriptions using the + button
3. Try to add a 6th to see the free tier limit
4. Mark one as cancelled to test savings tracker
5. Enable notifications in Settings

## Third-Party Services
- DeepSeek AI: Optional receipt scanning (user must tap "Scan Receipt")
- Supabase: Optional cloud sync (user must sign in with Google)

## Permissions
- Notifications: For trial reminders
- Camera/Photos: Only if user scans receipts (optional)

## Free Tier
- 5 subscriptions max for free users
- This is intentional, not a bug

## Notes
- App works 100% offline
- Google Sign-In is optional
- No Apple Sign In in v1.0 (planned for future)

Thank you for reviewing!
```

### Demo Account (Not needed)
```
☐ Not required
```

---

## PART 8: Version Release

**Automatically release this version:**
```
☑️ Yes (recommended for v1.0)
```

Or select "Manually release" if you want to control the exact release time after approval.

---

## PART 9: Privacy Details (CRITICAL)

### Step 1: Navigate to App Privacy
1. Click **"App Privacy"** in the left sidebar
2. Click **"Get Started"**

### Step 2: Data Collection
Answer these questions:

**Do you or your third-party partners collect data from this app?**
```
☑️ Yes
```

### Step 3: Data Types Collected

**Contact Info:**
- ☑️ **Email Address**
  - Used for: App functionality (authentication)
  - Linked to user: Yes
  - Used for tracking: No

**User Content:**
- ☑️ **Other User Content** (subscription data)
  - Used for: App functionality
  - Linked to user: Yes
  - Used for tracking: No

**Usage Data:**
- ☑️ **Product Interaction** (analytics)
  - Used for: Analytics
  - Linked to user: No
  - Used for tracking: No

### Step 4: Third-Party Partners
Answer questions about:
- DeepSeek: Image processing (receipts)
- Supabase: Data storage
- Google OAuth: Authentication

### Step 5: Privacy Policy
Confirm your privacy policy URL:
```
https://kansyl.juan-oclock.com/privacy
```

---

## PART 10: Save & Submit

### Before Submitting:
- [ ] All screenshots uploaded
- [ ] Description and metadata complete
- [ ] Privacy details filled out
- [ ] Reviewer notes added
- [ ] Build uploaded (we'll do this next)

### To Submit:
1. Click **"Add for Review"** (top-right)
2. Review all information
3. Click **"Submit for Review"**

---

## 🎯 NEXT STEPS AFTER THIS SETUP

Once App Store Connect is configured:

1. **Archive your app in Xcode**
   - Product > Archive
   - Validate Archive
   - Distribute to App Store

2. **Wait for build processing** (10-30 minutes)

3. **Select build in App Store Connect**
   - Return to version 1.0
   - Click "Select a build"
   - Choose your uploaded build

4. **Submit for review**

5. **Wait for approval** (typically 24-48 hours)

---

## 📁 Reference Files

- **Metadata:** `/AppStore/AppStoreMetadata.md`
- **Screenshots (6.7"):** `/AppStore/Screenshots/6.7-inch-iPhone/`
- **Screenshots (6.5"):** `/AppStore/Screenshots/6.5-inch-iPhone/`
- **Reviewer Notes:** `/AppStore/ReviewerNotes.md`
- **Privacy Policy:** `https://kansyl.juan-oclock.com/privacy`

---

## ⚠️ Common Issues & Solutions

**Issue: Bundle ID not found**
- Solution: Make sure Bundle ID in App Store Connect matches Xcode exactly

**Issue: Screenshots rejected**
- Solution: We may need to resize to exact Apple dimensions

**Issue: Privacy questions confusing**
- Solution: Refer to `ReviewerNotes.md` for what data you collect

**Issue: Build not appearing**
- Solution: Wait 30 minutes after upload, check for email from Apple

---

## ✅ Estimated Time

- **App Store Connect setup:** 30-45 minutes
- **Archive & upload:** 20 minutes
- **Review wait time:** 24-48 hours

**Total time to live:** ~2-3 days from now!

---

Good luck with your submission! 🚀
