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
/// | s      | compound        | Section-scored (approved zone design); interim |
/// |        |                 | classification pending a proper compound S-curve |
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
/// All of a, b, d, g, p, q, y are section-scored — see
/// `docs/zone_review/REVIEW.md` for the approved zone designs.
///
/// | Letter | Stroke | Direction | Notes |
/// |--------|--------|-----------|-------|
/// | a      | 1      | anticlockwise   | Closed left-opening oval (single stroke) |
/// | b      | 1      | topToBottom     | Vertical stem |
/// | b      | 2      | clockwise       | Right-opening bowl |
/// | d      | 1      | topToBottom     | Vertical stem (written first) |
/// | d      | 2      | anticlockwise   | Left-opening oval (written second) |
/// | g      | 1      | anticlockwise   | Left-opening oval (section-scored) |
/// | g      | 2      | topToBottom     | Descending stem with bottom-left hook (section-scored; see `docs/waypoint_section_definitions.md`) |
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
/// All five letters (f, i, j, t, x) are section-scored — see
/// `docs/zone_review/REVIEW.md` for the approved zone designs.
///
/// | Letter | Stroke | Direction | Notes |
/// |--------|--------|-----------|-------|
/// | f      | 1      | topToBottom     | Curved stem with top-right hook |
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
/// ## Compound-stroke letters — `k, m, r, u`
///
/// Letters whose pen never lifts but travels through multiple directional
/// phases. These, like every other letter in this registry, are now
/// section-scored: each [ExpectedStroke] carries a bespoke numbered
/// `sections` list (see `docs/zone_review/REVIEW.md` for the approved zone
/// designs) rather than the legacy shared 3×3 `WaypointRegion` grid.
///
/// | Letter | Stroke | Direction |
/// |--------|--------|-----------|
/// | k      | 1      | topToBottom     |
/// | k      | 2      | compound        |
/// | m      | 1      | compound        |
/// | r      | 1      | topToBottom     |
/// | r      | 2      | compound        |
/// | u      | 1      | compound        |
///
/// `k` and `r` have `minRequiredStrokes = 2` — the pen-lift between stem and
/// compound stroke is mandatory. `m` and `u` have `minRequiredStrokes = 1` —
/// they are drawn in a single continuous compound stroke.
///
/// `h` and `n` belong to this same structural family (pen travels through
/// multiple directional phases) and, like k, m, r, u, are scored via
/// `WaypointSectionScorer` using bespoke numbered sections instead of the
/// shared 3×3 grid.
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
              minX: 0.5,
              maxX: 1,
              minY: 0,
              maxY: 0.3,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0,
              maxY: 0.3,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0.3,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0.7,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0.7,
              maxY: 1,
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
              minX: 0,
              maxX: 0.33,
              minY: 0.37,
              maxY: 0.52,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0.37,
              maxY: 0.52,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1,
              minY: 0.37,
              maxY: 0.52,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1,
              minY: 0,
              maxY: 0.37,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0,
              maxY: 0.37,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.33,
              minY: 0,
              maxY: 0.37,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.33,
              minY: 0.52,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 8,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0.52,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 9,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1,
              minY: 0.52,
              maxY: 1,
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0.7,
              maxY: 1,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0.0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.0,
              maxX: 0.33,
              minY: 0.0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.0,
              maxX: 0.33,
              minY: 0.5,
              maxY: 1.0,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.33,
              maxX: 0.67,
              minY: 0.5,
              maxY: 1.0,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1.0,
              minY: 0.5,
              maxY: 1.0,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.67,
              maxX: 1.0,
              minY: 0.0,
              maxY: 0.5,
            ),
          ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0.35,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0.35,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0.65,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0.65,
              maxY: 1,
            ),
          ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.5,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1,
              minY: 0,
              maxY: 0.5,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.2,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.2,
              maxX: 0.4,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.4,
              maxX: 0.6,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.6,
              maxX: 0.8,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.8,
              maxX: 1,
              minY: 0,
              maxY: 0.5,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0,
              maxY: 0.3333333333333333,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.6666666666666666,
              maxX: 1,
              minY: 0,
              maxY: 0.3333333333333333,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.3333333333333333,
              maxX: 0.6666666666666666,
              minY: 0.3333333333333333,
              maxY: 0.6666666666666666,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0.6666666666666666,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.6666666666666666,
              maxX: 1,
              minY: 0.6666666666666666,
              maxY: 1,
            ),
          ),
        ],
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
              minX: 0.38,
              maxX: 0.72,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.38,
              maxX: 0.72,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1,
              minY: 0.5,
              maxY: 1,
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
              maxX: 0.25,
              minY: 0.00,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.25,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.25,
              minY: 0.67,
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
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.25,
              maxX: 0.62,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1.00,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1.00,
              minY: 0.67,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.25,
              maxX: 0.62,
              minY: 0.67,
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
              minX: 0.72,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1,
              minY: 0.67,
              maxY: 1,
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
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.38,
              maxX: 0.72,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0.35,
              maxY: 0.67,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0.67,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.38,
              maxX: 0.72,
              minY: 0.67,
              maxY: 1,
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.39,
              maxX: 0.72,
              minY: 0.00,
              maxY: 0.33,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.39,
              minY: 0.00,
              maxY: 0.33,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.39,
              minY: 0.33,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.39,
              maxX: 0.72,
              minY: 0.33,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1.00,
              minY: 0.12,
              maxY: 0.33,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.72,
              maxX: 1.00,
              minY: 0.33,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.39,
              maxX: 1.00,
              minY: 0.65,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 8,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.39,
              minY: 0.65,
              maxY: 1.00,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.74,
          maxX: 0.99,
          minY: 0.02,
          maxY: 0.17,
        ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.25,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.25,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.25,
              minY: 0.7,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.25,
              maxX: 0.62,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.25,
              maxX: 0.62,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.38,
              maxX: 0.75,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.38,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.38,
              maxX: 0.75,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.87,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.75,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.75,
              maxX: 1,
              minY: 0.35,
              maxY: 0.7,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.75,
              maxX: 1,
              minY: 0.7,
              maxY: 1,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.32,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.32,
              minY: 0.4,
              maxY: 1,
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
              minX: 0.32,
              maxX: 0.68,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.68,
              maxX: 1,
              minY: 0,
              maxY: 0.4,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.3333333333333333,
              maxX: 0.6666666666666666,
              minY: 0.35,
              maxY: 0.65,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.75,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.6666666666666666,
              maxX: 1,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.3333333333333333,
              maxX: 0.6666666666666666,
              minY: 0.65,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0.65,
              maxY: 1,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.46,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.30,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.26,
              maxX: 0.46,
              minY: 0.00,
              maxY: 0.30,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.26,
              maxX: 0.46,
              minY: 0.30,
              maxY: 1.00,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.25,
          maxY: 0.40,
        ),
        sections: [
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.26,
              minY: 0.30,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.46,
              maxX: 1.00,
              minY: 0.30,
              maxY: 1.00,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0.24,
              maxY: 0.62,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0.62,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.15,
          maxX: 0.85,
          minY: 0.00,
          maxY: 0.20,
        ),
        sections: [
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: 0.24,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.45,
              maxX: 1,
              minY: 0.18,
              maxY: 0.65,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.45,
              maxX: 1,
              minY: 0.65,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.45,
              minY: 0.65,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.15,
          maxX: 0.85,
          minY: 0.00,
          maxY: 0.25,
        ),
        sections: [
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.45,
              maxX: 1,
              minY: 0,
              maxY: 0.18,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.28,
              maxX: 0.58,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.28,
              maxX: 0.58,
              minY: 0.4,
              maxY: 0.78,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.28,
              maxX: 0.58,
              minY: 0.78,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.58,
              maxX: 1,
              minY: 0.78,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.24,
          minY: 0.26,
          maxY: 0.38,
        ),
        sections: [
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.28,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.58,
              maxX: 1,
              minY: 0,
              maxY: 0.4,
            ),
          ),
        ],
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0,
              maxY: 0.3333333333333333,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.3333333333333333,
              maxX: 0.6666666666666666,
              minY: 0.3333333333333333,
              maxY: 0.6666666666666666,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.6666666666666666,
              maxX: 1,
              minY: 0.6666666666666666,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.75,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        sections: [
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.6666666666666666,
              maxX: 1,
              minY: 0,
              maxY: 0.3333333333333333,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3333333333333333,
              minY: 0.6666666666666666,
              maxY: 1,
            ),
          ),
        ],
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Compound-stroke letters — k, m, r, u
  //
  // Letters whose pen never lifts but travels through multiple directional
  // phases. Compound strokes carry a non-empty waypoints list specifying the
  // ordered 3×3 WaypointRegion grid cells the stroke must pass through.
  //
  // k, r: stem (topToBottom) + compound second stroke.
  //   minRequiredStrokes = 2 — the pen-lift between stem and arch/kick is
  //   mandatory.
  //
  // m, u: single continuous compound stroke.
  //   minRequiredStrokes = 1.
  //
  // h and n share this structural family but have been migrated to bespoke
  // numbered sections — see docs/waypoint_section_definitions.md — and are
  // scored via WaypointSectionScorer instead of the shared 3×3 grid.
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.22,
              minY: 0.00,
              maxY: 0.82,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.22,
              minY: 0.82,
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
              minX: 0.22,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.50,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.22,
              maxX: 1.00,
              minY: 0.50,
              maxY: 0.82,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.22,
              maxX: 1.00,
              minY: 0.82,
              maxY: 1.00,
            ),
          ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.28,
              minY: 0,
              maxY: 0.35,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.28,
              minY: 0.35,
              maxY: 0.68,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.28,
              minY: 0.68,
              maxY: 1,
            ),
          ),
        ],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.60,
          maxX: 0.90,
          minY: 0.35,
          maxY: 0.55,
        ),
        sections: [
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1,
              minY: 0.35,
              maxY: 0.68,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.28,
              maxX: 0.62,
              minY: 0.35,
              maxY: 0.68,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.28,
              maxX: 0.62,
              minY: 0.68,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 7,
            rect: const StrokeStartRect(
              minX: 0.62,
              maxX: 1,
              minY: 0.68,
              maxY: 1,
            ),
          ),
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3,
              minY: 0.4,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.3,
              maxX: 0.68,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.3,
              maxX: 0.68,
              minY: 0.4,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.68,
              maxX: 1,
              minY: 0,
              maxY: 0.4,
            ),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
              minX: 0.68,
              maxX: 1,
              minY: 0.4,
              maxY: 1,
            ),
          ),
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
              maxX: 0.30,
              minY: 0.00,
              maxY: 0.75,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.00,
              maxX: 0.30,
              minY: 0.75,
              maxY: 1.00,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.30,
              maxX: 1.00,
              minY: 0.00,
              maxY: 0.40,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.30,
              maxX: 1.00,
              minY: 0.40,
              maxY: 0.75,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.30,
              maxX: 1.00,
              minY: 0.75,
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
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3,
              minY: 0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0,
              maxX: 0.3,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
              minX: 0.3,
              maxX: 0.68,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
              minX: 0.68,
              maxX: 1,
              minY: 0.5,
              maxY: 1,
            ),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
              minX: 0.68,
              maxX: 1,
              minY: 0,
              maxY: 0.5,
            ),
          ),
        ],
      ),
    ],
  ),
};
