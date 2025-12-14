# Google Authentication Setup Guide

This guide will help you set up Google Sign-In for TennisGPT on Web and Android.

---

## Prerequisites

- A Google account
- Access to [Google Cloud Console](https://console.cloud.google.com/)
- (Optional) Access to [Firebase Console](https://console.firebase.google.com/) if using Firebase

---

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown at the top → **New Project**
3. Enter project name: `TennisGPT` (or your preferred name)
4. Click **Create**
5. Wait for the project to be created, then select it

---

## Step 2: Configure OAuth Consent Screen

1. In Google Cloud Console, go to **APIs & Services → OAuth consent screen**
2. Select **External** (unless you have a Google Workspace organization)
3. Click **Create**
4. Fill in the required fields:
   - **App name**: `TennisGPT`
   - **User support email**: Your email
   - **Developer contact email**: Your email
5. Click **Save and Continue**
6. On Scopes page, click **Add or Remove Scopes**
   - Select: `email`, `profile`, `openid`
   - Click **Update**
7. Click **Save and Continue** through the remaining steps
8. Click **Back to Dashboard**

---

## Step 3: Create OAuth Client IDs

### 3a. Create Web Client ID

1. Go to **APIs & Services → Credentials**
2. Click **Create Credentials → OAuth Client ID**
3. Select **Web application**
4. Name: `TennisGPT Web`
5. Under **Authorized JavaScript origins**, add:
   ```
   http://localhost
   http://localhost:5000
   http://localhost:8080
   http://127.0.0.1:5000
   ```
   > **Note**: Add the port Flutter uses when you run `flutter run -d chrome`
   
6. Click **Create**
7. **Copy the Client ID** - it looks like: `123456789-abcdefg.apps.googleusercontent.com`

### 3b. Create Android Client ID (for Android app)

1. Click **Create Credentials → OAuth Client ID**
2. Select **Android**
3. Name: `TennisGPT Android`
4. Package name: `com.example.tennisgpt` (check your `android/app/build.gradle.kts` for the actual package name)
5. **SHA-1 certificate fingerprint**: Get this by running in your project folder:
   ```powershell
   cd android
   ./gradlew signingReport
   ```
   Look for `SHA1` under `Variant: debug`
   
6. Click **Create**
7. **Copy the Client ID**

---

## Step 4: Update Your Project Files

You need to update **4 files** with your new credentials:

### File 1: `web/index.html`

Find and replace the `google-signin-client_id` meta tag:

```html
<meta name="google-signin-client_id"
  content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

**Replace with**: Your Web Client ID from Step 3a

---

### File 2: `lib/services/auth_service.dart`

Find the `GoogleSignIn` initialization (around line 12):

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

**Replace `serverClientId` with**: Your Web Client ID from Step 3a

---

### File 3: `android/app/google-services.json`

Update the OAuth client IDs:

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "your-project-id"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:YOUR_PROJECT_NUMBER:android:your_app_id",
        "android_client_info": {
          "package_name": "com.example.tennisgpt"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 1
        },
        {
          "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "YOUR_API_KEY"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
```

> **Tip**: If using Firebase, download `google-services.json` from Firebase Console → Project Settings → Your Android app

---

### File 4: `web/firebase-config.js` (if using Firebase)

```javascript
const firebaseConfig = {
    apiKey: "YOUR_FIREBASE_API_KEY",
    authDomain: "your-project-id.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project-id.appspot.com",
    messagingSenderId: "YOUR_PROJECT_NUMBER",
    appId: "YOUR_WEB_APP_ID"
};
```

> **Tip**: Get these values from Firebase Console → Project Settings → General → Your apps → Web app

---

## Step 5: Test Your Setup

### Test on Web:
```powershell
flutter run -d chrome
```

### Test on Android:
```powershell
flutter run -d android
```

---

## Troubleshooting

### "MissingPluginException" on Windows
Google Sign-In doesn't support Windows desktop. Use `flutter run -d chrome` instead.

### "ClientID not set" error
Make sure the meta tag in `index.html` has your Web Client ID.

### "redirect_uri_mismatch" error
Add the exact URL shown in the error to your OAuth Client's **Authorized JavaScript origins** in Google Cloud Console.

### "idpiframe_initialization_failed" error
- Clear browser cache
- Make sure cookies are enabled
- Try incognito mode

### Sign-in popup closes immediately
Your OAuth consent screen might still be in "Testing" mode. Add your email as a test user:
1. Google Cloud Console → OAuth consent screen
2. Under "Test users", add your email

---

## Quick Reference: Files to Update

| File | What to Update |
|------|----------------|
| `web/index.html` | Web Client ID in meta tag |
| `lib/services/auth_service.dart` | Web Client ID in `serverClientId` |
| `android/app/google-services.json` | Android + Web Client IDs, API key |
| `web/firebase-config.js` | Firebase config (if using Firebase) |

---

## Need Help?

- [Google Sign-In for Flutter docs](https://pub.dev/packages/google_sign_in)
- [Google Cloud OAuth setup](https://developers.google.com/identity/protocols/oauth2)
- [Firebase Authentication docs](https://firebase.google.com/docs/auth)
