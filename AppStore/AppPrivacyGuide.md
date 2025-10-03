# App Privacy Questionnaire Guide - Kansyl

## 📍 Where to Find This
App Store Connect > Your App > App Privacy > Get Started

---

## ⚠️ IMPORTANT
Apple REQUIRES this before you can submit your app. Every answer below is based on what your app actually collects.

---

## QUESTION 1: Data Collection

**"Do you or your third-party partners collect data from this app?"**

**Answer:** ✅ **YES**

**Why:** You collect:
- Email addresses (when users sign in)
- Subscription data
- Basic analytics via Firebase

---

## QUESTION 2: Data Types

You'll be asked to select which types of data you collect. Check the following:

---

### 📧 CONTACT INFO

**✅ Email Address**

**Purposes for collecting:**
- ☑️ App Functionality
- ☐ Analytics (unchecked)
- ☐ Product Personalization (unchecked)
- ☐ Developer's Advertising or Marketing (unchecked)
- ☐ Third-Party Advertising (unchecked)
- ☐ Other Purposes (unchecked)

**Is this data linked to the user's identity?**
- ✅ **Yes** (when they sign in with Apple/Google/Email)

**Do you use this data for tracking purposes?**
- ❌ **No**

---

### 📊 USER CONTENT

**✅ Other User Content**

**What you collect:** Subscription information (service names, prices, dates, trial information)

**Purposes for collecting:**
- ☑️ App Functionality
- ☐ Analytics (unchecked)
- ☐ Product Personalization (unchecked)
- ☐ Developer's Advertising or Marketing (unchecked)
- ☐ Third-Party Advertising (unchecked)
- ☐ Other Purposes (unchecked)

**Is this data linked to the user's identity?**
- ✅ **Yes** (stored in their account if signed in, or locally on their device)

**Do you use this data for tracking purposes?**
- ❌ **No**

---

### 📱 USAGE DATA

**✅ Product Interaction**

**What you collect:** Basic app usage events (via Firebase Analytics)
- Screen views
- Button taps
- Feature usage

**Purposes for collecting:**
- ☐ App Functionality (unchecked)
- ☑️ Analytics
- ☐ Product Personalization (unchecked)
- ☐ Developer's Advertising or Marketing (unchecked)
- ☐ Third-Party Advertising (unchecked)
- ☐ Other Purposes (unchecked)

**Is this data linked to the user's identity?**
- ❌ **No** (Firebase Analytics is anonymous)

**Do you use this data for tracking purposes?**
- ❌ **No**

---

## ❌ DATA TYPES YOU DO NOT COLLECT

Make sure to NOT check these:

### Contact Info:
- ❌ Name
- ❌ Phone Number
- ❌ Physical Address
- ❌ Other Contact Info

### Health & Fitness:
- ❌ Health
- ❌ Fitness

### Financial Info:
- ❌ Payment Info
- ❌ Credit Info
- ❌ Other Financial Info

### Location:
- ❌ Precise Location
- ❌ Coarse Location

### Sensitive Info:
- ❌ Sensitive Info

### Contacts:
- ❌ Contacts

### User Content (other than what you selected):
- ❌ Emails or Text Messages
- ❌ Photos or Videos
- ❌ Audio Data
- ❌ Gameplay Content
- ❌ Customer Support
- ❌ Other User Content (if not subscription data)

### Browsing History:
- ❌ Browsing History

### Search History:
- ❌ Search History

### Identifiers:
- ❌ User ID
- ❌ Device ID
- ❌ Purchase History
- ❌ Advertising Data

### Purchases:
- ❌ Purchase History (IAP handled by Apple)

### Usage Data (other than what you selected):
- ❌ Advertising Data
- ❌ Other Usage Data

### Diagnostics:
- ❌ Crash Data
- ❌ Performance Data
- ❌ Other Diagnostic Data

---

## QUESTION 3: Third-Party Partners

**"Do your third-party partners collect data from this app?"**

**Answer:** ✅ **YES**

**Third-party partners and what they collect:**

### 1. Firebase Analytics (Google)
- **What they collect:** Anonymous usage data
- **Purpose:** Analytics
- **Linked to user:** No
- **Used for tracking:** No

### 2. Supabase
- **What they collect:** Email, subscription data (only if user signs in)
- **Purpose:** App Functionality (cloud sync)
- **Linked to user:** Yes
- **Used for tracking:** No

### 3. DeepSeek AI
- **What they collect:** Receipt/email images (temporarily, for scanning)
- **Purpose:** App Functionality (AI scanning)
- **Linked to user:** No
- **Used for tracking:** No
- **Note:** Images are not stored

---

## QUESTION 4: Data Used for Tracking

**"Is data collected from this app used for tracking?"**

**Answer:** ❌ **NO**

**Explanation:**
- You don't track users across apps/websites
- You don't share data with data brokers
- You don't use data for targeted advertising

---

## QUESTION 5: Privacy Policy

**"Privacy Policy URL"**

**Answer:**
```
https://kansyl.juan-oclock.com/privacy
```

This should already be filled in from App Information.

---

## 📋 SUMMARY - Quick Checklist

Before clicking "Publish":

- [ ] **Contact Info:** Email Address only
  - Linked: Yes
  - Tracking: No
  - Purpose: App Functionality

- [ ] **User Content:** Other User Content (subscription data)
  - Linked: Yes
  - Tracking: No
  - Purpose: App Functionality

- [ ] **Usage Data:** Product Interaction (analytics)
  - Linked: No
  - Tracking: No
  - Purpose: Analytics

- [ ] **Third-party partners:** Firebase, Supabase, DeepSeek declared

- [ ] **Tracking:** No

- [ ] **Privacy Policy URL:** https://kansyl.juan-oclock.com/privacy

---

## ⚠️ IMPORTANT NOTES

### What "Tracking" Means
According to Apple, tracking means:
- Linking user data with data from other companies for advertising
- Sharing user data with data brokers
- Using data to target ads

**You don't do any of this, so answer NO to tracking.**

### What "Linked to User" Means
- **Yes:** Data is connected to their account/identity
- **No:** Data is anonymous or not tied to them

### After Submission
- This privacy info will appear on your App Store page as a "Privacy Nutrition Label"
- Users will see what data you collect before downloading

---

## 🎯 NEXT STEPS

1. Go to **App Store Connect > App Privacy**
2. Click **"Get Started"** or **"Edit"**
3. Follow this guide step-by-step
4. Click **"Publish"** when done
5. ✅ Privacy section complete!

---

## 💡 Pro Tips

1. **Be honest** - Don't under-report data collection
2. **Be specific** - Only check what you actually collect
3. **Review carefully** - This appears publicly on App Store
4. **Update when needed** - If you add new data collection, update this

---

**Estimated time to complete:** 10-15 minutes

Good luck! 🚀
