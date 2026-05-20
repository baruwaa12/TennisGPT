# Tactical Coach Current State Audit

## Purpose
Document how Tactical Coach currently works, why feedback can feel repetitive, and what should be improved next.

## Current End-to-End Flow
1. User opens `Tactical Coach` and selects one of four fixed focus prompts in `lib/screens/tactical_coach_screen.dart`.
2. Optional free-text context is appended.
3. Player profile context (level and goal instructions) is prepended from `PlayerProfileService`.
4. App sends:
   - `matchDescription` (combined prompt text)
   - `recentMatches` (up to 10 recent match objects)
   to `POST /api/coaching/tactical-analysis` via `ApiService.tacticalAnalysis(...)`.
5. Backend (`CoachingController`) forwards request to `OpenAIService.TacticalAnalysisAsync(...)`.
6. `OpenAIService` builds a `MATCH DATA + RECENT MATCH HISTORY` prompt and calls model with a locked system prompt.
7. Response is parsed into structured JSON:
   - `whatToControl`
   - `nextMatchRule`
   - `constraintDrill`
   - `reminder`
   - optional `patternDetection`
8. Flutter renders those fields as cards and allows manual save of advice.

## Why Advice Repeats Today
- **No response memory in the tactical generation path**  
  The model does not receive the last generated tactical outputs, so it cannot avoid recent repeated advice.
- **Fixed response schema with narrow tactical framing**  
  The current "Control Mode" prompt strongly compresses output to one anchor and strict short fields. This improves clarity but reduces variation.
- **High reuse of stable context**  
  If user profile and recent matches are similar between sessions, model receives near-identical inputs and returns near-identical outputs.
- **No anti-repetition policy enforcement**  
  There is no hard rule such as "do not repeat last 3 recommendations unless explicitly justified."
- **No quality gate for novelty**  
  Current parse validation only checks required fields exist. It does not reject outputs that are too similar to recent ones.

## Existing Strengths to Keep
- Structured JSON contract is stable and UI-friendly.
- Match-history context is already included.
- Level-based language complexity is already integrated.
- Retry and fallback handling are in place for invalid model output.

## Gaps to Address in Next Tactical Iteration
- Add recent recommendation memory to each tactical request.
- Add anti-repetition instructions and justification rule.
- Add a novelty check (similarity gate) before returning final response.
- Add optional scenario tags (serve/return/pressure/closing) to diversify tactical framing.
- Add evidence-trace requirement in output (which match pattern triggered each recommendation).

## Immediate Candidate Improvements (Proposed)
1. **Prompt-layer fix**: include last 3 tactical outputs and "no-repeat unless justified" rules.
2. **Service-layer fix**: add response similarity check against recent outputs and regenerate once if too similar.
3. **Product-layer fix**: persist tactical output history (not only manually saved entries) for memory and evaluation.

## Decision Point
Tactical Coach is functional and stable, but currently optimized for concise control cues over variation.  
Before implementing behavior changes, we should choose whether to prioritize:
- maximum novelty,
- maximum consistency,
- or a balanced middle.
