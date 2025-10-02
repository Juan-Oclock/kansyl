# Automated App Store Screenshot Generation

This guide explains how to automatically capture App Store screenshots for Kansyl using the automated screenshot script.

## 📋 Overview

The screenshot automation system captures screenshots for all required device sizes:
- **iPhone 6.7"** (iPhone 15 Pro Max, 15 Plus) - 1290x2796
- **iPhone 6.5"** (iPhone 11 Pro Max, XS Max) - 1242x2688
- **iPhone 5.5"** (iPhone 8 Plus) - 1242x2208
- **iPad 12.9"** (iPad Pro 12.9-inch) - 2048x2732

## 🚀 Quick Start

### Prerequisites

1. **Xcode installed** with command-line tools
2. **Simulators installed** for all required devices
3. **UI Testing target** set up in your project

### Step 1: Make the Script Executable

```bash
cd /Users/juan_oclock/Documents/ios-mobile/kansyl/Scripts
chmod +x capture_screenshots.sh
```

### Step 2: Run the Screenshot Script

```bash
./capture_screenshots.sh
```

The script will:
1. Build the app
2. Launch each simulator
3. Run UI tests to capture screenshots
4. Save screenshots to organized folders

### Step 3: Review Screenshots

Screenshots are saved to: `/Users/juan_oclock/Documents/ios-mobile/kansyl/Screenshots/`

Directory structure:
```
Screenshots/
├── 6.7-inch/
│   ├── 01-MainSubscriptionList.png
│   ├── 02-AddSubscription.png
│   ├── 03-SubscriptionDetail.png
│   ├── 04-Notifications.png
│   ├── 05-SavingsDashboard.png
│   └── 06-Settings.png
├── 6.5-inch/
│   └── (same screenshots)
├── 5.5-inch/
│   └── (same screenshots)
└── 12.9-inch-iPad/
    └── (same screenshots)
```

## 📸 Screenshots Captured

The automation captures 6 key screenshots:

1. **Main Subscription List** - Shows all tracked subscriptions
2. **Add Subscription** - Demonstrates the add flow
3. **Subscription Detail** - Individual subscription view
4. **Notifications** - Notification settings and reminders
5. **Savings Dashboard** - Money saved analytics
6. **Settings** - App settings and preferences

## 🛠️ Customization

### Adding More Screenshots

Edit `kansylUITests/ScreenshotTests.swift` and add new test methods:

```swift
func testScreenshot07_YourNewScreen() throws {
    sleep(2)
    
    // Navigate to your screen
    let button = app.buttons["YourButton"]
    button.tap()
    sleep(1)
    
    // Capture screenshot
    snapshot("07-YourNewScreen")
    print("✅ Screenshot 7: Your New Screen captured")
}
```

### Changing Device Sizes

Edit `Scripts/capture_screenshots.sh` and modify the `DEVICES` array:

```bash
declare -a DEVICES=(
    "iPhone 15 Pro Max|1290x2796|3x|6.7-inch"
    "Your Device Name|Resolution|Scale|Directory Name"
)
```

### Using Mock Data

The UI tests launch with these arguments:
- `UI-TESTING` - Indicates test mode
- `DISABLE-ANIMATIONS` - Speeds up capture
- `USE-MOCK-DATA` - Shows demo subscriptions

To handle these in your app, add this to your main view:

```swift
if CommandLine.arguments.contains("USE-MOCK-DATA") {
    // Load mock subscriptions
    loadMockData()
}

if CommandLine.arguments.contains("DISABLE-ANIMATIONS") {
    UIView.setAnimationsEnabled(false)
}
```

## 🔧 Troubleshooting

### Problem: Script fails with "scheme not found"

**Solution**: Make sure you have a UI testing target and scheme configured in Xcode.

1. Open your project in Xcode
2. Go to Product > Scheme > Manage Schemes
3. Ensure your main scheme includes the UI Testing target

### Problem: Simulators not found

**Solution**: Install the required simulators:

1. Open Xcode
2. Go to Xcode > Settings > Platforms
3. Download required simulator runtimes
4. Verify simulators exist: `xcrun simctl list devices`

### Problem: Screenshots are blank or incorrect

**Solution**: 
1. Increase sleep times in test methods
2. Verify UI elements exist with proper identifiers
3. Run tests manually in Xcode to debug

### Problem: Build fails

**Solution**: Check the error message. Common issues:
- Missing dependencies
- Code signing issues (use simulator target)
- Workspace path incorrect

## 📱 Manual Testing

You can also run the UI tests manually in Xcode:

1. Open `kansyl.xcworkspace`
2. Select a simulator (e.g., iPhone 15 Pro Max)
3. Go to Product > Test
4. Select only `ScreenshotTests` to run
5. Screenshots will be in test results attachments

To view screenshots:
1. Open Test Navigator (⌘6)
2. Select your test run
3. Click on individual tests
4. View screenshot attachments

## 🎨 Enhancing Screenshots

After capturing screenshots, you may want to:

1. **Add device frames** - Use tools like [Fastlane Frameit](https://fastlane.tools/frameit)
2. **Add text overlays** - Use design tools (Sketch, Figma, Photoshop)
3. **Optimize file size** - Use ImageOptim or similar tools
4. **Ensure consistency** - Same status bar time (9:41), battery level, signal

### Recommended Tools

- **Fastlane Frameit**: Add device frames automatically
- **Apple's Screenshot Guidelines**: Follow best practices
- **ImageOptim**: Reduce file size without quality loss
- **Sketch/Figma**: Add professional text overlays

## 📊 App Store Requirements

### Screenshot Requirements

| Device | Resolution | Orientation | Required |
|--------|-----------|-------------|----------|
| 6.7" iPhone | 1290 x 2796 | Portrait | Yes |
| 6.5" iPhone | 1242 x 2688 | Portrait | Yes |
| 5.5" iPhone | 1242 x 2208 | Portrait | Optional |
| 12.9" iPad | 2048 x 2732 | Portrait/Landscape | If supporting iPad |

### Best Practices

- ✅ Show actual app content (no mockups)
- ✅ Use consistent status bar (9:41, full battery)
- ✅ Clean, professional appearance
- ✅ Highlight key features
- ✅ Tell a story with screenshot sequence
- ❌ No placeholder content ("Lorem ipsum")
- ❌ No offensive content
- ❌ No misleading information

## 🚀 Advanced: CI/CD Integration

You can integrate this into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Capture Screenshots
  run: |
    cd Scripts
    chmod +x capture_screenshots.sh
    ./capture_screenshots.sh
    
- name: Upload Screenshots
  uses: actions/upload-artifact@v3
  with:
    name: app-store-screenshots
    path: Screenshots/
```

## 📚 Additional Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)
- [Fastlane Snapshot Tool](https://docs.fastlane.tools/actions/snapshot/)
- [UI Testing in Xcode](https://developer.apple.com/documentation/xctest/user_interface_tests)

## 🆘 Support

If you encounter issues:

1. Check the script output for error messages
2. Verify all prerequisites are met
3. Test manually in Xcode first
4. Check simulator availability: `xcrun simctl list devices`

## 📝 Notes

- Screenshots are captured from **simulators**, not physical devices
- The script can take **10-15 minutes** to complete for all devices
- Screenshots are saved as **PNG files** for maximum quality
- You may need to **adjust sleep times** based on your Mac's performance

---

**Ready to capture your App Store screenshots!** 📸

Run: `./capture_screenshots.sh` and watch the magic happen! ✨
