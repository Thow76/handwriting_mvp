import 'dart:ui';

import '../models/letter_template.dart';

// ---------------------------------------------------------------------------
// All 30 letter templates: 15 lowercase + 15 uppercase.
//
// Coordinate space (template space):
//   x: 0.0 (left) → 1.0 (right)
//   y: 0.0 (descender line) → 1.0 (top of drawing zone)
//   Baseline = 0.25,  X-height = 0.55,  Cap-height = 0.75,  Ascender = 0.85
//
// Letters: a, b, d, e, f, g, h, j, k, l, m, p, q, t, y
// ---------------------------------------------------------------------------

/// Master map keyed by `letter_lower` or `letter_upper`.
final Map<String, LetterTemplate> kLetterTemplates = {
  for (final t in _allTemplates) t.key: t,
};

/// Convenience lookup.
LetterTemplate? lookupTemplate(String letter, {required bool uppercase}) {
  final key = '${letter.toLowerCase()}_${uppercase ? "upper" : "lower"}';
  return kLetterTemplates[key];
}

// ---------------------------------------------------------------------------
// LOWERCASE TEMPLATES
// ---------------------------------------------------------------------------

final List<LetterTemplate> _allTemplates = [
  // ==== a (lowercase) — single-story: circle + right stem ====
  LetterTemplate(
    letter: 'a',
    isUppercase: false,
    strokes: [
      [
        const Offset(0.68, 0.40),
        const Offset(0.64, 0.52),
        const Offset(0.52, 0.57),
        const Offset(0.38, 0.56),
        const Offset(0.26, 0.50),
        const Offset(0.22, 0.40),
        const Offset(0.26, 0.30),
        const Offset(0.38, 0.25),
        const Offset(0.52, 0.26),
        const Offset(0.64, 0.32),
        const Offset(0.68, 0.40),
        const Offset(0.68, 0.25),
      ],
    ],
  ),

  // ==== b (lowercase) — tall stem + right bowl ====
  LetterTemplate(
    letter: 'b',
    isUppercase: false,
    strokes: [
      // Stem
      [const Offset(0.30, 0.85), const Offset(0.30, 0.25)],
      // Bowl
      [
        const Offset(0.30, 0.53),
        const Offset(0.38, 0.57),
        const Offset(0.52, 0.56),
        const Offset(0.64, 0.50),
        const Offset(0.68, 0.40),
        const Offset(0.64, 0.30),
        const Offset(0.52, 0.25),
        const Offset(0.38, 0.25),
        const Offset(0.30, 0.28),
      ],
    ],
  ),

  // ==== d (lowercase) — circle + tall right stem ====
  LetterTemplate(
    letter: 'd',
    isUppercase: false,
    strokes: [
      // Circle
      [
        const Offset(0.65, 0.40),
        const Offset(0.60, 0.52),
        const Offset(0.48, 0.57),
        const Offset(0.36, 0.55),
        const Offset(0.26, 0.48),
        const Offset(0.22, 0.40),
        const Offset(0.26, 0.30),
        const Offset(0.36, 0.25),
        const Offset(0.50, 0.25),
        const Offset(0.60, 0.30),
        const Offset(0.65, 0.38),
      ],
      // Tall stem
      [const Offset(0.65, 0.85), const Offset(0.65, 0.25)],
    ],
  ),

  // ==== e (lowercase) — cross-bar + open arc ====
  LetterTemplate(
    letter: 'e',
    isUppercase: false,
    strokes: [
      [
        const Offset(0.22, 0.42),
        const Offset(0.68, 0.42),
        const Offset(0.68, 0.50),
        const Offset(0.62, 0.56),
        const Offset(0.48, 0.58),
        const Offset(0.34, 0.56),
        const Offset(0.22, 0.50),
        const Offset(0.22, 0.34),
        const Offset(0.32, 0.26),
        const Offset(0.48, 0.24),
        const Offset(0.62, 0.28),
        const Offset(0.68, 0.34),
      ],
    ],
  ),

  // ==== f (lowercase) — hook top + stem + crossbar ====
  LetterTemplate(
    letter: 'f',
    isUppercase: false,
    strokes: [
      // Hook curving left then stem down
      [
        const Offset(0.62, 0.82),
        const Offset(0.56, 0.85),
        const Offset(0.48, 0.84),
        const Offset(0.42, 0.78),
        const Offset(0.42, 0.25),
      ],
      // Crossbar at x-height
      [const Offset(0.25, 0.55), const Offset(0.60, 0.55)],
    ],
  ),

  // ==== g (lowercase) — circle + descending tail ====
  LetterTemplate(
    letter: 'g',
    isUppercase: false,
    strokes: [
      // Circle body
      [
        const Offset(0.68, 0.40),
        const Offset(0.64, 0.52),
        const Offset(0.52, 0.57),
        const Offset(0.38, 0.56),
        const Offset(0.26, 0.50),
        const Offset(0.22, 0.40),
        const Offset(0.26, 0.30),
        const Offset(0.38, 0.25),
        const Offset(0.52, 0.26),
        const Offset(0.64, 0.32),
        const Offset(0.68, 0.40),
      ],
      // Descending tail
      [
        const Offset(0.68, 0.55),
        const Offset(0.68, 0.15),
        const Offset(0.62, 0.06),
        const Offset(0.48, 0.02),
        const Offset(0.34, 0.05),
        const Offset(0.28, 0.12),
      ],
    ],
  ),

  // ==== h (lowercase) — tall stem + right hump ====
  LetterTemplate(
    letter: 'h',
    isUppercase: false,
    strokes: [
      // Tall stem
      [const Offset(0.28, 0.85), const Offset(0.28, 0.25)],
      // Hump from mid-stem going right and down
      [
        const Offset(0.28, 0.48),
        const Offset(0.36, 0.56),
        const Offset(0.48, 0.57),
        const Offset(0.58, 0.52),
        const Offset(0.65, 0.44),
        const Offset(0.68, 0.25),
      ],
    ],
  ),

  // ==== j (lowercase) — dot + descending stem with hook ====
  LetterTemplate(
    letter: 'j',
    isUppercase: false,
    strokes: [
      // Dot above x-height
      [const Offset(0.50, 0.65), const Offset(0.50, 0.63)],
      // Stem from x-height to descender with leftward hook
      [
        const Offset(0.50, 0.55),
        const Offset(0.50, 0.12),
        const Offset(0.45, 0.05),
        const Offset(0.36, 0.02),
        const Offset(0.28, 0.05),
      ],
    ],
  ),

  // ==== k (lowercase) — tall stem + two diagonals ====
  LetterTemplate(
    letter: 'k',
    isUppercase: false,
    strokes: [
      // Tall stem
      [const Offset(0.28, 0.85), const Offset(0.28, 0.25)],
      // Upper diagonal (from upper-right to mid-stem)
      [const Offset(0.68, 0.55), const Offset(0.42, 0.42), const Offset(0.28, 0.40)],
      // Lower diagonal (from mid-stem to lower-right)
      [const Offset(0.35, 0.40), const Offset(0.50, 0.32), const Offset(0.68, 0.25)],
    ],
  ),

  // ==== l (lowercase) — simple tall stem ====
  LetterTemplate(
    letter: 'l',
    isUppercase: false,
    strokes: [
      [const Offset(0.45, 0.85), const Offset(0.45, 0.25)],
    ],
  ),

  // ==== m (lowercase) — left stem + two humps ====
  LetterTemplate(
    letter: 'm',
    isUppercase: false,
    strokes: [
      // Left stem
      [const Offset(0.12, 0.55), const Offset(0.12, 0.25)],
      // First hump
      [
        const Offset(0.12, 0.48),
        const Offset(0.20, 0.56),
        const Offset(0.30, 0.56),
        const Offset(0.38, 0.48),
        const Offset(0.42, 0.25),
      ],
      // Second hump
      [
        const Offset(0.42, 0.48),
        const Offset(0.52, 0.56),
        const Offset(0.64, 0.56),
        const Offset(0.74, 0.48),
        const Offset(0.80, 0.25),
      ],
    ],
  ),

  // ==== p (lowercase) — descending stem + right bowl ====
  LetterTemplate(
    letter: 'p',
    isUppercase: false,
    strokes: [
      // Stem from x-height to descender
      [const Offset(0.28, 0.55), const Offset(0.28, 0.02)],
      // Right bowl
      [
        const Offset(0.28, 0.53),
        const Offset(0.38, 0.57),
        const Offset(0.52, 0.56),
        const Offset(0.64, 0.48),
        const Offset(0.68, 0.40),
        const Offset(0.64, 0.30),
        const Offset(0.52, 0.25),
        const Offset(0.38, 0.25),
        const Offset(0.28, 0.28),
      ],
    ],
  ),

  // ==== q (lowercase) — circle + descending right stem ====
  LetterTemplate(
    letter: 'q',
    isUppercase: false,
    strokes: [
      // Circle
      [
        const Offset(0.62, 0.40),
        const Offset(0.56, 0.52),
        const Offset(0.44, 0.57),
        const Offset(0.32, 0.54),
        const Offset(0.24, 0.46),
        const Offset(0.22, 0.40),
        const Offset(0.24, 0.32),
        const Offset(0.34, 0.25),
        const Offset(0.48, 0.25),
        const Offset(0.58, 0.30),
        const Offset(0.62, 0.38),
      ],
      // Descending right stem
      [const Offset(0.64, 0.55), const Offset(0.64, 0.02)],
    ],
  ),

  // ==== t (lowercase) — short stem + crossbar ====
  LetterTemplate(
    letter: 't',
    isUppercase: false,
    strokes: [
      // Stem (shorter than ascender — starts at ~0.72)
      [const Offset(0.45, 0.72), const Offset(0.45, 0.25)],
      // Crossbar at x-height
      [const Offset(0.28, 0.55), const Offset(0.65, 0.55)],
    ],
  ),

  // ==== y (lowercase) — left arm + right arm descending ====
  LetterTemplate(
    letter: 'y',
    isUppercase: false,
    strokes: [
      // Left arm: x-height down to centre
      [const Offset(0.20, 0.55), const Offset(0.38, 0.35), const Offset(0.45, 0.28)],
      // Right arm: x-height down through centre to descender
      [
        const Offset(0.72, 0.55),
        const Offset(0.58, 0.38),
        const Offset(0.45, 0.28),
        const Offset(0.38, 0.14),
        const Offset(0.30, 0.05),
        const Offset(0.22, 0.02),
      ],
    ],
  ),

  // =========================================================================
  // UPPERCASE TEMPLATES — sit between baseline (0.25) and cap-height (0.75)
  // =========================================================================

  // ==== A (uppercase) — two diagonals + crossbar ====
  LetterTemplate(
    letter: 'a',
    isUppercase: true,
    strokes: [
      // Left diagonal
      [const Offset(0.15, 0.25), const Offset(0.45, 0.75)],
      // Right diagonal
      [const Offset(0.45, 0.75), const Offset(0.75, 0.25)],
      // Crossbar
      [const Offset(0.27, 0.45), const Offset(0.63, 0.45)],
    ],
  ),

  // ==== B (uppercase) — stem + upper bump + lower bump ====
  LetterTemplate(
    letter: 'b',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Upper bump
      [
        const Offset(0.22, 0.75),
        const Offset(0.42, 0.76),
        const Offset(0.58, 0.70),
        const Offset(0.62, 0.60),
        const Offset(0.58, 0.52),
        const Offset(0.40, 0.50),
        const Offset(0.22, 0.50),
      ],
      // Lower bump (slightly wider)
      [
        const Offset(0.22, 0.50),
        const Offset(0.42, 0.50),
        const Offset(0.62, 0.44),
        const Offset(0.66, 0.38),
        const Offset(0.62, 0.30),
        const Offset(0.42, 0.25),
        const Offset(0.22, 0.25),
      ],
    ],
  ),

  // ==== D (uppercase) — stem + large curve ====
  LetterTemplate(
    letter: 'd',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Large curve
      [
        const Offset(0.22, 0.75),
        const Offset(0.42, 0.76),
        const Offset(0.62, 0.68),
        const Offset(0.72, 0.55),
        const Offset(0.72, 0.45),
        const Offset(0.62, 0.32),
        const Offset(0.42, 0.25),
        const Offset(0.22, 0.25),
      ],
    ],
  ),

  // ==== E (uppercase) — stem + three horizontals ====
  LetterTemplate(
    letter: 'e',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Top horizontal
      [const Offset(0.22, 0.75), const Offset(0.68, 0.75)],
      // Middle horizontal
      [const Offset(0.22, 0.50), const Offset(0.58, 0.50)],
      // Bottom horizontal
      [const Offset(0.22, 0.25), const Offset(0.68, 0.25)],
    ],
  ),

  // ==== F (uppercase) — stem + two horizontals ====
  LetterTemplate(
    letter: 'f',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Top horizontal
      [const Offset(0.22, 0.75), const Offset(0.68, 0.75)],
      // Middle horizontal
      [const Offset(0.22, 0.50), const Offset(0.58, 0.50)],
    ],
  ),

  // ==== G (uppercase) — C-arc + inward horizontal ====
  LetterTemplate(
    letter: 'g',
    isUppercase: true,
    strokes: [
      // C-arc from top-right, counterclockwise to bottom-right
      [
        const Offset(0.68, 0.65),
        const Offset(0.58, 0.74),
        const Offset(0.42, 0.76),
        const Offset(0.26, 0.70),
        const Offset(0.18, 0.58),
        const Offset(0.16, 0.50),
        const Offset(0.18, 0.40),
        const Offset(0.26, 0.30),
        const Offset(0.42, 0.25),
        const Offset(0.58, 0.27),
        const Offset(0.68, 0.35),
        const Offset(0.68, 0.50),
      ],
      // Inward horizontal bar
      [const Offset(0.68, 0.50), const Offset(0.48, 0.50)],
    ],
  ),

  // ==== H (uppercase) — two stems + crossbar ====
  LetterTemplate(
    letter: 'h',
    isUppercase: true,
    strokes: [
      // Left stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Right stem
      [const Offset(0.68, 0.75), const Offset(0.68, 0.25)],
      // Crossbar
      [const Offset(0.22, 0.50), const Offset(0.68, 0.50)],
    ],
  ),

  // ==== J (uppercase) — stem curving left at bottom ====
  LetterTemplate(
    letter: 'j',
    isUppercase: true,
    strokes: [
      [
        const Offset(0.58, 0.75),
        const Offset(0.58, 0.38),
        const Offset(0.54, 0.30),
        const Offset(0.45, 0.25),
        const Offset(0.35, 0.27),
        const Offset(0.28, 0.34),
      ],
    ],
  ),

  // ==== K (uppercase) — stem + two diagonals ====
  LetterTemplate(
    letter: 'k',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Upper diagonal (right-top to mid-stem)
      [const Offset(0.68, 0.75), const Offset(0.22, 0.50)],
      // Lower diagonal (mid-stem to right-bottom)
      [const Offset(0.28, 0.50), const Offset(0.68, 0.25)],
    ],
  ),

  // ==== L (uppercase) — stem + bottom horizontal ====
  LetterTemplate(
    letter: 'l',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Bottom horizontal
      [const Offset(0.22, 0.25), const Offset(0.68, 0.25)],
    ],
  ),

  // ==== M (uppercase) — left stem, diagonal down, diagonal up, right stem ====
  LetterTemplate(
    letter: 'm',
    isUppercase: true,
    strokes: [
      // Left stem
      [const Offset(0.12, 0.25), const Offset(0.12, 0.75)],
      // Left diagonal down to centre
      [const Offset(0.12, 0.75), const Offset(0.45, 0.42)],
      // Right diagonal up from centre
      [const Offset(0.45, 0.42), const Offset(0.78, 0.75)],
      // Right stem
      [const Offset(0.78, 0.75), const Offset(0.78, 0.25)],
    ],
  ),

  // ==== P (uppercase) — stem + top bump ====
  LetterTemplate(
    letter: 'p',
    isUppercase: true,
    strokes: [
      // Vertical stem
      [const Offset(0.22, 0.75), const Offset(0.22, 0.25)],
      // Top bump
      [
        const Offset(0.22, 0.75),
        const Offset(0.42, 0.76),
        const Offset(0.60, 0.70),
        const Offset(0.66, 0.60),
        const Offset(0.60, 0.52),
        const Offset(0.42, 0.48),
        const Offset(0.22, 0.50),
      ],
    ],
  ),

  // ==== Q (uppercase) — circle + tail ====
  LetterTemplate(
    letter: 'q',
    isUppercase: true,
    strokes: [
      // Circle
      [
        const Offset(0.45, 0.75),
        const Offset(0.62, 0.72),
        const Offset(0.72, 0.62),
        const Offset(0.74, 0.50),
        const Offset(0.72, 0.38),
        const Offset(0.62, 0.28),
        const Offset(0.45, 0.25),
        const Offset(0.28, 0.28),
        const Offset(0.18, 0.38),
        const Offset(0.16, 0.50),
        const Offset(0.18, 0.62),
        const Offset(0.28, 0.72),
        const Offset(0.45, 0.75),
      ],
      // Tail
      [const Offset(0.55, 0.38), const Offset(0.72, 0.22)],
    ],
  ),

  // ==== T (uppercase) — top horizontal + stem ====
  LetterTemplate(
    letter: 't',
    isUppercase: true,
    strokes: [
      // Top horizontal
      [const Offset(0.15, 0.75), const Offset(0.75, 0.75)],
      // Vertical stem from centre
      [const Offset(0.45, 0.75), const Offset(0.45, 0.25)],
    ],
  ),

  // ==== Y (uppercase) — two upper diagonals + stem ====
  LetterTemplate(
    letter: 'y',
    isUppercase: true,
    strokes: [
      // Left upper diagonal to centre
      [const Offset(0.15, 0.75), const Offset(0.45, 0.50)],
      // Right upper diagonal to centre
      [const Offset(0.75, 0.75), const Offset(0.45, 0.50)],
      // Stem from centre down
      [const Offset(0.45, 0.50), const Offset(0.45, 0.25)],
    ],
  ),
];
