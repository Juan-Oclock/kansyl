# 📸 Screenshot Automation - Quick Start

## ⚡ TL;DR - Run This Now

```bash
cd /Users/juan_oclock/Documents/ios-mobile/kansyl/Scripts
./capture_screenshots.sh
```

Screenshots will be saved to: `Screenshots/` folder

---

## 🎯 What You Get

Automated screenshots for **all required App Store device sizes**:
- ✅ iPhone 6.7" (iPhone 15 Pro Max) - **Required**
- ✅ iPhone 6.5" (iPhone 11 Pro Max) - **Required**  
- ✅ iPhone 5.5" (iPhone 8 Plus) - Optional
- ✅ iPad 12.9" - If supporting iPad

Each device gets **6 screenshots**:
1. Main subscription list
2. Add subscription flow
3. Subscription detail view
4. Notifications
5. Savings dashboard
6. Settings

---

## 🚦 Before You Run

### Check Prerequisites

```bash
# 1. Check if simulators are installed
xcrun simctl list devices | grep "iPhone 15 Pro Max"
xcrun simctl list devices | grep "iPhone 11 Pro Max"
xcrun simctl list devices | grep "iPhone 8 Plus"
xcrun simctl list devices | grep "iPad Pro (12.9-inch)"

# 2. Check if UI tests target exists
open kansyl.xcworkspace
# In Xcode: File > New > Target > "UI Testing Bundle" (if not exists)
```

### If Simulators Are Missing

```bash
# Open Xcode and download simulators
# Xcode > Settings > Platforms > iOS > Download
```

---

## 🎬 Running the Script

### Option 1: Automated (Recommended)

```bash
cd Scripts
./capture_screenshots.sh
```

**Time**: ~10-15 minutes for all devices

### Option 2: Manual in Xcode

1. Open `kansyl.xcworkspace`
2. Select simulator (e.g., iPhone 15 Pro Max)
3. Press `⌘U` to run tests
4. Select `ScreenshotTests` target
5. View results in Test Navigator (`⌘6`)

---

## 📂 Where Are My Screenshots?

```
kansyl/
└── Screenshots/
    ├── 6.7-inch/        ← iPhone 15 Pro Max screenshots
    │   ├── 01-MainSubscriptionList.png
    │   ├── 02-AddSubscription.png
    │   ├── 03-SubscriptionDetail.png
    │   ├── 04-Notifications.png
    │   ├── 05-SavingsDashboard.png
    │   └── 06-Settings.png
    ├── 6.5-inch/        ← iPhone 11 Pro Max screenshots
    ├── 5.5-inch/        ← iPhone 8 Plus screenshots
    └── 12.9-inch-iPad/  ← iPad Pro screenshots
```

---

## ⚠️ Troubleshooting

### "Build failed" or "Scheme not found"

```bash
# Make sure the workspace file exists
ls -la kansyl.xcworkspace

# Open in Xcode and verify scheme
open kansyl.xcworkspace
# Product > Scheme > Manage Schemes > Ensure "kansyl" exists
```

### "No screenshots captured"

The UI test might be failing. Run manually to debug:

1. Open Xcode
2. Select a simulator
3. Run just one test: `testScreenshot01_MainList`
4. Check console output for errors

### "Simulator not found"

Install the missing simulator:
1. Xcode > Settings > Platforms
2. Click the download icon next to iOS version
3. Wait for download to complete

---

## 🎨 Next Steps After Capturing

### 1. Review All Screenshots

```bash
# Open Screenshots folder
open Screenshots/
```

### 2. Check Image Quality

- ✅ Status bar shows 9:41 (standard time)
- ✅ Full battery indicator
- ✅ All content is visible
- ✅ No personal data visible
- ✅ App looks professional

### 3. Optional Enhancements

Use design tools to:
- Add device frames (makes them look more polished)
- Add text overlays highlighting features
- Adjust colors/brightness if needed
- Optimize file size

**Recommended tools:**
- [Fastlane Frameit](https://fastlane.tools/frameit) - Device frames
- Figma/Sketch - Professional editing
- ImageOptim - File size optimization

### 4. Prepare for Upload

Apple requirements:
- Max 10 screenshots per device size
- PNG or JPEG format
- Specific resolutions (already handled by script)
- Can include text overlays
- Must show actual app content

---

## 📊 Expected File Sizes

| Device | Count | Approx Size |
|--------|-------|-------------|
| 6.7" iPhone | 6 screenshots | ~12-18 MB |
| 6.5" iPhone | 6 screenshots | ~10-15 MB |
| 5.5" iPhone | 6 screenshots | ~8-12 MB |
| 12.9" iPad | 6 screenshots | ~15-20 MB |
| **Total** | **24 screenshots** | **~45-65 MB** |

---

## 🐛 Common Issues & Fixes

### Issue: "Operation timed out"
**Fix**: Increase `sleep` time in `ScreenshotTests.swift`

### Issue: Screenshots show wrong content
**Fix**: Check launch arguments in test setup:
```swift
app.launchArguments += ["USE-MOCK-DATA"]  // Shows demo data
```

### Issue: UI elements not found
**Fix**: Add accessibility identifiers to your views:
```swift
.accessibilityIdentifier("YourViewID")
```

### Issue: Tests pass but no screenshots
**Fix**: Check the `SCREENSHOTS_PATH` environment variable is set

---

## 🚀 Pro Tips

1. **Run during off-hours** - Takes 10-15 minutes
2. **Use mock data** - Ensures consistent, professional screenshots
3. **Clean status bar** - Use `SimulatorStatusMagic` or similar tools
4. **Batch process** - Enhance all screenshots at once
5. **Version control** - Keep screenshots in a separate branch

---

## 📞 Need Help?

### Quick Checks
```bash
# Is Xcode installed?
xcodebuild -version

# Are simulators installed?
xcrun simctl list devices available

# Can the project build?
cd /Users/juan_oclock/Documents/ios-mobile/kansyl
xcodebuild -workspace kansyl.xcworkspace -scheme kansyl -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' build
```

### Still Having Issues?

1. Read the detailed guide: `Scripts/README_SCREENSHOTS.md`
2. Check Xcode console output for errors
3. Verify UI test target is properly configured
4. Try running one test manually in Xcode first

---

## ✅ Checklist

Before uploading to App Store Connect:

- [ ] All 6 screenshots captured for 6.7" iPhone
- [ ] All 6 screenshots captured for 6.5" iPhone
- [ ] Screenshots show actual app content
- [ ] Status bar is clean (9:41, full battery)
- [ ] No personal/sensitive data visible
- [ ] Image quality is high (no pixelation)
- [ ] File sizes are reasonable (<5MB each)
- [ ] Screenshots tell a story (good sequence)
- [ ] Optional: Device frames added
- [ ] Optional: Text overlays added

---

**Ready to capture your screenshots? Run the script now!** 🎉

```bash
cd Scripts && ./capture_screenshots.sh
```

**Total time**: ~10-15 minutes ⏱️  
**Result**: Professional App Store screenshots ready for submission! 📱✨
