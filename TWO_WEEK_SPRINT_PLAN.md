# TennisGPT - 2-Week Sprint to Day-1 Monetization

## Sprint Overview

**Goal**: Transform TennisGPT from functional MVP to monetization-ready product  
**Duration**: 14 days (2 weeks)  
**Outcome**: App ready to charge $9.99/month on Day 1

---

## Week 1: Foundation & Core Experience

### Day 1 (Monday) - Setup & Onboarding Start

#### Morning: Project Setup
- [ ] Set up RevenueCat account (iOS + Android)
- [ ] Create App Store Connect & Google Play Console apps
- [ ] Set up subscription products:
  - `tennisgpt_monthly` - $9.99/month
  - `tennisgpt_annual` - $59.99/year
- [ ] Add RevenueCat Flutter SDK to pubspec.yaml

#### Afternoon: Onboarding Screen 1 - Welcome
- [ ] Create `lib/screens/onboarding/` folder
- [ ] Build `welcome_screen.dart`:
  - App logo animation
  - "Welcome to TennisGPT"
  - "Your AI Tennis Coach"
  - "Get Started" button
  - 3 value proposition cards (swipeable)

**Deliverable**: User sees beautiful welcome instead of login

---

### Day 2 (Tuesday) - Onboarding Flow

#### Morning: Player Profile Setup
- [ ] Create `player_profile_screen.dart`:
  - "What's your skill level?" (Beginner/Intermediate/Advanced/Competitive)
  - "How often do you play?" (1-2x/week, 3-4x/week, 5+/week)
  - "What's your main goal?" (Win more matches, Mental game, Technique, Fun)
- [ ] Create `lib/models/player_profile.dart`
- [ ] Store profile in SharedPreferences

#### Afternoon: First Experience Flow
- [ ] Create `first_experience_screen.dart`:
  - "Let's try your first mental reset"
  - Guide user through Emotional Reset feature
  - Celebrate completion with animation
- [ ] Show "feature unlocked" animation

**Deliverable**: Personalized onboarding with immediate value demonstration

---

### Day 3 (Wednesday) - Paywall Implementation

#### Morning: RevenueCat Integration
- [ ] Add to `lib/services/purchase_service.dart`:

```dart
class PurchaseService extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  
  Future<void> initialize() async {
    await Purchases.configure(PurchasesConfiguration('YOUR_RC_KEY'));
    await _checkSubscriptionStatus();
  }
  
  Future<void> purchaseMonthly() async { }
  Future<void> purchaseAnnual() async { }
  Future<void> restorePurchases() async { }
}
```

- [ ] Add provider in `main.dart`

#### Afternoon: Paywall Screen
- [ ] Create `lib/screens/paywall_screen.dart`:
  - Premium features list
  - Monthly option ($9.99)
  - Annual option ($59.99) with "Best Value" badge
  - "Restore Purchases" link
  - Terms & Privacy links
  - Close button (for soft paywall)

**Design Elements**:
- Green gradient background (brand color)
- Feature checkmarks with icons
- Price comparison showing annual savings
- "Start Free Trial" CTA if using trial

**Deliverable**: Functional paywall with subscription purchasing

---

### Day 4 (Thursday) - Usage Limits & Paywall Triggers

#### Morning: Usage Tracking System
- [ ] Create `lib/services/usage_service.dart`:

```dart
class UsageService {
  static const int FREE_CHECKINS = 3;
  static const int FREE_RESETS = 3;
  static const int FREE_MATCHES = 5;
  
  Future<bool> canUseMentalCheckIn() async { }
  Future<void> recordMentalCheckInUsage() async { }
  Future<int> getRemainingCheckIns() async { }
  // Similar for other features
}
```

- [ ] Store usage counts in SharedPreferences (monthly reset)

#### Afternoon: Soft Paywall Integration
- [ ] Modify `mental_check_in_screen.dart`:
  - Check usage before allowing submission
  - Show "3/3 free check-ins used" indicator
  - Show paywall when limit reached
- [ ] Modify `emotional_reset_screen.dart`:
  - Same usage limit pattern
- [ ] Show remaining uses on home screen cards

**Deliverable**: Free tier limits working with paywall triggers

---

### Day 5 (Friday) - Home Screen Redesign

#### Morning: New Home Screen Structure
- [ ] Redesign `home_screen.dart`:

**New Layout**:
```
┌─────────────────────────────────┐
│  👤 [Avatar] Good morning, Alex │
│     You're on a 5-day streak!   │
├─────────────────────────────────┤
│  📊 Quick Stats                 │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │ 73% │ │ 12  │ │ 5🔥 │       │
│  │Win  │ │Match│ │Strk │       │
│  └─────┘ └─────┘ └─────┘       │
├─────────────────────────────────┤
│  Today's Check-in (3 left)   ➡ │
├─────────────────────────────────┤
│  [Feature Cards - scrollable]   │
│  🧠 Mental Check-In             │
│  🎾 Tactical Coach              │
│  💥 Emotional Reset             │
│  📊 Match History               │
└─────────────────────────────────┘
```

- [ ] Add personalized greeting based on time of day
- [ ] Add streak counter display
- [ ] Add quick stats row

#### Afternoon: Visual Polish
- [ ] Create custom feature card component with:
  - Gradient backgrounds (different per feature)
  - Icons with subtle animations
  - Usage indicators (e.g., "2/3 remaining")
- [ ] Add pull-to-refresh
- [ ] Add smooth page transitions

**Deliverable**: Professional, personalized home screen

---

### Day 6 (Saturday) - Emotional Reset Upgrade

#### Morning: Trigger Selection Screen
- [ ] Redesign `emotional_reset_screen.dart`:

**Before**: Single generic button

**After**: Grid of emotional trigger buttons:
```
┌─────────────────────────────────┐
│  💥 What happened?              │
├─────────────────────────────────┤
│ ┌───────────┐ ┌───────────┐    │
│ │ I choked  │ │ Lost focus│    │
│ │ at crunch │ │ completely│    │
│ └───────────┘ └───────────┘    │
│ ┌───────────┐ ┌───────────┐    │
│ │ Opponent  │ │ Can't hit │    │
│ │ was toxic │ │ anything  │    │
│ └───────────┘ └───────────┘    │
│ ┌───────────┐ ┌───────────┐    │
│ │ Lost to   │ │ Pre-match │    │
│ │ weaker    │ │ nerves    │    │
│ │ player    │ │           │    │
│ └───────────┘ └───────────┘    │
│ ┌─────────────────────────┐    │
│ │ Other (describe...)     │    │
│ └─────────────────────────┘    │
└─────────────────────────────────┘
```

- [ ] Create specific AI prompts for each trigger
- [ ] Add context-aware responses

#### Afternoon: Response Screen Enhancement
- [ ] Add "Share this reset" button (generates image card)
- [ ] Add "Save to favorites" feature
- [ ] Add calming animation during loading

**Deliverable**: Engaging, shareable Emotional Reset feature

---

### Day 7 (Sunday) - Week 1 Review & Testing

#### Morning: Integration Testing
- [ ] Test complete onboarding flow (new user)
- [ ] Test paywall appears at correct times
- [ ] Test subscription purchase flow (sandbox)
- [ ] Test premium feature unlocking
- [ ] Fix any UI bugs

#### Afternoon: Polish
- [ ] Review all copy/text for consistency
- [ ] Ensure loading states are smooth
- [ ] Add haptic feedback on key actions
- [ ] Test on different screen sizes

**Deliverable**: Stable Week 1 build

---

## Week 2: Retention, Polish & Launch Prep

### Day 8 (Monday) - Streak & Progress System

#### Morning: Streak Service
- [ ] Create `lib/services/streak_service.dart`:

```dart
class StreakService {
  Future<int> getCurrentStreak() async { }
  Future<void> recordDailyActivity() async { }
  Future<bool> hasCheckedInToday() async { }
  Future<DateTime?> getLastActivityDate() async { }
}
```

- [ ] Store streak data in SharedPreferences
- [ ] Calculate streak logic (reset if missed day)

#### Afternoon: Streak UI
- [ ] Add streak badge to home screen
- [ ] Create streak milestone celebrations (5, 10, 30 days)
- [ ] Add streak lost/recovery messaging
- [ ] Show streak on profile/settings

**Deliverable**: Functional daily streak system

---

### Day 9 (Tuesday) - Push Notifications

#### Morning: Notification Setup
- [ ] Add `firebase_messaging` to pubspec.yaml
- [ ] Configure Firebase for both iOS and Android
- [ ] Create `lib/services/notification_service.dart`

#### Afternoon: Smart Notifications
- [ ] Daily check-in reminder (customizable time)
- [ ] Streak at risk notification (evening if not checked in)
- [ ] Weekly progress summary notification
- [ ] Add notification settings screen

**Sample Notifications**:
- "🎾 Ready for your mental check-in? Keep your 7-day streak going!"
- "📊 Your weekly progress report is ready"
- "💪 You're just one check-in away from a 10-day streak!"

**Deliverable**: Tasteful push notification system

---

### Day 10 (Wednesday) - Simplified Match Entry

#### Morning: Quick Add Mode
- [ ] Create `quick_add_match_screen.dart`:
  - Opponent name
  - Win/Loss toggle
  - Final score (simple input)
  - One optional note
  - "Add detailed info later" option
- [ ] Make this the default, detailed entry is "Advanced"

**Quick Add Flow**:
```
Who did you play? [___________]
Did you win? [✓ WIN] [ LOSS ]
Score? [2] - [0]
Quick note (optional): [____________]
[Save Match]
```

#### Afternoon: Voice Input (Bonus)
- [ ] Add `speech_to_text` package
- [ ] Add voice input for notes field
- [ ] "Just played John, won 6-4 6-2, backhand felt off"

**Deliverable**: 30-second match logging

---

### Day 11 (Thursday) - Insights Dashboard (Premium)

#### Morning: Progress Visualization
- [ ] Create `lib/screens/insights_screen.dart` (Premium only)
- [ ] Add to navigation

**Dashboard Components**:
```
┌─────────────────────────────────┐
│  📈 Your Progress               │
├─────────────────────────────────┤
│  Win Rate Trend                 │
│  [Line chart - last 10 matches] │
├─────────────────────────────────┤
│  Skill Progression              │
│  Serve:    ████████░░ 8.2       │
│  Forehand: ███████░░░ 7.5       │
│  Backhand: █████░░░░░ 5.2 ↑     │
├─────────────────────────────────┤
│  💡 AI Insight                  │
│  "Your backhand has improved    │
│   20% over the last 5 matches!" │
└─────────────────────────────────┘
```

- [ ] Add `fl_chart` package for visualizations
- [ ] Calculate trends from match history

#### Afternoon: AI Weekly Summary
- [ ] Generate weekly AI insight based on data
- [ ] Show on insights page
- [ ] Send as push notification (Sunday evening)

**Deliverable**: Premium insights dashboard

---

### Day 12 (Friday) - Settings & Polish

#### Morning: Settings Screen
- [ ] Create `lib/screens/settings_screen.dart`:
  - Account info (email, profile)
  - Subscription status + manage
  - Notification preferences
  - Privacy policy link
  - Terms of service link
  - "Rate the app" link
  - Sign out
  - Delete account

#### Afternoon: App-Wide Polish
- [ ] Add loading skeletons (shimmer effect)
- [ ] Improve error messages (user-friendly)
- [ ] Add empty states with illustrations
- [ ] Review all animations for smoothness
- [ ] Ensure dark mode works properly

**Deliverable**: Complete settings and polish pass

---

### Day 13 (Saturday) - Beta Testing & Feedback

#### Morning: Beta Distribution
- [ ] Build release version for iOS (TestFlight)
- [ ] Build release version for Android (Internal Testing)
- [ ] Create beta tester guide document
- [ ] Recruit 10-20 beta testers (friends, tennis club)

#### Afternoon: Feedback Collection
- [ ] Set up feedback form (Google Form)
- [ ] Monitor for crashes (add Crashlytics if not done)
- [ ] Watch beta testers use app (screen share if possible)
- [ ] Document critical issues

**Beta Tester Questions**:
1. How was the first experience?
2. Would you pay $9.99/month for this?
3. What confused you?
4. What's missing?
5. Would you recommend to a friend?

**Deliverable**: Beta version live with testers

---

### Day 14 (Sunday) - Launch Prep

#### Morning: App Store Assets
- [ ] Create app icon (all required sizes)
- [ ] Take 5-10 screenshots (iPhone + Android)
- [ ] Write App Store description:

```
TennisGPT - Your AI Tennis Coach

🧠 Build mental resilience with daily check-ins
🎾 Get personalized tactical analysis
💥 Instant emotional support when you need it
📊 Track your progress and see improvement

Features:
• AI-powered mental coaching
• Match history tracking
• Personalized drill recommendations
• Tactical analysis for your game
• Daily streak system
• Progress insights & trends

Whether you're struggling with nerves, trying to beat that rival, or just want to improve your mental game - TennisGPT is your pocket tennis coach available 24/7.

Premium Subscription:
• Monthly: $9.99/month
• Annual: $59.99/year (Save 50%)
```

- [ ] Create preview video (30-60 seconds)
- [ ] Write privacy policy & terms

#### Afternoon: Final Checks
- [ ] Complete App Store submission checklist
- [ ] Test production subscription flow
- [ ] Verify all analytics tracking
- [ ] Review crash reports from beta
- [ ] Make final bug fixes

**Deliverable**: Ready for App Store submission

---

## Post-Sprint Checklist

### Before Submitting to App Stores:
- [ ] All features working on iOS
- [ ] All features working on Android
- [ ] Subscription purchasing works
- [ ] RevenueCat webhooks configured
- [ ] No critical crashes
- [ ] Privacy policy URL live
- [ ] Terms of service URL live
- [ ] Support email set up

### Launch Day:
- [ ] Submit to App Store
- [ ] Submit to Google Play
- [ ] Announce on social media
- [ ] Email beta testers
- [ ] Monitor for issues

---

## Daily Schedule Template

| Time | Activity |
|------|----------|
| 9:00 AM | Daily standup (review yesterday, plan today) |
| 9:30 AM - 12:30 PM | Deep work block 1 |
| 12:30 PM - 1:30 PM | Lunch break |
| 1:30 PM - 5:30 PM | Deep work block 2 |
| 5:30 PM | Daily commit + push |
| 6:00 PM | Test on real devices |

---

## Tech Stack Additions

```yaml
# Add to pubspec.yaml during sprint
dependencies:
  purchases_flutter: ^6.0.0    # RevenueCat
  firebase_messaging: ^14.0.0   # Push notifications
  firebase_analytics: ^10.0.0   # Analytics
  fl_chart: ^0.66.0            # Charts
  shimmer: ^3.0.0              # Loading states
  speech_to_text: ^6.0.0       # Voice input
  share_plus: ^7.0.0           # Social sharing
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| RevenueCat setup issues | Start Day 1, test early |
| App Store rejection | Follow guidelines strictly, prepare for 1 round of feedback |
| Beta testers unavailable | Recruit extra, have backup plan |
| Feature creep | Stick to this plan, no additions |
| Burnout | Build in breaks, sustainable pace |

---

## Success Metrics (2 Weeks Post-Launch)

| Metric | Target |
|--------|--------|
| App Store rating | 4.5+ stars |
| Day 1 retention | 40%+ |
| Day 7 retention | 20%+ |
| Free-to-paid conversion | 3-5% |
| Monthly revenue | $500+ (50 subscribers) |

---

## Remember

> **Ship imperfect, iterate fast.**

This plan gets you to "good enough to charge." You'll continue improving after launch based on real user feedback. The goal is **revenue on Day 1**, not perfection.

Good luck! 🎾
