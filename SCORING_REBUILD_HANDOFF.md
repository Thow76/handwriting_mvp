# Scoring Rebuild Handoff

## Purpose

This document provides full context for rebuilding the shape scoring system in a Flutter handwriting practice app. The scoring service has been **stripped to a stub** and needs to be rebuilt incrementally using a **test-driven development** approach, verifying each component with real diagnostic data before adding the next.

---

## 1. What the app does

A mobile Flutter app for ESOL learners practising Roman letter formation. Two modes:

- **Trace mode**: template letter visible, user draws over it, colour-coded visual feedback (no scoring)
- **Recall mode**: letter shown for 3 seconds, hidden, user draws from memory, scored 1–10 across three categories

15 letters in both cases: a, b, d, e, f, g, h, j, k, l, m, p, q, t, y (lowercase + uppercase = 30 templates).

Three scored categories (each 1–10):
1. **Shape** — does the drawn form match the template shape?
2. **Placement** — is the letter in the right vertical position on the guidelines?
3. **Proportion** (full guidelines) or **Size** (baseline-only) — correct aspect ratio / zone distribution / scale

Combined score = average of the three.

---

## 2. What went wrong and why we're rebuilding

The shape scoring went through multiple iterations that each failed:

### Iteration 1: Procrustes + Fréchet + rotation penalty + structural error
- Shape error = `0.6 × procrustes + 0.4 × fréchet + rotationPenalty + structuralErr`
- Coverage (arc-length ratio) applied as multiplier on the **combined** score
- **Problem**: a fragment (just the tail of 'q') could score higher on shape than a complete well-drawn 'q' that was slightly off-position. The arc-length coverage was on the combined score, not shape, and was unreliable (conflated size with completeness).

### Iteration 2: Move arc-length coverage into shape score
- Proposed but **never implemented** — the handoff document flagged that arc-length coverage itself is flawed ("conflates incompleteness and size difference"), so moving it wouldn't fix the root cause.

### Iteration 3: Hybrid Procrustes + bitmap (different thicknesses)
- Template rendered thick (8px), user rendered thin (1.5px) on a 64×64 bitmap grid
- `shapeError = rawShapeError / (templateFill × coverage)`
- **Failed**: templateFill was structurally low (~25%) because a 1.5px line can never fill an 8px band. The division formula amplified this, capping shape score at 1 for decent drawings.

### Iteration 4: Same thickness + IoU
- Both template and user rendered at same thickness (8px beginner), using IoU
- `shapeError = 0.5 × (1 - IoU) + 0.5 × qualityError`
- **Failed**: hand-drawn letters produce IoU of ~0.5 at best (local wobble means pixels don't perfectly overlap), pushing shapeError to ~0.25–0.30. The difficulty thresholds (calibrated for Procrustes-only range of 0.02–0.10) mapped this to score 5, creating a ceiling.

### Iteration 5: Separate shape thresholds
- Added `kShapeDifficultyThresholds` with wider ranges
- **Still failed**: drawings off-centre or at different sizes were still scoring poorly, suggesting a deeper issue than just thresholds.

### Root cause analysis
Each iteration layered a fix without **verifying with real data** what the underlying algorithms were actually producing. The thresholds were guessed, not measured. The formulas were designed in theory but never validated against real hand-drawn input before being deployed.

### Decision
Strip the scoring service to a stub and rebuild incrementally using TDD, verifying each component with diagnostic output before adding the next.

---

## 3. The rebuild plan

### Step 1: Procrustes only (shape quality)
- Implement Procrustes alignment (translate → scale to unit norm → optimal rotation)
- Shape score = Procrustes residual distance mapped through difficulty thresholds
- **Write tests FIRST** that define the required behaviour:
  - Position independence: same letter shifted 100px → same shape score
  - Scale independence: same letter at 0.5× and 2× size → same shape score
  - Quality sensitivity: perfect copy → 10, wobbly → 7+, very wobbly → 5+, wrong shape → ≤3
- **Add diagnostic logging** that prints raw Procrustes distance for every scoring call
- **Verify with real drawings** on device: draw the same letter in multiple positions/sizes, confirm the Procrustes distance is consistent
- **Calibrate thresholds** from the observed value ranges — not from theory

### Step 2: Add bitmap IoU (completeness)
- Only after Step 1 is verified
- Render both Procrustes-aligned shapes at same thickness on 64×64 grid
- IoU measures visual overlap
- **Write tests** that define: fragment → low IoU, complete letter → high IoU
- **Log IoU alongside Procrustes** to see actual ranges
- Decide weighting from observed data

### Step 3: Combine shape score
- Blend Procrustes quality and bitmap completeness using weights derived from real data
- Calibrate thresholds for the blended error range

### Step 4: Rebuild placement and proportion/size
- These were working reasonably before — port them back with their original logic
- Verify with tests

### Step 5: Combined score + difficulty levels
- Wire everything together
- Edge case tests (fragments, wrong letters, empty input)

---

## 4. Current state of the codebase

### Scoring service (STUB)
**`lib/services/scoring_service.dart`** — cleared to a minimal stub. Has the correct public interface (`ScoringService.score(...)` returning `ScoringResult`) so the app compiles and runs, but returns all 1s.

```dart
static ScoringResult score({
  required List<StrokeData> userStrokes,
  required LetterTemplate template,
  required Size canvasSize,
  required GuidelineMode guidelineMode,
  required Difficulty difficulty,
})
```

### Test files (CLEARED)
- **`test/scoring_test.dart`** — empty `main()`, ready for Step 1 tests
- **`test/scoring_edge_cases_q_test.dart`** — empty `main()`, for later

### Available services (NOT imported, ready to use)
- **`lib/services/point_resampling.dart`** — `resampleEquidistant(List<Offset> points, int n)` → resamples a polyline to N equidistant points via arc-length interpolation. Proven, well-tested.
- **`lib/services/stroke_matching_service.dart`** — `StrokeMatchingService.alignAndConcatenate(templateStrokes, userStrokes)` → greedy centroid matching to reorder user strokes to match template order, then concatenates both into single paths. Proven.
- **`lib/services/bitmap_comparison_service.dart`** — `BitmapComparisonService.compare(alignedTemplate, alignedUser, difficulty)` → renders both paths at same thickness on 64×64 grid, returns IoU. The service itself works; the problem was how its output was used in the scoring formula.

### Models (UNCHANGED)
- **`ScoringResult`** — `shapeScore`, `placementScore`, `thirdScore`, `thirdScoreLabel`, `combinedScore`, `feedbackMessage`, `rawErrors`
- **`LetterTemplate`** — `letter`, `isUppercase`, `strokes: List<List<Offset>>` (template-space points)
- **`StrokeData`** — `points: List<PointVector>`, `width`, `simulatePressure`
- **`GuidelineMetrics`** — coordinate conversion between template space and canvas pixels

### App state enums
```dart
enum Difficulty { beginner, intermediate, advanced }
enum GuidelineMode { full, baselineOnly }
enum InputMode { finger, stylus }
enum LetterCase { lowercase, uppercase }
```

---

## 5. Coordinate system

**Template space** (y-up): x ∈ [0,1], y ∈ [0,1]
```
y = 0.00  descender line
y = 0.25  baseline
y = 0.55  x-height
y = 0.75  cap height
y = 0.85  ascender line
```

**Canvas space** (y-down): pixels, (0,0) = top-left
```
canvasY = (0.05 + (1.0 - templateY) × 0.90) × canvasHeight
templateY = 1.0 - (canvasY / canvasHeight - 0.05) / 0.90
```

5% padding top and bottom, 90% active writing zone.

`GuidelineMetrics(canvasSize)` provides `templateToCanvas(Offset)` and `canvasToTemplate(Offset)`.

---

## 6. Difficulty thresholds (current)

Used for placement, proportion, and size scoring (NOT for shape — shape needs its own thresholds derived from real data):

```dart
const Map<String, List<(double, int)>> kDifficultyThresholds = {
  'beginner':     [(0.08, 10), (0.12, 9), (0.20, 7), (0.30, 5), (0.45, 3), (inf, 1)],
  'intermediate': [(0.05, 10), (0.08, 9), (0.14, 7), (0.22, 5), (0.35, 3), (inf, 1)],
  'advanced':     [(0.03, 10), (0.05, 9), (0.09, 7), (0.15, 5), (0.25, 3), (inf, 1)],
};
```

There is also a `kShapeDifficultyThresholds` in constants.dart from a previous iteration — **ignore it**. Shape thresholds must be derived from real Procrustes distances observed in Step 1.

---

## 7. Procrustes algorithm reference

This is the algorithm that was proven to work correctly in isolation. It should be re-implemented (or ported from the previous code) in Step 1.

**Input**: two lists of N equidistant points (template and user, both resampled to N=64)

**Steps**:
1. Compute centroids of both point sets
2. Translate both to origin (subtract centroids)
3. Compute Frobenius norms: `norm = sqrt(Σ(x² + y²))`
4. Record scale factor: `scaleFactor = userNorm / templateNorm`
5. Scale both to unit norm (divide each point by its set's norm)
6. Find optimal rotation: `θ = atan2(Σ(u×t), Σ(u·t))` where × is 2D cross product, · is dot product
7. Rotate user points by θ
8. Try reversed user path, pick whichever gives lower residual
9. Compute residual: average Euclidean distance between corresponding aligned points

**Output**: residual distance (0 = identical shape), scale factor, rotation angle, aligned point sets

**Key property**: the residual is invariant to translation, scale, and rotation of the input. A letter drawn anywhere, at any size, slightly tilted, produces the same residual as one drawn on the template.

---

## 8. What the test canvas looks like for testing

```dart
const _canvasSize = Size(300, 360); // 1:1.2 ratio

// Convert template-space → canvas-space for test input
Offset _templateToCanvas(Offset t) {
  const pad = 0.05;
  const zone = 0.90;
  return Offset(
    t.dx * 300,
    (pad + (1.0 - t.dy) * zone) * 360,
  );
}

// Generate a perfect drawing from a template
List<StrokeData> _perfectDrawing(String letter, {bool uppercase = false}) {
  final template = lookupTemplate(letter, uppercase: uppercase)!;
  return template.strokes.map((stroke) {
    final canvasPoints = stroke.map((p) => _templateToCanvas(p)).toList();
    return _stroke(canvasPoints);
  }).toList();
}
```

Helper functions for degrading input: `_shiftDrawing(strokes, dx, dy)`, `_scaleDrawing(strokes, factor)`, `_addNoise(strokes, maxPixels)`.

---

## 9. Key files and their locations

```
lib/
  app_state.dart                    — enums + ChangeNotifier
  main.dart                         — routes, Provider setup, portrait lock
  data/
    letter_templates.dart           — all 30 templates as List<List<Offset>>
  models/
    guideline_metrics.dart          — coordinate conversion
    letter_template.dart            — LetterTemplate model
    scoring_result.dart             — ScoringResult model
    stroke_data.dart                — StrokeData model
  services/
    bitmap_comparison_service.dart  — IoU bitmap comparison (available, not imported)
    point_resampling.dart           — equidistant resampling (available, not imported)
    scoring_service.dart            — STUB — rebuild target
    stroke_matching_service.dart    — multi-stroke matching (available, not imported)
    trace_feedback_service.dart     — real-time trace colouring
  screens/
    home_screen.dart                — settings toggles
    letter_picker_screen.dart       — letter grid
    trace_screen.dart               — trace mode (working)
    recall_screen.dart              — recall mode (working, calls ScoringService)
    score_screen.dart               — animated score display (working)
    template_capture_screen.dart    — debug utility
  utils/
    constants.dart                  — all constants and thresholds
  widgets/
    drawing_canvas.dart             — DrawingCanvasController + DrawingCanvas
    guideline_painter.dart          — 4-line / baseline-only guidelines
    stroke_painter.dart             — renders strokes via perfect_freehand
    template_painter.dart           — renders template letter
    trace_stroke_painter.dart       — colour-coded trace strokes
test/
  scoring_test.dart                 — CLEARED — write Step 1 tests here
  scoring_edge_cases_q_test.dart    — CLEARED — for later
  widget_test.dart                  — basic HomeScreen test (passing)
```

---

## 10. Commands

```bash
cd "/Users/home/Development/Flutter Projects/Handwriting MVP/handwriting_mvp"
flutter analyze    # zero issues currently
flutter test       # 1 test passing (widget test)
flutter run        # runs on connected device/emulator
```

---

## 11. Critical rules for the rebuild

1. **Tests first**. Write the test that defines the behaviour, then write the code to pass it.
2. **Diagnostic logging**. Every scoring call should `debugPrint` the raw values (Procrustes distance, IoU, etc.) so the user can verify on-device before trusting the numbers.
3. **One component at a time**. Do not add bitmap IoU until Procrustes is verified. Do not add placement until shape is verified.
4. **Calibrate from data, not theory**. After implementing Procrustes, the user will draw real letters and share the console output. Set thresholds from those observed values.
5. **Do not use the old `kShapeDifficultyThresholds`**. They were guessed, not measured.
6. **The public interface must not change**. `ScoringService.score(...)` returns `ScoringResult`. Screens depend on this.
7. **The scoring service is the only file being rebuilt**. All other files (screens, widgets, models, templates) are working and must not be modified.

---

## 12. How to start the new chat

Paste this document and say:

> "I need to rebuild the shape scoring for this handwriting app using TDD. Start with Step 1: write the Procrustes shape tests first, then implement the code to pass them. Include diagnostic logging that prints raw values to the console."
