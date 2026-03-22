# Handwriting MVP — Context Handoff

**Date:** 2026-03-21
**Status:** All 8 phases complete. 121/121 tests passing. 0 analyzer issues.
**Working directory:** `/Users/home/Development/Flutter Projects/Handwriting MVP/handwriting_mvp`

---

## What This App Is

A Flutter proof-of-concept for ESOL learners with non-Roman script backgrounds to practise Roman letter formation. Portrait-only, Android/iOS, no login, no network.

**Two modes:**
- **Trace** — template letter visible; user draws over it; strokes colour-coded green/orange/red in real time based on proximity to template. No score.
- **Recall** — 3-second preview countdown, then template hidden; user draws from memory; scored across 3 categories (Shape, Placement, Proportion or Size).

**15 letters in both cases:** a, b, d, e, f, g, h, j, k, l, m, p, q, t, y (30 templates total).

---

## How to Run

```bash
cd "/Users/home/Development/Flutter Projects/Handwriting MVP/handwriting_mvp"
flutter run                     # run on connected device/emulator
flutter test                    # run all 121 tests
flutter analyze --no-pub        # static analysis (should be 0 issues)
```

---

## Complete File Structure

```
lib/
├── main.dart                        # App entry, portrait lock, Provider, routes
├── app_state.dart                   # ChangeNotifier: letterCase, inputMode,
│                                    # difficulty, guidelineMode, widthPresetIndex
│
├── models/
│   ├── letter_template.dart         # LetterTemplate(letter, isUppercase, strokes)
│   │                                # key getter: 'a_lower' / 'a_upper'
│   ├── stroke_data.dart             # StrokeData(points: List<PointVector>, width,
│   │                                # simulatePressure)
│   ├── scoring_result.dart          # ScoringResult(shapeScore, placementScore,
│   │                                # thirdScore, thirdScoreLabel, combinedScore,
│   │                                # feedbackMessage, rawErrors)
│   │                                # static messageForScore(int) → String
│   └── guideline_metrics.dart       # GuidelineMetrics(canvasSize)
│                                    # templateToCanvas(Offset) / canvasToTemplate(Offset)
│                                    # ascenderY, capHeightY, xHeightY, baselineY, descenderY
│
├── data/
│   └── letter_templates.dart        # kLetterTemplates map + lookupTemplate()
│                                    # All 30 templates hand-crafted in template space
│
├── services/
│   ├── scoring_service.dart         # ScoringService.score(...) → ScoringResult
│   │                                # Procrustes + Fréchet for shape
│   │                                # Bounding-box for placement
│   │                                # Aspect ratio + zone for proportion (full guidelines)
│   │                                # Scale factor for size (baseline-only)
│   ├── stroke_matching_service.dart # alignAndConcatenate() — greedy centroid matching
│   │                                # for multi-stroke letters
│   ├── point_resampling.dart        # resampleEquidistant(points, n) — arc-length interp
│   └── trace_feedback_service.dart  # TraceFeedbackService.classify(Offset) → TraceZone
│                                    # on / near / off based on distance to template segments
│
├── screens/
│   ├── home_screen.dart             # Mode buttons + settings panel (all toggles wired)
│   ├── letter_picker_screen.dart    # 5×3 grid; always passes lowercase key to routes
│   ├── trace_screen.dart            # GuidelinePainter → TemplatePainter → DrawingCanvas
│   │                                # with TraceStrokePainter injected via painterBuilder
│   ├── recall_screen.dart           # 4-phase state machine:
│   │                                #   preview (3s countdown) → drawing → scoring → results
│   │                                # Navigates to /score with {result, letter, uppercase}
│   ├── score_screen.dart            # Animated score screen (900ms ease-out)
│   │                                # Count-up combined score + staggered bar sweep-in
│   │                                # Try Again → /recall | Choose Another → /letter-picker
│   └── template_capture_screen.dart # Debug utility: draw a letter → copy Dart literal
│
├── widgets/
│   ├── drawing_canvas.dart          # DrawingCanvasController (ChangeNotifier)
│   │                                # manages _strokes, _currentPoints; undo/clear
│   │                                # DrawingCanvas widget: Listener → CustomPaint
│   │                                # Uses foregroundPainter (critical — strokes on top)
│   │                                # Optional painterBuilder for custom painters
│   ├── stroke_painter.dart          # StrokePainter — renders via perfect_freehand
│   ├── trace_stroke_painter.dart    # TraceStrokePainter — splits strokes into
│   │                                # same-colour runs; thinning:0 + 1-pt overlap at boundaries
│   ├── guideline_painter.dart       # GuidelinePainter — 4-line or baseline-only
│   │                                # dashed ascender/descender, solid baseline/x-height
│   └── template_painter.dart        # TemplatePainter — smooth quadratic Bézier
│                                    # through template control points
│
└── utils/
    └── constants.dart               # Width presets, canvas constants, template y-positions,
                                     # guideline colours, trace colours,
                                     # kDifficultyThresholds map

test/
├── scoring_test.dart                # 105 scoring tests across 9 groups
└── widget_test.dart                 # HomeScreen widget tests
```

---

## Coordinate System (Critical)

Templates are stored in **template space** (y-up):
- x: 0.0 (left) → 1.0 (right)
- y: 0.0 (descender) → 1.0 (top of zone)

Key y-positions in template space:
```
kTemplateDescender = 0.00
kTemplateBaseline  = 0.25
kTemplateXHeight   = 0.55
kTemplateCapHeight = 0.75
kTemplateAscender  = 0.85
```

**Canvas conversion** (y-down, 5% padding each side):
```dart
canvasY = (0.05 + (1.0 - templateY) * 0.90) * canvasHeight
canvasX = templateX * canvasWidth
```

`GuidelineMetrics` handles both directions. All scoring happens in template space — user canvas strokes are converted before any analysis.

---

## Scoring Pipeline

```
UserStrokes (canvas px)
  → canvasToTemplate() per point
  → StrokeMatchingService.alignAndConcatenate()   // greedy centroid reorder + concat
  → resampleEquidistant(N=64)                     // arc-length normalisation
  → _procrustes()                                 // translate + scale + rotate; tries
                                                  // forward and reversed path, picks best
  → _discreteFrechet()                            // 64×64 DP table
  → shapeError = 0.6 × procrustes + 0.4 × fréchet
  → _placementError()                             // bounding-box top/bottom vs template
  → _proportionError() OR _sizeError()            // based on GuidelineMode
  → _errorToScore(error, difficulty)              // kDifficultyThresholds lookup
  → ScoringResult
```

**Difficulty thresholds** (`kDifficultyThresholds` in `constants.dart`):

| Score | Beginner | Intermediate | Advanced |
|-------|----------|--------------|----------|
| 10    | < 0.08   | < 0.05       | < 0.03   |
| 9     | < 0.12   | < 0.08       | < 0.05   |
| 7     | < 0.20   | < 0.14       | < 0.09   |
| 5     | < 0.30   | < 0.22       | < 0.15   |
| 3     | < 0.45   | < 0.35       | < 0.25   |
| 1     | ≥ 0.45   | ≥ 0.35       | ≥ 0.25   |

---

## App State (AppState via Provider)

```dart
enum LetterCase   { lowercase, uppercase }
enum InputMode    { finger, stylus }
enum Difficulty   { beginner, intermediate, advanced }
enum GuidelineMode{ full, baselineOnly }

// Stored in AppState ChangeNotifier:
LetterCase letterCase      // default: lowercase
InputMode inputMode        // default: finger
Difficulty difficulty      // default: beginner
GuidelineMode guidelineMode// default: full
int widthPresetIndex       // 0=S, 1=M, 2=L (default: 1)
```

**Width presets:**
- Finger: `[5.0, 7.0, 9.0]` dp
- Stylus: `[1.5, 2.5, 3.5]` dp
- Template tolerance (trace): Finger `[20.0, 28.0, 36.0]`, Stylus `[12.0, 18.0, 24.0]` px

---

## Route Map

```
/               → HomeScreen
/letter-picker  → LetterPickerScreen  (args: String mode = 'trace' | 'recall')
/trace          → TraceScreen         (args: String letter — always lowercase key e.g. 'a')
/recall         → RecallScreen        (args: String letter — always lowercase key)
/score          → ScoreScreen         (args: Map{'result': ScoringResult,
                                                  'letter': String lowercase,
                                                  'uppercase': bool})
/capture        → TemplateCaptureScreen (debug utility, no args)
```

**Navigation conventions:**
- Letter picker always passes lowercase key ('a', not 'A'); screens derive display form from AppState.
- ScoreScreen "Try Again" → `pushReplacementNamed('/recall', arguments: letter)`
- ScoreScreen "Choose Another Letter" → `pushNamedAndRemoveUntil('/letter-picker', withName('/'), arguments: 'recall')`

---

## DrawingCanvas Architecture

```
Listener (PointerDown/Move/Up/Cancel)
  → DrawingCanvasController._startStroke / _addPoint / _endStroke
  → notifyListeners()
  → AnimatedBuilder rebuilds
  → CustomPaint(foregroundPainter: ...)   ← foregroundPainter, NOT painter
                                            so strokes render above child layers
```

**painterBuilder** — optional `StrokePainterBuilder` typedef:
```dart
typedef StrokePainterBuilder = CustomPainter Function({
  required List<StrokeData> completedStrokes,
  required List<PointVector>? currentPoints,
  required double currentWidth,
  required bool currentSimulatePressure,
});
```
Trace mode injects `TraceStrokePainter` via this parameter.

---

## Trace Feedback

`TraceFeedbackService.classify(canvasPoint)` returns `TraceZone`:
- `on` (green) — within `templateWidth / 2` of nearest template segment
- `near` (amber) — within `templateWidth`
- `off` (red) — beyond

`TraceStrokePainter` splits each stroke into contiguous same-colour runs.
Uses `thinning: 0.0` and 1-point overlap at colour boundaries to prevent gaps.

---

## Recall Screen State Machine

```
_Phase.preview   → 3s countdown, template visible, IgnorePointer on canvas
_Phase.drawing   → template hidden, guidelines visible, DrawingCanvas accepts input
_Phase.scoring   → ScoringService.score() called synchronously (<1ms)
                   IgnorePointer on canvas
_Phase.results   → 300ms delay then pushReplacementNamed to /score
```

---

## Score Screen Animation

`StatefulWidget` with `AnimationController(duration: 900ms)`.
Animations initialised in `didChangeDependencies()` once route args available:

- Combined score: `IntTween(0 → N).animate(easeOut)`
- Shape bar: `Interval(0.0, 0.75)`
- Placement bar: `Interval(0.1, 0.85)`
- Third bar: `Interval(0.2, 1.0)`
- Feedback message: `AnimatedOpacity` fades in when `controller.value > 0.6`

Score colours: green ≥9, blue ≥7, orange ≥5, red ≤4.

---

## Test Coverage

**121 tests, 0 failures:**

| Group | Tests |
|-------|-------|
| Point resampling | 3 |
| Stroke matching | 2 |
| Scoring — perfect match | 2 |
| Scoring — degraded input | 3 |
| Difficulty levels | 1 |
| Feedback messages | 1 |
| Multi-stroke letters | 2 |
| Edge cases | 1 |
| All 30 templates exist | 30 |
| All 30 — perfect scores 10 | 30 |
| All 30 — noisy scores valid | 30 |
| Difficulty ordering (15 letters) | 15 |
| HomeScreen widget tests | 1 |

---

## Known Limitations / Potential Next Steps

1. **Threshold calibration** — the `kDifficultyThresholds` values were set analytically. Real-device testing with actual learners may need retuning, especially the Procrustes + Fréchet combination weights (0.6 / 0.4).

2. **Template quality** — templates were hand-crafted as stroke centrelines. A capture session using the `/capture` route on a real device would produce higher-fidelity templates.

3. **Stylus pressure** — real pressure values are normalised but not tested on physical stylus hardware. Some devices report 0.0 on first contact (handled with 0.05 clamp).

4. **Multi-stroke letter order** — greedy centroid matching works well for letters with spatially distinct strokes (t, f, uppercase letters). Letters where strokes have very similar centroids could potentially mis-match.

5. **ML Kit identity check** — the plan included an optional letter-identity sanity check ("did they draw the right letter?") using `google_mlkit_digital_ink_recognition`. This was deferred as optional for the MVP.

6. **No persistence** — scores are not saved between sessions. A future iteration could add SQLite or Hive for session history.

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  perfect_freehand: ^2.5.2   # pressure-aware stroke rendering
  provider: ^6.1.0            # state management

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```
