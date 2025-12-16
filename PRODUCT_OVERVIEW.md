# TennisGPT - Product Overview

## Executive Summary

**TennisGPT** is a cross-platform mobile application that provides AI-powered mental coaching, tactical analysis, and emotional support for tennis players. Built with Flutter (frontend) and .NET (backend), it leverages OpenAI's GPT models to deliver personalized coaching insights.

---

## What Problem Does This Solve?

Tennis is one of the most mentally demanding sports. Players at all levels struggle with:

1. **Mental Game Issues**: Choking under pressure, losing focus, confidence crashes
2. **Lack of Coaching Access**: Personal coaches are expensive ($50-200/hour)
3. **No Real-Time Support**: Players face emotional struggles alone during/after matches
4. **Scattered Performance Data**: No centralized way to track patterns and improvement
5. **Generic Advice**: YouTube videos and books don't address individual player contexts

**TennisGPT is your pocket tennis coach** - available 24/7, personalized to your game, and a fraction of the cost.

---

## Core Features

### 1. 🧠 Mental Check-In
**Purpose**: Daily emotional awareness and AI-guided mental training

**How it works**:
- User rates their mood on a 1-5 scale (with emoji indicators)
- Writes a journal entry about their tennis-related feelings
- AI responds with:
  - Empathetic acknowledgment
  - A challenging coaching question to promote self-reflection
  - A concrete, actionable mindset exercise

**Value**: Builds mental resilience through consistent self-awareness practice

---

### 2. 🎾 Tactical Coach
**Purpose**: Get expert-level tactical analysis and customized drills

**Three Sub-Features**:

1. **Match Analysis**
   - Describe your match (opponent, what went well/poorly)
   - AI analyzes using your recent match history
   - Returns 3 key tactical recommendations with explanations

2. **Drill Recommendations**
   - Based on your match history patterns
   - Identifies weaknesses and provides specific drills
   - Includes setup, execution steps, and goals

3. **Quick Tactical Tips**
   - Describe a specific situation
   - Get concise, actionable advice in seconds

**Value**: Professional-level game analysis without the $150/hour coach

---

### 3. 💥 Emotional Reset
**Purpose**: Immediate emotional support during tough moments

**How it works**:
- One-tap button for instant support
- AI validates feelings and reframes the situation
- Provides calming message and actionable next step

**Value**: Like having a supportive coach in your pocket when frustration hits

---

### 4. 📊 Match History
**Purpose**: Track performance data and identify patterns over time

**Features**:
- Log detailed match data (opponent, score, surface, weather)
- Rate your performance per skill (1-10 scale)
  - Serve, Forehand, Backhand, Volley, Footwork
- Record key moments from the match
- View performance summary:
  - Total matches, Win rate, Favorite surface
- Each match gets AI-generated:
  - Tactical analysis
  - Recommended drills based on patterns

**Value**: Data-driven improvement with AI-powered insights

---

## Technical Architecture

### Frontend (Flutter/Dart)
```
lib/
├── main.dart                    # App entry, providers, theme
├── models/
│   ├── check_in_entry.dart      # Mental check-in data
│   └── match_performance.dart   # Match tracking data
├── screens/
│   ├── login_screen.dart        # Google OAuth login
│   ├── home_screen.dart         # Main navigation hub
│   ├── mental_check_in_screen.dart
│   ├── tactical_coach_screen.dart
│   ├── emotional_reset_screen.dart
│   ├── match_history_screen.dart
│   └── add_match_screen.dart
└── services/
    ├── auth_service.dart        # Google Sign-In + JWT
    ├── api_service.dart         # Backend communication
    ├── match_history_service.dart
    ├── storage_service.dart     # Local SharedPreferences
    └── token_service.dart       # JWT token management
```

### Backend (.NET 8 / C#)
```
backend/
├── TennisGPT.Api/              # REST API layer
│   ├── Controllers/
│   │   ├── AuthController.cs   # Google OAuth, JWT tokens
│   │   ├── CoachingController.cs # AI coaching endpoints
│   │   ├── MatchesController.cs
│   │   └── CheckInsController.cs
│   └── Program.cs              # DI, middleware config
├── TennisGPT.Application/      # Business logic
│   ├── Services/
│   │   ├── AuthService.cs
│   │   └── OpenAIService.cs    # GPT prompts & responses
│   └── DTOs/                   # Data transfer objects
├── TennisGPT.Domain/           # Entity models
│   └── Entities/
│       ├── User.cs
│       ├── Match.cs
│       └── CheckIn.cs
└── TennisGPT.Infrastructure/   # Data access
    ├── Data/TennisGPTDbContext.cs
    ├── Repositories/
    └── External/
        ├── GoogleAuthClient.cs
        └── OpenAIClient.cs
```

---

## Data Flow

```
┌──────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   Flutter App    │────▶│   .NET API      │────▶│    OpenAI API    │
│                  │◀────│                 │◀────│    (GPT-4o)      │
└──────────────────┘     └─────────────────┘     └──────────────────┘
        │                        │
        │                        ▼
        │                ┌─────────────────┐
        │                │   SQLite DB     │
        │                │ (Users, Matches │
        │                │   CheckIns)     │
        │                └─────────────────┘
        │
        ▼
┌──────────────────┐
│ SharedPreferences│
│ (Local cache)    │
└──────────────────┘
```

---

## Authentication Flow

1. User taps "Continue with Google"
2. Flutter calls `google_sign_in` package
3. Receives Google ID token (mobile) or Access token (web)
4. Sends token to backend `/api/auth/google`
5. Backend validates token with Google
6. Creates/updates user in database
7. Returns JWT access token + refresh token
8. All subsequent API calls include `Bearer` token

---

## Current State

| Aspect | Status |
|--------|--------|
| Core Features | ✅ Functional MVP |
| Google Auth | ✅ Working (mobile + web) |
| Backend API | ✅ All endpoints live |
| AI Integration | ✅ GPT-4o responses |
| Data Persistence | ✅ SQLite + SharedPreferences |
| UI/UX | ⚠️ Basic/functional (not polished) |
| Monetization | ❌ Not implemented |
| Analytics | ❌ Not implemented |
| Push Notifications | ❌ Not implemented |
| Onboarding | ❌ Not implemented |
| App Store Ready | ❌ Not yet |

---

## Target Users

1. **Recreational Players** (NTRP 3.0-4.5)
   - Play 2-4x/week
   - Want to improve but can't afford regular coaching
   - Struggle with mental game

2. **Junior Competitors** (Ages 12-18)
   - Tournament players
   - Need mental game support
   - Parents looking for coaching supplements

3. **Club Players**
   - League participants
   - Competitive but not professional
   - Data-driven improvement mindset

---

## Competitive Landscape

| Competitor | Focus | Pricing | Differentiator |
|------------|-------|---------|----------------|
| **SwingVision** | Video analysis | $20/mo | Technical/video only |
| **TennisPal** | Social/finding partners | Free | No coaching |
| **PlayYourCourt** | Lesson booking | Varies | Human coaches only |
| **Functional Tennis** | Video lessons | $15/mo | Generic content |
| **TennisGPT** | AI Mental Coach | TBD | Personalized + Mental focus |

**Our Unique Position**: The only AI-powered app focused on the **mental game** with **personalized** tactical coaching based on your actual match data.

---

## Why This Matters

> "Tennis is 70% mental, yet 90% of training focuses on technique."
> — Brad Gilbert, legendary tennis coach

TennisGPT addresses the most neglected aspect of tennis improvement - the mental game - at a price point accessible to amateur players who can't afford private coaching.
