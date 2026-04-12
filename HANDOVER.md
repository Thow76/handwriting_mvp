# Handover Document — Session 2026-04-12 (Session 3)

## What Was Built This Session

### 1. Coverage Normalisation (completed)

**Problem:** The user's drawing stroke (3px) is much thinner than the template glyph's filled shape. Even a perfect trace only covered ~40-45% of the template's pixels, making raw coverage misleading.

**Solution:** Skeletonize the template, rasterize the skeleton with the user's stroke width, measure what fraction of the template that ideal trace covers, then divide the user's actual coverage by that maximum.

```
normalised_coverage = actual_coverage / max_achievable_coverage
```

**How it works:**
1. Zhang-Suen thinning algorithm reduces the filled template glyph to a 1-pixel-wide centre-line skeleton
2. Each skeleton pixel is stamped as a single-point stroke at the user's stroke width
3. Coverage of that ideal trace against the full template = `maxCoverage`
4. User's raw coverage is divided by `maxCoverage`, clamped to 1.0

**Key design decision:** We discussed whether to increase the user's stroke width to improve coverage scores. Concluded that normalisation is the right fix — it makes scores independent of stroke width. A thin stroke with normalisation gives the best of both worlds: precision stays naturally high (less ink to bleed outside) and coverage becomes meaningful. The stroke width remains a UI/comfort choice, not a scoring lever.

**Files added:**
- `lib/models/skeletonizer.dart` — Zhang-Suen thinning algorithm
- `test/skeletonizer_test.dart` — 9 tests
- `test/normalised_coverage_test.dart` — 6 tests

**Files changed:**
- `lib/models/score_integrator.dart` — added `_maxAchievableCoverage()` private method; `score()` now returns normalised coverage transparently

No changes needed to `drawing_canvas.dart` or `score_display.dart` — normalisation happens inside `ScoreIntegrator.score()`.

---

## Current State of the App

### Scoring Pipeline

Three independent scores are calculated and displayed after each stroke:

| Score | What it measures | Status |
|-------|-----------------|--------|
| **Coverage** | % of the template shape traced, normalised against max achievable for the stroke width | Working — normalised this session |
| **Precision** | % of the user's ink that falls inside the template shape | Working — raw value, not yet normalised |
| **Placement** | Vertical position accuracy (top/bottom edge alignment with template ink bounds) | Working — but overly harsh (see Known Issues) |

### Architecture

```
User draws strokes
       ↓
  [Stroke model] ← list of Offset points
       ↓
  [StrokeRasterizer] → boolean grid (stroke mask)
       ↓
  [ScoreIntegrator] ← receives template mask + bounds
       |    ↓                    ↑
       |  normalised     [TemplateRasterizer] → boolean grid + bounds + inkBounds
       |  coverage              ↑
       |    ↓            [Skeletonizer] → centre-line skeleton of template
       |  [ScoreResult]
       |    ↓
       |  [ScoreDisplay]   [PlacementScorer] ← uses inkBounds + strokes
       ↓
  UI: Coverage %, Precision %, Placement %
```

### Test Suite — 112 tests, all passing

| Test file | Count | Component |
|-----------|-------|-----------|
| coverage_scorer_test.dart | 12 | CoverageScorer |
| precision_scorer_test.dart | 12 | PrecisionScorer |
| stroke_rasterizer_test.dart | 10 | StrokeRasterizer |
| template_rasterizer_test.dart | 8 | TemplateRasterizer |
| score_integrator_test.dart | 9 | ScoreIntegrator |
| score_display_test.dart | 7 | ScoreDisplay widget |
| placement_scorer_test.dart | 12 | PlacementScorer |
| ink_bounds_test.dart | 5 | TemplateRasterResult.inkBounds |
| font_metrics_test.dart | 22 | Diagnostic (test font limitation) |
| skeletonizer_test.dart | 9 | Skeletonizer (new) |
| normalised_coverage_test.dart | 6 | Normalised coverage (new) |

---

## Known Issues — Adjustments Needed

### 1. Placement Scoring Is Overly Harsh (Priority: High)

**Problem:** Placement compares the user's stroke bounding box (raw touch points) against pixel-precise template ink bounds. Scoring 100% is practically impossible because:

1. **Touch vs ink mismatch** — The rendered ink extends `strokeWidth / 2` beyond the touch points, but the scorer only looks at raw touch coordinates. So the visible ink is correct but the score penalises the offset.
2. **Sub-pixel precision** — Template ink bounds come from rasterized pixel scanning (integer boundaries). Touch points would need to land at those exact Y coordinates.

**Proposed fix:** Add a tolerance zone — any error within a threshold (e.g. a few pixels, or a small percentage of zone height) counts as a perfect score. This makes placement a "are you roughly in the right zone?" check rather than a pixel-precision test. Should be calibrated alongside the combined scoring system.

### 2. Precision Normalisation (Priority: Medium)

**Problem:** Same issue coverage had before normalisation. A wider stroke bleeds more pixels outside the template even on a perfect centre-line trace. Max achievable precision at a given stroke width is less than 100%.

**Proposed fix:** Mirror the coverage normalisation — calculate max achievable precision from the ideal skeleton trace and divide. The infrastructure (skeletonizer + ideal trace) already exists.

**Status:** Deferred until simulator testing shows whether raw precision is problematic in practice.

### 3. Precision Gating (Priority: Low)

**Problem:** Precision is meaningless when coverage is low — a single dot inside the template scores 100% precision.

**Proposed fix:** Exclude or de-weight precision when coverage is below a threshold. More relevant once the combined scoring system is designed.

---

## Proposed Advanced Features (Future Sessions)

These are fundamentally different from the current bitmap-based pipeline. The current system analyses **where ink landed** (the result). These features would analyse **how the ink was drawn** (the process), requiring a **per-letter stroke model** that defines expected stroke count, order, and direction for all 26 letters. This model does not exist in the font file and must be authored manually.

### Stroke Count (Complexity: Low, Value: High)
Does the user use the correct number of strokes? Simple count comparison against a lookup table. Important for letter formation learning.

### Stroke Direction (Complexity: Medium, Value: High)
Was each stroke drawn in the expected direction? (top-to-bottom, left-to-right) Requires matching user strokes to expected strokes and comparing start/end points. Important for developing proper motor habits.

### Stroke Order (Complexity: Medium-High, Value: Medium)
Were the strokes drawn in the correct sequence? Depends on reliable stroke matching. Matters for fluency development.

### Smoothness / Fluency (Complexity: Medium, Value: Medium)
Are the strokes smooth curves or jerky zigzags? Requires analysing point-to-point velocity and angle changes. Captures motor control quality that bitmap comparison cannot detect.

### Proportion (Complexity: Low, Value: Low-Medium)
Is the letter the right width relative to its height? Bounding box width comparison against per-letter expected ratios. Coverage and precision already partially capture this.

---

## Next Priority: Combined Scoring System

The immediate focus is bringing coverage, precision, and placement together into a coherent system that:

1. **Encourages practice** — does not over-penalise small imperfections that are normal for handwriting
2. **Doesn't over-reward poor performance** — scribbles outside the lines should not score well
3. **Feels fair to the learner** — the score should be motivating, not discouraging

This is a UX/pedagogy design challenge as much as a technical one. It requires:
- Calibrating what score ranges feel right through simulator testing with real handwriting
- Deciding on weighting, thresholds, and tolerance zones
- Designing how feedback is presented (numeric scores, star ratings, colour coding, messages)

---

## File Listing

```
lib/
  main.dart                         — App entry point
  drawing_canvas.dart               — Main screen: canvas, guidelines, scoring integration
  models/
    stroke.dart                     — Stroke data model
    guidelines.dart                 — Guideline positions from font metrics
    coverage_scorer.dart            — % of reference pixels covered by strokes
    precision_scorer.dart           — % of stroke pixels inside reference
    stroke_rasterizer.dart          — Strokes → boolean grid
    template_rasterizer.dart        — Font glyph → boolean grid + bounds + inkBounds
    skeletonizer.dart               — Zhang-Suen thinning → centre-line skeleton (new)
    score_integrator.dart           — Orchestrates rasterization + normalised scoring
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
  skeletonizer_test.dart            — 9 tests (new)
  normalised_coverage_test.dart     — 6 tests (new)
```

---

## Session History

| Session | Date | Key work |
|---------|------|----------|
| 1 | 2026-03-28 | Project reset, drawing canvas, stroke capture, guidelines, bitmap scoring pipeline (coverage + precision) |
| 2 | 2026-04-04 | Font change to Comic Neue, per-glyph guideline metrics, placement scorer, ink bounds |
| 3 | 2026-04-12 | Coverage normalisation via skeletonization, handover with combined scoring system as next priority |
