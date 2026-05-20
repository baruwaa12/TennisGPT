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
