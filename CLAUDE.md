# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kansyl is a free trial reminder app built with SwiftUI and Core Data that helps users track free trials and avoid unwanted subscription charges. The app features AI-powered receipt scanning, rich notifications, and a clean UI with subscription analytics.

## Development Commands

### Build & Run
```bash
# Open project in Xcode
open kansyl.xcodeproj

# Clean build (useful for cache issues)
./clean_build.sh

# Manual build commands
xcodebuild -project kansyl.xcodeproj -scheme kansyl build
xcodebuild -project kansyl.xcodeproj -scheme kansyl test
```

### API Configuration
```bash
# Setup DeepSeek API for receipt scanning
./setup_deepseek.sh
```

### Testing
```bash
# Run unit tests
xcodebuild test -project kansyl.xcodeproj -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project kansyl.xcodeproj -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:kansylUITests
```

## Architecture

### Tech Stack
- **UI Framework**: SwiftUI (iOS 15.0+)
- **Data Persistence**: Core Data with `PersistenceController`
- **Notifications**: UserNotifications framework with rich notifications
- **Architecture Pattern**: MVVM with ObservableObject
- **State Management**: Combine + StateObject/ObservableObject
- **External APIs**: DeepSeek AI for receipt scanning

### Key Architecture Components

#### Core Data Stack
- `PersistenceController`: Shared Core Data container with in-memory preview support
- `Subscription`: Core Data entity for trial/subscription data
- `ServiceTemplate`: Core Data entity for popular service presets

#### Data Layer
- `SubscriptionStore`: Repository pattern for data operations (kansyl/Models/SubscriptionStore.swift:37)
- `NotificationManager`: Handles rich notifications and user actions (kansyl/Models/NotificationManager.swift:13)
- `CostCalculationEngine`: Calculates savings and waste metrics
- `AchievementSystem`: Gamification with achievement tracking

#### Business Logic Managers
- `AppPreferences`: User settings and preferences
- `CurrencyManager`: Multi-currency support with conversion
- `AIConfigManager`: AI API configuration and keychain storage
- `PremiumManager`: Premium features and subscription management
- `CalendarManager`: Calendar integration for trial management

#### View Architecture
- `ContentView`: Root view with tab navigation
- Views organized by feature in `kansyl/Views/`
- Reusable components in `kansyl/Views/Components/`
- Design tokens in `kansyl/Design/DesignSystem.swift`

### AI Integration
The app includes AI-powered receipt scanning using DeepSeek API:
- `ReceiptScanner`: Handles image processing and API calls
- `AISettingsView`: Runtime API key configuration
- API key stored securely in iOS keychain
- Configuration via `Config.xcconfig` for development

## Development Notes

### Configuration Files
- `Config.xcconfig`: Development configuration (gitignored)
- `Config-Template.xcconfig`: Template for sharing configurations
- API keys should never be committed to the repository

### Core Data Model
- Subscription entity with status, dates, pricing, and service information
- ServiceTemplate entity for popular service presets
- Automatic migration handling in `PersistenceController`

### Notification System
- Rich notifications with service logos and quick actions
- Categories: 3-day warning, 1-day warning, day-of reminder
- Quiet hours support and customizable timing
- Delegate pattern for handling notification actions

### State Management
- `@StateObject` and `@ObservedObject` for view models
- `@Environment` for shared services
- Combine publishers for reactive updates
- Core Data notifications for data changes

### Testing
- Sample data in `PersistenceController.preview` for SwiftUI previews
- Unit tests in `kansylTests/`
- UI tests in `kansylUITests/`

### Siri Shortcuts
- Intent definitions in `kansyl/Intents/`
- Handler in `IntentHandler.swift`
- Support for "Add Trial", "Check Trials", and "Quick Add" actions

### App Extensions
- Share Extension for adding subscriptions from other apps
- Widget Extension for home screen subscription status
- Intent Extension for Siri shortcut handling

## Common Development Tasks

### Adding New Features
1. Create views in `kansyl/Views/`
2. Add business logic to appropriate manager class
3. Update Core Data model if needed
4. Add navigation in `ContentView`
5. Include in onboarding flow if applicable

### Working with Notifications
- Use `NotificationManager.shared` for all notification operations
- Follow the existing category pattern for new notification types
- Test with both foreground and background scenarios

### UI Development
- Follow design system tokens in `DesignSystem.swift`
- Use existing components when possible
- Test on multiple device sizes
- Ensure dark mode compatibility

### Data Persistence
- Use `SubscriptionStore` for all data operations
- Follow Core Data best practices
- Include proper error handling
- Test data migration when model changes

## File Structure
```
kansyl/
├── kansylApp.swift              # App entry point
├── AppDelegate.swift            # UIApplicationDelegate
├── ContentView.swift           # Root view
├── Persistence.swift            # Core Data stack
├── Models/                      # Data models and managers
├── Views/                       # SwiftUI views and components
├── Managers/                    # Service managers
├── Utilities/                   # Helper utilities
├── Extensions/                  # Swift extensions
├── Services/                    # External service integrations
├── Design/                      # Design system
├── Config/                      # Configuration files
└── docs/                        # Documentation
```