# 📸 Kansyl App Store Screenshots

This folder contains all screenshots for App Store submission.

## 📂 Folder Structure

```
AppStore/Screenshots/
├── 6.7-inch-iPhone/     ← iPhone 16 Pro Max, 15 Pro Max (REQUIRED)
│   ├── 01-MainList.png
│   ├── 02-AddSubscription.png
│   ├── 03-Detail.png
│   ├── 04-Notifications.png
│   ├── 05-Savings.png
│   └── 06-Settings.png
│
├── 6.5-inch-iPhone/     ← iPhone 15 Pro, 14 Pro Max (Optional)
│   └── (same 6 screenshots)
│
└── iPad/                ← iPad Pro 13-inch (Optional)
    └── (same 6 screenshots)
```

## ✅ Required Screenshots

### 6.7-inch iPhone (REQUIRED)
- **Device**: iPhone 16 Pro Max
- **Resolution**: 1290 x 2796 pixels
- **Count**: 6 screenshots minimum, 10 maximum
- **Status**: This size is REQUIRED by Apple

### Other Sizes (Optional but Recommended)
- **6.5-inch iPhone**: iPhone 15 Pro, 14 Pro Max (1242 x 2688)
- **iPad**: iPad Pro 13-inch or 12.9-inch (2048 x 2732)

## 📋 Screenshot Checklist

Before uploading to App Store Connect:

- [ ] All 6 screenshots captured for 6.7-inch iPhone
- [ ] Files named clearly (01-MainList.png, 02-AddSubscription.png, etc.)
- [ ] Status bar is clean (9:41, full battery, full signal)
- [ ] No personal/sensitive data visible
- [ ] Images are PNG format
- [ ] Correct resolution (1290 x 2796 for iPhone 16 Pro Max)
- [ ] Professional appearance (no placeholder content)

## 🎯 Screenshot Order

App Store displays screenshots in order, so sequence matters:

1. **01-MainList.png** - First impression! Show active subscriptions with savings
2. **02-AddSubscription.png** - Demonstrate ease of adding subscriptions
3. **03-Detail.png** - Show subscription management features
4. **04-Notifications.png** - Highlight smart reminders
5. **05-Savings.png** - Emphasize money-saving benefits
6. **06-Settings.png** - Show app features and customization

## 📤 Moving Screenshots from Desktop

After capturing screenshots in Simulator (saved to Desktop):

```bash
# Move iPhone 16 Pro Max screenshots
cd ~/Desktop
mv *iPhone*16*Pro*Max*.png /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots/6.7-inch-iPhone/

# Or if you named them differently:
mv 01-*.png 02-*.png 03-*.png 04-*.png 05-*.png 06-*.png /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots/6.7-inch-iPhone/
```

Or simply **drag and drop** from Desktop to the folder in Finder.

## 📏 Verify Resolution

Check screenshot resolution before uploading:

```bash
# Check all screenshots in 6.7-inch folder
cd /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots/6.7-inch-iPhone
sips -g pixelWidth -g pixelHeight *.png
```

Should show: **1290 x 2796** for iPhone 16 Pro Max

## 🎨 Optional Enhancements

### Add Device Frames
Make screenshots look more polished with device frames:
- [Fastlane Frameit](https://fastlane.tools/frameit)
- [Screenshot.rocks](https://screenshot.rocks/)
- [Mockuphone](https://mockuphone.com/)

### Add Text Overlays
Highlight key features:
- Keep text minimal and readable
- Use brand colors (#6B41C7 purple, #A8DE28 lime)
- Don't cover important UI elements
- Use Figma, Sketch, or Photoshop

### Optimize File Size
Reduce file size without quality loss:
```bash
# Install ImageOptim
brew install --cask imageoptim

# Optimize all screenshots
find /Users/juan_oclock/Documents/ios-mobile/kansyl/AppStore/Screenshots -name "*.png" -exec imageoptim {} \;
```

## 🚫 .gitignore Note

Screenshots are typically large files and change frequently. They're **not** tracked in Git by default (see `.gitignore`).

**Keep them**:
- ✅ In this folder for organization
- ✅ On your local machine
- ✅ Backed up separately
- ❌ Don't commit to Git (too large)

## 📱 App Store Connect Upload

When Apple approves your developer account:

1. Go to **App Store Connect** > Your App > **1.0 Prepare for Submission**
2. Scroll to **App Preview and Screenshots**
3. Select **6.7" Display** (iPhone 16 Pro Max)
4. Drag and drop screenshots from `6.7-inch-iPhone/` folder
5. Arrange in order (they should already be numbered correctly)
6. Repeat for other device sizes if you have them

## 📊 File Size Guidelines

| Device | Count | Approx Total Size |
|--------|-------|-------------------|
| 6.7" iPhone | 6 screenshots | 10-15 MB |
| 6.5" iPhone | 6 screenshots | 8-12 MB |
| iPad | 6 screenshots | 15-20 MB |

Apple's limit: **10 screenshots max per device size**

## ✨ Tips for Great Screenshots

1. **Tell a story** - Screenshots should show app flow
2. **Highlight benefits** - Focus on value to users
3. **Keep it real** - Show actual app content, not mockups
4. **Be consistent** - Same style, status bar across all screenshots
5. **First matters most** - First screenshot gets most visibility

## 🔗 Related Documentation

- **MANUAL_SCREENSHOT_GUIDE.md** - How to capture screenshots
- **APP_STORE_COPY.md** - Marketing text for App Store
- **APP_STORE_PUBLISHING_CHECKLIST.md** - Full submission checklist

---

**Current Status**: Folder structure created, ready for screenshots! 📸

Place your screenshots here after capturing them from the Simulator.
