# Post-Refactor Fix Plan — Composure

## Context
The main refactor (Sections A–G) is complete and the backend builds clean.
However, three issues were found during code review that need fixing before shipping.

---

## FIX 1 — CRITICAL: Four screens broken by tacticalAnalysis() return type change

### Problem
`lib/services/api_service.dart` → `tacticalAnalysis()` was changed from returning
`Future<String?>` to `Future<Map<String, dynamic>?>` for the new structured UI.

But **four other screens** still call it and expect a `String?`:

| File | Line(s) | How it uses the result |
|------|---------|----------------------|
| `lib/screens/add_match_screen.dart` | 153, 179, 208 | `analysis ?? ''` assigned to `tacticalAnalysis:` (String field) |
| `lib/screens/quick_match_screen.dart` | 173, 198, 212 | `analysis ?? ''` assigned to `tacticalAnalysis:` AND `_aiInsight = analysis` |
| `lib/screens/onboarding/onboarding_screen.dart` | 99, 102 | `_aiInsight = response` (expects String?) |
| `lib/screens/match_reflection_screen.dart` | 102, 106 | `_tacticalAdvice = response` (expects String?) |

### Fix Strategy
**Add a convenience method** in `api_service.dart` that wraps the structured call
and returns a plain string (the summary) for callers that don't need the full structure.

```dart
/// Returns just the summary text from tactical analysis.
/// Use this for screens that store/display a plain string.
Future<String?> tacticalAnalysisSummary(String matchDescription, List<MatchPerformance>? recentMatches) async {
  final result = await tacticalAnalysis(matchDescription, recentMatches);
  if (result == null) return null;
  // Return summary, or fall back to full JSON string
  return result['summary'] as String? ?? result.toString();
}
```

Then update the four callers to use `tacticalAnalysisSummary()` instead of `tacticalAnalysis()`:

1. **`lib/screens/add_match_screen.dart`** line 153:
   Change: `apiService.tacticalAnalysis(...)` → `apiService.tacticalAnalysisSummary(...)`

2. **`lib/screens/quick_match_screen.dart`** line 173:
   Change: `apiService.tacticalAnalysis(...)` → `apiService.tacticalAnalysisSummary(...)`

3. **`lib/screens/onboarding/onboarding_screen.dart`** line 99:
   Change: `apiService.tacticalAnalysis(...)` → `apiService.tacticalAnalysisSummary(...)`

4. **`lib/screens/match_reflection_screen.dart`** line 102:
   Change: `apiService.tacticalAnalysis(...)` → `apiService.tacticalAnalysisSummary(...)`

### Verification
- `dart analyze lib/` should show no new type errors
- Each screen should still compile and display text where it used to

---

## FIX 2 — IMPORTANT: OpenAI error strings waste a retry call in tactical analysis

### Problem
`backend/TennisGPT.Infrastructure/External/OpenAIClient.cs` → `CallOpenAIAsync()`
returns human-readable error strings on API failures (429, 401, 500+).

These flow back to `OpenAIService.TacticalAnalysisAsync()` which tries to
JSON-parse them, fails, then makes a **second unnecessary API call** (the retry),
which also fails, before finally returning a fallback.

### Fix Strategy
In `OpenAIClient.cs`, make `CallOpenAIAsync` return `null` on HTTP error status codes
instead of returning error strings. Then add a separate way to surface the error message.

**Option A (simplest):** Change `CallOpenAIAsync` to return `null` for error statuses,
and throw a descriptive exception that `SendPromptAsync` already catches:

In `CallOpenAIAsync()`, replace the error-return lines (lines ~119–129):
```csharp
// Instead of returning error strings, return null
// The existing null check in SendPromptAsync handles this:
// "No response generated. Please try again."
if ((int)response.StatusCode == 429)
    return null;
if ((int)response.StatusCode == 401)
{
    _logger.LogCritical("[{RequestId}] OpenAI API key is invalid!", requestId);
    return null;
}
if ((int)response.StatusCode >= 500)
    return null;

return null;
```

Then in `SendPromptAsync`, the `content == null` check on line 62 returns the
generic fallback. For `TacticalAnalysisAsync`, this null-returned fallback string
("No response generated. Please try again.") will still fail JSON parse, but
**it won't trigger a wasteful retry** because we can add a check:

In `OpenAIService.TacticalAnalysisAsync()`, before retrying, check if the raw
response looks like a known error fallback:
```csharp
// After first parse attempt fails
var parsed = TryParseTacticalResponse(rawResponse);
if (parsed != null) return parsed;

// Don't retry if the response is a known error/fallback (not AI content)
if (rawResponse.StartsWith("No response") ||
    rawResponse.StartsWith("AI coaching") ||
    rawResponse.StartsWith("The request took") ||
    rawResponse.StartsWith("Unable to") ||
    rawResponse.StartsWith("Something went wrong") ||
    rawResponse.StartsWith("Received an unexpected") ||
    rawResponse.StartsWith("OpenAI is experiencing") ||
    rawResponse.StartsWith("The coaching service"))
{
    _logger.LogWarning("Tactical analysis received error response, skipping retry: {Msg}", rawResponse);
    return new TacticalAnalysisResponse
    {
        Summary = rawResponse,
        Recommendations = new List<TacticalRecommendation>
        {
            new() { Title = "Service unavailable", Why = "The AI service could not process your request.", How = "Please try again in a moment." }
        },
        PatternDetected = "",
        NextMatchFocus = ""
    };
}

// Only retry if we got actual AI content that failed to parse
_logger.LogWarning("Tactical analysis JSON parse failed. Raw (truncated): {Raw}", ...);
```

### Verification
- Deploy and trigger a 429 (or test with misconfigured API key for 401)
- Confirm only one API call is made, not two
- Confirm the user sees a reasonable error, not a broken fallback

---

## FIX 3 — IMPORTANT: Readiness scale mismatch in MentalCheckInAsync

### Problem
`backend/TennisGPT.Application/Services/OpenAIService.cs` line 129:
```
Player's current readiness level: {mood}/5
```
But Flutter's Pre-Match Prep screen sends values 1–10 and the journal text
explicitly says `/10`. The AI gets contradictory info (e.g., "readiness: 8/5").

### Fix Strategy
Single line change in `OpenAIService.cs` line 129:

Change:
```csharp
Player's current readiness level: {mood}/5
```
To:
```csharp
Player's current readiness level: {mood}/10
```

### Verification
- Submit a pre-match prep with readiness 8
- Confirm the AI response references the rating sensibly (out of 10, not 5)

---

## Execution Order
1. Fix 1 first (critical — app won't compile/run without it)
2. Fix 3 second (one-line change, easy win)
3. Fix 2 third (defensive improvement, can ship without but should fix)

## Files Modified (Summary)
- `lib/services/api_service.dart` — add `tacticalAnalysisSummary()` method
- `lib/screens/add_match_screen.dart` — switch to `tacticalAnalysisSummary()`
- `lib/screens/quick_match_screen.dart` — switch to `tacticalAnalysisSummary()`
- `lib/screens/onboarding/onboarding_screen.dart` — switch to `tacticalAnalysisSummary()`
- `lib/screens/match_reflection_screen.dart` — switch to `tacticalAnalysisSummary()`
- `backend/TennisGPT.Application/Services/OpenAIService.cs` — change `/5` to `/10`
- `backend/TennisGPT.Infrastructure/External/OpenAIClient.cs` — (optional) return null on errors
- `backend/TennisGPT.Application/Services/OpenAIService.cs` — skip retry on error strings

## Do Not Touch
- Do not modify any other files
- Do not change the database provider
- Do not refactor unrelated architecture
