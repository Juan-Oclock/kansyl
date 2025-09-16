Free Trial Reminder App - PRD
Executive Summary
Product Name: Kansyl (working title)
Target Platform: iOS (iPhone primary, iPad secondary)
Core Value Proposition: Never forget a free trial again - get reminded before you're charged
Problem Statement: Users frequently forget about free trials and get unexpectedly charged when trials auto-convert to paid subscriptions, leading to wasted money and frustration.
Solution: A simple, beautiful iOS app that reminds users before their free trials expire, with lightning-fast data entry and intelligent notifications.

Product Goals
Primary Goals

Help users avoid unwanted subscription charges from forgotten free trials
Provide a delightful, friction-free experience for tracking trials
Build a sustainable, privacy-focused business model

Success Metrics

User retention: 60%+ after 30 days
Trial save rate: Users successfully cancel/decide on 80%+ of tracked trials
App Store rating: 4.7+ stars
Time to add trial: Under 30 seconds average


Target Audience
Primary Users

Age: 25-45 years old
Tech comfort: Moderate to high iOS users
Behavior: Frequently sign up for free trials, often across multiple services
Pain point: Forgetting trial end dates, getting unwanted charges

User Personas
"Trial Sampler Sarah" (Primary)

Signs up for 3-5 free trials monthly (streaming, software, apps)
Busy professional, values time-saving tools
Willing to pay for premium features that save money/time

"Cautious Carl" (Secondary)

Rarely uses free trials due to fear of forgetting
Would use more trials if had reliable tracking system
Values simplicity and clear notifications


Core Features (MVP)
1. Lightning-Fast Trial Entry
Objective: Make adding a trial take <30 seconds
Features:

Service Templates: Pre-built templates for popular services (Netflix, Spotify, Adobe, etc.)

Auto-fills trial duration (7, 14, 30 days)
Includes service logo and brand colors
Smart date calculation


Quick Add Flow:

Service search/selection
Trial start date (defaults to today)
Optional: Add custom notes
One-tap save


Alternative Input Methods:

Siri Shortcuts integration ("Hey Siri, add Netflix trial")
Share Sheet extension for confirmation emails/screenshots
Widget with "Quick Add" button



2. Smart Notifications
Objective: Timely, helpful reminders that drive action
Notification Strategy:

3-day warning: "Your Netflix trial ends in 3 days"
1-day warning: "Last chance! Netflix trial ends tomorrow"
Day-of reminder: "Your Netflix trial ends today - decide now!"

Smart Features:

Customizable notification timing per service
Rich notifications with service logo and quick actions
"Snooze for 2 hours" option for day-of reminders

3. Clean Dashboard
Objective: At-a-glance trial status and easy management
Layout:

Active Trials (sorted by days remaining)
Ending Soon section (trials ending within 7 days)
Ended Trials (last 30 days, with outcome tracking)

Trial Cards Display:

Service logo and name
Days remaining (prominent)
End date
Quick actions: "Remind me" / "I'll cancel" / "I'll keep"

4. Outcome Tracking
Objective: Help users understand their trial habits and app value
Features:

Track what users did with each trial (kept, canceled, forgot)
Simple stats: "You've saved $X this month"
Streak counter: "5 trials tracked without unwanted charges!"


Enhanced Features (Future Releases)
Phase 2: Power User Features

Calendar Integration: Sync trial dates with iOS Calendar
Multiple Reminder Profiles: Different timing for different service types
Family Sharing: Track trials for family members
Trial History: Full history with search and filtering

Phase 3: Smart Features

Email Integration: Forward trial confirmation emails for auto-parsing
Price Change Detection: Manual entry for when trial converts to different price
Trial Extension Detection: Track when services extend trials


UI/UX Design Recommendations
Visual Design Philosophy
Style: Clean, modern, trustworthy
Inspiration: Apple's own apps (Reminders, Calendar), Mint's simplicity
Color Palette:

Primary: iOS system blue (trustworthy, familiar)
Accent: Green for "safe/saved money"
Warning: Orange/red for urgent reminders

Key UX Principles

Speed First: Every interaction optimized for minimal taps
Glanceable: Key info visible without opening individual trials
Forgiving: Easy to edit/delete, clear undo options
Contextual: Smart defaults based on service type and user behavior

Screen-by-Screen Design
Home Screen (Dashboard)
[+ Quick Add Button - prominent]

ENDING SOON
[Netflix] [Logo] 2 days left
[Spotify] [Logo] 5 days left

ALL TRIALS
[Adobe] [Logo] 12 days left
[Disney+] [Logo] 18 days left

[Ended] tab at bottom
Quick Add Screen
Search: "What service?" [Popular services below]
[Netflix] [Spotify] [Adobe] [Disney+]...

Selected: Netflix
Start Date: [Today] [Custom]
Trial Length: [30 days] [Custom]
Notes: [Optional field]

[Add Trial] - large, prominent button
Trial Detail Screen
[Netflix Logo]
Netflix Premium Trial
Ends: March 15, 2024 (in 5 days)

[Edit] [Delete]

Reminder Settings:
□ 3 days before
□ 1 day before
□ Day of trial end

Notes: "Want to watch Stranger Things"

[Mark as Canceled] [Mark as Keeping]
Navigation Structure

Tab Bar: Trials / Stats / Settings
Modal presentations: Add trial, trial details
Swipe actions: Quick cancel/keep decisions
Stats Tab: Savings overview, waste prevention, achievement badges


Technical Requirements
Platform Specifications

Minimum iOS: 15.0 (for modern notification features)
Target devices: iPhone (primary), iPad (optimized layout)
Orientation: Portrait primary, landscape supported

Core Technologies

Framework: SwiftUI for modern, maintainable UI
Data: Core Data for local storage (privacy-focused)
Notifications: UserNotifications framework
Integration: SiriKit for shortcuts, Share Sheet extension

Performance Requirements

App launch: <2 seconds cold start
Quick add flow: <30 seconds average completion
Notification delivery: 99%+ reliability
Storage: Minimal - primarily text data


Monetization Strategy
Freemium Model
Free Tier (MVP):

Track up to 5 active trials
Basic notifications (1 day before)
Essential features only

Premium Tier ($2.99/month or $19.99/year):

Unlimited trials
Custom notification timing
Calendar integration
Trial history and analytics
Siri Shortcuts
Premium app icons

Alternative: One-time Purchase

$9.99 one-time purchase for full features
May appeal more to privacy-conscious users
Simpler business model


Privacy & Security
Privacy-First Approach

All data stored locally on device (Core Data)
No user accounts required for basic functionality
No tracking or analytics in free version
Optional iCloud sync for premium users only

Data Handling

No sensitive financial data collected
Only service names, dates, and user notes stored
Clear privacy policy explaining data usage
Easy data export/deletion options


Launch Strategy
Phase 1: MVP Launch (Months 1-3)

Core features only
Free version to build user base
Focus on App Store optimization and user feedback

Phase 2: Premium Features (Months 4-6)

Introduce premium tier
Add calendar integration and advanced notifications
Implement user feedback from Phase 1

Phase 3: Growth Features (Months 7-12)

Share sheet integration
Siri shortcuts
Family sharing
App Store featuring push


Success Criteria
Launch Goals (3 months)

10,000+ downloads
4.5+ App Store rating
50%+ 7-day retention rate

Growth Goals (12 months)

100,000+ downloads
15%+ premium conversion rate
Featured by Apple in "Apps We Love"
Break-even on development costs


Risk Assessment
Technical Risks

Notification reliability: iOS notification limits/user settings
Mitigation: Clear onboarding about notification permissions

Market Risks

Competition: Simple concept, could be copied easily
Mitigation: Focus on superior UX and rapid iteration

Business Risks

User acquisition: May require marketing spend
Mitigation: Focus on organic growth through App Store optimization and word-of-mouth
