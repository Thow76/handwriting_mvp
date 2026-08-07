import 'letter_formation_data.dart';
import 'stroke_formation_enums.dart';
import 'stroke_start_rect.dart';
import 'waypoint_section.dart';

/// Formation data for authored lowercase letters.
///
/// ## Start-rectangle groups
///
/// Every [ExpectedStroke.startRect] is expressed as fractions of the letter's
/// tight ink bounding box (x: left→right 0–1, y: top→bottom 0–1).  The groups
/// below are an authoring convenience; the runtime lookup is per
/// **(letter, stroke index) → rectangle** and does not use these group names.
///
/// | Group              | Letters / strokes                              | x          | y          |
/// |--------------------|------------------------------------------------|------------|------------|
/// | Anticlockwise oval | a, c, o, s                                     | 0.55–0.95  | 0.00–0.25  |
/// | Stem-first         | b[0], h[0], k[0], p[0], r[0]                  | 0.00–0.25  | 0.00–0.15  |
/// | Top-left           | v[0], z[0], x[0], y[0]                         | 0.00–0.25  | 0.00–0.15  |
///
/// Per-letter overrides (take precedence over group defaults):
///
/// | Letter | Stroke | x          | y          | Notes                                            |
/// |--------|--------|------------|------------|--------------------------------------------------|
/// | d      | 0      | 0.75–1.00  | 0.00–0.15  | Upper-right stem (stroke 0 = stem, before bowl)  |
/// | d      | 1      | 0.70–1.00  | 0.40–0.60  | Mid-right bowl (stroke 1, after stem)            |
/// | e      | 0      | 0.00–0.25  | 0.40–0.60  | Mid-left tongue start                            |
/// | l      | 0      | 0.00–1.00  | 0.00–0.15  | Full-width stem top (Andika); only stroke        |
/// | f      | 0      | 0.55–1.00  | 0.00–0.15  | Hook top; covers right half of hook start         |
/// | f      | 1      | 0.00–0.25  | 0.25–0.40  | Left at crossbar; y repositioned to midline       |
/// | t      | 0      | 0.35–0.65  | 0.00–0.15  | Mid-upper stem; recentred and widened             |
/// | t      | 1      | 0.00–0.24  | 0.26–0.38  | Left just above x-height                         |
/// | h      | 1      | 0.00–0.30  | 0.40–0.60  | Mid-left arch start                              |
/// | k      | 1      | 0.60–0.90  | 0.35–0.55  | Mid-right kick start                             |
/// | w      | 0      | 0.00–0.25  | 0.00–0.15  | Wider x bound                                    |
/// | x      | 1      | 0.75–1.00  | 0.00–0.15  | Top-right mirror                                 |
/// | y      | 1      | 0.75–1.00  | 0.00–0.15  | Top-right mirror                                 |
/// | i      | 0      | 0.25–0.75  | 0.30–0.45  | Centred; top edge at top of stem body (Andika)   |
/// | i      | 1      | 0.15–0.85  | 0.00–0.20  | Dot only; trimmed to dot extent (Andika)         |
/// | j      | 0      | 0.25–0.75  | 0.22–0.33  | Centred; below dot; smaller % due to descender   |
/// | j      | 1      | 0.15–0.85  | 0.00–0.25  | Generous dot zone; smaller % due to descender    |
/// | b      | 1      | 0.00–0.30  | 0.40–0.60  | Mid-left bowl at x-height                        |
/// | p      | 1      | 0.00–0.30  | 0.00–0.15  | Bowl starts at top of bounds (descender bounds)  |
/// | g      | 0      | 0.65–0.85  | 0.00–0.15  | Top-right of bowl, top edge at tight-bounds top  |
/// | g      | 1      | 0.74–0.99  | 0.02–0.17  | Top-right shoulder, widened toward right edge    |
/// | q      | 0      | 0.68–0.95  | 0.00–0.15  | Oval start — tighter than standard oval group    |
/// | q      | 1      | 0.87–1.00  | 0.00–0.15  | Far-right descender at top of bounds             |
/// | r      | 1      | 0.00–0.30  | 0.40–0.60  | Arch mid-left at x-height (same zone as h[1])    |
/// | m      | 0      | 0.00–0.30  | 0.00–0.20  | Widened compound start                           |
/// | n      | 0      | 0.00–0.30  | 0.00–0.20  | Widened compound start                           |
/// | u      | 0      | 0.00–0.30  | 0.00–0.15  | Widened compound start                           |
///
/// ## Single-stroke letters — `c, e, l, o, s, v, w, z`
///
/// Every entry has `minRequiredStrokes = 1` and exactly one [ExpectedStroke].
/// The canonical drawing direction (documented below for reference) follows
/// the Universal Core table in `stroke_formation_scope.md`:
///
/// | Letter | Direction | Notes |
/// |--------|-----------|-------|
/// | c      | anticlockwise   | Left-opening arc |
/// | e      | anticlockwise   | Closed left-opening oval |
/// | l      | topToBottom     | Vertical stem |
/// | o      | anticlockwise   | Closed oval |
/// | s      | compound        | Waypoint-scored (top → middle → bottom); interim |
/// |        |                 | placeholder pending a proper compound S-curve |
/// |        |                 | sequence (see stroke_formation_scope.md). |
/// | v      | topToBottom     | Diagonal (down-left then down-right) |
/// | w      | topToBottom     | Diagonal (two v-shapes joined) |
/// | z      | topToBottom     | Diagonal class (top bar → diagonal → base bar) |
///
/// ## Optional-lift oval-and-bowl letters — `a, b, d, g, p, q, y`
///
/// All entries have `minRequiredStrokes = 1`. Connected (one-stroke) and
/// separated (multi-stroke) formations are both pedagogically correct; the
/// scoring floor is 1, not the canonical count.
///
/// For b, d, g, p, q the strokes list contains two [ExpectedStroke]s
/// representing the canonical separated form (stem + bowl/oval). This gives
/// the scorers the correct structure without requiring a lift.
/// `strokes.length` is the canonical count; `minRequiredStrokes` is the
/// scoring floor — these are intentionally different for these five letters.
///
/// | Letter | Stroke | Direction | Notes |
/// |--------|--------|-----------|-------|
/// | a      | 1      | anticlockwise   | Closed left-opening oval (single stroke) |
/// | b      | 1      | topToBottom     | Vertical stem |
/// | b      | 2      | clockwise       | Right-opening bowl |
/// | d      | 1      | topToBottom     | Vertical stem (written first) |
/// | d      | 2      | anticlockwise   | Left-opening oval (written second) |
/// | g      | 1      | anticlockwise   | Left-opening oval |
/// | g      | 2      | topToBottom     | Descending tail |
/// | p      | 1      | topToBottom     | Vertical stem |
/// | p      | 2      | clockwise       | Right-opening bowl |
/// | q      | 1      | anticlockwise   | Left-opening oval |
/// | q      | 2      | topToBottom     | Vertical stem |
/// | y      | 1      | topToBottom     | Diagonal stem (top-left to bottom-right) |
/// | y      | 2      | topToBottom     | Diagonal tail (top-right to bottom-left) |
///
/// ## Required-lift letters — `f, i, j, t, x`
///
/// Every entry has `minRequiredStrokes = 2` and two [ExpectedStroke]s.
/// The pen-lift is mandatory; failing to lift is a formation error.
///
/// | Letter | Stroke | Direction | Notes |
/// |--------|--------|-----------|-------|
/// | f      | 1      | topToBottom     | Vertical stem |
/// | f      | 2      | leftToRight     | Crossbar |
/// | i      | 1      | topToBottom     | Vertical stem |
/// | i      | 2      | dot             | Dot — scored on presence |
/// | j      | 1      | topToBottom     | Vertical stem |
/// | j      | 2      | dot             | Dot — scored on presence |
/// | t      | 1      | topToBottom     | Vertical stem |
/// | t      | 2      | leftToRight     | Crossbar |
/// | x      | 1      | topToBottom     | Diagonal stroke (top-left to bottom-right) |
/// | x      | 2      | topToBottom     | Diagonal stroke (top-right to bottom-left) |
///
/// ## Compound-stroke letters — `h, k, m, n, r, u`
///
/// Letters whose pen never lifts but travels through multiple directional
/// phases. Compound [ExpectedStroke]s carry a non-empty `waypoints` list
/// specifying the ordered 3×3 grid cells the stroke must pass through.
///
/// | Letter | Stroke | Direction | Waypoints                                               |
/// |--------|--------|-----------|--------------------------------------------------------|
/// | h      | 1      | topToBottom     | — (stem)                                                |
/// | h      | 2      | compound        | left → top → bottomRight                               |
/// | k      | 1      | topToBottom     | — (stem)                                                |
/// | k      | 2      | compound        | topRight → middle → bottomRight                        |
/// | m      | 1      | compound        | topLeft → bottomLeft → top → bottom → top → bottomRight |
/// | n      | 1      | compound        | topLeft → bottomLeft → top → bottomRight               |
/// | r      | 1      | topToBottom     | — (stem)                                                |
/// | r      | 2      | compound        | left → topRight                                        |
/// | u      | 1      | compound        | topLeft → bottomLeft → bottom → bottomRight → topRight |
///
/// `h`, `k`, and `r` have `minRequiredStrokes = 2` — the pen-lift between
/// stem and compound stroke is mandatory. `m`, `n`, and `u` have
/// `minRequiredStrokes = 1` — they are drawn in a single continuous compound
/// stroke.
///
/// Returns `null` for any letter not yet authored.
final Map<String, LetterFormationData> letterFormationRegistry = {
  'c': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 0.95,
          minY: 0.00,
          maxY: 0.25,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.55,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.30,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.35,
              minY: 0.25,
              maxY: 0.75,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.20,
              maxX: 0.80,
              minY: 0.70,
              maxY: 1.00,
            ),
          ),
        ],
      ),
    ],
  ),
  'e': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.40,
          maxY: 0.60,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.15,
              maxX: 0.90,
              minY: 0.40,
              maxY: 0.60,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.55,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.30,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.35,
              minY: 0.25,
              maxY: 0.70,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.20,
              maxX: 0.80,
              minY: 0.70,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.65,
              maxX: 1.00,
              minY: 0.30,
              maxY: 0.75,
            ),
          ),
        ],
      ),
    ],
  ),
  'l': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
    ],
  ),
  'o': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 0.95,
          minY: 0.00,
          maxY: 0.25,
        ),
        waypoints: const [
          WaypointRegion.topRight,
          WaypointRegion.left,
          WaypointRegion.bottom,
          WaypointRegion.right,
        ],
      ),
    ],
  ),
  // Interim placeholder only: replace with a proper compound S-curve sequence.
  's': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 0.95,
          minY: 0.00,
          maxY: 0.25,
        ),
        waypoints: const [
          WaypointRegion.top,
          WaypointRegion.middle,
          WaypointRegion.bottom,
        ],
      ),
    ],
  ),
  'v': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topLeft, WaypointRegion.bottomRight],
      ),
    ],
  ),
  'w': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topLeft, WaypointRegion.bottomRight],
      ),
    ],
  ),
  'z': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.left, WaypointRegion.right],
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Optional-lift oval-and-bowl letters — a, b, d, g, p, q, r, y
  //
  // minRequiredStrokes = 1 for all. Connected and separated formations are
  // both correct; the scoring floor is 1, not the canonical stroke count.
  //
  // For b, d, g, p, q the strokes list has two entries (canonical separated
  // form) so the scorers have the right structure; minRequiredStrokes
  // remains 1 because failing to lift is NOT a formation error for these.
  // -------------------------------------------------------------------------
  'a': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 0.95,
          minY: 0.00,
          maxY: 0.25,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.55,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.30,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.35,
              minY: 0.25,
              maxY: 0.70,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.20,
              maxX: 0.80,
              minY: 0.70,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.65,
              maxX: 1.00,
              minY: 0.30,
              maxY: 0.75,
            ),
          ),
        ],
      ),
    ],
  ),
  'b': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.30,
              minY: 0.00,
              maxY: 0.20,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.30,
              minY: 0.80,
              maxY: 1.00,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.40,
          maxY: 0.60,
        ),
        sections: [
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.35,
              minY: 0.35,
              maxY: 0.55,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.50,
              maxX: 1.00,
              minY: 0.35,
              maxY: 0.60,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.50,
              maxX: 1.00,
              minY: 0.75,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.35,
              minY: 0.75,
              maxY: 1.00,
            ),
          ),
        ],
      ),
    ],
  ),
  'd': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.75,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.70,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.20,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.70,
              maxX: 1.00,
              minY: 0.80,
              maxY: 1.00,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.70,
          maxX: 1.00,
          minY: 0.40,
          maxY: 0.60,
        ),
        sections: [
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.65,
              maxX: 1.00,
              minY: 0.35,
              maxY: 0.55,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.50,
              minY: 0.35,
              maxY: 0.60,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.50,
              minY: 0.75,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.65,
              maxX: 1.00,
              minY: 0.75,
              maxY: 1.00,
            ),
          ),
        ],
      ),
    ],
  ),
  'g': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.65,
          maxX: 0.85,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [
          WaypointRegion.topRight,
          WaypointRegion.left,
          WaypointRegion.bottom,
          WaypointRegion.right,
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.74,
          maxX: 0.99,
          minY: 0.02,
          maxY: 0.17,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
    ],
  ),
  'p': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [
          WaypointRegion.topRight,
          WaypointRegion.right,
          WaypointRegion.bottom,
          WaypointRegion.left,
        ],
      ),
    ],
  ),
  'q': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.68,
          maxX: 0.95,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [
          WaypointRegion.topRight,
          WaypointRegion.left,
          WaypointRegion.bottom,
          WaypointRegion.right,
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.87,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
    ],
  ),
  'r': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.40,
          maxY: 0.60,
        ),
        waypoints: [WaypointRegion.left, WaypointRegion.topRight],
      ),
    ],
  ),
  'y': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topLeft, WaypointRegion.bottomRight],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.75,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topRight, WaypointRegion.bottomLeft],
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Required-lift letters — f, i, j, t, x
  // minRequiredStrokes = 2 for all; failing to lift is a formation error.
  // -------------------------------------------------------------------------
  'f': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.25,
          maxY: 0.40,
        ),
        waypoints: const [WaypointRegion.left, WaypointRegion.right],
      ),
    ],
  ),
  'i': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.25,
          maxX: 0.75,
          minY: 0.30,
          maxY: 0.45,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.15,
          maxX: 0.85,
          minY: 0.00,
          maxY: 0.20,
        ),
      ),
    ],
  ),
  'j': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.25,
          maxX: 0.75,
          minY: 0.22,
          maxY: 0.33,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.15,
          maxX: 0.85,
          minY: 0.00,
          maxY: 0.25,
        ),
      ),
    ],
  ),
  't': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.35,
          maxX: 0.65,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.24,
          minY: 0.26,
          maxY: 0.38,
        ),
        waypoints: const [WaypointRegion.left, WaypointRegion.right],
      ),
    ],
  ),
  'x': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topLeft, WaypointRegion.bottomRight],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.75,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.topRight, WaypointRegion.bottomLeft],
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Compound-stroke letters — h, k, m, n, r, u
  //
  // Letters whose pen never lifts but travels through multiple directional
  // phases. Compound strokes carry a non-empty waypoints list specifying the
  // ordered 3×3 WaypointRegion grid cells the stroke must pass through.
  //
  // h, k, r: stem (topToBottom) + compound second stroke.
  //   minRequiredStrokes = 2 — the pen-lift between stem and arch/kick is
  //   mandatory.
  //
  // m, n, u: single continuous compound stroke.
  //   minRequiredStrokes = 1.
  //
  // Waypoint sequences are starting-point calibrations; exact cell assignments
  // will be refined against real learner data in a post-launch calibration
  // ticket.
  // -------------------------------------------------------------------------
  'h': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.40,
          maxY: 0.60,
        ),
        waypoints: [
          WaypointRegion.left,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  ),
  'k': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.60,
          maxX: 0.90,
          minY: 0.35,
          maxY: 0.55,
        ),
        waypoints: [
          WaypointRegion.topRight,
          WaypointRegion.middle,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  ),
  'm': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.20,
        ),
        waypoints: [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.top,
          WaypointRegion.bottom,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  ),
  'n': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.20,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.33,
              minY: 0.00,
              maxY: 0.33,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.33,
              minY: 0.67,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0.00,
              maxY: 0.33,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1.00,
              minY: 0.67,
              maxY: 1.00,
            ),
          ),
        ],
      ),
    ],
  ),
  'u': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.bottom,
          WaypointRegion.bottomRight,
          WaypointRegion.topRight,
        ],
      ),
    ],
  ),
};
