# Scoring System — Deep-Dive Handoff

**Project:** Handwriting MVP (Flutter)
**Working directory:** `/Users/home/Development/Flutter Projects/Handwriting MVP/handwriting_mvp`
**Date:** 2026-03-22

---

## Purpose of This Document

The scoring system has grown incrementally and has several layers of penalty and correction logic that interact in non-obvious ways. This document maps out exactly what every component does, where its numbers come from, what it produces, and what its known problems are — so you can decide what to change, remove, or recalibrate.

---

## Files Involved

| File | Role |
|------|------|
| `lib/services/scoring_service.dart` | Main scoring logic (all maths lives here) |
| `lib/services/stroke_matching_service.dart` | Reorders multi-stroke user input to match template stroke order |
| `lib/services/point_resampling.dart` | Arc-length resampling to N equidistant points |
| `lib/models/scoring_result.dart` | Output data class |
| `lib/utils/constants.dart` | `kDifficultyThresholds` + template coord constants |

---

## End-to-End Pipeline

```
User lifts finger (RecallScreen "Done" button)
  │
  ▼
ScoringService.score(userStrokes, template, canvasSize, guidelineMode, difficulty)
  │
  ├─ 1. Convert user strokes from canvas pixels → template space (y-up, 0–1)
  │      via GuidelineMetrics.canvasToTemplate()
  │
  ├─ 2. StrokeMatchingService.alignAndConcatenate()
  │      • greedy centroid matching: reorders user strokes to match template stroke order
  │      • concatenates into two flat lists: templatePath + userPath
  │
  ├─ 3. Flatten all user points (for bounding-box analyses)
  │
  ├─ 4. resampleEquidistant(path, N=64) on both paths
  │      • arc-length interpolation → device-independent comparison
  │
  ├─ 5. _procrustes(template64, user64)
  │      • translate both to origin (subtract centroid)
  │      • scale both to unit Frobenius norm
  │      • optimal rotation: θ = atan2(Σ cross, Σ dot)
  │      • tries forward AND reversed user path; picks lower residual
  │      • returns: distance (residual), scaleFactor (user/template ratio),
  │                 rotationAngle, alignedTemplate, alignedUser
  │
  ├─ 6. _discreteFrechet(alignedTemplate, alignedUser)
  │      • 64×64 DP table; O(4096) — fast
  │      • measures worst-case leash distance between paths
  │
  ├─ 7. SHAPE ERROR
  │      rawShapeError  = 0.6 × procrustes.distance + 0.4 × fréchetDist
  │      rotationPenalty = ramps 0→0.50 for rotation angles beyond ±20°
  │      structuralErr  = checks x-position of ascender/descender ink
  │                       (catches b/d and p/q confusions)
  │      shapeError     = rawShapeError + rotationPenalty + structuralErr
  │
  ├─ 8. PLACEMENT ERROR
  │      compares top and bottom of user bounding box vs template bounding box
  │      placementError = (|user.maxY − tmpl.maxY| + |user.minY − tmpl.minY|) / 2
  │
  ├─ 9. THIRD METRIC ERROR
  │      if GuidelineMode.full  → proportionError
  │        = (aspectRatioErr + zoneDistributionErr + sizeErr) / 3
  │      if GuidelineMode.baselineOnly → sizeError = |1.0 − scaleFactor|
  │
  ├─ 10. Map each error → score (1–10)
  │       via kDifficultyThresholds lookup
  │
  ├─ 11. COVERAGE PENALTY
  │       coverageRatio = (userArcLen / templateArcLen) / scaleFactor
  │       if ratio ≥ 0.55: penalty = 1.0 (no reduction)
  │       if ratio < 0.55: penalty = (ratio / 0.55)² (quadratic ramp to 0)
  │
  ├─ 12. STRUCTURAL PENALTY (second application)
  │       if structuralErr > 0.15: multiplier = clamp(1 − 2×(err−0.15), 0.3, 1.0)
  │       else: multiplier = 1.0
  │
  └─ 13. combinedScore = round(avg(shape, placement, third) × coverage × structural)
                         clamped to 1–10
```

---

## Category 1: Shape Score

**What it measures:** How similar the drawn letter shape is to the template, ignoring position and size.

**Components:**

### Procrustes distance
- Removes translation, scale, and rotation to compare "pure shape"
- Returns average point distance between aligned paths (lower = better)
- **Known issue:** Procrustes is very forgiving of global deformations. A sloppy but roughly correct shape can score well if the overall distribution of points is similar.

### Fréchet distance
- More sensitive to stroke order and local deviations
- Acts as a "leash" metric — measures worst-case correspondence
- **Known issue:** After Procrustes alignment, Fréchet loses its scale-independence, so it partly double-counts Procrustes residuals.

### Rotation penalty
```
_kMaxFreeRotation = 20° (≈0.349 rad)   ← rotations within this are free
_kRotationPenaltyMax = 0.50             ← max additive penalty (at 180°)
```
- Added to shape error; does NOT affect placement or proportion scores
- **Known issue:** Procrustes always tries both forward and reversed paths, picking the better one. This means a mirrored letter (b vs d) may have a small rotation angle but large structural error — the rotation penalty alone won't catch it.

### Structural error
- Checks the horizontal position of ink at the vertical extremes
- Ascender zone: active when template has ink > xHeight + 0.10 (i.e. true ascenders: b, d, f, h, k, l, t, uppercase letters)
- Descender zone: active when template has ink < baseline − 0.05 (i.e. true descenders: g, j, p, q, y)
- Normalises x-position within each letter's own bounding box (0=left, 1=right)
- **Known issue:** Only checks the extreme 20% of the letter height. A moderate structural error (stem slightly on wrong side but not extreme) may produce a low structural error value. The 0.15 threshold for the combined-score multiplier was set analytically, not from real user data.

**Shape error formula:**
```
shapeError = (0.6 × procrustes + 0.4 × fréchet) + rotationPenalty + structuralErr
```

---

## Category 2: Placement Score

**What it measures:** Whether the letter sits in the right vertical position on the guidelines.

**Formula:**
```
placementError = (|user.maxY − template.maxY| + |user.minY − template.minY|) / 2
```

- Uses raw bounding boxes in template space (no Procrustes alignment)
- Both values are in template coordinate units (0–1 range)
- **Known issue:** Checks absolute top and bottom position but not the relationship to specific guidelines. A letter written entirely above the baseline scores the same as one written correctly as long as its bounding box edges match — which can't happen for correct letters, but could produce misleading scores for completely incorrect attempts.
- **Known issue:** Symmetric errors cancel. If the user writes the letter too high by 0.1 AND too tall by 0.1 (top shifts up by 0.2, bottom stays), the error is (0.2 + 0.0)/2 = 0.10. If they just shift up by 0.1, error is also 0.10. Different problems, same score.

---

## Category 3: Proportion (full guidelines) or Size (baseline-only)

### Proportion error (full guidelines)
```
proportionError = (aspectRatioErr + zoneDistributionErr + sizeErr) / 3

aspectRatioErr     = |userAspect − templateAspect| / templateAspect
zoneDistributionErr= |fraction of user pts above xHeight − same for template|
sizeErr            = |1.0 − scaleFactor|
```
- `scaleFactor` = userNorm / templateNorm from Procrustes (>1 means user drew bigger)
- **Known issue:** The three sub-metrics have very different natural ranges. Aspect ratio errors can easily reach 0.5+ for a wide letter drawn narrow. Zone distribution errors max out at 1.0 but typical values are 0.05–0.20. Averaging them without weighting can produce a misleading combined value.

### Size error (baseline-only)
```
sizeError = |1.0 − scaleFactor|
```
- Simpler: just how much the user's letter size differs from the template
- **Known issue:** Procrustes scaleFactor is affected by the path traversal (e.g., letters with loops generate more cumulative arc-length). A correctly-sized letter with an extra loop will appear "too big."

---

## Coverage Penalty

**What it measures:** Whether the user drew the complete letter or stopped partway.

```
coverageRatio = (userArcLen / templateArcLen) / procrustes.scaleFactor
if ratio ≥ 0.55 → coveragePenalty = 1.0   (no reduction)
if ratio < 0.55 → coveragePenalty = (ratio / 0.55)²   (quadratic, 0 at ratio=0)
```

- Scale-corrected so a correctly-sized shorter letter isn't penalised for size
- Applied as a **multiplier** to the combined score (does not affect category scores)
- **Known issue:** The 0.55 threshold was chosen to catch letters where the user draws roughly half the template. Arc-length coverage is not the same as visual coverage — a single dot at the correct position has very low arc-length but might be "correct" for a short letter.

---

## Structural Penalty (combined-score multiplier)

Second application of structural error, as a combined-score multiplier:
```
if structuralErr > 0.15:
    multiplier = clamp(1.0 − 2×(structuralErr − 0.15), 0.30, 1.0)
else:
    multiplier = 1.0
```

- At structuralErr = 0.15: multiplier = 1.0
- At structuralErr = 0.65: multiplier = 0.30 (maximum reduction)
- Applied alongside coverage to combined score: `combined = avg(scores) × coverage × structural`
- **Known issue:** structuralErr is also added to the shape error (step 7), so it is double-penalised. A letter with high structural error gets a lower shape score AND a lower combined score from this multiplier.

---

## Error → Score Mapping

```
kDifficultyThresholds (from constants.dart):

Error      Beginner   Intermediate   Advanced
< 0.03     —          —              10
< 0.05     —          10             9
< 0.08     10         9              7
< 0.12     9          —              —
< 0.09     —          —              7 (typo? see below)
< 0.14     —          7              —
< 0.15     —          —              5
< 0.20     7          —              —
< 0.22     —          5              —
< 0.25     —          —              3
< 0.30     5          —              —
< 0.35     —          3              —
< 0.45     3          —              —
≥ threshold 1         1              1
```

All three category errors (shape, placement, third) go through the same table.
The same thresholds apply regardless of which metric is being evaluated.

**Known issue:** Shape error, placement error, and proportion error have different natural value ranges. Using one threshold table for all three means the "same" threshold means different things for different categories. A placement error of 0.08 (letter shifted slightly off baseline) produces the same score as a shape error of 0.08 (substantially deformed letter).

---

## Combined Score Formula

```
rawCombined   = (shapeScore + placementScore + thirdScore) / 3.0
combinedScore = round(rawCombined × coveragePenalty × structuralPenalty)
                clamped to [1, 10]
```

Three equal-weight category scores, then two multiplicative penalties.

---

## What `rawErrors` Contains (for debugging)

The `ScoringResult.rawErrors` map contains:
```
'shape'        → final shapeError (after rotation + structural additions)
'placement'    → placementError
'proportion' or 'size' → thirdError
'procrustes'   → procResult.distance (before rotation penalty)
'frechet'      → fréchetDist (before weighting)
'scaleFactor'  → procResult.scaleFactor (user/template size ratio; 1.0 = same)
'coverageRatio'→ scale-corrected arc-length ratio (≥0.55 = no penalty)
'rotationDeg'  → rotation angle in degrees (Procrustes optimal rotation)
'structural'   → structuralErr value (before threshold checks)
```

To print these during development:
```dart
// In RecallScreen, after ScoringService.score() returns:
debugPrint(result.rawErrors.toString());
```

---

## Known Calibration Issues

1. **Thresholds not validated with real users.** All threshold values in `kDifficultyThresholds` were set analytically. Scores may feel inconsistent compared to a human teacher's assessment.

2. **Shape error inflation.** The rotation penalty and structural error are additive on top of the Procrustes+Fréchet combination. For a correct but slightly rotated letter on beginner difficulty, the shape score can drop from 10 to 7 from rotation alone.

3. **Double-penalisation of structural errors.** `structuralErr` is added to shape error (→ lower shape score) AND used as a combined-score multiplier. A confusable-pair error (e.g., drawing 'q' instead of 'p') is penalised twice.

4. **Proportion sub-metrics not normalised to comparable ranges.** Aspect ratio error, zone distribution error, and size error are averaged with equal weights but have different natural scales.

5. **Placement error doesn't distinguish "wrong position" from "wrong size."** A letter drawn in the right zone but slightly too tall produces a similar placement error to one drawn at the right size but shifted vertically.

6. **Coverage ratio formula.** Arc-length / scaleFactor conflates two things: incompleteness and size difference. A user who draws all the strokes but very small might trip the coverage threshold even though they drew everything.

---

## What Each Setting Controls

| Setting | Effect on Scoring |
|---------|-------------------|
| `Difficulty.beginner` | Uses wider error thresholds → easier to score 10 |
| `Difficulty.intermediate` | Medium thresholds |
| `Difficulty.advanced` | Tight thresholds → need near-perfect strokes for 10 |
| `GuidelineMode.full` | Third metric = Proportion (aspect ratio + zone + size) |
| `GuidelineMode.baselineOnly` | Third metric = Size (\|1 − scaleFactor\|) |
| `InputMode` (finger/stylus) | Affects trace tolerance zone width only — does NOT affect scoring |
| `widthPresetIndex` | Affects stroke display width only — does NOT affect scoring |
| `LetterCase` | Selects which template is used — scoring pipeline is identical |

---

## Suggested Changes / Questions to Answer First

Before modifying scoring, decide:

1. **Do you want separate thresholds per category?** (Shape vs Placement vs Proportion have different natural error ranges — unified thresholds produce inconsistent difficulty across categories.)

2. **Remove the double-penalty on structural error?** Either keep it as an additive shape term OR a combined-score multiplier — not both.

3. **Should difficulty affect leniency uniformly?** Currently all three category scores use the same threshold table. You might want placement to always be lenient (beginners need more vertical freedom) while shape tightens with difficulty.

4. **What should a coverage ratio of 0.4 mean?** Currently it reduces the combined score to 53% of its face value. Is that the right behaviour if the user drew 2 of 3 strokes of a letter?

5. **Should combined score be an average or a minimum?** Currently it is the average of three categories (plus penalty multipliers). If a user nails shape and proportion but draws on the wrong line, the combined score only slightly penalises that. A minimum or weighted floor would change this.
