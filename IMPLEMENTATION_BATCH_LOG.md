# Implementation Batch Log

Tracks work completed in 3-task batches.

---

## Batch 1 (Tactical Coach Assessment Batch)

### Task 1 - Audit tactical coach flow
- Reviewed tactical flow across: 
  - `lib/screens/tactical_coach_screen.dart`
  - `lib/services/api_service.dart`
  - `lib/services/player_profile_service.dart`
  - `backend/TennisGPT.Api/Controllers/CoachingController.cs`
  - `backend/TennisGPT.Application/Services/OpenAIService.cs`

### Task 2 - Document current behavior and repetition root causes
- Added `TACTICAL_COACH_CURRENT_STATE.md`.
- Documented:
  - exact request/response path,
  - prompt behavior,
  - structured output contract,
  - why repeated advice happens now,
  - concrete improvement options for next iteration.

### Task 3 - Establish implementation tracking artifact
- Added this file (`IMPLEMENTATION_BATCH_LOG.md`) to keep a persistent changelog of every 3-task implementation batch.

### Files Added
- `TACTICAL_COACH_CURRENT_STATE.md`
- `IMPLEMENTATION_BATCH_LOG.md`

### Notes
- No production code changed in Batch 1.
- This batch intentionally captures tactical current state first, per request, before implementing tactical behavior changes.

---

## Batch 2 (Tactical Input Quality Guardrails)

### Task 1 - Add self-analysis gate in Tactical Coach UI
- Updated `lib/screens/tactical_coach_screen.dart` to require meaningful self-analysis before generating insight.
- Added validation behavior:
  - If no self-analysis is provided, generation is blocked.
  - If input looks like score-only text (for example, "6-4 6-3") without tactical detail, generation is blocked.
- Added reflective question prompts so users know exactly what detail to add.

### Task 2 - Ensure backend also rejects low-detail tactical requests
- Updated `backend/TennisGPT.Api/Controllers/CoachingController.cs` with low-detail tactical input checks.
- Added a backend reflective prompt message when tactical input is too short or score-only.
- This protects quality for all clients, not only the Flutter app.

### Task 3 - Surface backend guidance to users (not generic errors)
- Updated `lib/services/api_service.dart` so HTTP 400 responses show the backend's user-facing `error` message directly.
- This ensures users see actionable coaching guidance instead of a generic "Something went wrong."

### Files Changed
- `lib/screens/tactical_coach_screen.dart`
- `backend/TennisGPT.Api/Controllers/CoachingController.cs`
- `lib/services/api_service.dart`
- `IMPLEMENTATION_BATCH_LOG.md`

---

## Batch 3 (Anti-Repetition and Tactical Memory)

### Task 1 - Inject recent tactical advice history into generation
- Updated `backend/TennisGPT.Api/Controllers/CoachingController.cs` to fetch up to 3 recent saved tactical advice entries per user.
- Passed that history into `IOpenAIService.TacticalAnalysisAsync(...)`.
- Updated `backend/TennisGPT.Application/Interfaces/IOpenAIService.cs` signature to accept `recentAdviceHistory`.

### Task 2 - Add anti-repetition/novelty rules to tactical prompting
- Updated `backend/TennisGPT.Application/Services/OpenAIService.cs` to append a dedicated novelty rule block to the tactical system prompt.
- Prompt now explicitly instructs the model to avoid reusing tactical anchors and phrasing from recent advice unless justified.
- Added recent advice context section into tactical user prompt payload.

### Task 3 - Add similarity gate with one regeneration pass
- Implemented response similarity scoring in `OpenAIService` (Jaccard-based lexical overlap).
- If generated tactical output is too similar to recent advice history, backend triggers one regeneration pass with stronger novelty instruction.
- If regeneration remains too similar or fails parse, service safely falls back to original valid candidate.

### Files Changed
- `backend/TennisGPT.Application/Interfaces/IOpenAIService.cs`
- `backend/TennisGPT.Api/Controllers/CoachingController.cs`
- `backend/TennisGPT.Application/Services/OpenAIService.cs`
- `IMPLEMENTATION_BATCH_LOG.md`

---

## Batch 4 (Auto-Capture + Advice Change Transparency)

### Task 1 - Auto-capture tactical outputs for memory context
- Added internal `SavedEntryCategory.TacticalHistory`.
- Updated `backend/TennisGPT.Api/Controllers/CoachingController.cs` to:
  - read recent tactical memory from `TacticalHistory` (fallback to `TacticalAdvice`),
  - auto-save each generated tactical output snapshot to `TacticalHistory`.
- Result: anti-repetition memory no longer depends on users manually pressing save.

### Task 2 - Add "why advice changed" to tactical response
- Updated tactical response contract in `backend/TennisGPT.Application/DTOs/Coaching/TacticalAnalysisResponse.cs` with `whyAdviceChanged`.
- Updated tactical system prompt and field rules in `backend/TennisGPT.Application/Services/OpenAIService.cs` to require this field.
- Updated `lib/screens/tactical_coach_screen.dart` to render a "Why this advice changed" card and include it in share text.

### Task 3 - Add internal evaluation report with before/after samples
- Added `TACTICAL_COACH_BATCH4_EVAL.md` documenting:
  - before/after prompt and response behavior,
  - sample payload scenarios,
  - manual QA checklist,
  - recommended production metrics.

### Files Changed
- `backend/TennisGPT.Domain/Entities/SavedEntry.cs`
- `backend/TennisGPT.Api/Controllers/CoachingController.cs`
- `backend/TennisGPT.Application/DTOs/Coaching/TacticalAnalysisResponse.cs`
- `backend/TennisGPT.Application/Services/OpenAIService.cs`
- `lib/screens/tactical_coach_screen.dart`
- `TACTICAL_COACH_BATCH4_EVAL.md`
- `IMPLEMENTATION_BATCH_LOG.md`

---

## Batch 5 (UI Polish Batch A — Shared Broadcast Kit)

Part of the premium-polish plan: A (shared kit) → B (Match History restyle) → C (Quick Match restyle) → D (cleanup).

### Task 1 - Create shared Broadcast component kit
- Added `lib/widgets/broadcast_kit.dart` with reusable Broadcast-language components:
  - `BroadcastCta` — lime CTA with pressed state (brighten + scale), glow, loading state, haptics, Semantics.
  - `BroadcastPanel` — accent-rule panel (optionally raised/tappable) with press feedback; replaces three hand-rolled copies of the same decoration.
  - `BroadcastSectionHeader` — uppercase section label with a ≥44px trailing action target.
  - `BroadcastScoreline` — monospace scoreline with lost sets dimmed (promoted from the throwaway prototype).
  - `BroadcastResultBadge` — compact W/L square for fixtures rows.

### Task 2 - Wire Home screen to the kit
- `lib/screens/home_screen.dart`: hero panel, stat strip CTA, recent-results header ("VIEW ALL" now has a proper tap target), match rows (scoreline now dims lost sets), coach card (now presses), and empty state all use the kit.

### Task 3 - Wire Tactical Coach screen to the kit
- `lib/screens/tactical_coach_screen.dart`: review CTA (pressed + loading states), form panel, empty-state panel, and expandable saved-advice cards all use the kit.

### Files Changed
- `lib/widgets/broadcast_kit.dart` (new)
- `lib/screens/home_screen.dart`
- `lib/screens/tactical_coach_screen.dart`
- `IMPLEMENTATION_BATCH_LOG.md`

### Notes
- `flutter analyze` clean for all touched files (remaining 12 findings are pre-existing in untouched screens).
- Next: Batch B — Match History rebuilt in Broadcast style with skeleton loading.

---

## Batch 6 (UI Polish Batch B — Match History in Broadcast)

### Task 1 - Rebuild Match History screen on the Broadcast canvas
- Rewrote `lib/screens/match_history_screen.dart` to match Home/Coach:
  - Broadcast top bar (back, accent rule, uppercase title, lime add action).
  - Summary strip panel (MATCHES / WIN % / BEST SURFACE) in scoreline type.
  - Fixtures-style results list: W/L badge, opponent, date · surface,
    mono scoreline with lost sets dimmed.
  - Pull-to-refresh wired to the Broadcast palette.

### Task 2 - Skeleton loading, empty state, error card
- Spinner replaced with layout-matched skeleton (summary + rows).
- Empty state is now a Broadcast panel with headline + lime CTA.
- Error card restyled to panel-with-loss-border.

### Task 3 - Detail sheet + delete flow in Broadcast language
- Bottom sheet: W/L badge + result label, big dimmed-set scoreline,
  uppercase section labels for summary/notes; themed to the canvas.
- Delete confirm dialog restyled (Broadcast panel, 44px actions).

### Files Changed
- `lib/screens/match_history_screen.dart` (rewritten)
- `IMPLEMENTATION_BATCH_LOG.md`

### Notes
- `flutter analyze` clean on changed files.
- Next: Batch C — Quick Match Log + success screen in Broadcast style.

---

## Batch 7 (UI Polish Batch C — Quick Match Log in Broadcast)

### Task 1 - Move Quick Match Log onto the Broadcast canvas
- `lib/screens/quick_match_screen.dart` now renders on the Broadcast canvas
  (status bar, themed wrapper, `_bc` palette) like Home/Coach/History.
- Broadcast top bar: close, accent rule, uppercase "LOG A MATCH".
- Uppercase section labels (MATCH FORMAT / RESULT / SCORE / OPTIONAL).
- Format and result selectors share one Broadcast selection tile:
  hairline border at rest, accent border + raised panel when selected,
  W/L badges on the result options, Semantics for screen readers.
- Sets tally now reads like a scoreboard (mono YOU–OPP readout) instead of
  disabled stepper buttons; removed ~110 lines of dead stepper widgets.

### Task 2 - Primary/secondary actions
- Save button is now the shared `BroadcastCta` (pressed + loading states,
  disabled until the score parses valid).
- "Add detailed match log" demoted to a quiet outlined secondary action
  with a ≥48px target; extracted `_openDetailedLog()` from the inline closure.

### Task 3 - Success view as a "FULL TIME" panel
- Result presented in a Broadcast accent-rule panel: FULL TIME · MATCH SAVED
  label, W/L badge, large mono scoreline, opponent line.
- Share stays as a quiet panel action; DONE is the lime CTA.

### Files Changed
- `lib/screens/quick_match_screen.dart`
- `IMPLEMENTATION_BATCH_LOG.md`

### Notes
- `flutter analyze` clean on changed file.
- Next: Batch D — cleanup (prototype screen, canvas A/B toggle, unused
  vibrant paths, brand-direction system).

---

## Batch 8 (UI Polish Batch D — Design System Cleanup)

Decision recorded: the Broadcast canvas is committed as **fixed dark**
(TV-graphics identity), regardless of the app's light/dark toggle.

### Task 1 - Delete the throwaway prototype
- Deleted `lib/screens/prototype/match_history_prototype.dart` (its winning
  ideas — mono scorelines with dimmed lost sets — shipped in Batches A/B).
- Removed the prototype tile from Settings.

### Task 2 - Commit the canvas: remove the A/B toggle
- `lib/theme/broadcast_theme.dart` simplified to a single fixed-dark token
  set; `BroadcastTheme.of(context)` no longer takes a canvas.
- Deleted `lib/services/ui_style_service.dart`; removed its provider from
  `main.dart`, the Settings picker, and the `context.watch` in all four
  Broadcast screens (Home, Coach, Quick Match, History).

### Task 3 - Strip dead styling systems
- `lib/widgets/ui_kit.dart` rewritten to only what's used: `AppAccents`
  (positive/negative), `TonalIconBadge`, `TonalChip`, `SkeletonBox`.
  Removed the never-taken "vibrant" branches and unused components
  (PrimaryActionButton, PressableCard, AmbientBackground, SegmentedTabs,
  StatRing, StatTile, SectionHeader) — ~600 lines of dead paths.
- Removed the three-way `BrandDirection` system: `app_theme.dart` now has a
  single const accent palette; `theme_service.dart` no longer persists a
  brand direction; deleted `lib/widgets/brand_direction_switcher.dart` and
  the Settings "Design direction" picker.

### Task 4 - Lint sweep
- `dart fix --apply` for const constructors enabled by the now-const palette
  (32 fixes across 10 files).
- Analyzer findings reduced from 12 (pre-batch baseline) to 5, all
  pre-existing and unrelated to UI work.

### Files Changed
- Deleted: `lib/screens/prototype/match_history_prototype.dart`,
  `lib/services/ui_style_service.dart`,
  `lib/widgets/brand_direction_switcher.dart`
- `lib/theme/broadcast_theme.dart` (simplified)
- `lib/widgets/ui_kit.dart` (rewritten, minimal)
- `lib/theme/app_theme.dart`, `lib/services/theme_service.dart`
- `lib/main.dart`, `lib/screens/settings_screen.dart`
- `lib/screens/home_screen.dart`, `lib/screens/tactical_coach_screen.dart`,
  `lib/screens/quick_match_screen.dart`, `lib/screens/match_history_screen.dart`
- const fixes in 10 files via `dart fix`
- `IMPLEMENTATION_BATCH_LOG.md`

### Notes
- Remaining polish candidates (future batches): Settings, Paywall, Login,
  Onboarding screens still on the legacy card style.

---

## Batch 9 (Home Hero Simplification — Form Delta)

### Change
- `lib/screens/home_screen.dart` hero decluttered:
  - Removed the DAY STREAK line (engagement metric, not a tennis metric;
    still available in Settings' stats card).
  - Removed the W/L form squares (duplicated the stat strip's WIN RUN /
    LAST 5 and the Recent Results badges).
  - Added a FORM delta line: win rate over the last 5 matches vs overall,
    shown as ↑/↓ signed % (green up, red down, muted flat). Hidden until
    6+ matches exist so small samples never show a misleading number.
- Home no longer watches `StreakService` (recording streaks on save is
  unchanged elsewhere).

### Files Changed
- `lib/screens/home_screen.dart`
- `IMPLEMENTATION_BATCH_LOG.md`
