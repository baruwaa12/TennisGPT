# App Store Review Checklist (Composure)

## Completed in code

- Added iOS privacy manifest: `ios/Runner/PrivacyInfo.xcprivacy`
  - Declares no tracking
  - Declares collected data types used for app functionality/analytics
  - Declares required-reason API usage for `UserDefaults` with reason `CA92.1`
- Added export compliance declaration in `ios/Runner/Info.plist`
  - `ITSAppUsesNonExemptEncryption = NO`
- Updated children privacy wording in `lib/screens/legal_screen.dart`
  - Removed "all ages / under 13" wording
  - Added "not directed to children under 13" language

## Still required in App Store Connect

- Update App Privacy "Nutrition Labels" to match actual behavior:
  - Data collected (name, email, user ID, usage/product interaction)
  - Data linked to identity
  - No tracking
  - Third-party processing disclosures (e.g., OpenAI for AI responses)
- Ensure demo credentials are entered in the dedicated review account fields
- Attach physical-device screen recording showing:
  - app launch
  - login flow
  - core feature flow
  - microphone/speech permission prompts
  - account deletion availability
- Keep backend service live during review

## Recommended (risk reduction)

- Add first-use in-app disclosure before sending prompts to AI services
- Consider bundling fonts locally and disabling runtime font fetching

## Submission reminders

- Use latest build in App Store Connect
- Keep Notes concise and aligned with implemented behavior
- Confirm screenshots show actual in-app screens (not only login/splash)
