# Kansyl - Free Trial Reminder App

**Never forget a free trial again** - A beautiful iOS app that reminds you before free trials auto-convert to paid subscriptions.

![iOS Version](https://img.shields.io/badge/iOS-15.0%2B-blue)
![Swift Version](https://img.shields.io/badge/Swift-5.0%2B-orange)
![Xcode Version](https://img.shields.io/badge/Xcode-14.0%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Overview

Kansyl helps users avoid unwanted subscription charges from forgotten free trials. With lightning-fast data entry, smart notifications, and a clean dashboard, users can track their trials effortlessly and make informed decisions before auto-renewal.

### Key Features

- ⚡ **Lightning-fast trial entry** (under 30 seconds)
- 🔔 **Smart notifications** with rich content and quick actions
- 📊 **Savings tracking** with achievements and analytics
- 🎨 **Beautiful UI** built with SwiftUI and modern design principles
- 🔒 **Privacy-focused** with local Core Data storage
- 📱 **Siri Shortcuts** integration for voice commands
- 🎯 **Service templates** for popular services (Netflix, Spotify, etc.)

## 📋 Requirements

### System Requirements
- **iOS**: 15.0 or later
- **Xcode**: 14.0 or later
- **Swift**: 5.0 or later
- **macOS**: 12.0 or later (for development)

### Device Support
- iPhone (Primary target)
- iPad (Optimized layout)
- Portrait and landscape orientations

## 🚀 Getting Started

### Clone the Repository
```bash
git clone git@github.com:Juan-Oclock/kansyl.git
cd kansyl
```

### Open in Xcode
```bash
open kansyl.xcodeproj
```

### Build and Run
1. Select your target device/simulator
2. Press `Cmd + R` to build and run
3. The app will launch with onboarding flow for new users

### First Launch Setup
The app includes an onboarding flow that introduces users to core features. For development, you can skip onboarding by setting `hasCompletedOnboarding` to `true` in UserDefaults.

## 🏗️ Architecture

### Tech Stack
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Notifications**: UserNotifications framework
- **Architecture Pattern**: MVVM with ObservableObject
- **State Management**: Combine + StateObject/ObservableObject

### Project Structure
```
kansyl/
├── kansylApp.swift              # Main app entry point
├── ContentView.swift            # Root view with tab navigation
├── Persistence.swift            # Core Data stack
├── Models/                      # Data models and business logic
│   ├── SubscriptionStore.swift  # Core Data operations
│   ├── NotificationManager.swift # Push notifications
│   ├── CostCalculationEngine.swift # Savings calculations
│   ├── AchievementSystem.swift  # Gamification
│   └── AppPreferences.swift     # User settings
├── Views/                       # SwiftUI views
│   ├── AddSubscriptionView.swift
│   ├── ModernSubscriptionsView.swift
│   ├── StatsView.swift
│   ├── SettingsView.swift
│   └── Components/             # Reusable UI components
├── Managers/                   # Service managers
│   ├── AnalyticsManager.swift
│   ├── CalendarManager.swift
│   └── SharingManager.swift
├── Utilities/                  # Helper utilities
│   ├── HapticManager.swift
│   ├── ThemeManager.swift
│   └── EmailParser.swift
└── Extensions/                 # Swift extensions
```

### Core Models
- **Subscription**: Core Data entity for trial/subscription data
- **SubscriptionStore**: Repository pattern for data operations
- **NotificationManager**: Handles rich notifications and user actions
- **CostCalculationEngine**: Calculates savings and waste metrics
- **AchievementSystem**: Gamification with 12+ achievement types

## 🎨 Design System

The app follows Apple's Human Interface Guidelines with a custom design system:

- **Color Palette**: iOS system colors with custom accent colors
- **Typography**: SF Pro system font with defined hierarchy
- **Components**: Reusable SwiftUI components with consistent styling
- **Dark Mode**: Full support with adaptive colors

Design tokens are defined in `Design/DesignSystem.swift`.

## 🔔 Notifications

### Rich Notifications
- Service logos and branding
- Quick action buttons (Cancel/Keep/Snooze)
- Customizable timing per service
- Quiet hours support

### Notification Categories
- **3-day warning**: Early reminder with trial info
- **1-day warning**: Urgent reminder with quick actions
- **Day-of reminder**: Final chance notification with snooze options

## 📊 Features Deep Dive

### Trial Management
- **Quick Add**: Service templates with logos and default settings
- **Bulk Management**: Multi-select operations for power users
- **Smart Status**: Active, ending soon, and historical sections
- **Swipe Actions**: Quick cancel/keep decisions

### Analytics & Insights
- **Savings Tracking**: Calculate money saved from avoided charges
- **Waste Prevention**: Track successful trial completions
- **Achievement System**: 12+ achievement categories
- **Monthly Reports**: Savings breakdown and trends

### Settings & Preferences
- **Default Trial Settings**: Customize trial length and currency
- **Notification Preferences**: Timing and quiet hours
- **Display Options**: Card styles and themes
- **Privacy Controls**: Analytics and data sharing toggles

## 🛠️ Development

### Code Style
- Swift style guide compliance
- SwiftLint integration (optional)
- Comprehensive comments for public APIs
- Unit tests for business logic

### Testing Strategy
- **Unit Tests**: Core business logic and calculations
- **UI Tests**: Critical user flows and navigation
- **Manual Testing**: Notification scenarios and edge cases

### Performance Considerations
- Lazy loading for large datasets
- Efficient Core Data fetching with predicates
- Image caching for service logos
- Background app refresh optimization

## 📱 Siri Shortcuts

The app supports Siri Shortcuts for hands-free trial management:

- **"Add [Service] Trial"**: Quick trial creation
- **"Check My Trials"**: View trials ending soon
- **"Open Kansyl"**: Launch app directly

Shortcuts are automatically suggested based on user behavior.

## 🚀 Release Process

### Version Management
- Semantic versioning (Major.Minor.Patch)
- Release notes for each version
- TestFlight beta testing

### App Store Optimization
- Localized metadata and screenshots
- Keyword optimization
- App preview videos showcasing key features

## 🤝 Contributing

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift API design guidelines
- Write unit tests for new features
- Update documentation for public APIs
- Ensure accessibility compliance
- Test on multiple device sizes

### Code Review Process
- All changes require PR review
- Automated tests must pass
- Manual testing on device required
- Performance impact assessment

## 📄 Documentation

### Additional Resources
- [Product Requirements Document](kansyl/docs/PRD.md)
- [Integration Checklist](INTEGRATION_CHECKLIST.md)
- [Swipe Actions Guide](SWIPE_ACTIONS_GUIDE.md)
- [Quick Actions Guide](QUICK_ACTIONS_GUIDE.md)

### API Documentation
Core APIs are documented inline with Swift documentation comments. Generate documentation using:
```bash
swift package generate-documentation
```

## 🔒 Privacy & Security

- **Local Storage**: All data stored locally with Core Data
- **No Analytics by Default**: User opt-in required for analytics
- **Notification Privacy**: Sensitive info only in locked notifications
- **Data Export**: Users can export their data anytime

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

### Getting Help
- Create an issue for bugs or feature requests
- Check existing documentation and guides
- Review closed issues for similar problems

### Contact
- **Developer**: Juan Oclock
- **Repository**: [github.com/Juan-Oclock/kansyl](https://github.com/Juan-Oclock/kansyl)

---

**Built with ❤️ using SwiftUI and Core Data**