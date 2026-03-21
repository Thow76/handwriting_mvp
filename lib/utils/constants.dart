import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Stroke width presets
// ---------------------------------------------------------------------------

/// Finger widths — wider to compensate for imprecise touch contact area.
const List<double> kFingerWidths = [5.0, 7.0, 9.0];

/// Stylus widths — finer for precision input.
const List<double> kStylusWidths = [1.5, 2.5, 3.5];

// ---------------------------------------------------------------------------
// Drawing canvas
// ---------------------------------------------------------------------------

/// Aspect ratio of the drawing zone (width : height).
const double kCanvasAspectRatio = 1 / 1.2;

/// Colour used to render the user's strokes.
const Color kStrokeColor = Color(0xFF1A1A2E);

// ---------------------------------------------------------------------------
// Template coordinate space  (y-UP: 0 = descender, 1 = top of zone)
// ---------------------------------------------------------------------------
// All letter template points are stored in this space.
// x: 0.0 (left edge) → 1.0 (right edge)
// y: 0.0 (descender line) → 1.0 (top of drawing zone)
//
// Key y-positions for the four writing lines:
const double kTemplateDescender = 0.00;
const double kTemplateBaseline  = 0.25;
const double kTemplateXHeight   = 0.55;
const double kTemplateCapHeight = 0.75;
const double kTemplateAscender  = 0.85;

// Padding above and below the writing zone (fraction of canvas height).
const double kCanvasPad = 0.05;  // 5% top, 5% bottom → zone spans 0.05–0.95

// ---------------------------------------------------------------------------
// Guideline Y-positions on canvas (normalised 0–1, 0 = top of canvas)
// ---------------------------------------------------------------------------
// Derived from template space via: canvasNorm = kCanvasPad + (1−ty)×0.90
// These are provided for reference; painters use GuidelineMetrics directly.
const double kNormAscender   = 0.185; // 0.05 + (1−0.85)×0.90
const double kNormCapHeight  = 0.275; // 0.05 + (1−0.75)×0.90
const double kNormXHeight    = 0.455; // 0.05 + (1−0.55)×0.90
const double kNormBaseline   = 0.725; // 0.05 + (1−0.25)×0.90
const double kNormDescender  = 0.950; // 0.05 + (1−0.00)×0.90

// ---------------------------------------------------------------------------
// Guideline colours
// ---------------------------------------------------------------------------

const Color kBaselineColor  = Color(0xFF1565C0); // solid blue
const Color kXHeightColor   = Color(0xFF42A5F5); // lighter blue
const Color kGuidelineColor = Color(0xFFBBDEFB); // dashed pale blue

// ---------------------------------------------------------------------------
// Recall mode
// ---------------------------------------------------------------------------

/// How long the letter is shown before the canvas appears (milliseconds).
const int kPreviewDurationMs = 3000;

// ---------------------------------------------------------------------------
// Scoring difficulty thresholds
// Raw error (0.0 = perfect) → score (10 = best)
// ---------------------------------------------------------------------------

/// Map of difficulty → list of (maxError, score) pairs, checked top to bottom.
const Map<String, List<(double, int)>> kDifficultyThresholds = {
  'beginner': [
    (0.08, 10),
    (0.12, 9),
    (0.20, 7),
    (0.30, 5),
    (0.45, 3),
    (double.infinity, 1),
  ],
  'intermediate': [
    (0.05, 10),
    (0.08, 9),
    (0.14, 7),
    (0.22, 5),
    (0.35, 3),
    (double.infinity, 1),
  ],
  'advanced': [
    (0.03, 10),
    (0.05, 9),
    (0.09, 7),
    (0.15, 5),
    (0.25, 3),
    (double.infinity, 1),
  ],
};

// ---------------------------------------------------------------------------
// Trace mode
// ---------------------------------------------------------------------------

/// Template tolerance zone widths for trace mode (canvas pixels).
/// These control how wide the template guide appears and how forgiving the
/// green/orange/red zones are.  Wider = easier for the learner.
const List<double> kFingerTemplateWidths = [20.0, 28.0, 36.0];
const List<double> kStylusTemplateWidths = [12.0, 18.0, 24.0];

// Trace feedback colours
const Color kTraceOnColor    = Color(0xFF2E7D32); // green  — within half-width
const Color kTraceNearColor  = Color(0xFFF57F17); // amber  — within full-width
const Color kTraceOffColor   = Color(0xFFC62828); // red    — outside template
