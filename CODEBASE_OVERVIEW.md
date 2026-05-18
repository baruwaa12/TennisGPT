# Composure (TennisGPT) Codebase Overview

## What is Composure?

Composure (Flutter package name `composure`, marketed as **TennisGPT** in older
materials) is a **cross-platform tennis performance app** that turns match
outcomes into tactical adjustments and calm, repeatable routines. The product
is a Flutter mobile app backed by a custom ASP.NET Core API, with a Next.js
landing page that embeds the Flutter Web PWA.

---

## Technology Stack

| Category | Technology |
|----------|------------|
| **Mobile framework** | Flutter (Dart, SDK `>=3.0.0 <4.0.0`) |
| **State management** | Provider |
| **Authentication** | Google Sign-In + Apple Sign-In → custom JWT backend |
| **Backend API** | ASP.NET Core 9 (`backend/TennisGPT.*`), deployed on Railway |
| **AI provider** | OpenAI (called only from the backend, model configured per env) |
| **Database** | PostgreSQL via EF Core migrations |
| **Subscriptions** | RevenueCat (`purchases_flutter`) + RevenueCat → backend webhook |
| **Landing / blog** | Next.js 15 (`landing/`) embedding the Flutter Web PWA at `/app/` |
| **Local storage** | SharedPreferences + `flutter_secure_storage` for tokens |
| **UI** | Material Design 3, Google Fonts, Flutter SVG, fl_chart |

---

## Project Structure

```
TennisGPT/
├── lib/
│   ├── main.dart                      # App entry point & initialization
│   ├── models/
│   │   ├── check_in_entry.dart        # Mental check-in data model
│   │   └── match_performance.dart     # Match performance data model
│   ├── screens/
│   │   ├── auth_wrapper.dart          # Auth routing logic
│   │   ├── login_screen.dart          # Google OAuth login UI
│   │   ├── home_screen.dart           # Main navigation hub
│   │   ├── mental_check_in_screen.dart# Mental wellness tracking
│   │   ├── tactical_coach_screen.dart # AI tactical advice
│   │   ├── emotional_reset_screen.dart# Emotional support feature
│   │   ├── match_history_screen.dart  # Match tracking & analytics
│   │   └── add_match_screen.dart      # Add new match data
│   └── services/
│       ├── auth_service.dart          # Supabase authentication
│       ├── openai_service.dart        # AI coaching responses
│       ├── api_service.dart           # Backend API (placeholder)
│       ├── match_history_service.dart # Match data management
│       └── storage_service.dart       # Local storage for check-ins
├── assets/
│   └── images/
│       └── logo.svg                   # App logo
├── android/                           # Android platform code
├── ios/                               # iOS platform code
├── macos/                             # macOS platform code
├── web/                               # Web platform code
├── pubspec.yaml                       # Package manifest
└── .env                               # Environment variables (create this!)
```

---

## Key Features

### 1. Mental Check-In
- Rate your mood (1-5 scale with emoji indicators)
- Journal your on-court feelings
- Receive AI-powered empathy, motivational anecdotes, and mindset exercises
- Track mood history over time

### 2. Tactical Coach
- Describe match/performance issues
- AI analyzes using your recent match history context
- Get 3 key tactical recommendations
- Auto-generated drill plans based on patterns
- Quick tactical tips for specific situations

### 3. Emotional Reset
- One-tap emotional support for common triggers
- AI validates feelings and offers reframing techniques
- Actionable next steps and calming messages

### 4. Match History
- Add matches with detailed performance data (opponent, result, sets, surface, weather)
- Rate strengths/weaknesses per skill (1-10 scale)
- View trends: win rate, skill progression, favorite surfaces
- AI-generated tactical analysis per match
- Recommended drills based on pattern analysis

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        SCREENS                               │
│  (auth_wrapper, login, home, mental_check_in, tactical,     │
│   emotional_reset, match_history, add_match)                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       SERVICES                               │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────┐  │
│  │ AuthService  │ │OpenAIService │ │MatchHistoryService │  │
│  │  (Supabase)  │ │  (GPT-4o)    │ │ (SharedPreferences)│  │
│  └──────────────┘ └──────────────┘ └────────────────────┘  │
│  ┌──────────────┐ ┌──────────────┐                         │
│  │StorageService│ │  ApiService  │                         │
│  │   (Local)    │ │  (Placeholder)│                        │
│  └──────────────┘ └──────────────┘                         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       MODELS                                 │
│        CheckInEntry          MatchPerformance               │
└─────────────────────────────────────────────────────────────┘
```

---

## External Services

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **Google Sign-In** | OAuth identity for Android/iOS/Web | `Google:ClientId` (server) + native client IDs |
| **Apple Sign-In** | OAuth identity for iOS / Web | `Apple:ClientId` (server) |
| **OpenAI** | AI coaching responses (server-side only) | `OpenAI:ApiKey`, `OpenAI:Model` |
| **RevenueCat** | Mobile subscriptions + entitlement webhook | `--dart-define=REVENUECAT_APPLE_KEY/GOOGLE_KEY`, `RevenueCat:WebhookAuthorization` |
| **Railway Postgres** | Primary database | `DATABASE_URL` (or `ConnectionStrings:DefaultConnection`) |

---

## Running Locally on macOS

### Prerequisites

1. **Install Flutter SDK**
   ```bash
   # Using Homebrew (recommended)
   brew install flutter

   # Or download from https://docs.flutter.dev/get-started/install/macos
   ```

2. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```
   Ensure all checks pass (or at least the ones you need for your target platform).

3. **Install Xcode** (for iOS/macOS development)
   - Download from Mac App Store
   - Accept license: `sudo xcodebuild -license accept`
   - Install command line tools: `xcode-select --install`

4. **Install CocoaPods** (for iOS dependencies)
   ```bash
   sudo gem install cocoapods
   ```

5. **Android Studio** (optional, for Android development)
   - Download from https://developer.android.com/studio
   - Install Flutter and Dart plugins

### Setup Steps

1. **Clone the repository** (if not already done)
   ```bash
   git clone https://github.com/baruwaa12/TennisGPT.git
   cd TennisGPT
   ```

2. **Choose a backend** (one of):

   - **Use hosted backend (fastest):** no env required. The client defaults to
     `https://tennisgpt-production.up.railway.app`.
   - **Run the backend locally:** see `backend/README` / `SETUP_GUIDE.md`. Point
     the Flutter app at it with
     `--dart-define=API_BASE_URL=http://localhost:5000`.

3. **Configure the .NET backend** (`backend/TennisGPT.Api/appsettings.json` or
   environment variables on Railway):

   ```env
   DATABASE_URL=postgresql://USER:PASS@HOST:5432/DBNAME
   Jwt__Key=<long random string>
   Google__ClientId=<web>;<ios>;<android>
   Apple__ClientId=com.tennisgpt.app
   OpenAI__ApiKey=sk-...
   OpenAI__Model=gpt-4o-mini
   RevenueCat__SecretApiKey=...
   RevenueCat__WebhookAuthorization=<shared secret>
   CORS_ALLOWED_ORIGINS=https://composuretennis.com,https://app.composuretennis.com
   ```

4. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

5. **Install iOS dependencies** (for iOS/macOS)
   ```bash
   cd ios && pod install && cd ..
   ```

### Running the App

**iOS Simulator:**
```bash
# List available simulators
flutter devices

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"
```

**macOS Desktop:**
```bash
flutter run -d macos
```

**Android Emulator:**
```bash
# Start an emulator first, then:
flutter run -d android
```

**Web Browser:**
```bash
flutter run -d chrome
```

**Hot Reload:** Press `r` in the terminal while the app is running.
**Hot Restart:** Press `R` for a full restart.

---

## Troubleshooting

### Common Issues

1. **"Unauthorized" calling the API**
   - Confirm the device clock is in sync (JWTs are time-sensitive).
   - Re-run `flutter run --dart-define=API_BASE_URL=...` after switching environments.

2. **Google Sign-In not working**
   - Ensure each platform's OAuth client ID is registered in Google Cloud and
     listed in the backend's `Google:ClientId` (semicolon-separated).
   - Check iOS URL schemes in `ios/Runner/Info.plist`.

3. **CocoaPods issues on M1/M2 Macs**
   ```bash
   sudo arch -x86_64 gem install ffi
   arch -x86_64 pod install
   ```

4. **Flutter doctor issues**
   ```bash
   flutter doctor -v
   ```
   Follow the suggestions provided for each issue.

5. **Build failures**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Current Development Status

- **Version:** 1.0.0+1
- **Branch:** main
- **Status:** Active development
- **Recent Work:** Google OAuth authentication implementation

### Recent Commits
```
bcf06b2 Currently Fixing google authentication
74bc3bc Mock authentication complete
05607a4 Google Authentication began
9d4c567 Removal of confetti and green banner. Addition of API backend
54d0ee1 Final fMVP feature added
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| [main.dart](lib/main.dart) | App entry point, providers setup, theme configuration |
| [config/app_config.dart](lib/config/app_config.dart) | Feature flags + `API_BASE_URL` (overridable via `--dart-define`) |
| [services/auth_service.dart](lib/services/auth_service.dart) | Google/Apple sign-in → JWT exchange with the backend |
| [services/api_service.dart](lib/services/api_service.dart) | Authenticated calls to the .NET API |
| [services/purchase_service.dart](lib/services/purchase_service.dart) | RevenueCat integration + founder inventory |
| [screens/home_screen.dart](lib/screens/home_screen.dart) | Main navigation and feature cards |
| [pubspec.yaml](pubspec.yaml) | Dependencies and project configuration |
| [backend/TennisGPT.Api/Program.cs](backend/TennisGPT.Api/Program.cs) | API host, EF Core migrations, CORS, JWT, RevenueCat wiring |

---

## Notes for Development

- The app uses **Provider** for state management - all services are registered in `main.dart`.
- Local data is cached via **SharedPreferences** and the canonical store is the **Postgres backend**.
- OpenAI is called **only from the .NET backend**, never directly from the app.
- Authentication is **Google / Apple Sign-In → JWT** issued by `TennisGPT.Api`.
- The app supports **Material 3** theming with both light and dark modes.
- Subscriptions flow through **RevenueCat**, and entitlement changes are mirrored to
  the backend via the `api/webhooks/revenuecat` endpoint (Authorization-secret protected).
