# Zone completion audit — mock-ups only

**This is an audit report with proposed mock-ups. Nothing here is wired into the app. No file outside `docs/zone_review/completion_audit/` was changed.**

## 1. What was audited

Branch: `origin/main`
Commit: `742d36ad0953ff8a4c7d6120ea7d2b2786f92dc0` — "Redesign h and n zones: bottom row forces strokes to the baseline (#157, #158) (#159)"

Sources read in full: `scripts/glyph_sections.py`, `docs/zone_review/REVIEW.md`, `lib/models/letter_formation_registry.dart`, and `proposals/<letter>.json` for the 25 letters that have one (all but `f`).

The question being asked: scoring only requires the pen to **enter** each numbered zone, in order — never to cross it or reach its far side. Wherever a stroke **ends** inside a zone, or **turns around** inside a zone (comes in and goes back out the same side), a tall/wide zone lets a learner stop well short of the letter's natural end point and still score 100%. `h` and `n` were fixed for exactly this reason in the commit above; this audit checks whether the other 24 letters have the same problem.

## 2. The h/n reference pattern (Step 1)

Both `h` and `n` still show their fix in the current registry — confirmed from the Dart source and rendered images (`docs/zone_review/h_grid.png`, `n_grid.png`, and freshly rendered copies below). The pattern:

- **`h`** (2 separate strokes: stem, then arch+leg): each stroke's last zone is a **short row across the bottom**, `y 0.82–1.00` — **18% of the letter's height**, forcing both the stem and the second leg to reach the baseline before that zone is satisfied. Before the fix, each stroke had only one zone covering the whole leg; the cap is zone **2** (added after old zone 1) and zone **5** (added after old zone 4).
- **`n`** (1 continuous stroke): the first leg gets a similar bottom cap, `y 0.75–1.00` — **25% of the height** — inserted as zone **2** right after the down-stroke (zone 1), renumbering the rest of the sequence (3,4,5). The second leg's final zone is *also* a `y 0.75–1.00` cap (zone 5).

So: **a thin zone (18–25% of the glyph's bounding-box height), added immediately after the zone that used to be the end of that leg, spanning the same column**. h and n don't use exactly the same fraction (18% vs 25%) — that's noted here rather than silently averaged away. For the candidate designs in this audit (Step 3) a **20% cap** was used as a single consistent value in that range; every candidate validated cleanly at that depth (see section 4).

## 3. Full zone table — every TURNAROUND / TERMINAL zone, all 26 letters

"Slack" = the zone's own depth (height for a vertical entry, width for a horizontal one) as a fraction of the glyph's tight bounds — i.e. how far short of the true end point a learner can stop and still satisfy that zone. START and PASS-THROUGH zones are omitted (per the audit's own rule, PASS-THROUGH zones require crossing to a different edge to progress, so they aren't a stopping-short risk). Verdict: **FLAGGED** >= 0.25, **borderline** 0.15-0.24, else ok.

| Letter | Stroke | Zone # | Kind | Entered via -> | Slack | Verdict |
|---|---|---|---|---|---|---|
| a | 0 | 6 | TERMINAL | top (upward close of stem) | 0.50 | **FLAGGED** |
| b | 0 (stem) | 3 | TERMINAL | top | 0.33 | **FLAGGED** |
| b | 1 (bowl) | 7 | TERMINAL | right | 0.37 | **FLAGGED** |
| c | 0 | 5 | TERMINAL | left | 0.50 | **FLAGGED** |
| d | 0 (stem) | 3 | TERMINAL | top | 0.33 | **FLAGGED** |
| d | 1 (bowl) | 7 | TERMINAL | left | 0.34 | **FLAGGED** |
| e | 0 | 9 | TERMINAL | left | 0.33 | **FLAGGED** |
| f | 0 (stem) | 3 | TERMINAL | top | 0.70 | **FLAGGED** |
| f | 1 (crossbar) | 5 | TERMINAL | left | 0.54 | **FLAGGED** |
| g | 0 | 8 | TERMINAL | right | 0.39 | **FLAGGED** |
| h | 0 (stem) | 2 | TERMINAL | top | 0.18 | borderline (reference, not re-fixed) |
| h | 1 (arch+leg) | 5 | TERMINAL | top | 0.18 | borderline (reference, not re-fixed) |
| i | 0 (stem) | 2 | TERMINAL | top | 0.38 | **FLAGGED** |
| j | 0 (stem+hook) | 3 | TERMINAL | right | 0.45 | **FLAGGED** |
| k | 0 (stem) | 3 | TERMINAL | top | 0.32 | **FLAGGED** |
| k | 1 (kick) | 7 | TERMINAL | left | 0.38 | **FLAGGED** |
| l | 0 | 3 | TERMINAL | top | 0.30 | **FLAGGED** |
| m | 0 | 2 | TURNAROUND | top / top | 0.60 | **FLAGGED** |
| m | 0 | 4 | TURNAROUND | top / top | 0.60 | **FLAGGED** |
| m | 0 | 6 | TERMINAL | top | 0.60 | **FLAGGED** |
| n | 0 | 2 | TURNAROUND | top / top | 0.25 | flagged by the numeric rule, but reference (not re-fixed) |
| n | 0 | 5 | TERMINAL | top | 0.25 | flagged by the numeric rule, but reference (not re-fixed) |
| o | 0 | 6 | TERMINAL | bottom (upward close) | 0.50 | **FLAGGED** |
| p | 0 (stem) | 3 | TERMINAL | top | 0.30 | **FLAGGED** |
| p | 1 (bowl) | 7 | TERMINAL | right | 0.37 | **FLAGGED** |
| q | 0 (oval) | 4 | TERMINAL | left | 0.37 | **FLAGGED** |
| q | 1 (stem) | 7 | TERMINAL | top | 0.30 | **FLAGGED** |
| r | 0 (stem) | 2 | TERMINAL | top | 0.60 | **FLAGGED** |
| r | 1 (shoulder) | 4 | TERMINAL | left | 0.32 | **FLAGGED** |
| s | 0 | 6 | TERMINAL | right | 0.50 | **FLAGGED** |
| t | 0 (stem) | 4 | TERMINAL | left | 0.42 | **FLAGGED** |
| t | 1 (crossbar) | 6 | TERMINAL | left | 0.42 | **FLAGGED** |
| u | 0 | 5 | TERMINAL | bottom (upward close) | 0.50 | **FLAGGED** |
| v | 0 | 4 | TERMINAL | bottom (upward close) | 0.50 | **FLAGGED** |
| w | 0 | 2 | TURNAROUND | top / top (valley 1) | 0.50 | **FLAGGED** |
| w | 0 | 3 | TURNAROUND | bottom / bottom (peak) | 0.50 | **FLAGGED** |
| w | 0 | 4 | TURNAROUND | top / top (valley 2) | 0.50 | **FLAGGED** |
| w | 0 | 5 | TERMINAL | bottom | 0.50 | **FLAGGED** |
| x | 0 | 3 | TERMINAL | diagonal (top-left to bottom-right) | 0.33 | **FLAGGED** |
| x | 1 | 5 | TERMINAL | diagonal (top-right to bottom-left) | 0.33 | **FLAGGED** |
| y | 0 (short arm) | 2 | TERMINAL | diagonal, down to the join | 0.30 | **FLAGGED** |
| y | 1 (tail) | 5 | TERMINAL | right (curl to the left) | 0.33 | **FLAGGED** |
| z | 0 | 5 | TERMINAL | left (bottom bar, rightward) | 0.33 | **FLAGGED** |

Zones not in this table (START zones, and true PASS-THROUGH zones — see section 6 for a couple that needed hand-checking) are not a stopping-short risk and were left alone.

**Result: every letter in the alphabet except `h` has at least one zone at or above the 0.25 slack threshold** (and `n`'s own cap sits exactly on that threshold too, at 0.25 — see section 6). 24 of 26 letters were flagged for a candidate fix; 2 (`h`, `n`) are the reference pattern already fixed by #157/#158, and are deliberately **not** touched again here.

## 4. What was mocked up, letter by letter (Step 3)

For every flagged zone, the fix follows the h/n pattern exactly: split the zone along its direction of travel into a **body** + a **20%-deep cap** at the far end, insert the cap as a new numbered zone immediately after the body, and renumber everything after it. Nothing else in the letter was touched. All 24 candidates validated cleanly on the first attempt with `glyph_sections.py --check-only` (non-overlapping ragged grid, ink present in every new zone, including every cap) — **no letter needed adjustment or was left unresolved.**

| Letter | What a learner can currently get away with | Candidate fix |
|---|---|---|
| a | Stop the closing stroke halfway back down the right side, never reaching the true foot. | Zone 6 split; new bottom cap added as zone 7. |
| b | Stop the stem or the bowl's closing curve early, well short of the baseline / the stem. | Zone 3 to 3+4 (stem cap), zone 7 to 8+9 (bowl cap, left). |
| c | Finish the bottom curve a third of the way back, never reaching the true bottom-right. | Zone 5 split; cap added on the right as zone 6. |
| d | Same as b, mirrored (stem on the right, bowl closes to the left). | Zone 3 to 3+4, zone 7 to 8+9 (bowl cap, right). |
| e | Finish the final "along the bottom" stroke without reaching bottom-right. | Zone 9 split; cap added on the right as zone 10. |
| f | Stop the descender well above its curl, or the crossbar well short of the right edge. | Zone 3 to 3+4 (stem cap), zone 5 to 6+7 (crossbar cap, right). |
| g | Finish the closing hook without curling all the way left. | Zone 8 split; cap added on the left as zone 9. |
| i | Stop the stem partway down, never reaching the baseline. | Zone 2 split; cap added as zone 3 (dot renumbers to 4). |
| j | Stop the hook before it curls left. | Zone 3 split; cap added on the left as zone 4 (dot renumbers to 5). |
| k | Stop the stem early, or stop the kick before it reaches the lower right. | Zone 3 to 3+4 (stem cap), zone 7 to 8+9 (kick cap, right). |
| l | The plain stem has no cap at all — a learner can stop a third of the way up from the bottom and still pass. This is the same failure h/n were fixed for, just never applied here. | Zone 3 split; cap added as zone 4. |
| m | All three legs can stop 60% of the way down and never touch the baseline — worse than h/n's un-fixed original design. | Zones 2, 4, 6 each split into body+cap (9 zones total). |
| o | The closing stroke can stop halfway back up, never reaching the top. | Zone 6 split; cap added on top as zone 7. |
| p | Same as b/d pattern: stem descender and bowl closing curve both have large slack. | Zone 3 to 3+4, zone 7 to 8+9 (bowl cap, left). |
| q | Oval can stop before reaching the stem; stem/descender can stop before the baseline. | Zone 4 to 4+5 (oval cap, right), zone 7 to 8+9 (stem cap). |
| r | Stem can stop 60% short of the baseline; the shoulder/kick can stop before reaching the lower right. | Zone 2 to 2+3 (stem cap), zone 4 to 5+6 (shoulder cap). |
| s | Final stroke can stop before reaching the true bottom-left. | Zone 6 split; cap added on the left as zone 7. |
| t | Foot curve and crossbar can both stop well short of the right edge. | Zone 4 to 4+5 (foot cap), zone 6 to 7+8 (crossbar cap). |
| u | Final upstroke can stop halfway up, never reaching the top. | Zone 5 split; cap added on top as zone 6. |
| v | Same as u — the final upstroke can stop at the midline. | Zone 4 split; cap added on top as zone 5. |
| w | Worst case in the audit. Every valley, the peak, and the final ascent each have 50% slack — a learner can draw an almost-flat squiggle that barely crosses the midline in each column and still score 100%, never actually forming the zigzag. | Zones 2, 3, 4, 5 each split into body+cap (9 zones total: 2 valley caps at the bottom, 1 peak cap at the top, 1 final cap at the top). |
| x | Either diagonal stroke can stop right after crossing into the final third of the glyph, well short of the actual corner. | Zone 3 split (cap at bottom) and zone 5 split (cap at bottom) — see section 6 for the one-axis caveat. |
| y | The short arm can stop well above the join; the tail's curl can stop before reaching the left edge. | Zone 2 split (cap at bottom, toward the join), zone 5 split (cap on the left). |
| z | The bottom bar can stop before reaching the true bottom-right corner. | Zone 5 split; cap added on the right as zone 6. |

Candidate JSON files: `docs/zone_review/completion_audit/candidates/<letter>.json` (24 files, same format as `proposals/<letter>.json`).
Renders: `docs/zone_review/completion_audit/png/<letter>_before.png` / `<letter>_after.png` (48 files) and one combined `contact_sheet_before_after.png`.

## 5. Borderline zones and single-zone (presence-only) strokes

**Borderline (0.15-0.24 slack):** only `h`'s two cap zones (0.18 each) — the reference pattern itself. No fix proposed (out of scope; already the thing everything else is being checked against).

**Single-zone strokes (pure presence check, cannot enforce completion at all):**
- `i`, stroke 2 — the dot (zone 3 alone).
- `j`, stroke 2 — the dot (zone 4 alone).

No changes proposed for either; per the task's own rule these get listed, not fixed (a dot has no "direction of travel" to add a cap along).

## 6. Mismatches, disagreements, and things worth flagging explicitly

- **Registry vs `proposals/*.json`: no mismatches found.** A field-by-field diff of all 25 letters that have a `proposals/<letter>.json` against what `lib/models/letter_formation_registry.dart` actually encodes found zero differences in zone count, numbering, stroke index, or any rectangle coordinate. The registry is a faithful transcription of every proposal.

- **`m`'s "turnaround" zones are the leg bottoms, not the arch tops.** Re-reading the task brief's own example list ("top of each arch of m" as a turnaround) against the actual geometry: the arch-top zones (3 and 5) are entered from the side (the previous leg) and exited through the bottom (continuing down into the next leg) — two different sides, i.e. genuine PASS-THROUGH, not a turnaround. The zones that really are turnarounds (entered and left through the same, bottom, edge, forcing a backtrack up through the previous leg before the pen can cross to the next one) are the leg bottoms, zones 2 and 4. This matches `REVIEW.md`'s own wording ("down...up...down...up...down") better than the brief's example did, so the table above (and the fix) targets 2 and 4, not 3 and 5. Verified visually against the rendered `m_sections.png`.

- **`u` and `v` do not have a turnaround at "bottom of the first leg"**, despite the m/n/w grouping suggesting one might expect it there too. In both letters the zone at the bottom of the first leg shares a full edge directly with the next required zone (not a coincidentally-placed later zone), so the pen can flow straight across at the valley without ever backtracking — confirmed both algorithmically and visually (`u_sections.png`, `v_sections.png`). This is a genuine structural difference from m/n, not an oversight — noted here since the task's phrasing implied otherwise. (Both letters still have an independent, separately-flagged TERMINAL slack problem at their final upstroke, zone 5 and zone 4 respectively — see section 3.)

- **`e`'s zone 6 is PASS-THROUGH, not a dead end**, even though it doesn't share a direct edge with the next zone (7) — the gap between them is the letter's own "tongue" cavity (hatched/unclaimed), which the down-the-left stroke crosses in the forward direction, not a backtrack. Confirmed against `REVIEW.md`'s description (a single continuous anticlockwise sweep, no mention of reversal).

- **`g`'s registry has a second `ExpectedStroke` with no `sections` at all.** `REVIEW.md` describes g as "single continuous stroke" (8 zones), but the Dart registry — like b/d/p/q — also carries a second, separated-form `ExpectedStroke` (the canonical "bowl then descender" split) for g. Unlike b/d/p/q's second stroke, g's second stroke has zero `WaypointSection`s defined, meaning a learner who draws g in the separated (two-stroke) form gets no section-scoring at all on the second stroke (presence-only, via `minRequiredStrokes`). This wasn't something the audit was asked to fix, but it's a gap worth someone's attention — flagged here, not touched.

- **Diagonal terminal zones (`x` zones 3 and 5, `y` zone 2) only get a one-axis fix.** The h/n pattern is designed for a straight vertical (or horizontal) stroke; applied to a diagonal, splitting along one axis (here, vertically) forces the pen deeper in that dimension but does not independently force it toward the correct horizontal position — a learner could still enter the new cap near its near-corner and stop, short of the true diagonal endpoint in the other dimension. This is called out explicitly rather than presented as a complete fix; a proper fix for diagonal strokes would need a different zone shape (not in scope here — the task asked for plain axis-aligned cells matching h/n).

- **`n`'s own caps sit exactly on the 0.25 flag threshold.** Applying the audit's mechanical >= 0.25 rule to n's own zones 2 and 5 (both exactly 0.25) technically flags them too, while h's (0.18) land in "borderline." Both are left alone here — they're the just-established reference commit (#157/#158), explicitly out of scope for further redesign — but it's worth the maintainers knowing that by the numbers used in this audit, n's margin is tighter than h's.

## 7. What's incomplete / where this stopped

Nothing was left incomplete. Step 1 confirmed the h/n pattern; Steps 2-4 covered all 26 letters, all their strokes, and every TURNAROUND/TERMINAL zone; all 24 flagged letters got a candidate design, a before/after render, and a passing validation; the contact sheet and this report were produced; and the branch was pushed with a draft PR opened. The one deliberate scope limitation is the diagonal one-axis caveat above (section 6), which is called out rather than silently worked around.
