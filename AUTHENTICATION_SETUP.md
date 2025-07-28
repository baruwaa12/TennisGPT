# Google Authentication Setup for TennisGPT

This guide will help you set up Google Sign-In authentication for your TennisGPT Flutter app.

## Prerequisites

1. A Google Cloud Console account
2. A Firebase project
3. Flutter development environment

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Enter a project name (e.g., "tennisgpt")
4. Follow the setup wizard (you can disable Google Analytics if not needed)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In your Firebase project, click the Android icon to add an Android app
2. Enter your package name: `com.example.tennisgpt`
3. Enter app nickname: "TennisGPT"
4. Click "Register app"
5. Download the `google-services.json` file
6. Replace the placeholder file in `android/app/google-services.json` with the downloaded file

## Step 3: Enable Google Sign-In

1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Go to the "Sign-in method" tab
4. Click on "Google" provider
5. Enable it and configure:
   - Project support email: your email
   - Web SDK configuration: Add your domain (for web support)
6. Click "Save"

## Step 4: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth 2.0 Client IDs"
5. Configure the OAuth consent screen if prompted
6. Create OAuth 2.0 client IDs for:
   - Android: Use your package name and SHA-1 fingerprint
   - Web: Add your domain
   - iOS: Add your bundle ID (if developing for iOS)

## Step 5: Get SHA-1 Fingerprint (Android)

Run this command in your project directory:
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 fingerprint in the debug variant and add it to your Firebase project.

## Step 6: Install Dependencies

Run this command to install the new dependencies:
```bash
flutter pub get
```

## Step 7: Test the Authentication

1. Run your app: `flutter run`
2. You should see the login screen with a "Continue with Google" button
3. Tap the button and complete the Google Sign-In flow
4. You should be redirected to the home screen with your profile picture in the app bar

## Troubleshooting

### Common Issues:

1. **"Google Sign-In failed"**: 
   - Check that your `google-services.json` is correctly placed
   - Verify SHA-1 fingerprint is added to Firebase
   - Ensure Google Sign-In is enabled in Firebase Authentication

2. **"App not verified" warning**:
   - This is normal for development. Users can still sign in by clicking "Advanced" > "Go to [Your App]"

3. **Build errors**:
   - Make sure all dependencies are installed: `flutter pub get`
   - Clean and rebuild: `flutter clean && flutter pub get`

### For Production:

1. Add your app to Google Play Console
2. Configure OAuth consent screen with proper app information
3. Add privacy policy and terms of service URLs
4. Submit for verification if you want to remove the "unverified app" warning

## Next Steps

Once authentication is working, you can:
1. Store user data in Firebase Firestore
2. Add user-specific features
3. Implement user profiles
4. Add more authentication providers (Apple, Facebook, etc.)

## API Integration

When you're ready to integrate with your backend API:
1. Get the user's ID token from Firebase Auth
2. Send it to your backend for verification
3. Use the token to identify the user in your API calls

Example:
```dart
String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
// Send this token to your backend
``` 