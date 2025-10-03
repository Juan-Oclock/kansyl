# App Store Reviewer Notes - Kansyl v1.0

## Overview
Kansyl is a free trial and subscription management app that helps users track their free trials and get reminders before they're charged. The app works primarily offline with optional cloud sync via Supabase.

---

## How to Test the App

### Basic Functionality (No Account Required)

The app works **completely offline** without any account creation. You can test all core features immediately:

1. **Launch the app** - You'll see the main subscription list (empty on first launch)

2. **Add a subscription:**
   - Tap the "+" button
   - Enter any service name (e.g., "Netflix", "Spotify")
   - Set a trial end date (recommend setting it 2-3 days from today for testing)
   - Add optional details like price ($9.99) and billing cycle (Monthly)
   - Tap "Save"

3. **View subscription details:**
   - Tap any subscription in the list
   - See countdown to trial end date
   - View all subscription information
   - Test the "Mark as Cancelled" button

4. **Test notifications:**
   - Go to Settings tab
   - Enable "Notifications"
   - Grant notification permissions when prompted
   - The app will schedule alerts before trials end

5. **Test savings tracker:**
   - Cancel a subscription (mark as cancelled)
   - Go to the "Savings" tab
   - See tracked savings from cancelled trials

6. **Test free tier limit:**
   - Add 5 subscriptions
   - Try to add a 6th subscription
   - A prompt will appear showing subscription limit reached
   - This demonstrates the free tier functionality

---

## Third-Party Services

### 1. DeepSeek AI API
**Purpose:** AI-powered receipt/email scanning to extract subscription details  
**Usage:** Optional feature - users can manually enter subscriptions or use AI scanning  
**Implementation:** 
- API endpoint: `https://api.deepseek.com/v1/chat/completions`
- Used only when user explicitly scans a receipt/email
- No data stored on DeepSeek servers
- API key included in app bundle (required for testing)

**To test AI scanning:**
- Tap "Scan Receipt" when adding a subscription
- Take a photo of any receipt or subscription email
- The AI will attempt to extract service name, price, and billing date
- User can edit/confirm before saving

### 2. Supabase (Backend & Authentication)
**Purpose:** Optional user authentication and cloud sync  
**Usage:** Users can optionally sign in to sync data across devices  
**Implementation:**
- Supabase project URL: `https://tyxcmzpuhwkuuqnwamwj.supabase.co`
- Authentication: Google OAuth Sign-In
- Database: PostgreSQL for storing user subscriptions
- Row Level Security (RLS) enabled - users only see their own data

**To test authentication (optional):**
- Go to Settings tab
- Tap "Sign In" (or "Account")
- Choose "Sign in with Google"
- Use any Google account
- Data will sync to Supabase backend

**Note:** Authentication is **completely optional** - the app works fully without signing in.

---

## App Permissions Requested

1. **Notifications** - To remind users before trials end
2. **Photo Library** (optional) - For AI receipt scanning feature
3. **Camera** (optional) - For AI receipt scanning feature

All permissions are requested only when the user attempts to use the related feature.

---

## Free Tier vs Premium

### Free Tier
- Track up to 5 subscriptions
- Basic notifications
- Savings tracker
- All core features

### Premium (In-App Purchase)
- Unlimited subscriptions
- Advanced analytics
- Priority support
- Export data (CSV/JSON)
- Custom notification sounds

**To test IAP:**
- Add 5 subscriptions to hit the free limit
- Try to add a 6th - premium prompt will appear
- You can test the purchase flow using Sandbox tester accounts

---

## App Architecture

### Data Storage
- **Local:** Core Data database stored on device
- **Cloud (Optional):** Supabase PostgreSQL database
- **Sync:** Automatic when user is signed in
- **Offline:** Full functionality without internet

### Key Features
1. Local-first architecture (works offline)
2. Optional cloud sync via Supabase
3. Push notifications for trial reminders
4. Share Extension (add subscriptions from Safari/Mail)
5. Home Screen widgets
6. Siri Shortcuts support

---

## Testing Checklist

- [ ] Add a subscription manually
- [ ] View subscription details
- [ ] Mark a subscription as cancelled
- [ ] Check savings tracker updates
- [ ] Test notifications (Settings > Enable Notifications)
- [ ] Hit free tier limit (add 5 subscriptions)
- [ ] Test premium prompt
- [ ] Try AI receipt scanning (optional)
- [ ] Test Google Sign-In (optional)
- [ ] Test Share Extension (optional - share from Safari)

---

## Known Limitations in v1.0

1. **No Apple Sign In** - Only Google OAuth in this version (Apple Sign In planned for v1.1)
2. **AI Scanning Accuracy** - DeepSeek AI may not perfectly extract all details from every receipt
3. **Free Tier Limit** - Enforced at 5 subscriptions for free users

---

## Privacy & Data Handling

### Data Collection
- **Email address** (only if user signs in with Google)
- **Subscription data** (service names, prices, dates)
- **Usage analytics** (Firebase Analytics - basic events only)

### Data Usage
- Subscription data used solely for app functionality
- Email used only for authentication
- No data sold to third parties
- Users can delete their account and all data anytime

### Third-Party Data Sharing
- **DeepSeek AI:** Receipt images sent for analysis, not stored
- **Supabase:** Subscription data stored in user's authenticated account
- **Google OAuth:** Email and profile info for authentication only

---

## Contact Information

**Developer:** Juan O'Clock  
**Support Email:** support@kansyl.juan-oclock.com  
**Website:** https://kansyl.juan-oclock.com

---

## Additional Notes

- App requires iOS 15.0 or later
- Optimized for iPhone (universal app)
- Supports Dark Mode
- Fully localized in English (more languages planned)
- No ads, no tracking, privacy-first design

**Review Time Estimate:** 15-20 minutes for full feature testing

Thank you for reviewing Kansyl! 🙏
