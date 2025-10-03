# Kansyl - Reviewer Notes (App Store Connect)

## Overview
Kansyl is a subscription management app that tracks free trials, premium subscriptions, and promotional offers. **Works completely offline without any account creation.**

---

## How to Test (No Sign-In Required)

### Basic Testing - 5 Minutes
1. **Launch app** - No sign-in needed, starts immediately
2. **Add subscriptions** - Tap "+" button, add any service (Netflix, Spotify, etc.)
3. **Set trial date** - Recommend 2-3 days from today for testing
4. **Test free tier limit** - Add 5 subscriptions, try adding a 6th (limit prompt will appear)
5. **Mark as cancelled** - Test any subscription, check Savings tab updates
6. **Enable notifications** - Settings tab > Enable Notifications

### Optional Features
- **AI Scanning** - Tap "Scan Receipt" when adding subscription (uses DeepSeek AI)
- **Cloud Sync** - Settings > Sign In with Apple or Google (optional)

---

## Third-Party Services

### DeepSeek AI (Optional)
- **Purpose:** Receipt/email scanning to extract subscription details
- **Endpoint:** https://api.deepseek.com/v1/chat/completions
- **Usage:** Only when user taps "Scan Receipt"
- **Data:** Images sent for analysis, not stored
- **API Key:** Included in app bundle

### Supabase (Optional)
- **Purpose:** Cloud sync across devices
- **URL:** https://tyxcmzpuhwkuuqnwamwj.supabase.co
- **Auth:** Apple Sign In or Google OAuth
- **Database:** PostgreSQL with Row Level Security
- **Usage:** Optional - app works fully offline

---

## App Architecture

### Data Storage
- **Local:** Core Data (offline functionality)
- **Cloud:** Supabase PostgreSQL (optional sync)
- **Default:** 100% offline, no internet required

### Key Features
1. Local-first architecture
2. Optional cloud sync
3. Push notifications for reminders
4. Share Extension
5. Home Screen widgets

---

## Free Tier vs Premium

### Free (5 subscriptions max)
- Track up to 5 subscriptions
- Notifications & reminders
- Savings tracker
- All core features

### Premium (In-App Purchase)
- Unlimited subscriptions
- Advanced analytics
- Priority support
- Export data (CSV/JSON)

**Note:** Free tier limit is intentional, not a bug.

---

## Permissions Requested

1. **Notifications** - For renewal reminders (core feature)
2. **Camera** - Only if user scans receipts (optional)
3. **Photo Library** - Only if user scans receipts (optional)

All permissions requested only when user uses the related feature.

---

## Privacy & Data

### Data Collected
- **Email** - Only if user signs in (optional)
- **Subscription data** - Service names, prices, dates (stored locally)
- **Analytics** - Basic app usage events (Firebase Analytics)

### Data Usage
- Subscription data: App functionality only
- Email: Authentication only
- No data sold to third parties
- Users can delete account and all data anytime

### Third-Party Sharing
- **DeepSeek:** Receipt images for scanning (not stored)
- **Supabase:** Subscription data (if user signed in)
- **Apple/Google OAuth:** Email/profile for auth only

---

## Known Limitations (v1.0)

1. **AI Accuracy** - DeepSeek may not perfectly extract all receipt details
2. **Free Tier** - 5 subscriptions limit for free users (intentional)

---

## Testing Checklist

- [ ] Add 5 subscriptions manually
- [ ] Try adding 6th (see free tier prompt)
- [ ] Mark one as cancelled
- [ ] Check Savings tab
- [ ] Enable notifications
- [ ] Test AI scanning (optional)
- [ ] Test Apple Sign-In (optional)
- [ ] Test Google Sign-In (optional)

---

## Contact

**Developer:** Juan O'Clock  
**Email:** support@kansyl.juan-oclock.com  
**Website:** https://kansyl.juan-oclock.com

**Estimated Review Time:** 15 minutes

Thank you for reviewing Kansyl! 🙏
