# Handover Document — Session 2026-04-04

## What Was Built This Session

### Core Pipeline (all tested and working)

1. **Drawing Canvas** (`lib/drawing_canvas.dart`)
   - Full-screen canvas with stroke capture via GestureDetector
   - Reference letter displayed in Comic Sans MS, baseline-aligned to guidelines
   - Guidelines: ascender line, dashed midline, solid baseline, descender line
   - Letter navigation (a–z) with forward/back buttons
   - Clear button to reset strokes
   - Scoring triggered after each stroke, displayed via ScoreDisplay widget

2. **Stroke Model** (`lib/models/stroke.dart`)
   - Simple list of Offset points representing a single drawn stroke

3. **Guidelines Model** (`lib/models/guidelines.dart`)
   - Uses known Comic Sans MS typographic ratios (x-height: 0.54, ascender: 0.93, descender: 0.25 of fontSize)
   - Centres the writing zone vertically within the canvas

4. **Coverage Scorer** (`lib/models/coverage_scorer.dart`) — 12 tests
   - Given two boolean grids, returns the fraction of reference pixels covered by stroke pixels

5. **Precision Scorer** (`lib/models/precision_scorer.dart`) — 12 tests
   - Given two boolean grids, returns the fraction of stroke pixels that fall inside reference pixels

6. **Stroke Rasterizer** (`lib/models/stroke_rasterizer.dart`) — 10 tests
   - Converts user strokes into a boolean grid within a bounding box
   - Maps canvas coordinates to grid coordinates relative to the bounding box origin
   - Walks stroke paths in small steps, stamping circular regions based on stroke width

7. **Template Rasterizer** (`lib/models/template_rasterizer.dart`) — 8 tests
   - Renders reference letter to an offscreen image via PictureRecorder
   - Reads pixel data back and converts to boolean mask using alpha threshold
   - Returns both the mask and the bounding box (in canvas coordinates)
   - Positions letter identically to the drawing canvas (baseline-aligned, horizontally centred)

8. **Score Integrator** (`lib/models/score_integrator.dart`) — 9 tests
   - Orchestrates the pipeline: takes reference mask + bounds + strokes → returns ScoreResult
   - Validates that reference mask dimensions match the bounds

9. **Score Display** (`lib/widgets/score_display.dart`) — 6 tests
   - Shows "Coverage: X%" and "Precision: X%" below the canvas
   - Always reserves layout space (uses Opacity rather than SizedBox.shrink) to prevent canvas resize when scores appear

10. **Score Result** (`lib/models/score_result.dart`)
    - Simple data class holding coverage and precision values

### Test Suite
- **57 tests total**, all passing
- Pure unit tests for scorers, stroke rasterizer, score integrator
- Widget tests (using `tester.runAsync`) for template rasterizer
- Widget tests for score display

### Known Limitation: Flutter Test Font
The Flutter test environment uses a fallback font that renders every character as a solid rectangle. Tests for the template rasterizer avoid assertions that depend on actual glyph shapes (e.g. "mask is not entirely filled"). The pipeline works correctly with real fonts at runtime.

---

## Issues Identified — Next Steps

### 1. Normalised Coverage (Priority: High)

**Problem:** The user's drawing stroke width (3px) is much thinner than the template glyph's filled shape. Even a perfect trace of the letter only covers ~40-45% of the template's pixels, making raw coverage misleading.

**Solution:** Calculate the **maximum achievable coverage** for a given stroke width against each template letter, then normalise:

```
normalised_coverage = actual_coverage / max_achievable_coverage
```

**Implementation approach:**
1. **Skeletonise the template** — reduce the filled glyph to its centre-line path (1px wide skeleton)
2. **Rasterize the skeleton** with the same stroke width as the user's drawing (3px)
3. **Run the existing coverage scorer** on that ideal rasterized skeleton vs the full template — this gives `max_achievable_coverage`
4. **Divide the user's actual coverage** by this maximum to get a normalised score

This way if the theoretical max for 'a' at 3px stroke width is 45%, and the user scores 41%, the normalised coverage is 91%.

**Testing approach:**
- Unit test the skeletonisation independently
- Test that max achievable coverage is always > 0 and <= 1.0
- Test that normalised coverage of a perfect trace returns ~1.0
- Test that normalised coverage scales correctly (half the shape traced → ~0.5)

### 2. Precision Gating (Priority: Medium)

**Problem:** Precision is meaningless when coverage is low — a single dot inside the template scores 100% precision.

**Solution:** Only consider precision meaningful when normalised coverage exceeds a threshold (e.g. 80%). Below that threshold, precision is not displayed or factored into feedback.

**Implementation:** This is a UI/display logic change, not a scorer change. The precision scorer itself stays as-is. The gating logic belongs in the score display or a presentation layer that decides what to show the user.

### 3. Shape Placement Scoring (Priority: High)

**Problem:** The current bitmap scoring only measures whether ink overlaps the template. It doesn't measure whether the letter is positioned correctly relative to the handwriting guidelines. This was identified as one of the two top priorities for the app (alongside shape completeness).

**Solution:** Measure how closely the user's stroke bounding box matches the expected vertical zone for that letter type. This is independent of the bitmap pipeline — it only needs stroke points and guideline positions.

**Letter categories and expected zones:**

| Category | Letters | Expected top | Expected bottom |
|----------|---------|-------------|-----------------|
| Short | a, c, e, m, n, o, r, s, u, v, w, x, z | midline | baseline |
| Tall | b, d, f, h, k, l, t | ascender line | baseline |
| Descender | g, p, q, y | midline | descender line |
| Tall + descender | j | ascender line | descender line |
| Special | i (dot above midline, body short) | — | — |

**Measurements:**
- **Baseline accuracy:** how close is the bottom of the user's strokes to the baseline (or descender line for descenders)?
- **Height accuracy:** how close is the top of the user's strokes to the expected line (midline for short letters, ascender for tall)?
- **Placement score:** combine these into a single metric, e.g. average of the two, expressed as a percentage

**Implementation approach:**
1. Create a letter classification map (letter → category → expected top/bottom lines)
2. Calculate the bounding box of the user's strokes
3. Compare stroke bounds to expected bounds
4. Score as distance from ideal, normalised to a 0–1 range

**Testing approach:**
- Strokes exactly within the expected zone → 100%
- Strokes shifted up/down → proportionally lower score
- Strokes too tall or too short → lower score
- Each letter category tested with correct and incorrect placement

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
  [ScoreResult]    [TemplateRasterizer] → boolean grid + bounds
       ↓
  [ScoreDisplay] → UI percentages
```

The template bounding box defines the grid size. Both masks use the same dimensions. The ScoreIntegrator feeds them into CoverageScorer and PrecisionScorer.

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
    template_rasterizer.dart        — Font glyph → boolean grid + bounds
    score_integrator.dart           — Orchestrates rasterization + scoring
    score_result.dart               — Data class for coverage + precision
  widgets/
    score_display.dart              — UI widget showing score percentages

test/
  coverage_scorer_test.dart         — 12 tests
  precision_scorer_test.dart        — 12 tests
  stroke_rasterizer_test.dart       — 10 tests
  template_rasterizer_test.dart     — 8 tests
  score_integrator_test.dart        — 9 tests
  score_display_test.dart           — 6 tests
  widget_test.dart                  — default (can be removed)
```

---

## User Preferences (for reference)

- Build incrementally with real-data validation at each step
- Tests first, then implementation
- No combined/merged scores in the UI — show individual metrics separately
- Comic Sans MS as the reference font
- Individual print letters, not cursive
- Wants deep understanding of technical decisions before proceeding
