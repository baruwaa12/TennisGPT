# TennisGPT Setup Guide

This guide walks you through setting up TennisGPT on your Windows machine from scratch. No prior experience with .NET, Flutter, or Google Cloud is required.

---

## Table of Contents

1. [Prerequisites Overview](#1-prerequisites-overview)
2. [Install an IDE for .NET Development](#2-install-an-ide-for-net-development)
3. [Install Flutter](#3-install-flutter)
4. [Install ngrok (Network Proxy)](#4-install-ngrok-network-proxy)
5. [Set Up Google Cloud Console (OAuth)](#5-set-up-google-cloud-console-oauth)
6. [Configure the Backend](#6-configure-the-backend)
7. [Configure the Flutter App](#7-configure-the-flutter-app)
8. [Running the Application](#8-running-the-application)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites Overview

You will need to install:

| Tool | Purpose |
|------|---------|
| **IDE** (Rider or Visual Studio) | Write and run the .NET backend |
| **Flutter SDK** | Build and run the mobile app |
| **ngrok** | Allow your phone to connect to your local backend |
| **Google Cloud Account** | Enable Google Sign-In for authentication |

---

## 2. Install an IDE for .NET Development

You have two options: **JetBrains Rider** (paid, 30-day free trial) or **Visual Studio Community** (free).

### Option A: JetBrains Rider (Recommended)

1. Go to [https://www.jetbrains.com/rider/download/](https://www.jetbrains.com/rider/download/)
2. Click **Download** for Windows
3. Run the installer (`JetBrains.Rider-*.exe`)
4. Follow the installation wizard:
   - Accept the license agreement
   - Choose installation location (default is fine)
   - Check "Add launchers dir to the PATH"
   - Check ".NET Core" under "Create Associations"
5. Click **Install** and wait for completion
6. Launch Rider
7. Sign in or start your free trial
8. Rider will automatically detect and install .NET SDK if needed

### Option B: Visual Studio Community (Free)

1. Go to [https://visualstudio.microsoft.com/vs/community/](https://visualstudio.microsoft.com/vs/community/)
2. Click **Free download**
3. Run the installer (`VisualStudioSetup.exe`)
4. In the **Workloads** tab, check:
   - **ASP.NET and web development**
   - **.NET desktop development**
5. Click **Install** (this may take 15-30 minutes)
6. Launch Visual Studio and sign in with a Microsoft account (free)

### Verify .NET Installation

Open **Command Prompt** or **PowerShell** and run:

```
dotnet --version
```

You should see something like `10.0.100` or similar. If not, download .NET SDK from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).

---

## 3. Install Flutter

1. Go to [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2. Download the Flutter SDK zip file
3. Extract to `C:\flutter` (or your preferred location)
4. Add Flutter to your PATH:
   - Press `Win + X` and select **System**
   - Click **Advanced system settings**
   - Click **Environment Variables**
   - Under "User variables", select **Path** and click **Edit**
   - Click **New** and add `C:\flutter\bin`
   - Click **OK** on all dialogs
5. Open a **new** Command Prompt and run:

```
flutter doctor
```

6. Follow any instructions to install missing dependencies (Android SDK, etc.)

---

## 4. Install ngrok (Network Proxy)

ngrok creates a secure tunnel so your mobile phone can reach your local backend server.

### Why do I need this?

When you run the backend on your computer, it's only accessible at `localhost:5000`. Your phone can't reach `localhost` because it's a different device. ngrok gives you a public URL (like `https://abc123.ngrok-free.app`) that forwards to your local server.

### Installation Steps

1. Go to [https://ngrok.com/download](https://ngrok.com/download)
2. Click **Download for Windows**
3. Extract the zip file to a folder (e.g., `C:\ngrok`)
4. Add ngrok to your PATH:
   - Press `Win + X` and select **System**
   - Click **Advanced system settings** > **Environment Variables**
   - Under "User variables", select **Path** and click **Edit**
   - Click **New** and add `C:\ngrok`
   - Click **OK** on all dialogs

### Create a Free ngrok Account

1. Go to [https://dashboard.ngrok.com/signup](https://dashboard.ngrok.com/signup)
2. Sign up for a free account
3. After signing in, go to [https://dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
4. Copy your authtoken
5. Open Command Prompt and run:

```
ngrok config add-authtoken 36nEEZDGOdK2X8Lfvxoi02yxWMj_7mcxfd7cCJQt5rs5Cbyeh
```

### Test ngrok

Run this command:

```
ngrok http 5000
```

You should see output like:

```
Forwarding    https://abc123.ngrok-free.app -> http://localhost:5000
```

Press `Ctrl+C` to stop ngrok for now.

---

## 5. Set Up Google Cloud Console (OAuth)

This section creates the credentials needed for "Sign in with Google" to work.

### 5.1 Create a Google Cloud Project

1. Go to [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Click the project dropdown at the top (next to "Google Cloud")
4. Click **New Project**
5. Enter:
   - **Project name**: `TennisGPT`
   - **Organization**: Leave as default
6. Click **Create**
7. Wait for the project to be created, then select it from the dropdown

### 5.2 Configure OAuth Consent Screen

Before creating credentials, you must configure the consent screen (what users see when signing in).

1. In the left sidebar, go to **APIs & Services** > **OAuth consent screen**
2. Select **External** and click **Create**
3. Fill in the form:
   - **App name**: `TennisGPT`
   - **User support email**: Your email address
   - **App logo**: Skip (optional)
   - **App domain**: Skip all fields
   - **Developer contact information**: Your email address
4. Click **Save and Continue**
5. On the **Scopes** page, click **Add or Remove Scopes**
6. Select these scopes:
   - `email`
   - `profile`
   - `openid`
7. Click **Update**, then **Save and Continue**
8. On the **Test users** page, click **Add Users**
9. Add your own email address (and any other testers)
10. Click **Save and Continue**
11. Review and click **Back to Dashboard**

### 5.3 Create OAuth Credentials

You need THREE different OAuth client IDs:

#### A. Web Client (Required for Backend)

1. Go to **APIs & Services** > **Credentials**
2. Click **+ Create Credentials** > **OAuth client ID**
3. Select **Web application**
4. Enter:
   - **Name**: `TennisGPT Web Client`
   - **Authorized JavaScript origins**: Leave empty
   - **Authorized redirect URIs**: Leave empty
5. Click **Create**
6. **IMPORTANT**: Copy and save the **Client ID** - it looks like:
   ```
   123456789-abcdefghijk.apps.googleusercontent.com
   ```
7. Click **OK**

#### B. Android Client

1. Click **+ Create Credentials** > **OAuth client ID**
2. Select **Android**
3. Enter:
   - **Name**: `TennisGPT Android`
   - **Package name**: `com.tennisgpt`
   - **SHA-1 certificate fingerprint**: (see below)

**How to get SHA-1 fingerprint:**

Open Command Prompt and run:

```
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line that says `SHA1:` and copy the fingerprint (looks like `AA:BB:CC:DD:...`).

4. Paste the SHA-1 fingerprint
5. Click **Create**
6. Copy and save the **Client ID**

#### C. iOS Client

1. Click **+ Create Credentials** > **OAuth client ID**
2. Select **iOS**
3. Enter:
   - **Name**: `TennisGPT iOS`
   - **Bundle ID**: `com.tennisgpt`
4. Click **Create**
5. Copy and save the **Client ID**

### 5.4 Create an API Key

1. Click **+ Create Credentials** > **API key**
2. Copy the API key that appears
3. Click **Restrict Key** (recommended):
   - Under **API restrictions**, select **Restrict key**
   - Enable only the APIs you need
4. Click **Save**

### 5.5 Summary of Credentials

You should now have:

| Credential | Example Value | Used For |
|------------|---------------|----------|
| Web Client ID | `123456-abc.apps.googleusercontent.com` | Backend + Flutter serverClientId |
| Android Client ID | `123456-def.apps.googleusercontent.com` | google-services.json |
| iOS Client ID | `123456-ghi.apps.googleusercontent.com` | iOS Info.plist |
| API Key | `AIzaSy...` | google-services.json |

---

## 6. Configure the Backend

### 6.1 Open the Backend Project

**In Rider:**
1. Open Rider
2. Click **Open**
3. Navigate to `TennisGPT/backend/TennisGPT.sln`
4. Click **Open**

**In Visual Studio:**
1. Open Visual Studio
2. Click **Open a project or solution**
3. Navigate to `TennisGPT/backend/TennisGPT.sln`
4. Click **Open**

### 6.2 Update appsettings.json

Open `TennisGPT.Api/appsettings.json` and update these values:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=tennisgpt.db"
  },
  "Jwt": {
    "Key": "YOUR_SECRET_KEY_HERE_MAKE_IT_LONG_AND_RANDOM",
    "Issuer": "TennisGPT",
    "Audience": "TennisGPTApp",
    "ExpiryMinutes": 60
  },
  "Google": {
    "ClientId": "YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com"
  },
  "OpenAI": {
    "ApiKey": "sk-your-openai-api-key-here",
    "Model": "gpt-4o"
  }
}
```

**Replace:**
- `YOUR_SECRET_KEY_HERE_MAKE_IT_LONG_AND_RANDOM` - Generate a random 32+ character string
- `YOUR_WEB_CLIENT_ID_HERE` - Your **Web Client ID** from step 5.3A
- `sk-your-openai-api-key-here` - Your OpenAI API key (get one at [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys))

**To generate a random JWT key**, run this in PowerShell:

```powershell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

### 6.3 Build the Backend

**In Rider:** Press `Ctrl+Shift+B`

**In Visual Studio:** Press `Ctrl+Shift+B`

**From Command Line:**
```
cd TennisGPT\backend\TennisGPT.Api
dotnet build
```

---

## 7. Configure the Flutter App

### 7.1 Update google-services.json (Android)

Open `android/app/google-services.json` and update with your credentials:

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "tennisgpt"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:YOUR_PROJECT_NUMBER:android:tennisgpt",
        "android_client_info": {
          "package_name": "com.tennisgpt"
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
          "current_key": "YOUR_API_KEY_HERE"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
```

**Replace:**
- `YOUR_PROJECT_NUMBER` - Find this in Google Cloud Console under **Project Info**
- `YOUR_ANDROID_CLIENT_ID` - Your Android Client ID from step 5.3B
- `YOUR_WEB_CLIENT_ID` - Your Web Client ID from step 5.3A
- `YOUR_API_KEY_HERE` - Your API Key from step 5.4

### 7.2 Update .env File

Open `.env` in the TennisGPT root folder and update:

```
API_BASE_URL=https://YOUR_NGROK_URL.ngrok-free.app
GOOGLE_CLIENT_ID_IOS=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com
```

**Note:** You'll update `API_BASE_URL` each time you start ngrok (the URL changes).

### 7.3 Update serverClientId in auth_service.dart

Open `lib/services/auth_service.dart` and find this line:

```dart
serverClientId: '750269168426-5l9q1pskuunfuqqhrirko0u8p0plcvb8.apps.googleusercontent.com',
```

Replace the Client ID with your **Web Client ID** from step 5.3A.

### 7.4 Install Flutter Dependencies

Open a terminal in the TennisGPT folder and run:

```
flutter pub get
```

---

## 8. Running the Application

### Step 1: Start the Backend

**From Command Line:**
```
cd TennisGPT\backend\TennisGPT.Api
dotnet run
```

**From Rider:** Click the green **Run** button (or press `Shift+F10`)

**From Visual Studio:** Press `F5` or click **Start**

You should see:
```
Now listening on: http://localhost:5000
```

### Step 2: Start ngrok

Open a **new** terminal window and run:

```
ngrok http 5000
```

Copy the **Forwarding** URL (e.g., `https://abc123.ngrok-free.app`).

### Step 3: Update the .env File

Open `.env` and update `API_BASE_URL` with the ngrok URL:

```
API_BASE_URL=https://abc123.ngrok-free.app
```

### Step 4: Connect Your Android Phone

1. Enable **Developer Options** on your phone:
   - Go to **Settings** > **About Phone**
   - Tap **Build Number** 7 times
2. Enable **USB Debugging**:
   - Go to **Settings** > **Developer Options**
   - Turn on **USB Debugging**
3. Connect your phone via USB cable
4. When prompted on your phone, select **Allow USB debugging**

### Step 5: Run the Flutter App

```
flutter run
```

If multiple devices are detected, select your Android phone.

### Step 6: Test Sign-In

1. The app should launch on your phone
2. Tap **Continue with Google**
3. Select your Google account
4. You should be signed in and see the home screen

---

## 9. Troubleshooting

### "Unable to connect to localhost:5000"

- Make sure the backend is running
- Make sure ngrok is running
- Update `.env` with the current ngrok URL
- **Restart** the Flutter app (hot reload won't pick up .env changes)

### "Google Sign-In failed"

- Verify the **Web Client ID** matches in:
  - `appsettings.json` (backend)
  - `auth_service.dart` (Flutter)
  - `google-services.json` (client_type: 3)
- Make sure your email is added as a test user in Google Cloud Console
- Check that the SHA-1 fingerprint matches your debug keystore

### "404 Not Found" when signing in

- Make sure the backend is running on port 5000
- Check that ngrok is forwarding to port 5000
- Verify the API endpoint: `POST /api/auth/google`

### ngrok URL keeps changing

The free tier of ngrok generates a new URL each time you restart it. You must:
1. Update `.env` with the new URL
2. Restart the Flutter app

**Pro tip:** Upgrade to ngrok paid tier for a static URL, or use your computer's local IP address if your phone is on the same WiFi network.

### "Invalid JWT" or "Token validation failed"

- Verify the **Web Client ID** is identical in all locations
- Make sure the backend's `Google:ClientId` matches Flutter's `serverClientId`

---

## Quick Reference: File Locations

| File | Location | Purpose |
|------|----------|---------|
| Backend config | `backend/TennisGPT.Api/appsettings.json` | JWT keys, Google Client ID, OpenAI key |
| Flutter env | `.env` | API base URL, Google client IDs |
| Android config | `android/app/google-services.json` | Google OAuth for Android |
| Auth service | `lib/services/auth_service.dart` | serverClientId for Google Sign-In |

---

## Need Help?

If you encounter issues not covered here, please open an issue at the project repository with:
1. The error message you're seeing
2. Which step you're on
3. Your operating system version
