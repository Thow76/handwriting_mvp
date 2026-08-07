# Waypoint Section Definitions

Reference document for bespoke numbered section layouts for waypoint scoring.
All bounds are expressed as fractions of tight ink bounds (0.0–1.0).
Sections are numbered in stroke order — the sequence the learner is expected
to travel through them, not by grid position.

## Scoring model (applies to every letter)

Scoring is strictly pass or fail. A stroke scores 1.0 only if every one of its
numbered sections is hit in the correct sequential order; otherwise it scores 0.0.
There is no partial credit for a correct prefix, no credit for out-of-order hits,
and scoring stops at the first break in the sequence. For multi-stroke letters,
every stroke must pass for the letter to pass.

The bitmap metrics (Coverage, Precision, Placement, Efficiency) handle whether the
resulting shape looks correct. The waypoint sections check only whether the correct
process was followed to produce it.

The section rectangles below are derived by reasoning about each glyph's path.
They have not been visually validated against the rendered Andika typeface, and
should be treated as provisional until an a–z validation sweep confirms them.

---

## Letter: a

### Grid layout

3 columns × 2 rows = 6 sections.

The rightmost column is narrow and maps to the stem of the letter.
The left and middle columns cover the oval.
The horizontal division sits at the midpoint of the letter height.

| | Left col (x 0.00–0.38) | Middle col (x 0.38–0.72) | Stem col (x 0.72–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.50)** | Section 2 | Section 1 | Section 5 |
| **Bottom row (y 0.50–1.00)** | Section 3 | Section 4 | Section 6 |

### Section definitions

| Section | Label | x min | x max | y min | y max |
|---------|-------|-------|-------|-------|-------|
| 1 | Oval top-right | 0.38 | 0.72 | 0.00 | 0.50 |
| 2 | Oval top-left | 0.00 | 0.38 | 0.00 | 0.50 |
| 3 | Oval bottom-left | 0.00 | 0.38 | 0.50 | 1.00 |
| 4 | Oval bottom-right | 0.38 | 0.72 | 0.50 | 1.00 |
| 5 | Stem top | 0.72 | 1.00 | 0.00 | 0.50 |
| 6 | Stem bottom | 0.72 | 1.00 | 0.50 | 1.00 |

### Expected sequence

1 → 2 → 3 → 4 → 5 → 6

The stroke starts at the top-right of the oval, sweeps anticlockwise
(top-left → bottom-left → bottom-right), then travels up to the top
of the stem and down to finish.

### Scoring model

Scoring is strictly pass or fail. A stroke scores 1.0 only if every one of its
numbered sections is hit in the correct sequential order. If any section is missed,
or any section is hit out of order, the stroke scores 0.0. There is no partial
credit for a correct prefix, and scoring stops the moment the sequence breaks.

The bitmap metrics (Coverage, Precision, Placement, Efficiency) handle whether the
resulting shape looks correct. The waypoint sections are not checking the shape —
they are checking whether the correct process was followed to produce it.

### Error cases

| Scenario | What happens | Score |
|----------|-------------|-------|
| Correct anticlockwise a | All six sections hit in order | PASS |
| Straight vertical line | Section 1 never hit — sequence never starts | FAIL |
| Clockwise oval + stem | Section 1 hit, then sequence breaks at section 4 (goes wrong way) | FAIL |
| Anticlockwise oval, no stem | Sections 1–4 hit in order, sequence ends there | FAIL |
| Started from bottom of oval | Section 1 never hit — sequence never starts | FAIL |
| Started from stem top | Section 1 never hit — sequence never starts | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- The stem column is intentionally narrow to reflect the actual
  proportional width of the stem in the letter.
- Section 1 acts as a gatekeeper — nothing scores until the stroke
  enters the top-right of the oval, which a straight vertical line
  cannot do.

---

## Letter: b

### Grid layout

3 columns × 2 rows = 6 sections.

The leftmost column is narrow and maps to the stem. The middle and right
columns cover the bowl. The horizontal division sits at the midpoint of
the letter height.

| | Stem col (x 0.00–0.30) | Middle col (x 0.30–0.58) | Right col (x 0.58–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.48)** | Section 1 | Section 3 | Section 4 |
| **Bottom row (y 0.48–1.00)** | Section 2 | Section 6 | Section 5 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.00 | 0.30 | 0.00 | 0.48 |
| 2 | 0 | Stem bottom | 0.00 | 0.30 | 0.48 | 1.00 |
| 3 | 1 | Bowl top-left | 0.30 | 0.58 | 0.00 | 0.48 |
| 4 | 1 | Bowl top-right | 0.58 | 1.00 | 0.00 | 0.48 |
| 5 | 1 | Bowl bottom-right | 0.58 | 1.00 | 0.48 | 1.00 |
| 6 | 1 | Bowl bottom-left | 0.30 | 0.58 | 0.48 | 1.00 |

### Expected sequences

b is a two-stroke letter. Each stroke has its own independent sequence.
Both sequences must pass for the letter to pass.

- Stroke 0 (stem): 1 → 2
- Stroke 1 (bowl, clockwise): 3 → 4 → 5 → 6

### Scoring model

Each stroke's sections must be hit in strict order within that stroke, and each
stroke scores 1.0 or 0.0 on that basis alone. The letter passes only if every
stroke passes; any failing stroke fails the letter.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct b | PASS | PASS | PASS |
| Stem only, no bowl | PASS | FAIL | FAIL |
| Reversed stem, correct bowl | FAIL | PASS | FAIL |
| Correct stem, anticlockwise bowl | PASS | FAIL — breaks after section 3 | FAIL |
| Reversed stem, no bowl | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- Sections 1–2 belong to stroke 0 and sections 3–6 to stroke 1.
  A learner who draws the bowl correctly despite reversing the stem
  still fails the letter — the stem stroke scores 0.0, and every
  stroke must pass.

---

## Letter: c

### Grid layout

2 columns × 2 rows = 4 sections.

A simple equal-quadrant grid. The vertical and horizontal divisions
both sit at the midpoint of the letter.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.50)** | Section 2 | Section 1 |
| **Bottom row (y 0.50–1.00)** | Section 3 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Top-right | 0.50 | 1.00 | 0.00 | 0.50 |
| 2 | 0 | Top-left | 0.00 | 0.50 | 0.00 | 0.50 |
| 3 | 0 | Bottom-left | 0.00 | 0.50 | 0.50 | 1.00 |
| 4 | 0 | Bottom-right | 0.50 | 1.00 | 0.50 | 1.00 |

### Expected sequence

1 → 2 → 3 → 4

Single stroke starting at the top-right, sweeping anticlockwise over
the top, down the left side, along the bottom, finishing at the
bottom-right.

### Error cases

| Scenario | What happens | Score |
|----------|-------------|-------|
| Correct anticlockwise c | All four sections hit in order | PASS |
| Clockwise c (starts bottom-right) | Section 1 never hit first — sequence never starts | FAIL |
| Correct direction, stops halfway | Sections 1–2 hit, sequence ends | FAIL |
| Straight line | Section 1 never hit — sequence never starts | FAIL |

### Notes

- The equal quadrant grid works well for c because the stroke
  travels through all four quadrants in a clean sequence.
- Section 1 (top-right) is the gatekeeper. A clockwise stroke
  starting from the bottom-right hits section 4 first and scores
  nothing.

---

## Letter: d

### Grid layout

3 columns × 2 rows = 6 sections.

Three equal columns. The rightmost column maps to the ascender stem.
The left and middle columns cover the anticlockwise bowl.
The horizontal division sits at the midpoint of the letter height.

Note: d is the mirror of b — stem on the right, bowl on the left.

| | Left col (x 0.00–0.33) | Middle col (x 0.33–0.67) | Stem col (x 0.67–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.50)** | Section 4 | Section 3 | Section 1 |
| **Bottom row (y 0.50–1.00)** | Section 5 | Section 6 | Section 2 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.67 | 1.00 | 0.00 | 0.50 |
| 2 | 0 | Stem bottom | 0.67 | 1.00 | 0.50 | 1.00 |
| 3 | 1 | Bowl top-right | 0.33 | 0.67 | 0.00 | 0.50 |
| 4 | 1 | Bowl top-left | 0.00 | 0.33 | 0.00 | 0.50 |
| 5 | 1 | Bowl bottom-left | 0.00 | 0.33 | 0.50 | 1.00 |
| 6 | 1 | Bowl bottom-right | 0.33 | 0.67 | 0.50 | 1.00 |

### Expected sequences

d is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom): 1 → 2
- Stroke 1 (bowl, anticlockwise): 3 → 4 → 5 → 6

The bowl starts at the top-middle where it meets the stem, sweeps
left across the top, down the left side, along the bottom, and
closes back at the bottom-middle.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct d | PASS | PASS | PASS |
| Stem only, no bowl | PASS | FAIL | FAIL |
| Reversed stem, correct bowl | FAIL | PASS | FAIL |
| Correct stem, clockwise bowl | PASS | FAIL — breaks after section 3 | FAIL |
| Reversed stem, no bowl | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- d is structurally identical to b but mirrored — the same six-section
  two-stroke model applies, with stem and bowl columns swapped.

---

## Letter: e

> **Provenance note.** Unlike every other letter in this document, e was
> never designed here. No screenshot or grid layout was agreed for it
> during the authoring session, and the letter was skipped. The design
> below was authored by a coding agent during the Phase D migration
> (PR #141, closing issue #137) and is recorded here after the fact so
> the document is complete. It has not been reviewed against a grid
> overlay in the way the other 25 letters were.

### Grid layout

5 sections, single stroke.

e is the only letter that begins with a horizontal movement before
joining a curve. The first section is bespoke — it covers the tongue,
the straight horizontal stroke that runs left to right across the
middle of the letter. Once the tongue completes, the path is
genuinely identical to a's anticlockwise oval, so the remaining four
sections reuse that geometry.

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Tongue (horizontal) | *see registry* | | | |
| 2 | 0 | Oval top-right | *see registry* | | | |
| 3 | 0 | Oval top-left | *see registry* | | | |
| 4 | 0 | Oval bottom-left | *see registry* | | | |
| 5 | 0 | Oval bottom-right | *see registry* | | | |

The exact rectangle values live in `letter_formation_registry.dart`
and are pinned by assertions in `letter_formation_registry_test.dart`.
They have not been transcribed into this document.

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3 → 4 → 5

The stroke starts at the left end of the tongue, travels right across
the middle of the letter, then curves up and sweeps anticlockwise —
over the top, down the left side, along the bottom — to finish at the
bottom-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct e | PASS |
| Tongue drawn right to left | FAIL — section 1 never entered from the left |
| Oval drawn first, tongue second | FAIL — sequence starts out of order |
| Tongue only, no oval | FAIL |
| Correct tongue, clockwise oval | FAIL — sequence breaks after section 2 |

### Notes

- e is the only letter in the document with a bespoke leading section
  followed by borrowed geometry.
- The starting position was confirmed separately during the start
  rectangle work: e begins on the **left**, where the tongue starts,
  not on the right. Start rectangle x 0–25%, y 40–60%.
- The e template glyph previously had a malformed tongue, which
  distorted its tight ink bounds. This was resolved by the change to
  the Andika typeface.
- Because this layout was agent-authored rather than designed against
  a grid overlay, it is the strongest candidate in the document for
  review during the a–z validation sweep.

---

## Letter: f

### Grid layout

3 columns × 2 rows = 6 cells, but only 5 are active.
The top-left cell is empty — no part of the letter passes through it.

The middle column is narrow and contains the stem.
The right column is wide and contains the hook at the top and the
right extension of the crossbar.
The left column is narrow and contains only the left end of the crossbar.
The horizontal division sits at approximately the crossbar level.

| | Left col (x 0.00–0.26) | Middle col (x 0.26–0.46) | Right col (x 0.46–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.30)** | — (empty) | Section 2 | Section 1 |
| **Bottom row (y 0.30–1.00)** | Section 4 | Section 3 | Section 5 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Hook top-right | 0.46 | 1.00 | 0.00 | 0.30 |
| 2 | 0 | Hook meets stem | 0.26 | 0.46 | 0.00 | 0.30 |
| 3 | 0 | Stem body | 0.26 | 0.46 | 0.30 | 1.00 |
| 4 | 1 | Crossbar left | 0.00 | 0.26 | 0.30 | 1.00 |
| 5 | 1 | Crossbar right | 0.46 | 1.00 | 0.30 | 1.00 |

### Expected sequences

f is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (curved stem): 1 → 2 → 3
- Stroke 1 (crossbar, left to right): 4 → 5

The stem stroke starts at the top of the hook on the right, sweeps
left through the top-middle, then travels down the full stem.
The crossbar stroke starts at the left and travels right across the stem.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct f | PASS | PASS | PASS |
| Stem only, no crossbar | PASS | FAIL | FAIL |
| Straight stem, no hook | FAIL — section 1 never hit | PASS | FAIL |
| Correct stem, crossbar right to left | PASS | FAIL — section 4 never hit first | FAIL |
| Reversed stem (bottom to top), no crossbar | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- f is one of the letters where StrokeBreakCounter carries meaningful
  signal — the crossbar is a mandatory second stroke.
- The top-left cell is unused. Section 1 (top-right hook) acts as the
  gatekeeper for stroke 0 — a straight downward stem never enters it
  and scores zero for that stroke.

---

## Letter: g

### Grid layout

2 columns × 3 rows = 6 sections.

The right column is narrow and contains the descender stem.
The left column is wide and contains the bowl and the bottom hook.
Three rows divide the letter vertically — top covers the bowl,
middle covers the stem junction, bottom covers the descender hook.

| | Left col (x 0.00–0.78) | Right col (x 0.78–1.00) |
|---|---|---|
| **Top row (y 0.00–0.40)** | Section 2 | Section 1 |
| **Middle row (y 0.40–0.65)** | Section 3 | Section 4 |
| **Bottom row (y 0.65–1.00)** | Section 6 | Section 5 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Bowl top-right | 0.78 | 1.00 | 0.00 | 0.40 |
| 2 | 0 | Bowl top-left | 0.00 | 0.78 | 0.00 | 0.40 |
| 3 | 0 | Bowl bottom | 0.00 | 0.78 | 0.40 | 0.65 |
| 4 | 1 | Stem top | 0.78 | 1.00 | 0.40 | 0.65 |
| 5 | 1 | Stem bottom | 0.78 | 1.00 | 0.65 | 1.00 |
| 6 | 1 | Descender hook | 0.00 | 0.78 | 0.65 | 1.00 |

### Expected sequences

g is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (anticlockwise bowl): 1 → 2 → 3
- Stroke 1 (descender stem and hook): 4 → 5 → 6

The bowl starts at the top-right where it meets the stem, sweeps
anticlockwise over the top and down the left side, closing at the
bottom-middle. The descender then starts at the mid-right stem
junction, travels down, and hooks to the left at the bottom.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct g | PASS | PASS | PASS |
| Bowl only, no descender | PASS | FAIL | FAIL |
| Clockwise bowl, correct descender | FAIL — breaks after section 1 | PASS | FAIL |
| Correct bowl, reversed stem (bottom to top) | PASS | FAIL | FAIL |
| Correct bowl, stem only (no hook) | PASS | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- The 3-row structure is necessary here because the descender extends
  below the baseline — a 2-row grid would not distinguish the stem
  from the descender hook.
- Section 6 (descender hook) captures whether the learner completed
  the full descender curve to the left, rather than stopping mid-stem.

---

## Letter: h

### Grid layout

2 columns × 2 rows = 4 sections.

The left column is narrow and contains the ascender stem.
The right column is wide and contains the arch.
The horizontal division sits at approximately the point where the
arch branches off from the stem.

| | Left col (x 0.00–0.22) | Right col (x 0.22–1.00) |
|---|---|---|
| **Top row (y 0.00–0.57)** | Section 1 | Section 3 |
| **Bottom row (y 0.57–1.00)** | Section 2 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.00 | 0.22 | 0.00 | 0.57 |
| 2 | 0 | Stem bottom | 0.00 | 0.22 | 0.57 | 1.00 |
| 3 | 1 | Arch peak | 0.22 | 1.00 | 0.00 | 0.57 |
| 4 | 1 | Arch right leg | 0.22 | 1.00 | 0.57 | 1.00 |

### Expected sequences

h is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom): 1 → 2
- Stroke 1 (arch): 3 → 4

The arch stroke starts from the stem junction, sweeps up through
the top-right area, then comes down the right leg through the
bottom-right area.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct h | PASS | PASS | PASS |
| Stem only, no arch | PASS | FAIL | FAIL |
| Reversed stem, correct arch | FAIL | PASS | FAIL |
| Correct stem, arch drawn bottom to top | PASS | FAIL — section 4 hit before section 3 | FAIL |
| Reversed stem, no arch | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- Section 3 (arch peak) is the gatekeeper for stroke 1 — the arch
  must pass through the upper-right area before the lower-right,
  catching a bottom-to-top reversal of the arch leg.

---

## Letter: i

### Grid layout

1 column × 3 rows = 3 sections, all active.

No vertical division. The top row is the dot area. The stem is
subdivided into upper and lower halves, allowing a bottom-to-top
reversed stroke to be caught by the strict sequential check.

| | Full width (x 0.00–1.00) |
|---|---|
| **Top row (y 0.00–0.28)** | Section 1 |
| **Middle row (y 0.28–0.62)** | Section 2 |
| **Bottom row (y 0.62–1.00)** | Section 3 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 1 | Dot area | 0.00 | 1.00 | 0.00 | 0.28 |
| 2 | 0 | Stem top | 0.00 | 1.00 | 0.28 | 0.62 |
| 3 | 0 | Stem bottom | 0.00 | 1.00 | 0.62 | 1.00 |

### Expected sequences

i is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom): 2 → 3
- Stroke 1 (dot): 1

The stem must pass through the upper half before the lower half,
catching a reversed bottom-to-top stroke. The dot is a single
section presence check.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct i (stem + dot) | PASS | PASS | PASS |
| Stem only, no dot | PASS | FAIL | FAIL |
| Reversed stem (bottom to top) | FAIL — section 3 hit before section 2 | PASS | FAIL |
| Dot only, no stem | FAIL | PASS | FAIL |
| Dot drawn in stem area | PASS | FAIL | FAIL |

### Notes

- Row boundary proportions are approximate and require visual
  validation against the Andika typeface before finalising.
- The stem subdivision was added specifically to catch reversed
  bottom-to-top strokes, which the original 2-section layout
  could not detect.
- i is one of the five letters where StrokeBreakCounter carries
  meaningful signal — the dot is a mandatory second stroke.

---

## Letter: j

### Grid layout

1 column × 3 rows = 3 sections, all active.

Identical structure to i. The top row is the dot area. The stem
is subdivided into upper and lower halves to catch reversed
bottom-to-top strokes. The bottom row includes the descender hook.

| | Full width (x 0.00–1.00) |
|---|---|
| **Top row (y 0.00–0.25)** | Section 1 |
| **Middle row (y 0.25–0.63)** | Section 2 |
| **Bottom row (y 0.63–1.00)** | Section 3 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 1 | Dot area | 0.00 | 1.00 | 0.00 | 0.25 |
| 2 | 0 | Stem top | 0.00 | 1.00 | 0.25 | 0.63 |
| 3 | 0 | Stem bottom and hook | 0.00 | 1.00 | 0.63 | 1.00 |

### Expected sequences

j is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem with descender hook, top to bottom): 2 → 3
- Stroke 1 (dot): 1

The stem must pass through the upper half before the lower half,
catching a reversed bottom-to-top stroke. The descender hook is
contained within section 3.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct j (stem + dot) | PASS | PASS | PASS |
| Stem only, no dot | PASS | FAIL | FAIL |
| Reversed stem (bottom to top) | FAIL — section 3 hit before section 2 | PASS | FAIL |
| Dot only, no stem | FAIL | PASS | FAIL |

### Notes

- Row boundary proportions are approximate and require visual
  validation against the Andika typeface before finalising.
- j and i now share the same 3-section structure. The top row
  is proportionally smaller for j because the descender makes
  the full bounding box taller.
- j is one of the five letters where StrokeBreakCounter carries
  meaningful signal — the dot is a mandatory second stroke.

---

## Letter: k

### Grid layout

2 columns × 2 rows = 4 sections.

Identical grid structure to h. The left column is narrow and contains
the ascender stem. The right column is wide and contains the kick
strokes. The horizontal division sits at approximately the mid-height
junction where the two diagonals of the kick meet.

| | Left col (x 0.00–0.21) | Right col (x 0.21–1.00) |
|---|---|---|
| **Top row (y 0.00–0.57)** | Section 1 | Section 3 |
| **Bottom row (y 0.57–1.00)** | Section 2 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.00 | 0.21 | 0.00 | 0.57 |
| 2 | 0 | Stem bottom | 0.00 | 0.21 | 0.57 | 1.00 |
| 3 | 1 | Kick upper diagonal | 0.21 | 1.00 | 0.00 | 0.57 |
| 4 | 1 | Kick lower diagonal | 0.21 | 1.00 | 0.57 | 1.00 |

### Expected sequences

k is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom): 1 → 2
- Stroke 1 (kick): 3 → 4

The kick stroke starts from the top-right, sweeps diagonally down
to the junction point at mid-height, then continues diagonally down
to the bottom-right.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct k | PASS | PASS | PASS |
| Stem only, no kick | PASS | FAIL | FAIL |
| Reversed stem, correct kick | FAIL | PASS | FAIL |
| Correct stem, kick drawn bottom to top | PASS | FAIL — section 4 hit before section 3 | FAIL |
| Reversed stem, no kick | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- k and h share the same grid structure. The only difference is the
  nature of the second stroke — arch for h, kick diagonals for k.
- Section 3 (kick upper) is the gatekeeper for stroke 1 — the kick
  must enter the upper-right area before the lower-right, catching
  a bottom-to-top reversal.

---

## Letter: l

### Grid layout

1 column × 2 rows = 2 sections.

No vertical division. The horizontal division splits the stem into
upper and lower halves, allowing direction to be verified.

| | Full width (x 0.00–1.00) |
|---|---|
| **Top row (y 0.00–0.42)** | Section 1 |
| **Bottom row (y 0.42–1.00)** | Section 2 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.00 | 1.00 | 0.00 | 0.42 |
| 2 | 0 | Stem bottom | 0.00 | 1.00 | 0.42 | 1.00 |

### Expected sequence

- Stroke 0 (stem, top to bottom): 1 → 2

### Error cases

| Scenario | Score |
|----------|-------|
| Correct l (top to bottom) | PASS |
| Reversed stem (bottom to top) | FAIL — section 2 hit before section 1 |
| Partial stroke (top half only) | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- l is one of the most straightforward letters in the system —
  a single stroke, two sections, one directional check.
- Section 1 is the gatekeeper. A reversed stroke hits section 2
  first and scores zero.

---

## Letter: m

### Grid layout

3 columns × 2 rows = 6 sections, all active.

The left column is narrow and covers the first leg.
The middle column covers the first arch and second leg.
The right column covers the second arch and third leg.
The horizontal division sits at approximately mid-height.

| | Left col (x 0.00–0.18) | Middle col (x 0.18–0.62) | Right col (x 0.62–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.53)** | Section 1 | Section 3 | Section 5 |
| **Bottom row (y 0.53–1.00)** | Section 2 | Section 4 | Section 6 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | First leg top | 0.00 | 0.18 | 0.00 | 0.53 |
| 2 | 0 | First leg bottom | 0.00 | 0.18 | 0.53 | 1.00 |
| 3 | 0 | First arch top | 0.18 | 0.62 | 0.00 | 0.53 |
| 4 | 0 | First arch bottom | 0.18 | 0.62 | 0.53 | 1.00 |
| 5 | 0 | Second arch top | 0.62 | 1.00 | 0.00 | 0.53 |
| 6 | 0 | Second arch bottom | 0.62 | 1.00 | 0.53 | 1.00 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3 → 4 → 5 → 6

The stroke starts at the top-left, descends the first leg, rises
through the first arch, descends the second leg, rises through the
second arch, then descends the third leg to finish at the bottom-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct m | PASS |
| First leg only | FAIL |
| First leg and first arch only | FAIL |
| Reversed (starts bottom-right) | FAIL — section 1 never hit |
| Started from wrong side (top-right) | FAIL — section 1 never hit |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- m is a single stroke covering all 6 sections. The left-to-right
  progression of the columns means any attempt to draw m from the
  wrong side scores zero immediately.
- The green dots visible in the screenshot mark the endpoints of the
  horizontal divider and confirm it runs the full width of the letter.

---

## Letter: n

### Grid layout

2 columns × 2 rows = 4 sections, all active.

The left column is narrow and covers the first leg.
The right column is wide and covers the arch and second leg.
The horizontal division sits at approximately mid-height.

n is a single-arch version of m — same structure, half the columns.

| | Left col (x 0.00–0.22) | Right col (x 0.22–1.00) |
|---|---|---|
| **Top row (y 0.00–0.52)** | Section 1 | Section 3 |
| **Bottom row (y 0.52–1.00)** | Section 2 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | First leg top | 0.00 | 0.22 | 0.00 | 0.52 |
| 2 | 0 | First leg bottom | 0.00 | 0.22 | 0.52 | 1.00 |
| 3 | 0 | Arch top | 0.22 | 1.00 | 0.00 | 0.52 |
| 4 | 0 | Second leg bottom | 0.22 | 1.00 | 0.52 | 1.00 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3 → 4

The stroke starts at the top-left, descends the first leg, rises
through the arch, then descends the second leg to finish at
the bottom-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct n | PASS |
| First leg only | FAIL |
| Reversed (starts bottom-right) | FAIL — section 1 never hit |
| Started from top-right | FAIL — section 1 never hit |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- n and m share the same underlying grid logic. n uses 4 sections
  across 2 columns; m extends that to 6 sections across 3 columns.
- Section 1 (first leg top) is the gatekeeper — starting from
  anywhere other than the top-left scores zero immediately.

---

## Letter: o

### Grid layout

2 columns × 2 rows = 4 sections.

Identical grid structure to c. Equal quadrant division — both the
vertical and horizontal divisions sit at the midpoint of the letter.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.50)** | Section 2 | Section 1 |
| **Bottom row (y 0.50–1.00)** | Section 3 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Top-right | 0.50 | 1.00 | 0.00 | 0.50 |
| 2 | 0 | Top-left | 0.00 | 0.50 | 0.00 | 0.50 |
| 3 | 0 | Bottom-left | 0.00 | 0.50 | 0.50 | 1.00 |
| 4 | 0 | Bottom-right | 0.50 | 1.00 | 0.50 | 1.00 |

### Expected sequence

- Stroke 0 (single anticlockwise oval): 1 → 2 → 3 → 4

The stroke starts at the top-right, sweeps anticlockwise over the
top, down the left side, along the bottom, and closes at the
bottom-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct anticlockwise o | PASS |
| Clockwise o | FAIL — section 1 hit, then sequence breaks at section 4 |
| Straight vertical line | FAIL — section 1 never hit |
| Anticlockwise but incomplete | FAIL |

### Notes

- o and c share the same grid structure and sequence. The difference
  is that o closes back through section 4, whereas c ends at
  section 4 without needing to close a full oval.
- A clockwise o fails: section 1 is hit, but the sequence then breaks
  at section 4, so the stroke scores 0.0.

---

## Letter: p

### Grid layout

2 columns × 2 rows = 4 sections.

The left column is narrow and contains the full stem including the
descender. The right column is wide and contains the bowl.
The horizontal division sits at approximately the bottom of the bowl.

| | Left col (x 0.00–0.17) | Right col (x 0.17–1.00) |
|---|---|---|
| **Top row (y 0.00–0.40)** | Section 1 | Section 3 |
| **Bottom row (y 0.40–1.00)** | Section 2 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top | 0.00 | 0.17 | 0.00 | 0.40 |
| 2 | 0 | Stem bottom / descender | 0.00 | 0.17 | 0.40 | 1.00 |
| 3 | 1 | Bowl top | 0.17 | 1.00 | 0.00 | 0.40 |
| 4 | 1 | Bowl bottom | 0.17 | 1.00 | 0.40 | 1.00 |

### Expected sequences

p is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom): 1 → 2
- Stroke 1 (bowl, clockwise): 3 → 4

The bowl starts at the stem junction at the top, sweeps clockwise
down the right side and along the bottom, closing back at the top.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct p | PASS | PASS | PASS |
| Stem only, no bowl | PASS | FAIL | FAIL |
| Reversed stem, correct bowl | FAIL | PASS | FAIL |
| Correct stem, anticlockwise bowl | PASS | FAIL — breaks after section 3 | FAIL |
| Reversed stem, no bowl | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- p uses a simplified 4-section layout compared to b's 6 sections.
  The two bowl sections are sufficient to verify clockwise direction
  at this stage, with the bitmap metrics handling shape correctness.
- The bottom-right section (4) is largely empty in the right column
  since the descender is on the left. It is retained to provide
  the directional check for the bowl.

---

## Letter: q

### Grid layout

2 columns × 2 rows = 4 sections.

The left column is wide and contains the bowl.
The right column is narrow and contains the full stem including
the descender. The horizontal division sits at approximately
the bottom of the bowl.

q is the mirror of p — same 4-section layout, columns swapped.

| | Left col (x 0.00–0.75) | Right col (x 0.75–1.00) |
|---|---|---|
| **Top row (y 0.00–0.41)** | Section 1 | Section 3 |
| **Bottom row (y 0.41–1.00)** | Section 2 | Section 4 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Bowl top | 0.00 | 0.75 | 0.00 | 0.41 |
| 2 | 0 | Bowl bottom | 0.00 | 0.75 | 0.41 | 1.00 |
| 3 | 1 | Stem top | 0.75 | 1.00 | 0.00 | 0.41 |
| 4 | 1 | Stem bottom / descender | 0.75 | 1.00 | 0.41 | 1.00 |

### Expected sequences

q is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (bowl, anticlockwise): 1 → 2
- Stroke 1 (stem, top to bottom): 3 → 4

The bowl starts at the stem junction, sweeps anticlockwise upward
over the top, down the left side, and along the bottom.
The stem then descends from top to bottom including the descender.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct q | PASS | PASS | PASS |
| Bowl only, no stem | PASS | FAIL | FAIL |
| Clockwise bowl, correct stem | FAIL — section 2 hit before section 1 | PASS | FAIL |
| Correct bowl, reversed stem | PASS | FAIL | FAIL |
| Clockwise bowl, no stem | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- q and p are structural mirrors. p has a clockwise bowl on the right
  with the stem on the left; q has an anticlockwise bowl on the left
  with the stem on the right.
- The anticlockwise check works here because the bowl sweeps upward
  first (hitting section 1) before descending (hitting section 2).
  A clockwise stroke dips down first, hitting section 2 before
  section 1 and scoring zero.

---

## Letter: r

### Grid layout

2 columns × 1 row = 2 sections, both active.

No horizontal division. The left column contains the stem at full
height. The right column contains the shoulder at full height.
Removing the horizontal divider eliminates the unnecessary empty
bottom-right cell from the previous layout.

| Left col (x 0.00–0.22) | Right col (x 0.22–1.00) |
|---|---|
| Section 1 | Section 2 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem | 0.00 | 0.22 | 0.00 | 1.00 |
| 2 | 1 | Shoulder | 0.22 | 1.00 | 0.00 | 1.00 |

### Expected sequences

r is a two-stroke letter. Each stroke has its own independent section.

- Stroke 0 (stem): 1
- Stroke 1 (shoulder): 2

Both strokes have one section each — presence checks confirming
each component is drawn in the correct region. The Start scorer
handles starting positions and the bitmap metrics handle shape.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct r | PASS | PASS | PASS |
| Stem only, no shoulder | PASS | FAIL | FAIL |
| Shoulder only, no stem | FAIL | PASS | FAIL |
| Shoulder drawn in stem area | PASS | FAIL | FAIL |

### Notes

- Column boundary proportions are approximate and require visual
  validation against the Andika typeface before finalising.
- r has the simplest two-stroke layout in the document — one section
  per stroke, both presence checks only.
- If directional checking of either stroke becomes important later,
  a horizontal divider can be reintroduced to split each column into
  top and bottom sections without changing the overall grid concept.

---

## Letter: w

### Grid layout

4 columns × 2 rows = 8 sections, all active.

Four roughly equal columns capture each leg of the W shape.
The horizontal division sits at mid-height. The stroke zigzags
through all 8 sections in sequence — the most complex layout
in the document.

| | Col 1 (x 0.00–0.25) | Col 2 (x 0.25–0.50) | Col 3 (x 0.50–0.75) | Col 4 (x 0.75–1.00) |
|---|---|---|---|---|
| **Top row (y 0.00–0.50)** | Section 1 | Section 4 | Section 5 | Section 8 |
| **Bottom row (y 0.50–1.00)** | Section 2 | Section 3 | Section 6 | Section 7 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | First leg top | 0.00 | 0.25 | 0.00 | 0.50 |
| 2 | 0 | First leg bottom | 0.00 | 0.25 | 0.50 | 1.00 |
| 3 | 0 | First valley | 0.25 | 0.50 | 0.50 | 1.00 |
| 4 | 0 | First ascent top | 0.25 | 0.50 | 0.00 | 0.50 |
| 5 | 0 | Second descent top | 0.50 | 0.75 | 0.00 | 0.50 |
| 6 | 0 | Second descent bottom | 0.50 | 0.75 | 0.50 | 1.00 |
| 7 | 0 | Second valley | 0.75 | 1.00 | 0.50 | 1.00 |
| 8 | 0 | Final ascent top | 0.75 | 1.00 | 0.00 | 0.50 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

The stroke starts at the top-left, descends the first leg,
turns at the first valley, rises to the top, descends the second
leg, turns at the second valley, and rises to finish at the
top-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct w | PASS |
| Reversed w (starts top-right) | FAIL — section 1 never hit first |
| First V only (stops after section 4) | FAIL |
| Started from wrong side (top-right) | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- w uses the same zigzag logic as m and n but extended to 4 columns.
  It is the widest layout in the document.
- All 8 sections are active — no empty cells.

---

## Letter: s

### Grid layout

2 columns × 3 rows = 6 sections, all active.

Equal columns and roughly equal rows. The three rows capture the
upper curve, the inflection crossing, and the lower curve of the
S-shape. This layout replaces the interim topToBottom placeholder
and provides the proper compound S-curve sequence.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.34)** | Section 2 | Section 1 |
| **Middle row (y 0.34–0.66)** | Section 3 | Section 4 |
| **Bottom row (y 0.66–1.00)** | Section 6 | Section 5 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Upper curve start (top-right) | 0.50 | 1.00 | 0.00 | 0.34 |
| 2 | 0 | Upper curve top (top-left) | 0.00 | 0.50 | 0.00 | 0.34 |
| 3 | 0 | Upper curve descends (mid-left) | 0.00 | 0.50 | 0.34 | 0.66 |
| 4 | 0 | Inflection crosses right (mid-right) | 0.50 | 1.00 | 0.34 | 0.66 |
| 5 | 0 | Lower curve descends (bottom-right) | 0.50 | 1.00 | 0.66 | 1.00 |
| 6 | 0 | Lower curve end (bottom-left) | 0.00 | 0.50 | 0.66 | 1.00 |

### Expected sequence

- Stroke 0 (single continuous S-curve): 1 → 2 → 3 → 4 → 5 → 6

The stroke starts at the top-right, sweeps anticlockwise over the
top and down the left side to the middle, then switches direction
and sweeps clockwise down the right side to the bottom-left.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct s | PASS |
| Reversed s (starts bottom-left) | FAIL — section 1 never hit |
| Upper curve correct, lower curve reversed | FAIL — breaks at section 4 |
| Straight vertical line | FAIL — section 1 never hit from top-right |
| Upper curve only | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- s was previously an interim topToBottom placeholder. This 6-section
  layout is the proper compound S-curve sequence and retires that
  placeholder.
- The Z-pattern through the grid (top-right → top-left → mid-left →
  mid-right → bottom-right → bottom-left) is unique to s and cannot
  be shared with any other letter template.

---

## Letter: t

### Grid layout

3 columns × 3 rows = 9 cells, 5 active.

The left column is narrow. The middle column contains the stem body.
The right column is wide and contains the right crossbar extension
and the bottom curve of the stem.
The middle row sits at the crossbar level.
The top and bottom rows cover above and below the crossbar respectively.

| | Left col (x 0.00–0.22) | Middle col (x 0.22–0.52) | Right col (x 0.52–1.00) |
|---|---|---|---|
| **Top row (y 0.00–0.32)** | — | Section 1 | — |
| **Middle row (y 0.32–0.52)** | Section 4 | Section 2 | Section 5 |
| **Bottom row (y 0.52–1.00)** | — | Section 3 | Section 3 (extended) |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Stem top (above crossbar) | 0.22 | 0.52 | 0.00 | 0.32 |
| 2 | 0 | Stem mid (crossbar level) | 0.22 | 0.52 | 0.32 | 0.52 |
| 3 | 0 | Stem bottom and curve | 0.22 | 1.00 | 0.52 | 1.00 |
| 4 | 1 | Crossbar left | 0.00 | 0.22 | 0.32 | 0.52 |
| 5 | 1 | Crossbar right | 0.52 | 1.00 | 0.32 | 0.52 |

### Expected sequences

t is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (stem, top to bottom with curve): 1 → 2 → 3
- Stroke 1 (crossbar, left to right): 4 → 5

The stem starts above the crossbar, passes through the crossbar
level, and curves to the right at the bottom. The crossbar starts
at the left and travels right across the stem.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct t | PASS | PASS | PASS |
| Stem only, no crossbar | PASS | FAIL | FAIL |
| Reversed stem, correct crossbar | FAIL | PASS | FAIL |
| Correct stem, crossbar right to left | PASS | FAIL | FAIL |
| Reversed stem, no crossbar | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- Section 3 is wider than the middle column to accommodate the
  curved bottom of the stem in the Andika typeface, which sweeps
  into the right column at the bottom.
- t is one of the five letters where StrokeBreakCounter carries
  meaningful signal — the crossbar is a mandatory second stroke.
- The green dots in the screenshot mark the endpoints of the left
  vertical divider running the full height of the bounding box.

---

## Letter: u

### Grid layout

3 columns × 1 row = 3 sections.

No horizontal division. The three columns map to the left leg,
the bottom curve, and the right leg respectively.

| Left col (x 0.00–0.37) | Middle col (x 0.37–0.68) | Right col (x 0.68–1.00) |
|---|---|---|
| Section 1 | Section 2 | Section 3 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Left leg | 0.00 | 0.37 | 0.00 | 1.00 |
| 2 | 0 | Bottom curve | 0.37 | 0.68 | 0.00 | 1.00 |
| 3 | 0 | Right leg | 0.68 | 1.00 | 0.00 | 1.00 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3

The stroke starts at the top of the left leg, descends through
the left column, curves through the bottom middle, then rises
up the right leg to finish at the top-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct u | PASS |
| Reversed u (starts top-right) | FAIL — section 1 never hit first |
| Left leg only | FAIL |
| Left leg and curve, no right leg | FAIL |

### Notes

- Column boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- u is the only letter with a 3-column × 1-row layout. The absence
  of a horizontal division means the check is purely left-to-right
  progression — confirming the stroke travels the correct direction
  across the letter.
- The Start scorer handles the starting position (top-left),
  and the bitmap metrics handle the U-shape. Together with the
  waypoint check, a reversed stroke scores zero immediately.

---

## Letter: v

### Grid layout

2 columns × 2 rows = 4 sections.

Equal quadrant division — same grid structure as c and o.
Both the vertical and horizontal divisions sit at the midpoint.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.50)** | Section 1 | Section 4 |
| **Bottom row (y 0.50–1.00)** | Section 2 | Section 3 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Top-left | 0.00 | 0.50 | 0.00 | 0.50 |
| 2 | 0 | Bottom-left | 0.00 | 0.50 | 0.50 | 1.00 |
| 3 | 0 | Bottom-right | 0.50 | 1.00 | 0.50 | 1.00 |
| 4 | 0 | Top-right | 0.50 | 1.00 | 0.00 | 0.50 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3 → 4

The stroke starts at the top-left, travels diagonally down through
the bottom-left, curves through the bottom-right, then rises
diagonally to finish at the top-right.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct v | PASS |
| Reversed v (starts top-right) | FAIL — section 1 never hit first |
| Left diagonal only (no return stroke) | FAIL |
| Started from bottom (going up-left then up-right) | FAIL |

### Notes

- v, c, and o share the same equal 2×2 grid structure. The section
  numbering differs because the stroke paths are different.
- Section 1 (top-left) is the gatekeeper — starting from anywhere
  other than the top-left scores zero immediately.

---

## Letter: x

### Grid layout

2 columns × 2 rows = 4 sections.

Equal quadrant division. Each stroke occupies exactly two opposite
quadrants — stroke 0 runs top-left to bottom-right, stroke 1 runs
top-right to bottom-left.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.50)** | Section 1 | Section 3 |
| **Bottom row (y 0.50–1.00)** | Section 4 | Section 2 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Top-left | 0.00 | 0.50 | 0.00 | 0.50 |
| 2 | 0 | Bottom-right | 0.50 | 1.00 | 0.50 | 1.00 |
| 3 | 1 | Top-right | 0.50 | 1.00 | 0.00 | 0.50 |
| 4 | 1 | Bottom-left | 0.00 | 0.50 | 0.50 | 1.00 |

### Expected sequences

x is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (top-left to bottom-right diagonal): 1 → 2
- Stroke 1 (top-right to bottom-left diagonal): 3 → 4

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct x | PASS | PASS | PASS |
| Stroke 0 reversed (bottom-right to top-left) | FAIL | PASS | FAIL |
| Stroke 1 reversed (bottom-left to top-right) | PASS | FAIL | FAIL |
| Both strokes drawn in same direction | PASS | FAIL | FAIL |
| Both strokes reversed | FAIL | FAIL | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- x has the most symmetrical layout in the document — each stroke
  maps to exactly two diagonally opposite quadrants with no overlap
  or unused cells.
- Drawing both strokes in the same diagonal direction fails, because
  stroke 1 never enters its gatekeeper section (top-right) first.

---

## Letter: y

### Grid layout

3 sections total, all active.

The top row is split into two equal cells by a vertical divider
that runs from the top down to the horizontal divider only —
it does not continue into the bottom row. The bottom row is a
single full-width cell covering the descender.

| | Left col (x 0.00–0.50) | Right col (x 0.50–1.00) |
|---|---|---|
| **Top row (y 0.00–0.55)** | Section 1 | Section 2 |
| **Bottom row (y 0.55–1.00)** | Section 3 (full width) | ← |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Left arm | 0.00 | 0.50 | 0.00 | 0.55 |
| 2 | 1 | Right arm | 0.50 | 1.00 | 0.00 | 0.55 |
| 3 | 1 | Descender (full width) | 0.00 | 1.00 | 0.55 | 1.00 |

### Expected sequences

y is a two-stroke letter. Each stroke has its own independent sequence.

- Stroke 0 (left arm): 1
- Stroke 1 (right arm continuing as descender): 2 → 3

Stroke 0 has only one section — a presence check confirming the
left arm is in the correct region. The Start scorer handles the
starting position. Stroke 1 checks that the right arm continues
downward into the descender.

### Error cases

| Scenario | Stroke 0 | Stroke 1 | Overall |
|----------|----------|----------|---------|
| Correct y | PASS | PASS | PASS |
| Left arm only, no right arm or descender | PASS | FAIL | FAIL |
| Left arm correct, right arm with no descender | PASS | FAIL | FAIL |
| Stroke 1 reversed (starts bottom, goes up-right) | PASS | FAIL — section 3 hit before section 2 | FAIL |
| Left arm drawn right-to-left | FAIL | PASS | FAIL |

### Notes

- Column and row boundary proportions are approximate and require
  visual validation against the Andika typeface before finalising.
- The vertical divider runs through the top row only — the bottom
  row is undivided. This means no empty cells in this layout.
- Stroke 0 has only one section, making it a presence check.
  The Start scorer and bitmap metrics provide the remaining coverage.

---

## Letter: z

### Grid layout

1 column × 3 rows = 3 sections, all active.

No vertical division. The three rows map to the top bar, the
diagonal, and the bottom bar of the letter. This is the horizontal
counterpart of l — same structure but with three rows instead of two.

| | Full width (x 0.00–1.00) |
|---|---|
| **Top row (y 0.00–0.23)** | Section 1 |
| **Middle row (y 0.23–0.77)** | Section 2 |
| **Bottom row (y 0.77–1.00)** | Section 3 |

### Section definitions

| Section | Stroke | Label | x min | x max | y min | y max |
|---------|--------|-------|-------|-------|-------|-------|
| 1 | 0 | Top bar | 0.00 | 1.00 | 0.00 | 0.23 |
| 2 | 0 | Diagonal | 0.00 | 1.00 | 0.23 | 0.77 |
| 3 | 0 | Bottom bar | 0.00 | 1.00 | 0.77 | 1.00 |

### Expected sequence

- Stroke 0 (single continuous stroke): 1 → 2 → 3

The stroke starts in the top bar area, sweeps right, then the
diagonal travels down through the middle section, then the bottom
bar sweeps right to finish.

### Error cases

| Scenario | Score |
|----------|-------|
| Correct z | PASS |
| Reversed z (starts bottom-right) | FAIL — section 1 never hit first |
| Top bar and diagonal only, no bottom bar | FAIL |
| Diagonal only (skipping top bar) | FAIL — section 1 never hit first |

### Notes

- Row boundary proportions are approximate and require visual
  validation against the Andika typeface before finalising.
- z and l share the same single-column structure. l has 2 rows
  for a simple stem; z has 3 rows to capture the three distinct
  phases of its stroke.
- Section 1 (top bar) is the gatekeeper — the stroke must begin
  in the top section, preventing a learner from starting at the
  diagonal or the bottom bar.
