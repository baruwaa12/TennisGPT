# Tactical Coach Batch 4 Evaluation

## Scope
Batch 4 introduced three tactical quality upgrades:
- automatic capture of generated tactical outputs for memory context,
- a new `whyAdviceChanged` response field,
- and stronger anti-repetition behavior already added in Batch 3.

## Prompt/Response Delta (Before vs After)

### Before
- Tactical prompt had no explicit explanation field for response variation.
- Memory context depended on manually saved tactical advice.
- UI did not show why guidance changed between sessions.

### After
- Tactical prompt now requires:
  - `whyAdviceChanged` (single-line rationale tied to current context/history).
- Tactical endpoint now auto-saves every generated tactical output into internal `TacticalHistory`.
- Tactical generation history retrieval prioritizes `TacticalHistory` and falls back to manual `TacticalAdvice`.
- UI now renders a "Why this advice changed" section when present.

## Before/After Sample Prompt Payloads

### Example A - Score-only to detailed context

#### Before (often generic output)
Current situation:
`I lost 6-4 6-3`

Recent match history:
`[unchanged]`

#### After (target behavior)
Current situation:
`I lost 6-4 6-3. At 30-30 I missed second-serve returns crosscourt and got pinned deep on backhand rallies.`

Recent tactical advice:
- Advice 1: focus on early shoulder turn + depth margin
- Advice 2: if late on backhand, play heavy crosscourt reset

Expected output behavior:
- fresh anchor (or justified overlap),
- explicit `whyAdviceChanged` tied to return/backhand pressure pattern.

### Example B - Similar recent context

#### Before
- repeated anchor and drill likely.

#### After
- similarity gate compares new output with recent tactical history.
- if overlap is high, one regeneration pass is triggered.
- final output should show changed execution detail and `whyAdviceChanged`.

## Manual QA Checklist
- [ ] Empty or score-only inputs are blocked with reflective guidance.
- [ ] Tactical response includes `whyAdviceChanged` in backend JSON.
- [ ] Tactical screen displays "Why this advice changed" card when field is populated.
- [ ] Repeated sessions with similar context produce materially varied wording or justified overlap.
- [ ] Generated tactical outputs are being auto-captured under internal history category.

## Measurement Suggestions
- Track overlap ratio on successive tactical outputs per user (7-day rolling).
- Track percentage of responses with non-empty `whyAdviceChanged`.
- Track user follow-through: whether users provide richer context after reflective prompt.

## Notes
- This report documents implementation-level evaluation criteria.
- Live quality benchmarking should be run on production-like prompt samples after deployment.
