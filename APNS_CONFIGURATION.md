# 🔐 Apple Push Notification Service (APNs) Configuration

**IMPORTANT: Keep this file secure and never commit it to public repositories!**

---

## 📋 APNs Credentials

### Key Information:
- **Key ID**: `C294DWA9AX`
- **Team ID**: `YXXWV4ZNFS`
- **Bundle ID**: `com.juan-oclock.kansyl.kansyl`
- **Key File**: `AuthKey_C294DWA9AX.p8`
- **Environment**: Production (works for both Sandbox and Production)

### Key File Location:
- **Current Location**: `~/Downloads/AuthKey_C294DWA9AX.p8`
- **Recommended Storage**: Move to a secure location (see below)

---

## 📁 Secure Storage Recommendations

### Option 1: Project Secure Directory (Not in Git)
```bash
# Create secure directory
mkdir -p ~/Documents/ios-mobile/kansyl/secrets

# Move key file
mv ~/Downloads/AuthKey_C294DWA9AX.p8 ~/Documents/ios-mobile/kansyl/secrets/

# Add to .gitignore
echo "secrets/" >> ~/Documents/ios-mobile/kansyl/.gitignore
```

### Option 2: Password Manager
Store the key file and credentials in your password manager (1Password, LastPass, etc.)

### Option 3: macOS Keychain
Store in a secure note in Keychain Access

---

## 🔧 Backend Configuration (Supabase)

When you're ready to implement push notifications in your backend:

### Supabase Edge Functions Setup:

1. **Install Supabase Dependencies**:
```typescript
import { createClient } from '@supabase/supabase-js'
// You'll need an APNs library like 'apn' or use HTTP/2 directly
```

2. **Configure APNs Client**:
```typescript
// Example configuration (adjust based on your library)
const apnsConfig = {
  token: {
    key: 'contents of AuthKey_C294DWA9AX.p8',
    keyId: 'C294DWA9AX',
    teamId: 'YXXWV4ZNFS'
  },
  production: true  // Use production APNs server
}
```

3. **Send Notification**:
```typescript
const notification = {
  topic: 'com.juan-oclock.kansyl.kansyl',
  payload: {
    aps: {
      alert: {
        title: 'Trial Ending Soon',
        body: 'Your Netflix trial ends in 3 days'
      },
      sound: 'default',
      badge: 1
    }
  }
}
```

---

## 📱 iOS App Configuration

### Device Token Registration
In your iOS app, you'll need to:

1. Request notification permission
2. Register for remote notifications
3. Store the device token in your database
4. Send it to your backend

### Example Swift Code:
```swift
// Request permission
let center = UNUserNotificationCenter.current()
center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

// Handle device token
func application(_ application: UIApplication, 
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send token to your Supabase backend
    print("Device Token: \(token)")
}
```

---

## 🧪 Testing Push Notifications

### Test with Terminal (using curl):
```bash
# You'll need to generate a JWT token first
# See: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification
```

### Test with GUI Tools:
- **Pusher** (Mac app): https://github.com/noodlewerk/NWPusher
- **Knuff** (Mac app): https://github.com/KnuffApp/Knuff
- **APNS Tool** (Web): Various online tools available

---

## 🔒 Security Best Practices

1. ✅ **Never commit the .p8 key file to version control**
2. ✅ **Store in a secure location with restricted access**
3. ✅ **Use environment variables in your backend**
4. ✅ **Rotate keys periodically if compromised**
5. ✅ **Keep backup in a secure password manager**

---

## 📚 Additional Resources

- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [Sending Notification Requests to APNs](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)

---

## ✅ Checklist

- [ ] Move AuthKey_C294DWA9AX.p8 to secure location
- [ ] Add secrets directory to .gitignore
- [ ] Store credentials in password manager (backup)
- [ ] Configure backend when ready to implement push notifications
- [ ] Test push notifications in development
- [ ] Test push notifications in production

---

**Last Updated**: October 3, 2025
**Created By**: Apple Developer Portal Setup Process
