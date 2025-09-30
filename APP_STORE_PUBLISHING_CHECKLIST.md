# App Store Publishing Checklist for Kansyl

**Last Updated**: 2025-09-30  
**App Name**: Kansyl - Free Trial Reminder  
**Target Release**: Version 1.0  
**Purpose**: Complete checklist for successful App Store submission

---

## 🎯 Current Status Summary

### ✅ Completed
- Code signing configured (Automatic signing enabled)
- App successfully runs on physical iPhone device
- Bundle ID: `com.juan-oclock.kansyl.kansyl`
- iOS 15.0+ deployment target set
- All privacy permission descriptions configured
- Version 1.0, Build 1 set
- API keys properly secured in Config.private.xcconfig
- Backend services: Supabase (Google auth) + DeepSeek (receipt scanning)
- iPhone & iPad support configured

### ⏳ In Progress
- Apple Developer Program membership (pending approval)

### 🚫 Blockers
- Cannot proceed with App Store Connect setup until Apple Developer membership is approved
- Cannot create App ID or Distribution Certificate until membership approved

### 📋 Next Steps (After Membership Approval)
1. Complete Apple Developer account setup (certificates, App ID)
2. Create App Store Connect listing
3. ~~Write App Store description and marketing materials~~ ✅ CAN DO NOW
4. ~~Take and prepare screenshots~~ ✅ CAN DO NOW
5. ~~Create privacy policy~~ ✅ DONE (kansyl.juan-oclock.com)
6. TestFlight testing
7. Submit for review

### ✨ Tasks That Can Be Done NOW (While Waiting for Approval)
1. ✅ Write App Store description and marketing materials (Section 3)
2. ✅ Prepare screenshots and app preview video (Section 5)
3. ✅ Write reviewer notes and prepare demo account info (Section 6)
4. ✅ Fix compiler warnings and run tests (Section 7)
5. ✅ Plan TestFlight testing strategy (Section 8)
6. ✅ Review App Store Guidelines compliance (Section 9)
7. ✅ Prepare marketing materials and launch plan (Section 12)

---

## Pre-Submission Requirements

### 1. Apple Developer Account Setup

#### Developer Account
- [ ] Active Apple Developer Program membership ($99/year) - **PENDING - In progress**
- [ ] Account in good standing
- [ ] Tax and banking information completed
- [ ] Agreements accepted in App Store Connect

#### Certificates and Identifiers
- [ ] App ID created with correct bundle identifier
- [ ] Distribution Certificate created
- [ ] App Store provisioning profile created
- [ ] Push Notification certificate/key configured (if using)
- [ ] CloudKit container configured
- [ ] App Groups configured for extensions

#### Capabilities and Entitlements
- [ ] Push Notifications enabled
- [ ] CloudKit enabled (if syncing data)
- [ ] Siri enabled (for shortcuts)
- [ ] Background Modes configured (if needed)
- [ ] App Groups for Widget and Share Extension
- [ ] Sign in with Apple (if required)

---

## 2. App Configuration

### Info.plist Requirements
- [x] Bundle identifier matches App ID - `com.juan-oclock.kansyl.kansyl`
- [x] Version number set (e.g., 1.0) - Currently 1.0
- [x] Build number set (must be unique for each submission) - Currently 1
- [ ] Display name set
- [x] Minimum iOS version specified (15.0) - ✅ iOS 15.0
- [ ] Required device capabilities defined
- [x] Supported interface orientations configured - Portrait, Landscape Left & Right

### Privacy Permissions Descriptions
- [x] `NSUserNotificationsUsageDescription` - ✅ "Kansyl sends you timely reminders before your free trials end, helping you avoid unwanted charges."
- [x] `NSCameraUsageDescription` - ✅ "Kansyl needs access to your camera to scan receipts and automatically detect subscription information using AI."
- [x] `NSPhotoLibraryUsageDescription` - ✅ "Kansyl needs access to your photo library to let you add custom logos for your subscriptions and scan receipt images for AI-powered subscription detection."
- [x] `NSCalendarUsageDescription` - ✅ "Kansyl needs access to your calendar to create reminders for your trial end dates. This helps ensure you never forget to cancel unwanted subscriptions."
- [ ] `NSUserTrackingUsageDescription` - Not needed (not using tracking)
- [x] All descriptions are clear, user-friendly, and accurate - ✅ Well written

### App Transport Security
- [ ] All API endpoints use HTTPS
- [ ] No ATS exceptions unless absolutely necessary
- [ ] If exceptions exist, document justification

### Supported Devices
- [x] iPhone support verified - ✅ Tested on physical iPhone
- [x] iPad support configured (if supporting) - ✅ TARGETED_DEVICE_FAMILY = "1,2" (iPhone & iPad)
- [x] Device requirements specified
- [x] Orientation support tested - Portrait, Landscape Left & Right

---

## 3. App Store Connect Configuration

### App Information

#### Basic Information
- [x] App name (max 30 characters): "Kansyl" - ✅ Only 6 characters
- [ ] Subtitle (max 30 characters): "Never Miss a Free Trial" - To be set in App Store Connect
- [ ] Bundle ID selected - `com.juan-oclock.kansyl.kansyl` (ready to register)
- [ ] SKU created (unique identifier for your reference)
- [ ] Primary language selected

#### Categories
- [ ] Primary category selected (Productivity or Finance)
- [ ] Secondary category selected (optional)
- [ ] Content rating questionnaire completed

#### Pricing and Availability
- [ ] Price selected (Free or paid)
- [ ] Availability territories selected (all countries or specific)
- [ ] Pre-order options configured (if applicable)
- [ ] Educational discount enabled/disabled

### Version Information

#### Description (max 4000 characters)
- [ ] Compelling opening paragraph highlighting pain point
- [ ] Key features listed clearly:
  - Lightning-fast trial entry
  - Smart reminders and notifications
  - Savings tracking and analytics
  - Beautiful, intuitive interface
  - Privacy-focused local storage
  - Siri Shortcuts integration
- [ ] Benefits explained (save money, avoid forgotten charges)
- [ ] Call to action
- [ ] No marketing language that violates guidelines
- [ ] No emoji or special characters that look unprofessional
- [ ] Grammar and spelling checked

#### Keywords (max 100 characters)
- [ ] Relevant keywords researched
- [ ] Comma-separated list created
- [ ] Examples: "free trial,subscription,reminder,tracker,trials,money,savings,notifications,budgeting"
- [ ] No duplicate keywords
- [ ] No competitor names
- [ ] No category names

#### Promotional Text (max 170 characters, can be updated anytime)
- [ ] Written to highlight current features or promotions
- [ ] Example: "Track unlimited free trials, get smart reminders, and save money. Join thousands who never miss a trial deadline!"

#### What's New (Release Notes)
- [ ] Clear description of what's new in this version
- [ ] For version 1.0: "Initial release! Track your free trials, get timely reminders, and never get charged unexpectedly again."
- [ ] Bullet points for easy reading
- [ ] Professional tone

#### Support URL
- [x] Website or support page URL provided - ✅ https://kansyl.juan-oclock.com
- [x] URL is accessible and works correctly - ✅ Confirmed
- [x] Page includes contact information - ✅ Has contact link
- [x] FAQ or documentation available - ✅ Has FAQ section

#### Marketing URL (optional)
- [x] Product website URL (if available) - ✅ https://kansyl.juan-oclock.com
- [x] Landing page with app information - ✅ Complete with features, pricing, FAQ

#### Privacy Policy URL (REQUIRED)
- [x] Privacy policy created and hosted - ✅ https://kansyl.juan-oclock.com/privacy
- [x] URL accessible to everyone - ✅ Confirmed accessible
- [x] Policy covers:
  - What data is collected
  - How data is used
  - Data storage and security
  - User rights (access, deletion, export)
  - Third-party services (DeepSeek, Supabase)
  - Contact information
- [x] Complies with GDPR and CCPA - ✅ Ready
- [x] Written in plain language - ✅ Ready

---

## 4. App Privacy Details

### Data Collection Questionnaire
Complete for all applicable data types:

#### Contact Information
- [x] Name: ☐ Yes ☑ No - Not collected
- [x] Email: ☑ Yes ☐ No - Using Supabase Google auth
- [x] Purpose: Account creation, authentication, user support
- [x] Linked to user: Yes
- [x] Used for tracking: No

#### Financial Information
- [x] Purchase History: ☐ Yes ☑ No
- [x] Subscription data: Yes (for core functionality) - User tracks their own subscriptions
- [x] Linked to user: Yes (stored locally via Supabase)
- [x] Used for tracking: No

#### Usage Data
- [ ] Product Interaction: ☐ Yes ☐ No (if using analytics)
- [ ] Crash Data: ☐ Yes ☐ No
- [ ] Performance Data: ☐ Yes ☐ No
- [ ] Purpose: Analytics, app improvement
- [ ] Linked to user: No (anonymized)

#### Identifiers
- [ ] Device ID: ☐ Yes ☐ No
- [ ] User ID: ☐ Yes ☐ No (if using Supabase auth)

### Privacy Nutrition Label
- [ ] Review generated privacy label
- [ ] Verify accuracy of all claims
- [ ] Ensure "No Data Collected" is only used if truly no data collected
- [ ] Document data collection practices

---

## 5. App Screenshots and Previews

### iPhone Screenshots (REQUIRED)

#### 6.7" Display (iPhone 14 Pro Max, 15 Pro Max)
- [ ] 1-10 screenshots at 1290 x 2796 pixels
- [ ] Screenshot 1: Hero/Main feature (subscription list)
- [ ] Screenshot 2: Add subscription flow
- [ ] Screenshot 3: Notifications/Reminders
- [ ] Screenshot 4: Savings/Analytics
- [ ] Screenshot 5: Settings/Features overview
- [ ] All screenshots show compelling features
- [ ] Status bar cleaned (hide personal info)
- [ ] Consistent design and branding

#### 6.5" Display (iPhone 11 Pro Max, XS Max)
- [ ] 1-10 screenshots at 1242 x 2688 pixels
- [ ] Same content as 6.7" display
- [ ] Properly sized for device

#### 5.5" Display (iPhone 8 Plus) (if supporting iOS 15)
- [ ] 1-10 screenshots at 1242 x 2208 pixels
- [ ] Same content, optimized for smaller screen

### iPad Screenshots (if supporting iPad)
- [ ] 12.9" iPad Pro (3rd gen): 2048 x 2732 pixels
- [ ] 12.9" iPad Pro (2nd gen): 2048 x 2732 pixels

### Screenshot Best Practices
- [ ] Show real app content, not mockups
- [ ] No placeholder text or "Lorem ipsum"
- [ ] Highlight key features visually
- [ ] Use text overlays sparingly (if at all)
- [ ] Show app in context (real use cases)
- [ ] Professional quality (no pixelation)
- [ ] Consistent color scheme
- [ ] Screenshots tell a story (sequence matters)

### App Preview Video (Optional but Recommended)
- [ ] 15-30 seconds in length
- [ ] Portrait orientation for iPhone
- [ ] Shows key features in action
- [ ] No spoken words if possible (use captions)
- [ ] Engaging first 3 seconds
- [ ] Professional quality
- [ ] Music/sound effects appropriate
- [ ] Same sizes as screenshots required
- [ ] Demonstrates core value proposition

---

## 6. App Review Information

### Contact Information
- [ ] First name
- [ ] Last name
- [ ] Phone number (reachable during review)
- [ ] Email address (monitored during review)

### Demo Account (if applicable)
- [ ] Username provided
- [ ] Password provided
- [ ] Account remains active during review
- [ ] Account has full access to features
- [ ] Document any special instructions

### Notes for Reviewer
- [ ] Explain core functionality
- [ ] List any non-obvious features
- [ ] Note any region-specific functionality
- [ ] Explain third-party services (DeepSeek, Supabase)
- [ ] Note test data or demo mode (if any)
- [ ] Explain API key usage (if asked)
- [ ] Attach any necessary documentation

### App Review Attachments
- [ ] Architecture diagrams (if helpful)
- [ ] Feature documentation
- [ ] Privacy documentation
- [ ] Third-party service documentation

---

## 7. Build and Archive

### Pre-Archive Checklist
- [ ] All security audits completed
- [ ] All performance optimizations done
- [ ] All compiler warnings fixed
- [ ] Release scheme selected in Xcode
- [x] Correct bundle ID verified - ✅ `com.juan-oclock.kansyl.kansyl`
- [x] Version and build numbers incremented - ✅ Version 1.0, Build 1
- [x] API keys and secrets not hardcoded - ✅ Using Config.private.xcconfig
- [x] Config files (.xcconfig, .plist) properly configured - ✅ Config.private.xcconfig exists
- [ ] All tests passing

### Archive Process
- [ ] Clean build folder (Cmd+Shift+K)
- [ ] Select "Any iOS Device (arm64)"
- [ ] Product > Archive
- [ ] Wait for archive to complete
- [ ] Open Organizer (Window > Organizer)

### Validate Archive
- [ ] Select archive in Organizer
- [ ] Click "Validate App"
- [ ] Select distribution method (App Store Connect)
- [ ] Choose automatic or manual signing
- [ ] Include bitcode: No (if not needed)
- [ ] Upload symbols: Yes (for crash reporting)
- [ ] Complete validation process
- [ ] Fix any errors or warnings
- [ ] Re-archive if necessary

### Upload to App Store Connect
- [ ] Click "Distribute App" in Organizer
- [ ] Select "App Store Connect"
- [ ] Select destination: Upload
- [ ] Configure distribution options:
  - [ ] Include bitcode for iOS content: No (unless needed)
  - [ ] Upload your app's symbols: Yes
  - [ ] Manage Version and Build Number: Automatic
- [ ] Review app information
- [ ] Upload build
- [ ] Wait for upload to complete (can take 10-60 minutes)
- [ ] Verify build appears in App Store Connect

### Post-Upload Verification
- [ ] Check email for upload confirmation
- [ ] Verify build in App Store Connect > TestFlight
- [ ] Wait for processing to complete
- [ ] Check for any processing errors
- [ ] Note build number for submission

---

## 8. TestFlight Testing (Highly Recommended)

### Internal Testing
- [ ] Add internal testers (up to 100)
- [ ] Distribute build to internal testers
- [ ] Collect feedback
- [ ] Test on multiple devices
- [ ] Verify all features work in production build
- [ ] Test push notifications
- [ ] Test deep links and shortcuts
- [ ] Test widget and share extension

### External Testing (Optional)
- [ ] Create beta testing groups
- [ ] Add external testers (up to 10,000)
- [ ] Write clear test instructions
- [ ] Submit for Beta App Review (if required)
- [ ] Monitor feedback and crash reports
- [ ] Address critical issues before release

### TestFlight Checklist
- [ ] Export compliance set correctly
- [ ] Test instructions provided
- [ ] Feedback mechanism explained
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] User experience validated

---

## 9. App Store Review Guidelines Compliance

### Guideline 1: Safety
- [ ] No objectionable content
- [ ] User-generated content properly moderated (if applicable)
- [ ] No content promoting illegal activity
- [ ] Privacy protections in place

### Guideline 2: Performance
- [ ] App is complete and not a demo
- [ ] All features functional
- [ ] No placeholder content
- [ ] No unfinished features
- [ ] Links work correctly
- [ ] Crashes handled gracefully

### Guideline 3: Business
- [ ] In-app purchases properly implemented (if applicable)
- [ ] Pricing clearly displayed
- [ ] No alternative payment mechanisms outside IAP (for digital content)
- [ ] Subscription terms clear (if applicable)

### Guideline 4: Design
- [ ] App follows Human Interface Guidelines
- [ ] Proper use of iOS features
- [ ] Native iOS look and feel
- [ ] No web wrapper
- [ ] Proper keyboard and input handling
- [ ] Dark Mode support implemented
- [ ] Dynamic Type support

### Guideline 5: Legal
- [ ] Privacy policy provided
- [ ] Terms of service (if applicable)
- [ ] Intellectual property rights respected
- [ ] No use of private APIs
- [ ] Proper licenses for third-party content

---

## 10. Submission to App Store

### Select Build
- [ ] Go to App Store Connect
- [ ] Navigate to your app
- [ ] Select version (e.g., 1.0)
- [ ] Click "Select a build before you submit your app"
- [ ] Choose the build uploaded from Xcode
- [ ] Wait for build to be available (if just uploaded)

### Export Compliance
- [ ] Answer export compliance questions
- [ ] For most apps: "No" to encryption (unless using custom encryption)
- [ ] If using HTTPS only: Standard encryption, no export doc needed
- [ ] Document CCATS or ERN if required

### Content Rights
- [ ] Confirm you own rights to all content
- [ ] Third-party content properly licensed
- [ ] No trademark violations
- [ ] No copyright violations

### Advertising Identifier (IDFA)
- [ ] Answer if app uses IDFA
- [ ] If using for ads: Specify how
- [ ] For most apps without ads: "No"

### Version Release
- [ ] Select release option:
  - [ ] Automatically after approval
  - [ ] Manually release (you control timing)
  - [ ] Schedule for specific date
- [ ] Choose based on your launch strategy

### Phased Release (Optional)
- [ ] Enable for gradual rollout over 7 days
- [ ] Recommended for first release
- [ ] Can pause if issues discovered

### Final Review
- [ ] Review all information one more time
- [ ] Check screenshots display correctly
- [ ] Verify description formatting
- [ ] Confirm pricing and availability
- [ ] Check privacy information accuracy
- [ ] Verify all URLs work

### Submit for Review
- [ ] Click "Submit for Review"
- [ ] Confirm submission
- [ ] Note submission date and time
- [ ] App status changes to "Waiting for Review"

---

## 11. During Review Process

### Monitor Status
- [ ] Check App Store Connect daily
- [ ] Monitor email for updates
- [ ] Status progression:
  - Waiting for Review
  - In Review (usually 24-48 hours)
  - Pending Developer Release (if manual release)
  - Ready for Sale

### If App is Rejected
- [ ] Read rejection reason carefully
- [ ] Review cited guidelines
- [ ] Make necessary changes
- [ ] Re-submit with clear response
- [ ] Use Resolution Center for clarifications

### Common Rejection Reasons
- [ ] Crashes or bugs during review
- [ ] Incomplete features
- [ ] Misleading metadata or screenshots
- [ ] Privacy policy issues
- [ ] Missing demo account credentials
- [ ] Guideline violations

---

## 12. Post-Approval Launch

### Pre-Launch
- [ ] Prepare press release (if applicable)
- [ ] Notify beta testers
- [ ] Prepare social media posts
- [ ] Create landing page (if not already)
- [ ] Prepare customer support resources

### Release Day
- [ ] If manual release: Click "Release This Version"
- [ ] Verify app appears in App Store (can take 2-24 hours)
- [ ] Test installation from App Store
- [ ] Check app page displays correctly
- [ ] Monitor initial reviews and ratings
- [ ] Respond to user feedback

### Monitoring
- [ ] Set up crash reporting (if not already)
- [ ] Monitor App Store reviews
- [ ] Track downloads in App Store Connect
- [ ] Monitor server load (for backend services)
- [ ] Check for critical bugs
- [ ] Gather user feedback

### Marketing
- [ ] Share on social media
- [ ] Email newsletter (if applicable)
- [ ] Reach out to press/bloggers
- [ ] Submit to app review sites
- [ ] Create Product Hunt launch (if applicable)
- [ ] Update website with App Store link

---

## 13. Post-Launch Maintenance

### Week 1
- [ ] Monitor crash reports daily
- [ ] Respond to all reviews
- [ ] Fix critical bugs immediately
- [ ] Prepare hotfix if needed
- [ ] Analyze user behavior
- [ ] Track key metrics

### Week 2-4
- [ ] Continue monitoring feedback
- [ ] Plan first update
- [ ] Implement highly-requested features
- [ ] Optimize based on analytics
- [ ] Build marketing momentum

### Ongoing
- [ ] Regular updates (every 2-3 months minimum)
- [ ] Respond to reviews
- [ ] Monitor iOS updates for compatibility
- [ ] Keep dependencies updated
- [ ] Maintain security patches
- [ ] Grow user base

---

## 14. App Store Optimization (ASO)

### Continuous Improvement
- [ ] Test different keywords
- [ ] Update screenshots based on performance
- [ ] Refresh promotional text regularly
- [ ] A/B test icon and screenshots
- [ ] Monitor keyword rankings
- [ ] Track conversion rates

### Localization (Future)
- [ ] Identify target markets
- [ ] Localize metadata
- [ ] Localize screenshots
- [ ] Translate app content
- [ ] Adapt to cultural differences

---

## 15. Legal and Compliance

### Required Legal Documents
- [x] Privacy Policy (required) - ✅ https://kansyl.juan-oclock.com/privacy
- [x] Terms of Service (recommended) - ✅ https://kansyl.juan-oclock.com/terms
- [x] End User License Agreement (optional) - ✅ Not needed (covered in ToS)
- [x] Cookie Policy (if using cookies) - ✅ Not needed (no cookies in native app)

### Compliance
- [ ] GDPR compliance (EU users)
- [ ] CCPA compliance (California users)
- [ ] COPPA compliance (if targeting children)
- [ ] Accessibility compliance (recommended)

### Trademark
- [ ] Consider trademarking app name
- [ ] Register domain name
- [ ] Protect brand identity

---

## Emergency Contacts

### Apple Support
- Developer Support: https://developer.apple.com/contact/
- App Review: Use Resolution Center in App Store Connect
- Phone: 1-800-633-2152 (US)

### Third-Party Services
- Supabase Support: support@supabase.io
- DeepSeek Support: (check platform)

---

## Checklist Sign-Off

### Pre-Submission
- [ ] All technical requirements met
- [ ] All marketing materials prepared
- [ ] All legal documents ready
- [ ] TestFlight testing completed

### Submission
- [ ] Build uploaded successfully
- [ ] All App Store Connect fields completed
- [ ] Submitted for review
- [ ] Date submitted: ________________

### Post-Approval
- [ ] App released to App Store
- [ ] Marketing launched
- [ ] Monitoring in place
- [ ] Release date: ________________

---

## Success Metrics to Track

### Technical Metrics
- [ ] Crash-free rate (target: >99%)
- [ ] App launch time
- [ ] User retention (Day 1, 7, 30)
- [ ] API error rates

### Business Metrics
- [ ] Downloads per day/week/month
- [ ] Active users (DAU, MAU)
- [ ] Conversion rate (if premium features)
- [ ] Average rating (target: 4.5+)
- [ ] Review sentiment

---

**Good luck with your App Store launch!** 🚀

Remember: The first submission is always the hardest. Take your time, follow this checklist carefully, and don't be discouraged by rejections – they're a learning opportunity!