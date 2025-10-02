//
//  ScreenshotTests.swift
//  kansylUITests
//
//  Automated screenshot capture for App Store submission
//

import XCTest

class ScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        setupSnapshot(app)
        
        // Launch arguments for consistent screenshot state
        app.launchArguments += ["UI-TESTING"]
        app.launchArguments += ["DISABLE-ANIMATIONS"]
        app.launchArguments += ["USE-MOCK-DATA"]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Screenshot 1: Main Subscription List
    func testScreenshot01_MainList() throws {
        // Wait for the app to load
        sleep(2)
        
        // Ensure we're on the main subscriptions view
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        
        // Take screenshot
        snapshot("01-MainSubscriptionList")
        
        print("✅ Screenshot 1: Main Subscription List captured")
    }
    
    // MARK: - Screenshot 2: Add Subscription Flow
    func testScreenshot02_AddSubscription() throws {
        sleep(2)
        
        // Tap the add button
        let addButton = app.buttons["plus"]
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            snapshot("02-AddSubscription")
            print("✅ Screenshot 2: Add Subscription captured")
        } else {
            // Try alternative ways to open add sheet
            let addSubscriptionButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'add'")).firstMatch
            if addSubscriptionButton.exists {
                addSubscriptionButton.tap()
                sleep(1)
                snapshot("02-AddSubscription")
                print("✅ Screenshot 2: Add Subscription captured")
            } else {
                print("⚠️  Add button not found, skipping screenshot 2")
            }
        }
    }
    
    // MARK: - Screenshot 3: Subscription Detail View
    func testScreenshot03_SubscriptionDetail() throws {
        sleep(2)
        
        // Tap on the first subscription card
        let subscriptionCards = app.otherElements.matching(identifier: "SubscriptionCard")
        if subscriptionCards.count > 0 {
            subscriptionCards.firstMatch.tap()
            sleep(1)
            
            snapshot("03-SubscriptionDetail")
            print("✅ Screenshot 3: Subscription Detail captured")
            
            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        } else {
            // Try tapping any cell
            let cells = app.cells
            if cells.count > 0 {
                cells.firstMatch.tap()
                sleep(1)
                snapshot("03-SubscriptionDetail")
                print("✅ Screenshot 3: Subscription Detail captured")
            } else {
                print("⚠️  No subscriptions found, skipping screenshot 3")
            }
        }
    }
    
    // MARK: - Screenshot 4: Notifications View
    func testScreenshot04_Notifications() throws {
        sleep(2)
        
        // Tap the notification bell button
        let notificationButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'bell'")).firstMatch
        if notificationButton.exists {
            notificationButton.tap()
            sleep(1)
            
            snapshot("04-Notifications")
            print("✅ Screenshot 4: Notifications captured")
            
            // Close the sheet
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
                sleep(1)
            }
        } else {
            print("⚠️  Notification button not found, skipping screenshot 4")
        }
    }
    
    // MARK: - Screenshot 5: Savings Dashboard
    func testScreenshot05_SavingsDashboard() throws {
        sleep(2)
        
        // The savings card should be visible on the main screen
        let savingsCard = app.otherElements.matching(identifier: "SavingsCard").firstMatch
        if savingsCard.exists {
            snapshot("05-SavingsDashboard")
            print("✅ Screenshot 5: Savings Dashboard captured")
        } else {
            // If not visible, just capture the main view
            snapshot("05-SavingsDashboard")
            print("✅ Screenshot 5: Savings Dashboard captured (main view)")
        }
    }
    
    // MARK: - Screenshot 6: Settings View
    func testScreenshot06_Settings() throws {
        sleep(2)
        
        // Navigate to settings (usually via tab bar or menu)
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'gear'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            
            snapshot("06-Settings")
            print("✅ Screenshot 6: Settings captured")
        } else {
            // Try tab bar
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                let settingsTab = tabBar.buttons.element(boundBy: tabBar.buttons.count - 1)
                settingsTab.tap()
                sleep(1)
                snapshot("06-Settings")
                print("✅ Screenshot 6: Settings captured")
            } else {
                print("⚠️  Settings not found, skipping screenshot 6")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppToSettle() {
        sleep(1)
        // Wait for animations to complete
        let _ = XCTWaiter.wait(for: [expectation(description: "Wait for UI")], timeout: 0.5)
    }
}

// MARK: - Snapshot Helper (Fastlane Snapshot compatible)

func setupSnapshot(_ app: XCUIApplication) {
    // This makes the script compatible with Fastlane Snapshot
    // You can also run it standalone
}

func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    // Check if we have a custom screenshots path from environment
    let screenshotsPath = ProcessInfo.processInfo.environment["SCREENSHOTS_PATH"]
    
    // Take the screenshot
    let screenshot = XCUIScreen.main.screenshot()
    
    // Create attachment
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    
    // Add to test
    XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
        activity.add(attachment)
    }
    
    // If we have a custom path, also save there
    if let path = screenshotsPath {
        saveScreenshot(screenshot, name: name, path: path)
    }
    
    print("📸 Screenshot captured: \(name)")
}

func saveScreenshot(_ screenshot: XCUIScreenshot, name: String, path: String) {
    let fileManager = FileManager.default
    let screenshotPath = "\(path)/\(name).png"
    
    do {
        // Create directory if it doesn't exist
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        // Save the image
        try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: screenshotPath))
        print("💾 Screenshot saved to: \(screenshotPath)")
    } catch {
        print("❌ Error saving screenshot: \(error.localizedDescription)")
    }
}
