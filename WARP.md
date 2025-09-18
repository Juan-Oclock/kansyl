# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Kansyl is a free trial reminder iOS app built with SwiftUI and Core Data that helps users track free trials and avoid unwanted subscription charges. The app features AI-powered receipt scanning using DeepSeek API, rich notifications, and a clean UI with subscription analytics.

## Development Commands

### Build & Run
```bash
# Open project in Xcode
open kansyl.xcodeproj

# Clean build (useful for cache issues)
./clean_build.sh

# Manual build commands
xcodebuild -project kansyl.xcodeproj -scheme kansyl build
xcodebuild -project kansyl.xcodeproj -scheme kansyl -configuration Debug -sdk iphonesimulator build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project kansyl.xcodeproj -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests only
xcodebuild test -project kansyl.xcodeproj -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:kansylUITests

# Run specific test suite
xcodebuild test -project kansyl.xcodeproj -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:kansylTests
```

### AI Configuration
```bash
# Setup DeepSeek API for receipt scanning
./setup_deepseek.sh

# Verify Core Data migration (if needed)
./verify_migration.sh
```

### Development Utilities
```bash
# Add test subscription data for development
swift add_test_subscriptions.swift

# Clean all Xcode caches and build artifacts
./clean_build.sh
```

## Architecture Overview

### Tech Stack
- **UI Framework**: SwiftUI (iOS 15.0+)
- **Data Persistence**: Core Data with `PersistenceController`
- **Notifications**: UserNotifications framework with rich notifications
- **Architecture Pattern**: MVVM with ObservableObject
- **State Management**: Combine + StateObject/ObservableObject
- **External APIs**: DeepSeek AI for receipt scanning

### Core Architecture Components

#### Data Layer
- `PersistenceController`: Shared Core Data container with in-memory preview support
- `SubscriptionStore`: Repository pattern for all subscription data operations
- `Subscription` & `ServiceTemplate`: Core Data entities for trial and service template data

#### Business Logic Managers (kansyl/Managers/)
- `NotificationManager`: Handles rich notifications with service logos and quick actions
- `CostCalculationEngine`: Calculates savings and waste prevention metrics
- `AchievementSystem`: Gamification system with 12+ achievement categories
- `AppPreferences`: User settings and configuration management
- `CurrencyManager`: Multi-currency support with real-time conversion
- `AIConfigManager`: AI API configuration with secure keychain storage
- `PremiumManager`: Premium features and subscription management
- `CalendarManager`: Calendar integration for trial management

#### View Architecture
- `ContentView`: Root view with tab navigation (main entry point)
- Views organized by feature in `kansyl/Views/`
- Reusable UI components in `kansyl/Views/Components/`
- Design system tokens in `kansyl/Design/DesignSystem.swift`

#### AI Integration
- `ReceiptScanner`: Handles image processing and DeepSeek API calls
- `AISettingsView`: Runtime API key configuration interface
- API keys stored securely in iOS keychain, never in code
- Development configuration via `Config.xcconfig` (git-ignored)

### Key Patterns

#### Core Data Integration
- Use `SubscriptionStore` for all data operations, never direct Core Data calls
- `PersistenceController.preview` provides sample data for SwiftUI previews
- Automatic migration handling built into the persistence controller

#### Notification System
- Three notification categories: 3-day warning, 1-day warning, day-of reminder
- Rich notifications with service logos and interactive quick actions
- Quiet hours support and per-service customizable timing
- All handled through `NotificationManager.shared`

#### State Management
- `@StateObject` and `@ObservedObject` for view models
- `@Environment` for injecting shared services like persistence context
- Combine publishers for reactive data updates
- Core Data notifications automatically update SwiftUI views

#### Configuration Management
- `Config.xcconfig`: Development-time configuration (git-ignored)
- `Config-Template.xcconfig`: Template for sharing configurations
- Runtime API configuration stored in iOS keychain via `AIConfigManager`
- Never commit API keys or secrets to the repository

### App Extensions Support
- **Siri Shortcuts**: Intent definitions in `kansyl/Intents/` with support for "Add Trial", "Check Trials", and "Quick Add" actions
- **Share Extension**: Add subscriptions from other apps (kansyl/ShareExtension/)
- **Widget Extension**: Home screen subscription status widget (KansylWidget/)
- **Intent Extension**: Handles Siri shortcut processing

### Important Development Notes

#### Working with Notifications
- All notification operations go through `NotificationManager.shared`
- Test both foreground and background notification scenarios
- Rich notifications include service logos and interactive buttons
- Follow existing category pattern for new notification types

#### AI Receipt Scanning
- DeepSeek API integration for cost-effective receipt processing (~$0.001 per scan)
- Secure API key storage in iOS keychain
- Image processing and parsing handled by `ReceiptScanner`
- Configuration via AI Settings screen in production builds

#### Currency & Localization
- Multi-currency support with real-time exchange rate conversion
- Use `CurrencyManager` for all currency-related operations
- Savings calculations handled by `CostCalculationEngine`

#### Data Migration
- Core Data model changes require migration planning
- Use `./verify_migration.sh` to test migrations
- Sample data available via `PersistenceController.preview`

## Common File Paths
- Main app entry: `kansyl/kansylApp.swift`
- Root view: `kansyl/ContentView.swift`
- Core Data stack: `kansyl/Persistence.swift`
- Business logic: `kansyl/Models/SubscriptionStore.swift`
- Notifications: `kansyl/Models/NotificationManager.swift`
- UI components: `kansyl/Views/Components/`
- Design system: `kansyl/Design/DesignSystem.swift`
- Configuration: `Config.xcconfig` (create from `Config-Template.xcconfig`)