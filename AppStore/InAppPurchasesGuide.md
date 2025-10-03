# In-App Purchases Setup Guide - Kansyl Premium

## 📍 Where to Find This
App Store Connect > Your App > Monetization > In-App Purchases > Manage

---

## ⚠️ IMPORTANT
You MUST set up your Premium subscription products before submitting your app if you want users to be able to upgrade.

---

## 🎯 What You're Creating

Two subscription products:
1. **Kansyl Premium Monthly** - $2.99/month
2. **Kansyl Premium Yearly** - $19.99/year (Save 44%)

---

## STEP 1: Create Subscription Group

Before creating individual subscriptions, you need a subscription group.

### 1.1 Click "Create" or "+" Button
In the In-App Purchases section, look for **"Create"** or **"+"**

### 1.2 Select Subscription Type
Choose: **"Auto-Renewable Subscription"**

### 1.3 Create Subscription Group
If this is your first subscription, you'll be prompted to create a group.

**Subscription Group Reference Name:**
```
Kansyl Premium
```

**Subscription Group Display Name:**
```
Kansyl Premium
```

**Click "Create"**

---

## STEP 2: Create Monthly Subscription

### 2.1 Basic Information

**Reference Name:** (Internal only, users don't see this)
```
Kansyl Premium Monthly
```

**Product ID:** (Must be unique, cannot be changed later)
```
com.juan-oclock.kansyl.premium.monthly
```

**Click "Create"**

---

### 2.2 Subscription Duration

**Subscription Duration:**
```
1 Month
```

---

### 2.3 Subscription Prices

**Price:**
```
$2.99 USD
```

Apple will automatically convert this to other currencies for other countries.

**Availability:**
- ☑️ Make available in all territories

**Click "Next" or "Save"**

---

### 2.4 Subscription Localization (English - U.S.)

**Display Name:** (What users see in the app)
```
Premium Monthly
```

**Description:**
```
Unlock unlimited subscription tracking, advanced analytics, priority support, and export features. Billed monthly.
```

**Click "Save"**

---

### 2.5 App Store Localization (English - U.S.)

This is what appears on the App Store product page.

**Display Name:**
```
Premium Monthly
```

**Description:**
```
Get unlimited subscriptions, advanced analytics, priority support, custom notifications, and CSV/JSON export. Cancel anytime.
```

**Click "Save"**

---

### 2.6 Subscription Review Information

**Screenshot:**
- Upload a screenshot showing the Premium features
- Use one of your existing screenshots that shows the app interface
- Or create a simple graphic listing Premium benefits

**Review Notes:** (Optional)
```
This subscription unlocks Premium features including unlimited subscription tracking and advanced analytics. Users can test with Sandbox tester accounts.
```

---

### 2.7 Subscription Benefits (Optional but Recommended)

Add benefits that will appear on the App Store:

**Benefit 1:**
```
Unlimited Subscriptions
```

**Benefit 2:**
```
Advanced Analytics
```

**Benefit 3:**
```
Priority Support
```

**Benefit 4:**
```
Export Data (CSV/JSON)
```

---

## STEP 3: Create Yearly Subscription

Now repeat the process for the yearly subscription.

### 3.1 Click "+" to Add Another Subscription

In your Subscription Group, click **"+"** to add another product.

---

### 3.2 Basic Information

**Reference Name:**
```
Kansyl Premium Yearly
```

**Product ID:**
```
com.juan-oclock.kansyl.premium.yearly
```

**Click "Create"**

---

### 3.3 Subscription Duration

**Subscription Duration:**
```
1 Year
```

---

### 3.4 Subscription Prices

**Price:**
```
$19.99 USD
```

**Calculate the savings:**
- Monthly: $2.99 × 12 = $35.88/year
- Yearly: $19.99/year
- Savings: $15.89/year (44% off!)

**Availability:**
- ☑️ Make available in all territories

---

### 3.5 Subscription Localization (English - U.S.)

**Display Name:**
```
Premium Yearly
```

**Description:**
```
Unlock unlimited subscription tracking, advanced analytics, priority support, and export features. Billed annually. Save 44% compared to monthly!
```

**Click "Save"**

---

### 3.6 App Store Localization (English - U.S.)

**Display Name:**
```
Premium Yearly
```

**Description:**
```
Get unlimited subscriptions, advanced analytics, priority support, custom notifications, and CSV/JSON export. Best value - save 44%! Cancel anytime.
```

**Click "Save"**

---

### 3.7 Subscription Review Information

**Screenshot:**
- Same as monthly (or different if you want to highlight yearly savings)

**Review Notes:**
```
Annual subscription option for Premium features. Offers 44% savings compared to monthly billing. Users can test with Sandbox tester accounts.
```

---

### 3.8 Subscription Benefits

Same as monthly:
- Unlimited Subscriptions
- Advanced Analytics
- Priority Support
- Export Data (CSV/JSON)

---

## STEP 4: Subscription Group Settings

### 4.1 Set Subscription Level (Ranking)

In your subscription group, you can set which subscription is "higher tier":

**Monthly:**
```
Level 1 (Base)
```

**Yearly:**
```
Level 1 (Base - same level as monthly)
```

**Why same level?** They're the same features, just different billing periods. Users can freely switch between them.

---

### 4.2 Introductory Offers (Optional)

You can add a free trial or discounted intro price:

**Free Trial Option:**
```
3 days free, then $2.99/month
```

Or:
```
7 days free, then $2.99/month
```

**To set up:**
1. Edit each subscription
2. Go to "Subscription Prices"
3. Click "Set Up Introductory Offer"
4. Choose: **"Free"**
5. Duration: **3 days** or **7 days**
6. Save

**Recommendation:** Offer a 3-day free trial to let users test Premium features!

---

## STEP 5: Submit for Review

### 5.1 Review Each Subscription

Make sure both subscriptions have:
- ✅ Product ID set
- ✅ Price configured
- ✅ Localization complete
- ✅ Screenshot uploaded
- ✅ Status: "Ready to Submit"

---

### 5.2 Submit with App

Your subscriptions will be reviewed alongside your app. They share the same review process.

**Status flow:**
1. **Missing Metadata** → Add all required info
2. **Ready to Submit** → Attached to app version
3. **Waiting for Review** → With your app
4. **In Review** → Being tested by Apple
5. **Approved** → Live when app goes live!

---

## STEP 6: Testing with Sandbox

### 6.1 Create Sandbox Tester Accounts

1. Go to: **App Store Connect > Users and Access > Sandbox Testers**
2. Click **"+"** to add tester
3. Create test accounts:

**Tester 1:**
```
Email: test1.kansyl@icloud.com (or similar)
Password: [Create a password]
First Name: Test
Last Name: User
```

**Tester 2:**
```
Email: test2.kansyl@icloud.com
Password: [Create a password]
First Name: Test
Last Name: Premium
```

---

### 6.2 Test on Your Device

1. **Sign out** of your Apple ID in Settings > App Store
2. Build and run your app on device (must be a real device, not simulator)
3. Attempt to purchase Premium
4. When prompted, use your **Sandbox Tester** account
5. Verify the purchase goes through
6. Test features unlock

**Note:** Sandbox purchases are FREE and don't charge real money!

---

## 📋 QUICK CHECKLIST

Before submitting:

**Subscription Group:**
- [ ] Group created: "Kansyl Premium"
- [ ] Group display name set

**Monthly Subscription:**
- [ ] Product ID: `com.juan-oclock.kansyl.premium.monthly`
- [ ] Price: $2.99 USD
- [ ] Duration: 1 Month
- [ ] Display name: "Premium Monthly"
- [ ] Description written
- [ ] Screenshot uploaded
- [ ] Status: Ready to Submit

**Yearly Subscription:**
- [ ] Product ID: `com.juan-oclock.kansyl.premium.yearly`
- [ ] Price: $19.99 USD
- [ ] Duration: 1 Year
- [ ] Display name: "Premium Yearly"
- [ ] Description written (mention 44% savings!)
- [ ] Screenshot uploaded
- [ ] Status: Ready to Submit

**Optional but Recommended:**
- [ ] Free trial configured (3 or 7 days)
- [ ] Subscription benefits added
- [ ] Sandbox testers created
- [ ] Tested on device with Sandbox account

---

## 🔗 Link to Your App

Your subscriptions are automatically linked to your app when you submit. Make sure:

1. Your Xcode project has the correct Product IDs in code
2. Your PremiumManager uses these Product IDs:
   - `com.juan-oclock.kansyl.premium.monthly`
   - `com.juan-oclock.kansyl.premium.yearly`

---

## ⚠️ COMMON ISSUES

### Issue: "Product ID already exists"
- **Solution:** Use a unique ID, can't reuse deleted ones

### Issue: "Missing metadata"
- **Solution:** Fill in all required fields (name, description, price, screenshot)

### Issue: "Can't test purchases"
- **Solution:** Must use real device + Sandbox tester account

### Issue: "Subscription not showing in app"
- **Solution:** Check Product IDs match exactly between App Store Connect and your code

---

## 💰 Pricing Strategy

Your current pricing:
- **Monthly:** $2.99 (Entry-level, easy to try)
- **Yearly:** $19.99 (44% savings, good value)

**This is competitive!** Similar apps charge:
- Budget apps: $3-5/month
- Subscription trackers: $2-4/month
- Your pricing is on the lower end = good for adoption!

---

## 📊 After Launch

### Monitor Your Subscriptions

In App Store Connect, you can track:
- Total subscribers
- Monthly recurring revenue (MRR)
- Conversion rate (free → paid)
- Churn rate
- Renewal rate

**Analytics available at:**
App Store Connect > Sales and Trends > Subscriptions

---

## 🎯 NEXT STEPS

1. **Create subscription group** (5 min)
2. **Create monthly subscription** (10 min)
3. **Create yearly subscription** (10 min)
4. **Add free trial** (optional, 5 min)
5. **Create sandbox testers** (5 min)
6. **Test on device** (10 min)
7. **Submit with app** ✅

**Total time:** 30-45 minutes

---

## 📱 Product IDs Reference

Save these - you'll need them in your code:

```swift
// PremiumManager.swift or StoreKit configuration

let monthlyProductID = "com.juan-oclock.kansyl.premium.monthly"
let yearlyProductID = "com.juan-oclock.kansyl.premium.yearly"
```

---

## ✅ Verification

Before submitting, verify in Xcode:

1. Open your project
2. Search for these Product IDs in your code
3. Make sure they match EXACTLY what you entered in App Store Connect
4. Even one character off = purchases won't work!

---

**Good luck setting up your Premium subscriptions!** 🚀

If you have any questions during setup, refer back to this guide or Apple's official documentation.
