# RevenueCat Setup Guide for TennisGPT

This guide walks you through setting up RevenueCat for in-app subscriptions on iOS and Android.

---

## Overview

**What is RevenueCat?**
RevenueCat is a subscription management platform that handles:
- In-app purchases for iOS and Android
- Receipt validation
- Cross-platform subscription sync
- Analytics and revenue tracking
- Webhook integrations

**TennisGPT Subscription Products:**
| Product ID | Price | Billing |
|------------|-------|---------|
| `tennisgpt_monthly` | $9.99 | Monthly |
| `tennisgpt_annual` | $59.99 | Yearly (Save 50%) |

---

## Step 1: Create RevenueCat Account

1. Go to [app.revenuecat.com](https://app.revenuecat.com)
2. Sign up with Google or email
3. Click **"Create New Project"**
4. Name it: `TennisGPT`

---

## Step 2: Create Your Apps in RevenueCat

### iOS App Setup

1. In your RevenueCat project, click **"+ New App"**
2. Select **"App Store (iOS)"**
3. Fill in:
   - **App Name:** TennisGPT iOS
   - **Bundle ID:** `com.yourcompany.tennisgpt` (match your Xcode bundle ID)
4. Click **"Create App"**
5. Copy the **Public API Key** (starts with `appl_`)

### Android App Setup

1. Click **"+ New App"** again
2. Select **"Play Store (Android)"**
3. Fill in:
   - **App Name:** TennisGPT Android
   - **Package Name:** `com.yourcompany.tennisgpt` (match your Android package)
4. Click **"Create App"**
5. Copy the **Public API Key** (starts with `goog_`)

---

## Step 3: Configure App Store Connect (iOS)

### 3.1 Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in app details
4. Note your **App Apple ID** (number in URL)

### 3.2 Create Subscriptions

1. In your app, go to **"Subscriptions"** in the sidebar
2. Click **"+"** to create a Subscription Group
3. Name it: `TennisGPT Premium`
4. Click **"Create"**

**Create Monthly Subscription:**
1. Click **"+"** next to your subscription group
2. Reference Name: `TennisGPT Monthly`
3. Product ID: `tennisgpt_monthly`
4. Click **"Create"**
5. Add subscription duration: **1 Month**
6. Add pricing: **$9.99**
7. Add localization (display name, description)

**Create Annual Subscription:**
1. Click **"+"** again
2. Reference Name: `TennisGPT Annual`
3. Product ID: `tennisgpt_annual`
4. Click **"Create"**
5. Add subscription duration: **1 Year**
6. Add pricing: **$59.99**
7. Add localization

### 3.3 Create Shared Secret

1. Go to **"App Information"** in sidebar
2. Scroll to **"App-Specific Shared Secret"**
3. Click **"Manage"** → **"Generate"**
4. Copy the shared secret

### 3.4 Connect to RevenueCat

1. In RevenueCat, go to your iOS app
2. Click **"App Store Connect"** in sidebar
3. Paste your **Shared Secret**
4. Enter your **App Apple ID**
5. Click **"Save"**

---

## Step 4: Configure Google Play Console (Android)

### 4.1 Create App in Play Console

1. Go to [play.google.com/console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in app details

### 4.2 Create Subscriptions

1. Go to **"Monetize"** → **"Products"** → **"Subscriptions"**
2. Click **"Create subscription"**

**Create Monthly Subscription:**
1. Product ID: `tennisgpt_monthly`
2. Name: TennisGPT Monthly
3. Add base plan:
   - Billing period: Monthly
   - Price: $9.99
4. Click **"Save"** → **"Activate"**

**Create Annual Subscription:**
1. Product ID: `tennisgpt_annual`
2. Name: TennisGPT Annual
3. Add base plan:
   - Billing period: Yearly
   - Price: $59.99
4. Click **"Save"** → **"Activate"**

### 4.3 Create Service Account

1. Go to **"Setup"** → **"API access"**
2. Click **"Create new service account"**
3. Follow the link to Google Cloud Console
4. Create service account with name: `revenuecat-service`
5. Grant role: **"Pub/Sub Admin"**
6. Create JSON key and download it
7. Back in Play Console, grant the service account **"Admin"** permissions

### 4.4 Connect to RevenueCat

1. In RevenueCat, go to your Android app
2. Click **"Play Store Credentials"**
3. Upload your service account JSON file
4. Click **"Save"**

---

## Step 5: Create Entitlements & Offerings in RevenueCat

### 5.1 Create Entitlement

1. In RevenueCat, go to **"Entitlements"** in sidebar
2. Click **"+ New"**
3. Identifier: `premium`
4. Description: `Full access to all TennisGPT features`
5. Click **"Add"**

### 5.2 Create Products

1. Go to **"Products"** in sidebar
2. Click **"+ New"**
3. For each product:

**Monthly:**
- Identifier: `tennisgpt_monthly`
- App Store Product ID: `tennisgpt_monthly`
- Play Store Product ID: `tennisgpt_monthly`
- Click **"Add"**

**Annual:**
- Identifier: `tennisgpt_annual`
- App Store Product ID: `tennisgpt_annual`
- Play Store Product ID: `tennisgpt_annual`
- Click **"Add"**

### 5.3 Attach Products to Entitlement

1. Go back to **"Entitlements"**
2. Click on `premium`
3. Click **"Attach"**
4. Select both `tennisgpt_monthly` and `tennisgpt_annual`
5. Click **"Add"**

### 5.4 Create Offering

1. Go to **"Offerings"** in sidebar
2. Click **"+ New"**
3. Identifier: `default`
4. Description: `Default offering`
5. Click **"Add"**

### 5.5 Create Packages in Offering

1. Click on your `default` offering
2. Click **"+ New Package"**

**Monthly Package:**
- Identifier: `$rc_monthly` (RevenueCat magic identifier)
- Product: `tennisgpt_monthly`
- Click **"Add"**

**Annual Package:**
- Identifier: `$rc_annual` (RevenueCat magic identifier)
- Product: `tennisgpt_annual`
- Click **"Add"**

### 5.6 Make Offering Current

1. Still in Offerings
2. Click the **"..."** menu on your `default` offering
3. Click **"Make Current"**

---

## Step 6: Update Flutter Code

### 6.1 Get Your API Keys

In RevenueCat dashboard:
1. Go to **"API Keys"** in sidebar
2. Copy your **Public API Key** for iOS (starts with `appl_`)
3. Copy your **Public API Key** for Android (starts with `goog_`)

### 6.2 Update purchase_service.dart

Open `lib/services/purchase_service.dart` and replace the placeholder keys:

```dart
// RevenueCat API Keys
static const String _revenueCatApiKeyApple = 'appl_YOUR_ACTUAL_IOS_KEY';
static const String _revenueCatApiKeyGoogle = 'goog_YOUR_ACTUAL_ANDROID_KEY';
```

---

## Step 7: iOS Configuration

### 7.1 Add StoreKit Configuration (for testing)

1. In Xcode, go to **File** → **New** → **File**
2. Search for **"StoreKit Configuration File"**
3. Name it: `StoreKitConfiguration.storekit`
4. Add your products:
   - `tennisgpt_monthly` (Auto-Renewable, $9.99, Monthly)
   - `tennisgpt_annual` (Auto-Renewable, $59.99, Yearly)

### 7.2 Enable StoreKit Testing

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **"Run"** on the left
3. Go to **"Options"** tab
4. Set **"StoreKit Configuration"** to your `.storekit` file

### 7.3 Add In-App Purchase Capability

1. In Xcode, select your project
2. Go to **"Signing & Capabilities"**
3. Click **"+ Capability"**
4. Add **"In-App Purchase"**

---

## Step 8: Android Configuration

### 8.1 Add Billing Permission

Open `android/app/src/main/AndroidManifest.xml` and add:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add this permission -->
    <uses-permission android:name="com.android.vending.BILLING" />
    
    <application ...>
```

---

## Step 9: Testing

### Testing on iOS Simulator

1. Use the StoreKit configuration file
2. Purchases work without real App Store account
3. RevenueCat will show sandbox transactions

### Testing on iOS Device (Sandbox)

1. Create sandbox tester in App Store Connect:
   - Go to **"Users and Access"** → **"Sandbox Testers"**
   - Add new tester with test email
2. On device, sign out of App Store
3. When prompted during purchase, sign in with sandbox account

### Testing on Android Emulator

1. Use license testing in Play Console:
   - Go to **"Setup"** → **"License testing"**
   - Add your Google account email
2. Purchases will complete but won't charge

### Testing on Android Device

1. Upload your app to **Internal Testing** track
2. Add yourself as a tester
3. Install from Play Store link
4. Purchases will use test cards

---

## Step 10: Verify Integration

### Check RevenueCat Dashboard

1. Make a test purchase
2. Go to RevenueCat → **"Customers"**
3. Search for your test user
4. Verify the transaction appears

### Debug Logging

In your app, purchases will log to console:
```
PurchaseService: Initialized successfully
PurchaseService: Premium status: false
PurchaseService: Offerings fetched
PurchaseService: Package: $rc_monthly - $9.99
PurchaseService: Package: $rc_annual - $59.99
```

---

## Troubleshooting

### "No products available"

1. Check product IDs match exactly (case-sensitive)
2. Ensure products are approved in App Store Connect / Play Console
3. Wait 24-48 hours for new products to propagate
4. Verify RevenueCat Products are linked correctly

### "Invalid receipt"

1. Check shared secret is correct (iOS)
2. Check service account permissions (Android)
3. Verify app bundle ID matches

### "Entitlement not granted"

1. Check products are attached to `premium` entitlement
2. Verify offering is set as current
3. Check package identifiers use `$rc_monthly` / `$rc_annual`

### iOS Purchases fail on real device

1. Ensure In-App Purchase capability is added
2. Check sandbox tester account is set up
3. Verify paid agreements are signed in App Store Connect

### Android Purchases fail

1. Check BILLING permission in AndroidManifest
2. Ensure app is uploaded to Play Console
3. Verify license testing is configured

---

## Production Checklist

Before going live:

- [ ] Real API keys (not test keys)
- [ ] Products approved in App Store Connect
- [ ] Products approved in Play Console
- [ ] Sandbox testing completed
- [ ] Real device testing completed
- [ ] Restore purchases works
- [ ] Subscription status persists across app restarts
- [ ] Analytics showing in RevenueCat dashboard
- [ ] Webhook configured (if using server-side validation)

---

## Resources

- [RevenueCat Flutter Docs](https://docs.revenuecat.com/docs/flutter)
- [RevenueCat Dashboard](https://app.revenuecat.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Google Play Console](https://play.google.com/console)
- [RevenueCat Community](https://community.revenuecat.com)

---

## Quick Reference

| Item | Value |
|------|-------|
| Monthly Product ID | `tennisgpt_monthly` |
| Annual Product ID | `tennisgpt_annual` |
| Entitlement ID | `premium` |
| Monthly Price | $9.99 |
| Annual Price | $59.99 |
| Package ID (Monthly) | `$rc_monthly` |
| Package ID (Annual) | `$rc_annual` |
