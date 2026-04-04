# Handover Document — Session 2026-04-04 (Session 2)

## What Was Built This Session

### 1. Font Change: Comic Sans MS → Comic Neue

**Problem:** The app referenced `'Comic Sans MS'` but never bundled the font file. On Android it silently fell back to Roboto. Comic Sans MS is Microsoft-licensed and can't be redistributed.

**Solution:** Bundled Comic Neue (open-source, OFL license) from the original GitHub repo.

**Files changed:**
- Added `fonts/ComicNeue-Regular.ttf`
- `pubspec.yaml` — added `fonts:` section declaring the font
- `lib/drawing_canvas.dart` — changed `_fontFamily` from `'Comic Sans MS'` to `'Comic Neue'`

### 2. Guidelines Corrected with Per-Glyph Metrics

**Problem:** The guideline ratios came from the font's OS/2 table, which describes the overall design envelope — not where individual glyphs actually render. The ascender line was at 0.90 but tall letters (b, d, h) only reach ~0.685. The descender was at 0.25 but descender letters only drop to ~0.193.

**Solution:** Parsed the TTF's `glyf` table to extract per-glyph bounding boxes for all 26 lowercase letters, then derived category-specific ratios:

| Metric | Old (OS/2) | New (per-glyph) |
|--------|-----------|-----------------|
| x-height (midline) | 0.487 | **0.493** |
| ascender | 0.900 | **0.685** |
| descender | 0.250 | **0.193** |

Per-glyph measurements from the font file (unitsPerEm = 1000):
- Short letters (a,c,e,m,n,o,r,s,u,v,w,x,z): yMax ≈ 493
- Tall letters (b,d,f,h,k,l): yMax ≈ 681
- t: yMax = 663 (slightly shorter than other tall letters)
- Descenders (g,p,q,y): yMin ≈ -193 (average of -188,-198,-186,-200)
- j: yMax = 679, yMin = -184
- i: yMax = 674

**Files changed:**
- `lib/models/guidelines.dart` — updated ratios and comments

**Note:** These are hardcoded ratios derived from the TTF file's glyph table. If the font changes, these would need re-measuring. The ratios describe where the font's glyph outlines sit, which should closely match what Flutter renders.

### 3. Placement Scorer (new component)

**What it does:** Scores how closely the user's strokes match the expected vertical zone for a letter. Compares the top and bottom of the stroke bounding box against the template's actual ink bounds.

**Scoring formula:**
```
edge_score = max(0, 1 - abs(actual - expected) / zone_height)
placement_score = average(top_score, bottom_score)
```

- Scores both top and bottom edges of the user's strokes
- Zone height = expected bottom - expected top (varies per letter)
- Overshooting and undershooting are penalised equally
- Score is 0.0 to 1.0

**Files added:**
- `lib/models/placement_scorer.dart` — 12 tests
- `test/placement_scorer_test.dart`

### 4. Ink Bounds on TemplateRasterResult

**What it does:** Scans the template mask to find the topmost and bottommost rows containing ink pixels, returning a tight `Rect` in canvas coordinates. This gives the actual rendered glyph bounds (not the TextPainter layout bounds, which are the same for every character).

**Files changed:**
- `lib/models/template_rasterizer.dart` — added `inkBounds` getter to `TemplateRasterResult`
- `test/ink_bounds_test.dart` — 5 tests

### 5. ScoreResult Extended with Placement

**Files changed:**
- `lib/models/score_result.dart` — added `placement` field
- `lib/models/score_integrator.dart` — passes `placement: 0.0` (bitmap pipeline doesn't calculate placement)
- `lib/widgets/score_display.dart` — displays "Placement: X%" alongside Coverage and Precision
- `test/score_display_test.dart` — updated to include placement in all test cases (7 tests)

### 6. Placement Scoring Wired into Drawing Canvas

**How it works at runtime:**
1. `TemplateRasterizer.rasterize()` is called (already existed for coverage/precision)
2. `templateResult.inkBounds` extracts the actual ink top/bottom from the mask
3. `PlacementScorer.score()` compares user stroke bounds against the ink bounds
4. All three scores (coverage, precision, placement) are displayed independently

**Files changed:**
- `lib/drawing_canvas.dart` — imports PlacementScorer, calculates placement after bitmap scoring, constructs ScoreResult with all three scores

### 7. Font Metrics Test (diagnostic, not production)

**What it does:** Rasterizes representative letters from each category and prints their ink bounds. Used during development to verify glyph positioning. All letters render as identical rectangles in the test environment due to the Flutter test font limitation.

**Files added:**
- `test/font_metrics_test.dart` — 22 tests (all pass but measurements are meaningless due to test font)

---

## Test Suite
- **97 tests total**, all passing
- Coverage scorer: 12 tests
- Precision scorer: 12 tests
- Stroke rasterizer: 10 tests
- Template rasterizer: 8 tests
- Score integrator: 9 tests
- Score display: 7 tests
- Placement scorer: 12 tests
- Ink bounds: 5 tests
- Font metrics: 22 tests (diagnostic)

---

## Issues Identified — Next Steps

### 1. Normalised Coverage (Priority: High)

**Status:** Not started. Carried forward from previous session.

**Problem:** The user's drawing stroke width (3px) is much thinner than the template glyph's filled shape. Even a perfect trace only covers ~40-45% of the template's pixels, making raw coverage misleading.

**Solution:** Calculate the maximum achievable coverage for a given stroke width against each template letter, then normalise:
```
normalised_coverage = actual_coverage / max_achievable_coverage
```

**Implementation approach:**
1. Skeletonise the template — reduce the filled glyph to its centre-line path
2. Rasterize the skeleton with the same stroke width as the user's drawing
3. Run the existing coverage scorer on that ideal skeleton vs the full template → max_achievable_coverage
4. Divide the user's actual coverage by this maximum

### 2. Precision Gating (Priority: Medium)

**Status:** Not started. Carried forward from previous session.

**Problem:** Precision is meaningless when coverage is low — a single dot inside the template scores 100% precision.

**Solution:** Only display precision when normalised coverage exceeds a threshold (e.g. 80%). This is a UI/display logic change, not a scorer change.

### 3. Guideline Ratios: Hardcoded vs Runtime (Priority: Low)

**Status:** Currently using hardcoded per-glyph ratios from the TTF file. These are accurate for Comic Neue but would break if the font changes.

**Alternative:** Measure ink bounds at runtime from the TemplateRasterizer output. This would always be accurate regardless of font, but adds a startup cost.

**Decision:** Hardcoded ratios are fine for now. If the font changes, re-run the TTF parsing script to get new ratios. The Python script used is documented in the git history.

### 4. Placement Scoring: Baseline-Only Option (Priority: Low)

**Open question from user:** Should placement score both edges (top and bottom) or focus specifically on the baseline (bottom edge)? Currently scores both. The user asked about this but didn't express a strong preference. Worth revisiting after testing on the simulator.

---

## Architecture Overview

```
User draws strokes
       ↓
  [Stroke model] ← list of Offset points
       ↓
  [StrokeRasterizer] → boolean grid (stroke mask)
       ↓
  [ScoreIntegrator] ← also receives template mask + bounds
       ↓                    ↑
  [ScoreResult]    [TemplateRasterizer] → boolean grid + bounds + inkBounds
       ↓                    ↑
  [ScoreDisplay]   [PlacementScorer] ← uses inkBounds + strokes
       ↓
  UI: Coverage %, Precision %, Placement %
```

The bitmap pipeline (coverage + precision) and placement scoring are independent. Both consume the TemplateRasterizer output but use different parts of it:
- Bitmap pipeline uses `mask` and `bounds`
- Placement scoring uses `inkBounds` (derived from `mask`)

---

## File Listing

```
lib/
  main.dart                         — App entry point, launches DrawingCanvas
  drawing_canvas.dart               — Main screen: canvas, guidelines, scoring integration
  models/
    stroke.dart                     — Stroke data model
    guidelines.dart                 — Guideline positions from font metrics
    coverage_scorer.dart            — % of reference pixels covered by strokes
    precision_scorer.dart           — % of stroke pixels inside reference
    stroke_rasterizer.dart          — Strokes → boolean grid
    template_rasterizer.dart        — Font glyph → boolean grid + bounds + inkBounds
    score_integrator.dart           — Orchestrates bitmap rasterization + scoring
    score_result.dart               — Data class for coverage, precision, placement
    placement_scorer.dart           — Vertical placement accuracy scorer
  widgets/
    score_display.dart              — UI widget showing three score percentages

fonts/
  ComicNeue-Regular.ttf             — Bundled font (OFL license)

test/
  coverage_scorer_test.dart         — 12 tests
  precision_scorer_test.dart        — 12 tests
  stroke_rasterizer_test.dart       — 10 tests
  template_rasterizer_test.dart     — 8 tests
  score_integrator_test.dart        — 9 tests
  score_display_test.dart           — 7 tests
  placement_scorer_test.dart        — 12 tests
  ink_bounds_test.dart              — 5 tests
  font_metrics_test.dart            — 22 tests (diagnostic)
  widget_test.dart                  — default (can be removed)
```

---

## User Preferences (for reference)

- Build incrementally with real-data validation at each step
- Tests first, then implementation
- No combined/merged scores in the UI — show individual metrics separately
- Comic Neue as the reference font (changed from Comic Sans MS this session)
- Individual print letters, not cursive
- Wants deep understanding of technical decisions before proceeding
- Running on Android simulator (macOS host)
