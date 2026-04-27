**Stroke Formation Scoring**

*Agreed Pedagogical Scope and Stroke Count Modifications*

# Purpose

This document records the pedagogical decisions agreed for the stroke formation scoring module of the handwriting recognition app. The module sits alongside the existing bitmap scores (coverage, precision, efficiency) and adds process-based feedback — how the letter was drawn, not just where the ink landed. The target user is an ESOL learner coming from a non-Roman script (Arabic, Hebrew, Chinese, Devanagari, etc.) whose L1 motor habits produce specific, predictable errors when writing Latin letters.

These decisions replace the original Phase 1 and Phase 2 plan. The key change is a deliberate narrowing of scope to tradition-neutral universals, which removes the risk of penalising learners for regional differences in handwriting pedagogy (D'Nealian, Zaner-Bloser, Nelson, etc.).

# Pedagogical Principle

The app checks only the elements on which every mainstream Latin handwriting tradition agrees. Anything contested between traditions is deliberately excluded.

## Excluded by design

- Single-story vs double-story a, g

- Whether k is drawn as 2 or 3 strokes

- Exact clock-position start on ovals (1 o'clock vs 2 o'clock)

- Retrace vs lift on d, p, q

- Entry and exit flicks

- Overall letter count matching a specific tradition

## Included — the universal core

These six elements are agreed across D'Nealian, Zaner-Bloser, Nelson, and every other mainstream system, and they cover essentially every L1-transfer error the app is designed to catch.

| **Element** | **Rule** | **RTL-Transfer Diagnostic** |
| --- | --- | --- |
| Horizontal strokes | Always drawn left-to-right | Strongest signal for Arabic/Hebrew L1 transfer |
| Vertical strokes | Always drawn top-to-bottom | Generic beginner signal |
| Closed and left-opening ovals | Anticlockwise: o, c, a, d, g, q, e | Strong RTL signal — natural Arabic habit is clockwise |
| Right-opening bowls on stems | Clockwise: b, p | Pairs with oval check |
| Diagonals | Always drawn top-to-bottom (either slant) | Catches reversed x, v, w, y |
| Starting position | First point lands in top or top-left region, never right | Most diagnostic single check; requires no direction analysis |

# Stroke Count — Revised Treatment

Stroke count is not dropped, but it is no longer scored against an exact expected value. Instead, each letter declares a minimum required number of strokes, reflecting pen-lifts that are mandatory for correct formation. Drawing more strokes than required is always acceptable; drawing fewer indicates a real error (missing dot, skipped crossbar, retraced 'x').

## Why the change

- **Exact count was ****tradition-dependent****. **A learner drawing 'b' as one flowing stroke is correct in cursive and several print traditions, but would have been penalised under the original plan.

- **Required lifts are universal. **Every tradition agrees that the crossbar on t, the dot on i, and the two diagonals of x must involve lifts. These are real formation errors when missed.

- **The scoring becomes a threshold, not a distance. **The 1/(1+Δ) curve is dropped. Score is 1.0 if actualCount ≥ minRequiredStrokes, otherwise low or zero. Simpler, stricter, more defensible.

## Letter categorisation

| **Category** | **Letters** | **Behaviour** |
| --- | --- | --- |
| **Required lifts** | t, f, i, j, x | Must lift; failing to lift is a real formation error. minRequiredStrokes = 2 |
| **Optional lifts** | b, d, p, q, h, n, m, r, a, g, k | Connected or separated both correct. minRequiredStrokes = 1 |
| **Single stroke** | c, e, l, o, s, u, v, w, z | Always one continuous stroke. minRequiredStrokes = 1 |

## Per-letter minRequiredStrokes values

The following table replaces the exact-count table in the original implementation plan. It specifies the minRequiredStrokes value for every letter of the lowercase alphabet. Only five letters (f, i, j, t, x) carry a required lift and therefore a minimum above 1; every other letter accepts one-stroke formation as correct.

Note particularly that b, d, g, p, q — letters the original plan specified as requiring exactly 2 strokes — are marked as optional lifts with minRequiredStrokes = 1. Under the revised model, a learner who draws 'b' as one continuous stroke (stem flowing into bowl without lifting) is drawing a correct letter and must not be penalised on stroke count.

| **Letter** | **minRequiredStrokes** | **Category** |
| --- | --- | --- |
| **a** | 1 | Optional lift |
| **b** | 1 | Optional lift |
| **c** | 1 | Single stroke |
| **d** | 1 | Optional lift |
| **e** | 1 | Single stroke |
| **f** | 2 | Required lift — crossbar lifts from stem |
| **g** | 1 | Optional lift |
| **h** | 1 | Optional lift |
| **i** | 2 | Required lift — stem plus dot |
| **j** | 2 | Required lift — stem plus dot |
| **k** | 1 | Optional lift |
| **l** | 1 | Single stroke |
| **m** | 1 | Optional lift |
| **n** | 1 | Optional lift |
| **o** | 1 | Single stroke |
| **p** | 1 | Optional lift |
| **q** | 1 | Optional lift |
| **r** | 1 | Optional lift |
| **s** | 1 | Single stroke |
| **t** | 2 | Required lift — crossbar lifts from stem |
| **u** | 1 | Single stroke |
| **v** | 1 | Single stroke |
| **w** | 1 | Single stroke |
| **x** | 2 | Required lift — two crossing diagonals |
| **y** | 1 | Optional lift |
| **z** | 1 | Single stroke |

The canonical stroke count for display or diagnostic purposes is derived separately from the strokes list in LetterFormationData (strokes.length), which represents the textbook presentation of the letter. minRequiredStrokes is the scoring floor, not the canonical count.

## StrokeBreakCounter specification

The original plan used a distance-curve formula — 1 / (1 + |actual - expected|) — that symmetrically penalised both over- and under-counting. Under the revised model, there is no single expected count; there is only a minimum number of required pen-lifts. Exceeding the minimum is acceptable, and only falling below it is an error. The scorer has been renamed from StrokeCountScorer to StrokeBreakCounter to reflect what it actually measures — the presence of required breaks in the motion sequence, not distance from an expected count.

## Formula

The scorer takes two inputs: the letter's minRequiredStrokes and the observed actualCount. Three cases cover all inputs:

- **actualCount**** ≥ ****minRequiredStrokes**** → 1.0. **Over-counting is never penalised. A learner drawing 'b' in 1, 2, or 3 strokes all score full marks.

- **0 ****<**** ****actualCount**** ****<**** ****minRequiredStrokes**** → ****actualCount**** / ****minRequiredStrokes****. **Proportional partial credit. A learner drawing 'i' with just the stem and no dot (1 of 2 required) scores 0.5 — enough signal to indicate something is missing while giving credit for what was done.

- **actualCount**** = 0 → 0.0. **Defensive case; should not occur in practice because scoring would not trigger on an empty stroke list.

No symmetric penalty. No curve. No tuning parameter.

## Behaviour in practice

For the five letters with minRequiredStrokes = 2 (f, i, j, t, x), the scorer discriminates: 1 stroke scores 0.5, 2 or more strokes score 1.0. For the 21 letters with minRequiredStrokes = 1, the scorer produces 1.0 unless the learner produces no strokes at all.

This asymmetry is by design. Stroke count is genuinely not a useful signal for letters with optional lifts, and the scorer honestly reflects that rather than manufacturing penalties where none are warranted. The result is that StrokeBreakCounter carries real information only on the required-lift letters — which is exactly where it should carry information.

## Revised test list

The original plan's ten tests enforce the rejected symmetric-penalty behaviour ("off by 1 over → 0.5", "symmetric: delta over = delta under"). Replace with the following ten tests against the revised semantics:

- actualCount == minRequiredStrokes → 1.0

- actualCount > minRequiredStrokes → 1.0 (over-counting allowed)

- Extreme over-counting (10× minimum) → 1.0

- actualCount == minRequiredStrokes − 1, min = 2 → 0.5

- actualCount == 1, min = 3 → 0.333

- actualCount == 0 → 0.0

- min = 1, actualCount == 1 → 1.0 (common case)

- min = 1, actualCount == 5 → 1.0 (optional-lift letters never penalised for over-counting)

- Property test: result always in [0.0, 1.0]

- Property test: result monotonic in actualCount up to the minimum, flat at 1.0 thereafter

## UI visibility note

Because 21 of 26 letters score 1.0 unconditionally, displaying a 'Strokes' score for every letter will clutter the UI with uninformative feedback. Consider suppressing the StrokeBreakCounter score in ScoreDisplay when minRequiredStrokes == 1 for the current letter, surfacing it only on the five required-lift letters where it actually discriminates.

This is a ScoreDisplay decision rather than a scorer decision, and does not affect how StrokeBreakCounter itself behaves — but it is worth deciding when the UI layer is wired up, otherwise learners may see a spurious 100% 'Strokes' metric on letters where the scorer has nothing meaningful to report.

# Revised Data Model

The data model reflects the narrower scope and the required-minimum approach to counting.

## StrokeDirection enum

| **StrokeDirection**** value** | **Used for** |
| --- | --- |
| topToBottom | All verticals and all diagonals |
| leftToRight | Horizontals only (crossbars on t, f) |
| clockwise | Right-opening bowls on b, p |
| anticlockwise | o, c, a, d, g, q, e |
| compound | n, m, u, and second stroke of h and k — direction scoring skipped; scored via waypoint sequence (see Waypoints section) |
| dot | i, j dots — scored on presence, not direction |

## StrokeStartRegion enum

The initial implementation uses a vertical-only, three-region model. The letter's bounding box is divided horizontally into thirds (top, middle, bottom) and the first point of each stroke is classified into one of those three zones. No horizontal subdivision is used in the first release.

The rationale is that in print handwriting, almost every first stroke starts at the top of the letter regardless of tradition. This makes "top vs not top" a powerful binary check for RTL-transfer errors without committing to any tradition's view of exactly where around the top the pen should land.

| **Region** | **Position** | **Used for** |
| --- | --- | --- |
| **top** | Upper third of the letter's bounding box | First stroke of almost every letter (stems, ovals, diagonals, dots) |
| **middle** | Middle third of the letter's bounding box | Crossbar on t and f (second stroke) |
| **bottom** | Lower third of the letter's bounding box | Not used as an expected value — appears only as an observed error |

Start regions are relative to the letter's expected bounding box (the template's tight ink bounds — see Bounding Box Source section for the specific data source). This prevents a learner who draws too small or off-centre from scoring wrongly on start position when their formation is otherwise correct.

## Start-region scoring

Each stroke's observed start region is compared to its expected start region. Exact match scores 1.0, adjacent mismatch scores 0.5, opposite mismatch scores 0.0. The overall StrokeStartScorer score is the mean across all strokes.

| **Expected** | **Observed** | **Score** |
| --- | --- | --- |
| top | top | **1.0** |
| top | middle | 0.5 |
| top | bottom | **0.0** |
| middle | middle | **1.0** |
| middle | top or bottom | 0.5 |

## Expansion path

If validation with real learner data later shows that horizontal subdivision carries useful signal — for example, that 'c' learners who start on the left third behave differently from those who start on the right third — the enum can be expanded to topLeft, top, topRight (and equivalents for middle and bottom). Because letter formation data currently only uses the vertical values, adding the horizontal variants is backward-compatible: existing records remain valid, and only the letters where horizontal position matters need updating.

This expansion should be driven by evidence, not anticipation. Ship the simple model first.

## Waypoints (for compound strokes)

Compound strokes — letters where the pen never lifts but travels through multiple distinct directional phases — cannot be scored by a single primaryDirection. 'n' drawn down-up-over-down and a simple diagonal from top-left to bottom-right have the same overall start and end points; only the path through the middle distinguishes them. The waypoints field captures this by specifying an ordered sequence of regions that the stroke must pass through in order.

Waypoints are used only for strokes whose primaryDirection is 'compound'. All other strokes leave the waypoints list empty and are scored by direction as described above. This keeps the scoring elements compartmentalised — each scorer evaluates one thing, cleanly.

## WaypointRegion enum

Waypoints use a 3×3 grid (nine cells) of the letter's bounding box. Horizontal position is needed here because compound strokes cross vertical zones, so the vertical-thirds model used for StrokeStartRegion is not rich enough to distinguish them.

| **topLeft** | **top** | **topRight** |
| --- | --- | --- |
| **left** | **middle** | **right** |
| **bottomLeft** | **bottom** | **bottomRight** |

Note that WaypointRegion is a separate enum from StrokeStartRegion. They are related conceptually but used by different scorers with different granularity requirements. Keeping them distinct preserves the compartmentalised design.

## Waypoint sequences for compound letters

The following sequences define the expected path for each compound stroke. These are starting points — exact cell assignments will need calibration against real learner data. Tolerance (how close an observed point must come to a waypoint to count as a hit) is specified separately in the Waypoint tolerance subsection below.

| **Letter** | **Waypoint sequence** | **Description** |
| --- | --- | --- |
| **n** | topLeft → bottomLeft → top → bottomRight | Stem down, arch up and over, stem down |
| **m** | topLeft → bottomLeft → top → bottom → top → bottomRight | Two arches over three stems |
| **u** | topLeft → bottomLeft → bottom → bottomRight → topRight | Down, curve across bottom, up |
| **h (2nd stroke)** | left → top → bottomRight | Arch from stem, over, and down |
| **k (2nd stroke)** | topRight → middle → bottomRight | Upper kick in to stem, lower kick out |

## Waypoint scoring algorithm

For each expected waypoint in sequence, scan forward through the observed stroke points from the last matched index. Find the closest observed point to the waypoint's cell centre; if it lies within tolerance AND occurs after the previous match, count it as a hit and advance the match index. The stroke score is hits divided by expected waypoints count.

The sequence enforcement (new matches must come after previous matches in the point index) is what makes this a sequential check rather than a set-membership check. A learner who drew 'n' upside-down would touch all the required regions but in the wrong order, and would score 0.

Missing a waypoint is a proportional penalty rather than a hard fail — a stroke that hits 3 of 4 waypoints scores 0.75. This gives more actionable feedback than a binary pass/fail.

## Waypoint tolerance

Tolerance is the radius around each waypoint's anchor point within which an observed stroke point counts as a hit. Real handwriting wobbles, curves cut corners, and arch peaks land slightly off-centre; the scorer cannot require a perfect match on the cell centre.

Tolerance must be expressed relative to the bounding box rather than as a fixed pixel value. A fixed pixel value would mean different things at different rendering sizes — a 20-pixel tolerance is a third of a 60-pixel-tall letter on a phone but only a tenth of a 200-pixel-tall letter on a tablet. The same scorer code would produce hyper-strict scoring on tablets and uselessly forgiving scoring on phones. Expressing tolerance as a fraction of the bounding box makes the scorer scale-invariant: a learner drawing on either device gets scored identically because tolerance scales with the letter.

## Tolerance formula

Tolerance is computed at scoring time as a fraction of the smaller cell dimension:

    tolerance = waypointToleranceFraction × min(cellWidth, cellHeight)

where cellWidth = boundingBox.width / 3 and cellHeight = boundingBox.height / 3, derived from the tight template bounding box specified in the Bounding Box Source section.

Using min(cellWidth, cellHeight) rather than width or height alone produces a circular hit zone that fits within any cell, regardless of letter aspect ratio. The default value of waypointToleranceFraction is 0.5, exposed as a const in CompoundStrokeScorer:

    static const double waypointToleranceFraction = 0.5;

At fraction = 0.5, the tolerance circles around adjacent waypoints just touch but do not overlap, preserving the meaning of the grid. At fraction = 1.0, neighbouring tolerance circles overlap and the scorer cannot reliably distinguish which cell a point belongs to. At fraction below 0.3, the scorer requires near-pixel-perfect hits and natural handwriting variation produces false negatives. 0.5 is the geometrically defensible starting point and the value the scorer ships with.

## Why this is calibration-ready, not calibrated

0.5 is a defensible starting value, not a final value. The right tolerance depends on real learner stroke data — how much wobble actual ESOL learners produce when writing each letter. The scorer is designed to make tuning trivial: change one constant, rebuild, observe results. Once learner data is available, validate against a sample of strokes that should score well (correct formations) and a sample that should score poorly (clear errors), and adjust the fraction up or down until the boundary between them is sharp.

## Aspect-ratio note

The 3×3 grid produces square-ish cells when the bounding box is roughly square. For elongated letters (tall narrow 'l', wide squat 'm'), cells are rectangles. The min-dimension formula handles this correctly — tolerance shrinks to fit the narrower dimension, preventing hit zones from spilling out of their cells. None of the current compound letters (n, m, u, h, k) have extreme aspect ratios, so this is not an immediate concern, but the formula is robust if compound scoring is later extended to letters that do.

## ExpectedStroke and LetterFormationData

ExpectedStroke carries three fields: primaryDirection (from the StrokeDirection enum), startRegion (from the StrokeStartRegion enum), and waypoints (an ordered list of WaypointRegion values, empty for non-compound strokes).

LetterFormationData carries the list of expected strokes and minRequiredStrokes. The canonical stroke count is derived as strokes.length; minRequiredStrokes is a separate field representing the pen-lift floor.

# Bounding Box Source

Three of the four scorers (StrokeStartScorer, StrokeDirectionScorer's spatial matching, and CompoundStrokeScorer) need a bounding box to compute regions against. This section resolves where that bounding box comes from.

## Resolution

The bounding box used for region computation is templateResult.inkBounds, extended to be column-tight for horizontal accuracy. inkBounds is already computed in template_rasterizer.dart and is in scope at scoring time — _runScoring() in drawing_canvas.dart already references it (line 70). It represents the vertical extent of actual ink in the rasterised glyph, which is the right concept for region scoring: it excludes the line-height whitespace that templateResult.bounds (the TextPainter layout rect) includes above and below short letters.

## Required extension

inkBounds as currently implemented is vertically tight (computed by row-scanning the mask) but horizontally inherits its left and right edges from the full TextPainter layout width. For a thin letter like 'i' or 'l', this means the horizontal extent is too wide — the box stretches across the full glyph cell rather than hugging the actual ink.

StrokeStartScorer's vertical-thirds model is unaffected by this and could use inkBounds as-is. CompoundStrokeScorer needs horizontal accuracy because its 3×3 grid divides into columns. The fix is a symmetric column scan added to the inkBounds computation, mirroring the existing row scan in template_rasterizer.dart (lines 22–39). Approximately ten lines of code; produces a fully tight bounding box.

Implementation note: rather than modifying inkBounds itself (which is consumed by the existing PlacementScorer for vertical-only purposes), add a new getter — tightBounds or formationBounds — to TemplateRasterResult. This preserves the existing scorer's contract and makes the new behaviour additive.

## Why not the alternatives

- **templateResult.bounds**** — **the TextPainter layout rect. Includes line-height whitespace above and below the actual ink, so a short letter like 'a' would have its 'top third' fall in empty space above the glyph. Wrong concept for region scoring.

- **Learner's stroke bounding box — **computed from the strokes the learner actually drew. Self-referential: a learner who draws too small gets their regions shrunk proportionally, so a stroke starting at the top of their tiny drawing always looks correct regardless of where on the canvas it landed. Defeats the purpose of start-position scoring.

- **Canvas bounds — **only horizontal width is available (_canvasWidth); no vertical extent in scope. Even if it were, the canvas is much larger than the letter, so regions would be meaningless.

## What this means for implementation

The bounding box source is settled. No design changes to the scope are required. The implementation work consists of: (1) adding the column scan to TemplateRasterResult to produce a tight bounding box, exposed as a new getter; (2) passing this tight bounding box into each formation scorer that needs it; (3) computing region cells as fractions of that bounding box's width and height.

PlacementScorer's existing use of inkBounds.top/bottom is unaffected and need not change.

# Scoring Architecture

Three scorers, each producing an independent 0.0–1.0 score. Each is optional in ScoreResult — null when not applicable.

- **StrokeStartScorer**** — **checks where the first point of each stroke lands relative to the letter template's bounding box. The single most diagnostic check for RTL-transfer errors.

- **StrokeDirectionScorer**** — **for strokes marked as a scorable direction (not compound, not dot), checks that the movement matches expectation. Correct = 1.0, opposite = 0.0, other mismatch = 0.5.

- **CompoundStrokeScorer**** — **for strokes marked compound, runs the waypoint sequence check described above. Produces a 0.0–1.0 score per stroke; the overall CompoundStrokeScorer score is the mean across all compound strokes in the letter.

- **StrokeBreakCounter**** — **threshold check against minRequiredStrokes. At or above the minimum = 1.0; below = proportional partial credit (actualCount / minRequiredStrokes). Carries real signal only on the five required-lift letters (f, i, j, t, x).

Stroke-to-expected matching uses spatial matching (nearest bounding-box centroid), not positional. This separates three distinct error classes cleanly: wrong place, wrong direction, and wrong order.

# Feedback Output

Each scorer returns more than a single number. To prove the concept that the scoring module can produce meaningful, learner-facing feedback, scorers must surface as much information as possible about what they observed — not only when something went wrong, but also when something went right. A correct stroke that the scorer can describe ("started in the top-left as expected") is as much evidence the system works as a wrong stroke it can flag.

## Why this matters for a proof of concept

If a scorer returns only a 0.0–1.0 score, there is no way to confirm whether the scorer caught the right thing or got confused. A 50% direction score could mean the scorer correctly identified that one of two strokes went the wrong way, or it could mean the scorer misclassified a correct stroke. With per-stroke observations attached to the score, every result is auditable: you can read exactly what the scorer thought happened and verify whether it was right.

This also makes the scorers self-debugging during development. When a manual trial produces a surprising score, the observations explain why without requiring separate instrumentation.

## Required output shape

Every scorer returns three pieces of information:

- **Overall score **(double, 0.0–1.0) — the headline number used for percentage display in ScoreDisplay.

- **Per-stroke observations **(list) — one entry per stroke examined, including correct strokes. Each observation captures: expected behaviour, observed behaviour, per-stroke score, and a plain-language note describing the result.

- **Summary message **(string, one or two sentences) — a learner-facing description of the overall result, suitable for direct display as a caption or feedback line.

## StrokeObservation data structure

A single shared data class captures the per-stroke observation, used by all four scorers:

class StrokeObservation {

    final int strokeIndex;          // which stroke was examined

    final String expected;          // what the rule called for

    final String observed;          // what the learner actually did

    final double score;             // 0.0–1.0 for this individual stroke

    final String note;              // plain-language explanation

}

expected and observed are strings rather than enum values to keep the structure scorer-agnostic — StrokeStartScorer might record expected = "top", StrokeDirectionScorer might record expected = "leftToRight", and CompoundStrokeScorer might record expected = "top → bottomLeft → top → bottomRight". The string field accommodates all of them without requiring a discriminated union per scorer.

## Scorer return type

Each scorer returns a FormationScore (or per-scorer subtype if helpful):

class FormationScore {

    final double overallScore;

    final List<StrokeObservation> observations;

    final String summary;

}

ScoreResult holds four optional FormationScore fields (one per scorer) alongside the existing bitmap score fields. ScoreDisplay reads overallScore for percentage display today; observations and summary are populated now and consumed by feedback UI work later.

## Example output

StrokeStartScorer running on a correctly-drawn 'n':

    overallScore: 1.0

    observations: [{ strokeIndex: 0, expected: "top", observed: "topLeft", score: 1.0, note: "Started in the top region — correct." }]

    summary: "All strokes started in the right place."

StrokeStartScorer running on a reversed 'n':

    overallScore: 0.0

    observations: [{ strokeIndex: 0, expected: "top", observed: "bottomRight", score: 0.0, note: "Started at the bottom-right; should start at the top." }]

    summary: "The stroke started in the wrong place — try starting at the top."

StrokeDirectionScorer running on a learner who drew the 'o' clockwise:

    overallScore: 0.0

    observations: [{ strokeIndex: 0, expected: "anticlockwise", observed: "clockwise", score: 0.0, note: "Drew the circle clockwise; should be drawn anticlockwise." }]

    summary: "The circle was drawn the wrong way round."

## Notes for each scorer

- **StrokeStartScorer**** **populates one observation per stroke, recording the expected and observed StrokeStartRegion as strings.

- **StrokeDirectionScorer**** **populates one observation per non-compound, non-dot stroke. For compound and dot strokes, an observation is still recorded with note = "skipped — handled by CompoundStrokeScorer" or similar, so the audit trail is complete.

- **CompoundStrokeScorer**** **populates one observation per compound stroke, recording which waypoints were hit and which were missed. The note should identify the missed waypoint by description ("missed the arch peak") rather than by index where possible.

- **StrokeBreakCounter**** **populates a single observation describing minRequiredStrokes and actualCount. For optional-lift letters where minRequiredStrokes = 1, the observation should note this explicitly ("this letter accepts any number of strokes").

# Out of Scope

Recorded explicitly so these do not quietly creep back in:

- Letter reversal / mirror writing (separate error class, not an RTL-transfer signal)

- Stroke timing, pressure, or velocity

- Absolute letter size or position on canvas

- Joins between letters (this is a print-letter checker, not a cursive one)

- Tradition-specific elements listed under 'Excluded by design' above

# Future Directions

## Waypoints as a replacement for direction scoring

The waypoint mechanism introduced here for compound strokes could, in principle, replace StrokeDirectionScorer entirely. A linear stroke becomes a two-waypoint sequence (start region → end region). A circular stroke becomes a four-waypoint sequence, for example anticlockwise 'o' as top → left → bottom → right. This would unify all stroke scoring under a single mechanism and remove the need for the signed-area (shoelace) calculation, which is sensitive to noise on short or jagged strokes.

This is deliberately deferred. The current design keeps each scoring element compartmentalised — StrokeDirectionScorer evaluates direction, CompoundStrokeScorer evaluates waypoint sequences, StrokeStartScorer evaluates starting position, StrokeBreakCounter evaluates pen-lift thresholds. Each can be validated and tuned independently, and each produces feedback that maps to a specific teaching moment. Unifying them before the compartmentalised versions are proven risks losing that clarity.

Once the compartmentalised scorers have been validated against real learner data, moving to a unified waypoint model becomes a straightforward refactor — the compound-stroke waypoint machinery already exists, and only the per-letter data file needs expansion.

# Summary of Changes From Original Plan

- **Scope narrowed **to universal, tradition-neutral elements only.

- **Stroke count reframed **as minRequiredStrokes (threshold), not exact match (distance curve).

- **Starting region promoted **from Phase 3 to core — it is the most diagnostic single check.

- **Spatial matching adopted **in place of positional matching, so wrong-order and wrong-direction are distinguishable.

- **Compound-stroke letters handled explicitly **(n, m, h, u) — direction check skipped, start region carries the weight.

- **Compound-stroke letters handled via waypoints **(n, m, u, second stroke of h and k) — an ordered sequence of regions the stroke must pass through, using a 3×3 WaypointRegion grid.

- **StrokeDirection**** ****enum**** simplified **to six values; bottomToTop and rightToLeft exist only as observed errors, never as targets.