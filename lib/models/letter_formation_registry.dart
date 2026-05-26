import 'letter_formation_data.dart';
import 'stroke_formation_enums.dart';
import 'stroke_start_rect.dart';

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
/// | Anticlockwise oval | a, c, o, s, g[0]                               | 0.55–0.95  | 0.00–0.25  |
/// | Stem-first         | b[0], h[0], k[0], l[0], p[0], r[0]            | 0.00–0.25  | 0.00–0.15  |
/// | Top-left           | v[0], z[0], x[0], y[0]                         | 0.00–0.25  | 0.00–0.15  |
///
/// Per-letter overrides (take precedence over group defaults):
///
/// | Letter | Stroke | x          | y          | Notes                                            |
/// |--------|--------|------------|------------|--------------------------------------------------|
/// | d      | 0      | 0.75–1.00  | 0.00–0.15  | Upper-right stem (stroke 0 = stem, before bowl)  |
/// | d      | 1      | 0.70–1.00  | 0.40–0.60  | Mid-right bowl (stroke 1, after stem)            |
/// | e      | 0      | 0.00–0.25  | 0.40–0.60  | Mid-left tongue start                            |
/// | f      | 0      | 0.60–0.90  | 0.00–0.30  | Upper-right stem; wider y to absorb hook depth   |
/// | f      | 1      | 0.00–0.20  | 0.44–0.56  | Left at x-height crossbar                        |
/// | t      | 0      | 0.35–0.65  | 0.00–0.15  | Mid-upper stem; recentred and widened             |
/// | t      | 1      | 0.00–0.24  | 0.26–0.38  | Left just above x-height                         |
/// | h      | 1      | 0.00–0.30  | 0.40–0.60  | Mid-left arch start                              |
/// | k      | 1      | 0.60–0.90  | 0.35–0.55  | Mid-right kick start                             |
/// | w      | 0      | 0.00–0.25  | 0.00–0.15  | Wider x bound                                    |
/// | x      | 1      | 0.75–1.00  | 0.00–0.15  | Top-right mirror                                 |
/// | y      | 1      | 0.75–1.00  | 0.00–0.15  | Top-right mirror                                 |
/// | i      | 0      | 0.25–0.75  | 0.10–0.25  | Centred; y moved up within dot-inclusive bounds  |
/// | i      | 1      | 0.15–0.85  | 0.00–0.36  | Generous dot zone                                |
/// | j      | 0      | 0.25–0.75  | 0.22–0.33  | Centred; below dot; smaller % due to descender   |
/// | j      | 1      | 0.15–0.85  | 0.00–0.25  | Generous dot zone; smaller % due to descender    |
/// | b      | 1      | 0.00–0.30  | 0.40–0.60  | Mid-left bowl at x-height                        |
/// | p      | 1      | 0.00–0.30  | 0.00–0.15  | Bowl starts at top of bounds (descender bounds)  |
/// | g      | 1      | 0.65–0.95  | 0.00–0.25  | Upper-right link/tail start                      |
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
/// Direction assignments follow the Universal Core table in
/// `stroke_formation_scope.md`:
///
/// | Letter | primaryDirection | Notes |
/// |--------|-----------------|-------|
/// | c      | anticlockwise   | Left-opening arc |
/// | e      | anticlockwise   | Closed left-opening oval |
/// | l      | topToBottom     | Vertical stem |
/// | o      | anticlockwise   | Closed oval |
/// | s      | topToBottom     | Interim placeholder — scope does not assign |
/// |        |                 | a primary direction; flagged for review before |
/// |        |                 | stage 4 ships (see stroke_formation_scope.md). |
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
/// direction scoring the correct structure without requiring a lift.
/// `strokes.length` is the canonical count; `minRequiredStrokes` is the
/// scoring floor — these are intentionally different for these five letters.
///
/// | Letter | Stroke | primaryDirection | Notes |
/// |--------|--------|-----------------|-------|
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
/// | y      | 1      | topToBottom     | Diagonal stem (down-left) |
/// | y      | 2      | topToBottom     | Diagonal tail (down-right) |
///
/// ## Required-lift letters — `f, i, j, t, x`
///
/// Every entry has `minRequiredStrokes = 2` and two [ExpectedStroke]s.
/// The pen-lift is mandatory; failing to lift is a formation error.
///
/// | Letter | Stroke | primaryDirection | Notes |
/// |--------|--------|-----------------|-------|
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
/// phases. Compound [ExpectedStroke]s have `primaryDirection = compound` and
/// a non-empty `waypoints` list specifying the ordered 3×3 grid cells the
/// stroke must pass through.
///
/// | Letter | Stroke | primaryDirection | Waypoints                                               |
/// |--------|--------|-----------------|--------------------------------------------------------|
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
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.55, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  'e': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.40, maxY: 0.60),
      ),
    ],
  ),
  'l': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  'o': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.55, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  // s: primaryDirection is topToBottom as an interim placeholder.
  // The scope's Universal Core table lists s as single-stroke but does not
  // assign a primary direction (both clockwise and anticlockwise sub-arcs are
  // present). This value must be confirmed with the scope owner before stage 4
  // ships; it affects only StrokeDirectionScorer's behaviour on s.
  's': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.55, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  'v': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  'w': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  'z': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
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
  // form) so direction scoring has the right structure; minRequiredStrokes
  // remains 1 because failing to lift is NOT a formation error for these.
  // -------------------------------------------------------------------------
  'a': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.55, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  'b': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.clockwise,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      ),
    ],
  ),
  'd': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.70, maxX: 1.00, minY: 0.40, maxY: 0.60),
      ),
    ],
  ),
  'g': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.55, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.65, maxX: 0.95, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  'p': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.clockwise,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  'q': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRect: const StrokeStartRect(minX: 0.68, maxX: 0.95, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.87, maxX: 1.00, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  'r': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
        waypoints: [
          WaypointRegion.left,
          WaypointRegion.topRight,
        ],
      ),
    ],
  ),
  'y': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
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
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.60, maxX: 0.90, minY: 0.00, maxY: 0.30),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.leftToRight,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.20, minY: 0.44, maxY: 0.56),
      ),
    ],
  ),
  'i': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.10, maxY: 0.25),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.dot,
        startRect: const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.36),
      ),
    ],
  ),
  'j': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.22, maxY: 0.33),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.dot,
        startRect: const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.25),
      ),
    ],
  ),
  't': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.35, maxX: 0.65, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.leftToRight,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.24, minY: 0.26, maxY: 0.38),
      ),
    ],
  ),
  'x': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Compound-stroke letters — h, k, m, n, r, u
  //
  // Letters whose pen never lifts but travels through multiple directional
  // phases. Compound strokes have primaryDirection = compound and a non-empty
  // waypoints list specifying the ordered 3×3 WaypointRegion grid cells the
  // stroke must pass through.
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
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
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
        primaryDirection: StrokeDirection.topToBottom,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.60, maxX: 0.90, minY: 0.35, maxY: 0.55),
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
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
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
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
        waypoints: [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  ),
  'u': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRect: const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
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
