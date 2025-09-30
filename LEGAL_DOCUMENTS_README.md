# Legal Documents - Hosting Instructions

**Created:** September 30, 2025  
**Purpose:** Instructions for hosting legal documents for App Store submission

---

## 📄 Documents Created

Three essential legal documents have been created for your Kansyl app:

1. **`PRIVACY_POLICY.md`** - REQUIRED for App Store submission
2. **`TERMS_OF_SERVICE.md`** - Recommended (protects you legally)
3. **`DATA_COLLECTION_SUMMARY.md`** - Reference for App Store Connect privacy questionnaire

---

## ⚠️ CRITICAL: Hosting Requirements

### Apple Requires:
- **Privacy Policy URL must be publicly accessible**
- Must be reachable from anywhere without login
- Must remain stable (URL shouldn't change)
- Should load quickly and be mobile-friendly

**You CANNOT submit to App Store without a hosted Privacy Policy URL!**

---

## 🌐 Hosting Options

### Option 1: GitHub Pages (FREE & Easy) ⭐ RECOMMENDED

**Pros:** Free, reliable, easy to update, version controlled  
**Cons:** Slightly technical initial setup

**Steps:**

1. **Create a new GitHub repository** (can be public or private)
   ```bash
   # Example repo name: kansyl-legal
   ```

2. **Push your documents:**
   ```bash
   git init
   git add PRIVACY_POLICY.md TERMS_OF_SERVICE.md
   git commit -m "Add legal documents"
   git push
   ```

3. **Enable GitHub Pages:**
   - Go to repo Settings → Pages
   - Source: Deploy from branch `main`
   - Folder: `/ (root)`
   - Click Save

4. **Your URLs will be:**
   ```
   https://[your-username].github.io/kansyl-legal/PRIVACY_POLICY
   https://[your-username].github.io/kansyl-legal/TERMS_OF_SERVICE
   ```

5. **Optional:** Add a Jekyll theme or custom HTML for better formatting

---

### Option 2: Netlify or Vercel (FREE & Professional)

**Pros:** Professional, custom domain, automatic deployments, better formatting  
**Cons:** Requires more setup

**Netlify Steps:**
1. Sign up at https://netlify.com
2. Connect your GitHub repo
3. Deploy
4. Get URL: `https://kansyl-legal.netlify.app/privacy`

**Vercel Steps:**
1. Sign up at https://vercel.com
2. Import your GitHub repo
3. Deploy
4. Get URL: `https://kansyl-legal.vercel.app/privacy`

---

### Option 3: Your Own Website

If you already have a website for Kansyl:

1. Create pages:
   - `yourdomain.com/privacy-policy`
   - `yourdomain.com/terms-of-service`

2. Convert Markdown to HTML or use a CMS

3. Ensure pages are:
   - Publicly accessible
   - Mobile-friendly
   - Fast loading

---

### Option 4: Google Docs (QUICK BUT NOT RECOMMENDED)

**Pros:** Super fast setup  
**Cons:** Unprofessional, limited formatting, not ideal for legal docs

**Only use if you need something immediately and will replace later!**

1. Copy Privacy Policy content to Google Doc
2. File → Share → Publish to web
3. Get the public URL
4. Use for now, replace with proper hosting before launch

---

## ✅ After Hosting: Update Your Documents

### 1. Update Contact Information

In BOTH documents, replace these placeholders:

```
[YOUR_EMAIL_ADDRESS_HERE] → your-email@example.com
[YOUR_MAILING_ADDRESS_HERE] → (optional) Your business address
[YOUR_JURISDICTION_HERE] → "California, USA" or your location
```

### 2. Update App Store Connect

Once hosted:
1. Go to App Store Connect
2. Navigate to your app
3. App Privacy → Privacy Policy URL
4. Enter your hosted URL
5. Save

---

## 📝 TODO Before Submission

- [ ] **Host Privacy Policy** on one of the platforms above
- [ ] **Get public URL** for Privacy Policy
- [ ] **Update placeholders** in documents:
  - [ ] Replace `[YOUR_EMAIL_ADDRESS_HERE]` with real email
  - [ ] Replace `[YOUR_JURISDICTION_HERE]` with your location
  - [ ] Replace `[YOUR_MAILING_ADDRESS_HERE]` (optional)
- [ ] **Add Privacy Policy URL** to App Store Connect
- [ ] **Add Privacy Policy URL** to your app (Settings → Privacy)
- [ ] **Verify URL works** from mobile browser
- [ ] **Test on different devices** (iPhone, iPad)
- [ ] **Keep URL stable** (don't change after submission)

---

## 🔗 Recommended: Add Links to Your App

Add Privacy Policy and Terms links within your app:

**Locations to add links:**
1. **Onboarding/Sign Up screen** - "By continuing, you agree to our Terms & Privacy Policy"
2. **Settings → About → Privacy Policy**
3. **Settings → About → Terms of Service**
4. **Account deletion screen** - Remind users of data deletion policy

**SwiftUI Example:**
```swift
Link("Privacy Policy", destination: URL(string: "https://your-url.com/privacy")!)
Link("Terms of Service", destination: URL(string: "https://your-url.com/terms")!)
```

---

## 🛡️ Maintaining Your Legal Documents

### When to Update:

Update and re-publish when you:
- Change data collection practices
- Add new features that collect data
- Integrate new third-party services
- Change backend providers
- Add payment/subscription features
- Expand to new regions/countries

### How to Update:

1. Edit the Markdown files
2. Update "Last Updated" date
3. Re-deploy to your hosting platform
4. Notify users of material changes (in-app notification)

---

## 📊 Using DATA_COLLECTION_SUMMARY.md

This document helps you complete the App Store Connect privacy questionnaire:

1. Open `DATA_COLLECTION_SUMMARY.md`
2. Go to App Store Connect → App Privacy
3. Answer each question using the summary as reference
4. Be accurate - Apple reviews this carefully!

**Key sections to complete:**
- Contact Info: Email (yes)
- Financial Info: User's subscription data (yes)
- User Content: Notes, receipt text (yes)
- Identifiers: User ID only (not for tracking)
- Diagnostics: Crash/performance data (anonymized)

---

## ⚙️ Optional: Convert Markdown to HTML

For better formatting, convert Markdown to HTML:

**Using Pandoc:**
```bash
pandoc PRIVACY_POLICY.md -o privacy-policy.html --standalone
pandoc TERMS_OF_SERVICE.md -o terms-of-service.html --standalone
```

**Using Online Tools:**
- https://markdowntohtml.com
- https://dillinger.io (with export)

**Using Jekyll/Hugo (for GitHub Pages):**
- Add front matter to Markdown files
- Apply themes for professional look
- Automatic HTML generation

---

## 🎨 Styling Tips

If converting to HTML, add:
- Consistent headers and navigation
- Table of contents with anchor links
- Mobile-responsive design
- Dark mode support (optional)
- Print-friendly CSS
- Last updated date prominently displayed

---

## ✨ Example HTML Template Structure

```html
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy - Kansyl</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        /* Add mobile-friendly CSS */
        body { max-width: 800px; margin: 0 auto; padding: 20px; }
        h2 { color: #007AFF; }
    </style>
</head>
<body>
    <h1>Privacy Policy for Kansyl</h1>
    <p>Last Updated: September 30, 2025</p>
    
    <!-- Convert Markdown content here -->
    
    <footer>
        <p>Questions? Contact: your-email@example.com</p>
    </footer>
</body>
</html>
```

---

## 🚀 Quick Start Checklist

**I want to submit ASAP:**

- [ ] Choose hosting (GitHub Pages recommended)
- [ ] Upload PRIVACY_POLICY.md
- [ ] Get public URL
- [ ] Update email placeholder in document
- [ ] Add URL to App Store Connect
- [ ] Test URL works on mobile
- [ ] ✅ Ready to submit!

**I want it perfect:**

- [ ] Host on professional platform (Netlify/Vercel)
- [ ] Convert to HTML with custom styling
- [ ] Add custom domain
- [ ] Update all placeholders
- [ ] Add links in app
- [ ] Add Terms of Service page
- [ ] Add support/contact page
- [ ] Test on all devices
- [ ] ✅ Ready to submit!

---

## 📞 Need Help?

If you get stuck:
1. Check App Store Connect Help docs
2. Review Apple's App Privacy guidelines
3. Contact Apple Developer Support
4. Consider consulting with a lawyer for legal review (optional but recommended)

---

## ✅ Final Verification

Before submission, verify:

**Privacy Policy URL:**
- [ ] Works from mobile browser
- [ ] No login required
- [ ] Loads quickly
- [ ] Mobile-friendly
- [ ] All placeholders replaced
- [ ] Contact email correct
- [ ] Covers all data collection

**App Store Connect:**
- [ ] Privacy URL entered
- [ ] Privacy questionnaire completed
- [ ] Answers match Privacy Policy
- [ ] Third-party services listed

---

**You're almost ready to submit! Good luck! 🚀**

---

*Need updates to these documents? Edit the Markdown files and re-deploy.*