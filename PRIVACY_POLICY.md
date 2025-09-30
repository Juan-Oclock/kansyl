# Privacy Policy for Kansyl

**Last Updated:** September 30, 2025  
**Effective Date:** September 30, 2025

## Introduction

Welcome to Kansyl ("we," "our," or "us"). We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, store, and protect your information when you use the Kansyl mobile application (the "App").

**By using Kansyl, you agree to the collection and use of information in accordance with this Privacy Policy.**

---

## 1. Information We Collect

### 1.1 Information You Provide Directly

**Account Information:**
- **Email Address:** When you sign in with Google, we collect your email address for authentication and account management purposes.
- **Name:** We may collect your name from your Google account profile (if provided).

**Subscription Data:**
- **Service Names:** Names of subscription services you track (e.g., "Netflix," "Spotify").
- **Pricing Information:** Monthly or annual subscription costs.
- **Dates:** Start dates, end dates, renewal dates, and billing cycle information.
- **Notes:** Any personal notes you add to your subscriptions.
- **Categories:** Subscription categories you assign.
- **Payment Methods:** Information about how you pay for subscriptions (stored as text, not actual payment credentials).

### 1.2 Information Collected Automatically

**Device & Usage Data:**
- Device model and iOS version
- App version and build number
- App usage patterns and feature usage
- Crash reports and error logs (anonymized)
- App performance metrics

### 1.3 Photos and Camera Access

**Receipt Scanning (Optional Feature):**
- **Camera Access:** When you use the AI receipt scanning feature, we access your device camera to capture receipt images.
- **Photo Library Access:** You may select existing receipt images from your photo library.
- **Image Processing:** Receipt images are processed **locally on your device** using iOS Vision framework for optical character recognition (OCR).
- **Text Transmission:** Only the extracted **text content** (not images) is sent to our third-party AI service (DeepSeek) for analysis.
- **No Image Storage:** We do **not** store, transmit, or retain receipt images on our servers.

### 1.4 Calendar Access (Optional)

- **Calendar Integration:** With your permission, we can add subscription renewal reminders to your device calendar.
- **No Calendar Data Collection:** We do not collect or store your calendar data. Integration is handled entirely on your device.

### 1.5 Third-Party Authentication Data

**Google Sign-In:**
- When you sign in with Google, we receive your email address and basic profile information from Google.
- We use this information solely for authentication and do not access other Google services or data.
- Google's privacy practices are governed by Google's Privacy Policy: https://policies.google.com/privacy

---

## 2. How We Use Your Information

### 2.1 Primary Uses

We use the collected information to:

1. **Provide Core Functionality:**
   - Track your subscription services and free trials
   - Calculate total spending and savings
   - Send timely renewal reminders
   - Sync your data across your devices

2. **AI Receipt Scanning:**
   - Analyze receipt text to automatically detect subscription information
   - Extract service names, prices, and billing dates from receipts
   - Match detected services with your existing subscriptions

3. **Account Management:**
   - Authenticate your identity
   - Manage your account settings
   - Provide customer support

4. **App Improvement:**
   - Analyze app usage patterns to improve features
   - Identify and fix bugs
   - Optimize app performance

### 2.2 We DO NOT Use Your Data For:

- ❌ Selling or renting your personal information to third parties
- ❌ Serving advertisements
- ❌ Building user profiles for marketing purposes
- ❌ Tracking you across other apps or websites
- ❌ Training AI models on your personal data

---

## 3. Data Storage and Security

### 3.1 Where Your Data is Stored

**Local Device Storage:**
- Your subscription data is stored locally on your device using Core Data (Apple's local database framework).
- This data is protected by your device's security features (encryption, passcode/biometrics).

**Cloud Synchronization (Optional):**
- If you choose to enable sync, your subscription data is stored in:
  - **Supabase:** A secure, privacy-focused backend service (PostgreSQL database hosted in the cloud)
  - **Location:** Your data is stored in Supabase's secure data centers (primarily US-based)

**API Keys:**
- DeepSeek API keys (if you provide your own) are stored securely in your device's iOS Keychain
- We never transmit or store API keys on our servers

### 3.2 Security Measures

We implement industry-standard security measures:

✅ **Encryption in Transit:** All data transmitted between your device and our servers uses HTTPS/TLS encryption  
✅ **Encryption at Rest:** Your subscription data is encrypted in the Supabase database  
✅ **Secure Authentication:** We use Supabase's secure authentication system with Google OAuth 2.0  
✅ **No Plaintext Passwords:** We do not store passwords; authentication is handled by Google  
✅ **API Security:** All API calls require authentication tokens  
✅ **Row-Level Security:** Database access is restricted to your own data only  

### 3.3 Data Retention

- **Active Accounts:** Your data is retained as long as your account is active.
- **Account Deletion:** When you delete your account, all your subscription data is permanently deleted within 30 days.
- **Inactive Accounts:** Accounts inactive for more than 2 years may be subject to deletion after notification.

---

## 4. Third-Party Services

### 4.1 Services We Use

**Supabase (Backend & Authentication):**
- **Purpose:** User authentication and data synchronization
- **Data Shared:** Email address, subscription data you create
- **Privacy Policy:** https://supabase.com/privacy
- **Location:** United States
- **Security:** SOC 2 Type II certified, GDPR compliant

**DeepSeek (AI Receipt Analysis):**
- **Purpose:** Analyzing receipt text to extract subscription information
- **Data Shared:** Only text extracted from receipts (OCR text), never images
- **Privacy Policy:** https://platform.deepseek.com/privacy
- **Data Retention:** DeepSeek does not store or use API call data for training
- **Usage:** Only when you use the AI receipt scanning feature

**Google OAuth (Authentication):**
- **Purpose:** Sign in with Google account
- **Data Shared:** Email address and basic profile information
- **Privacy Policy:** https://policies.google.com/privacy
- **Control:** Managed by Google's authentication system

### 4.2 No Third-Party Analytics or Advertising

We do **NOT** use:
- Google Analytics
- Facebook Pixel
- Advertising SDKs
- User tracking services
- Cross-app tracking

---

## 5. Your Privacy Rights

### 5.1 Under GDPR (European Users)

If you are located in the European Economic Area (EEA), you have the following rights:

- **Right to Access:** Request a copy of your personal data
- **Right to Rectification:** Request correction of inaccurate data
- **Right to Erasure ("Right to be Forgotten"):** Request deletion of your data
- **Right to Data Portability:** Receive your data in a machine-readable format
- **Right to Restrict Processing:** Limit how we process your data
- **Right to Object:** Object to certain data processing activities
- **Right to Withdraw Consent:** Withdraw consent at any time

**Legal Basis for Processing:**
- Consent: AI receipt scanning, calendar integration
- Contract Performance: Providing subscription tracking services
- Legitimate Interest: App improvement and security

### 5.2 Under CCPA (California Users)

If you are a California resident, you have the following rights:

- **Right to Know:** Request information about data collection and use
- **Right to Delete:** Request deletion of your personal data
- **Right to Opt-Out:** Opt out of the "sale" of personal information (we do not sell data)
- **Right to Non-Discrimination:** Not be discriminated against for exercising your rights

### 5.3 How to Exercise Your Rights

To exercise any of these rights:
1. **In-App:** Go to Settings → Account → Privacy Settings → "Request Data" or "Delete Account"
2. **Email:** Contact us at kansyl@juan-oclock.com
3. **Response Time:** We will respond within 30 days

---

## 6. Data Sharing and Disclosure

### 6.1 We Do Not Sell Your Data

We do **not** sell, rent, or trade your personal information to third parties for monetary consideration.

### 6.2 Limited Sharing

We may share your data only in these specific circumstances:

**Service Providers:**
- Supabase (backend infrastructure)
- DeepSeek (AI receipt analysis, only when you use this feature)

**Legal Compliance:**
- When required by law, court order, or government regulation
- To protect our legal rights or defend against legal claims
- To prevent fraud, security threats, or illegal activity

**Business Transfers:**
- In the event of a merger, acquisition, or sale of assets, your data may be transferred to the new owner (you will be notified)

### 6.3 No Cross-Border Data Transfers (Except as Specified)

Your data is primarily stored in the United States (Supabase servers). If you are outside the US, your data may be transferred to and processed in the US.

---

## 7. Children's Privacy

Kansyl is **not intended for children under 13 years of age**. We do not knowingly collect personal information from children under 13. If we discover that a child under 13 has provided us with personal information, we will delete it immediately.

If you are a parent or guardian and believe your child has provided us with personal information, please contact us at kansyl@juan-oclock.com.

---

## 8. Data Export and Deletion

### 8.1 Export Your Data

You can export all your subscription data:
1. Open the app
2. Go to Settings → Account → "Export Data"
3. Receive a JSON file with all your subscription information

### 8.2 Delete Your Account and Data

You can permanently delete your account and all associated data:
1. Open the app
2. Go to Settings → Account → "Delete Account"
3. Confirm deletion
4. All your data will be permanently deleted within 30 days

**Note:** Deletion is irreversible and cannot be undone.

---

## 9. Cookies and Tracking

**We do not use cookies** as Kansyl is a native iOS app. We do not track you across websites or other apps.

**Analytics:** We do not use third-party analytics services. Any app usage analytics are collected anonymously and used solely to improve the app.

---

## 10. International Users

Kansyl is designed to comply with:
- **GDPR (General Data Protection Regulation)** - European Union
- **CCPA (California Consumer Privacy Act)** - California, USA
- **PIPEDA (Personal Information Protection and Electronic Documents Act)** - Canada
- **Apple's App Store Guidelines** - Worldwide

If you use Kansyl from outside the United States, your data may be transferred to and processed in the US where Supabase servers are located.

---

## 11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. When we make changes:

1. We will update the "Last Updated" date at the top of this policy
2. We will notify you through the app or via email (for material changes)
3. Your continued use of the app after changes constitutes acceptance of the new policy

**We encourage you to review this Privacy Policy periodically.**

---

## 12. Contact Us

If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:

**Email:** kansyl@juan-oclock.com  
**App:** Settings → Support → "Contact Us"  
**Website:** https://kansyl.juan-oclock.com

**Response Time:** We aim to respond to all inquiries within 5 business days.

---

## 13. Transparency Report

### What Data We Collect:
✅ Email address (for authentication)  
✅ Subscription information you enter  
✅ Receipt text (only when using AI scanning)  
✅ Basic app usage data (anonymized)  

### What Data We DO NOT Collect:
❌ Credit card or payment information  
❌ Social Security numbers or government IDs  
❌ Location data or GPS coordinates  
❌ Contacts or phone numbers  
❌ Messages or communications  
❌ Browsing history or search queries  
❌ Receipt images (only text is extracted locally)  

### How We Use Your Data:
✅ Provide subscription tracking services  
✅ Sync your data across devices  
✅ Send renewal reminders  
✅ Analyze receipts with AI (opt-in feature)  
✅ Improve app functionality  

### How We DO NOT Use Your Data:
❌ Sell or rent to third parties  
❌ Show advertisements  
❌ Track you across other apps  
❌ Train AI models without consent  
❌ Share with marketers  

---

## 14. Your Consent

By using Kansyl, you consent to this Privacy Policy and agree to its terms.

**You can withdraw consent at any time by:**
- Disabling specific permissions in iOS Settings
- Deleting your account
- Uninstalling the app

---

## 15. Compliance Certifications

- ✅ **GDPR Compliant:** European data protection standards
- ✅ **CCPA Compliant:** California privacy regulations
- ✅ **Apple App Store Guidelines:** Privacy and security requirements
- ✅ **HTTPS/TLS Encryption:** All network communications
- ✅ **SOC 2 Type II:** Our backend provider (Supabase) is certified

---

**Thank you for trusting Kansyl with your subscription management!**

---

*This Privacy Policy is written in plain English to be easily understood. If you have any questions about any section, please don't hesitate to contact us.*