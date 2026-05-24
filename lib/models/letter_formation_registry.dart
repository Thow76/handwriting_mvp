import 'letter_formation_data.dart';
import 'stroke_formation_enums.dart';
import 'stroke_start_rect.dart';

/// Formation data for authored lowercase letters.
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
/// ## Optional-lift oval-and-bowl letters — `a, b, d, g, p, q, r, y`
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
/// | Letter | Stroke | primaryDirection | startRegion | Notes |
/// |--------|--------|-----------------|-------------|-------|
/// | a      | 1      | anticlockwise   | top         | Closed left-opening oval (single stroke) |
/// | b      | 1      | topToBottom     | top         | Vertical stem |
/// | b      | 2      | clockwise       | top         | Right-opening bowl |
/// | d      | 1      | anticlockwise   | top         | Left-opening oval |
/// | d      | 2      | topToBottom     | top         | Vertical stem |
/// | g      | 1      | anticlockwise   | top         | Left-opening oval |
/// | g      | 2      | topToBottom     | top         | Descending tail |
/// | p      | 1      | topToBottom     | top         | Vertical stem |
/// | p      | 2      | clockwise       | top         | Right-opening bowl |
/// | q      | 1      | anticlockwise   | top         | Left-opening oval |
/// | q      | 2      | topToBottom     | top         | Vertical stem |
/// | r      | 1      | topToBottom     | top         | Stem/entry stroke |
/// | y      | 1      | topToBottom     | top         | Diagonal stem (down-left) |
/// | y      | 2      | topToBottom     | top         | Diagonal tail (down-right) |
///
/// ## Required-lift letters — `f, i, j, t, x`
///
/// Every entry has `minRequiredStrokes = 2` and two [ExpectedStroke]s.
/// The pen-lift is mandatory; failing to lift is a formation error.
///
/// | Letter | Stroke | primaryDirection | startRegion | Notes |
/// |--------|--------|-----------------|-------------|-------|
/// | f      | 1      | topToBottom     | top         | Vertical stem |
/// | f      | 2      | leftToRight     | middle      | Crossbar |
/// | i      | 1      | topToBottom     | top         | Vertical stem |
/// | i      | 2      | dot             | top         | Dot — scored on presence |
/// | j      | 1      | topToBottom     | top         | Vertical stem |
/// | j      | 2      | dot             | top         | Dot — scored on presence |
/// | t      | 1      | topToBottom     | top         | Vertical stem |
/// | t      | 2      | leftToRight     | middle      | Crossbar |
/// | x      | 1      | topToBottom     | top         | Diagonal stroke (top-left to bottom-right) |
/// | x      | 2      | topToBottom     | top         | Diagonal stroke (top-right to bottom-left) |
///
/// ## Compound-stroke letters — `h, k, m, n, u`
///
/// Letters whose pen never lifts but travels through multiple directional
/// phases. Compound [ExpectedStroke]s have `primaryDirection = compound` and
/// a non-empty `waypoints` list specifying the ordered 3×3 grid cells the
/// stroke must pass through.
///
/// | Letter | Stroke | primaryDirection | startRegion | Waypoints                                               |
/// |--------|--------|-----------------|-------------|---------------------------------------------------------|
/// | h      | 1      | topToBottom     | top         | — (stem)                                                |
/// | h      | 2      | compound        | middle      | left → top → bottomRight                               |
/// | k      | 1      | topToBottom     | top         | — (stem)                                                |
/// | k      | 2      | compound        | top         | topRight → middle → bottomRight                        |
/// | m      | 1      | compound        | top         | topLeft → bottomLeft → top → bottom → top → bottomRight |
/// | n      | 1      | compound        | top         | topLeft → bottomLeft → top → bottomRight               |
/// | u      | 1      | compound        | top         | topLeft → bottomLeft → bottom → bottomRight → topRight |
///
/// `h` and `k` have `minRequiredStrokes = 2` — the pen-lift between stem and
/// compound stroke is mandatory. `m`, `n`, and `u` have
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'e': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'l': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'o': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'v': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'w': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'z': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'b': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.clockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'd': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'g': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'p': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.clockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'q': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'r': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'y': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.leftToRight,
        startRegion: StrokeStartRegion.middle,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 1.0 / 3.0, maxY: 2.0 / 3.0),
      ),
    ],
  ),
  'i': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.dot,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  'j': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.dot,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  't': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.leftToRight,
        startRegion: StrokeStartRegion.middle,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 1.0 / 3.0, maxY: 2.0 / 3.0),
      ),
    ],
  ),
  'x': LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Compound-stroke letters — h, k, m, n, u
  //
  // Letters whose pen never lifts but travels through multiple directional
  // phases. Compound strokes have primaryDirection = compound and a non-empty
  // waypoints list specifying the ordered 3×3 WaypointRegion grid cells the
  // stroke must pass through.
  //
  // h and k: stem (topToBottom) + compound second stroke.
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRegion: StrokeStartRegion.middle,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 1.0 / 3.0, maxY: 2.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      ),
      ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
        startRegion: StrokeStartRegion.top,
        startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
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
