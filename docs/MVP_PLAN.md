# handwriting_mvp — MVP build plan

Master checklist for finishing the Practice flow. One step per Claude Code run.
Tick a step (`[x]`) only when its PR is **merged** into main. Mark `[~]` while a PR is open.
Steps must be done in order unless a step says otherwise.

Sources of truth (read these, do not re-decide them):
- Screens and flow: project doc `figma_interactive_prototype_spec.md` (Practice) and the
  "Handwriting App — MVP screens" design canvas. Games screens are NOT part of this plan.
- Scoring: bitmap scorers + StrokeStartScorer, WaypointSectionScorer, StrokeBreakCounter.
  Path scoring is strict pass/fail. Never change scoring behaviour in this plan.
- Levels: `claude/stroke_formation_post_mvp_roadmap.md` Stream B (B1, B2).

Decisions taken for the MVP (Andrew can override by editing this file):
- Lowercase a–z only. Home shows no uppercase "A–Z" option.
- No single-letter mode. Every session is a set of 1+ letters; the progress bar is hidden
  when the set has exactly one letter.
- "Choose your own" practises letters in alphabetical order.
- The existing `DrawingCanvas` developer screen stays, reachable from a small "Dev" link
  on Home. It keeps its debug panel and full ScoreDisplay. Nothing in this plan removes it.
- Feedback word thresholds: overall < 0.50 "More practice", 0.50–0.75 "Okay", ≥ 0.75 "Good".
  "Overall" = the mean of the scores permitted at the current level.

## Phase 0 — in flight (not for the build routine)
- [ ] 0.1 Transcribe the 24 approved zone designs into the registry (Andrew's own routine).
- [ ] 0.2 `g` registry tidy: remove the second ExpectedStroke that has a startRect but no
      sections (design is one stroke). Do this AFTER 0.1 has merged.

## Phase 1 — clean-up
- [~] 1.1 Remove legacy waypoint scoring (compound_stroke_scorer, match_waypoints, the
      `waypoints` field, the scorer switch in ScoreIntegrator, the scorer-name switch in
      debug_score_view) and the four old scripts. Registry file: zero diff.

## Phase 2 — scoring levels (independent of Phase 3; can run in parallel)
- [ ] 2.1 `ScoringLevel` enum {shapeOnly, shapeAndStart, shapeStartAndPath, full} in
      lib/models/scoring_level.dart, with a pure helper that says which of the seven scores
      are visible at each level: L1 bitmap four; L2 + start; L3 + path; L4 + strokes.
      Unit tests for the helper. No UI change.
- [ ] 2.2 `ScoreDisplay` takes an optional `ScoringLevel` and hides rows the level does not
      permit. Default (null) = show everything, so the dev screen is unchanged. Widget test.

## Phase 3 — Practice flow screens
- [ ] 3.1 Session model + navigation shell. `PracticeSession` {List<String> letters,
      ScoringLevel level, int index} with next()/isLast/current. Named routes for
      home, levelSelect, guide, feedback, sessionComplete. main.dart starts at Home.
      Placeholder screens (title text only) for each route so the app runs end to end.
      Dev link on Home opens the existing DrawingCanvas. Tests for PracticeSession.
- [ ] 3.2 Home screen: "Alphabet a–z" card; "Choose your own" card with a 7-column a–z
      multi-select grid and a Practice button (disabled when nothing is selected);
      "By letter shape" card with three fixed groups (sits on the line: a c e m n o r s u
      v w x z; reaches up: b d f h k l t i; drops below: g j p q y). Each leads to Level
      select with the set chosen. Level select: four tiles 1–4, tap = choose and go to
      Guide for letter 1. Widget tests for grid selection and disabled button.
- [ ] 3.3 Guide screen: hosts the drawing canvas widget for the current letter (extract
      the canvas painting/input from DrawingCanvas into a reusable widget if needed; the
      dev screen must keep working). Shows guidelines + ghost model letter. Eye toggle
      hides the model. Undo clears the attempt. Finish runs scoring; at level 1 goes
      straight to the next letter (or Session complete); at levels 2–4 goes to Feedback.
      Progress "X of N" + bar when set size > 1. No level markers yet (that is Phase 4).
- [ ] 3.4 Feedback screen: ring + one word (thresholds above), never a numeral. One-line
      note naming the weakest thing checked at this level (start / path / strokes) using a
      small string table in lib/feedback/feedback_strings.dart; no note when the weakest
      score is a bitmap score. Buttons: below Good = outline "Try again" (same letter,
      attempt cleared, model visible) + solid "Next letter"; at Good = "Next letter" only.
      Records each letter's result in the session. Widget tests for the three bands and
      the button rule.
- [ ] 3.5 Session complete screen: completion message; per-letter list (letter, small
      ring, word) when set size > 1; "Practice again" (same set, same level, solid) and
      "Home" (outline). Widget test.

## Phase 4 — guide markers for levels 2–4
- [ ] 4.1 Prepare the template letter on letter load, not only after drawing (tight
      bounds + mask cached per letter/canvas size; _runScoring reuses it; scores identical
      before/after — check a, i, k by hand).
- [ ] 4.2 Anchor builder: pure function giving, per stroke, the start point (centre of
      startRect) and one point per section in number order, snapped to the nearest
      skeleton pixel inside that zone (fallback: zone centre). Strokes with no sections are
      skipped. Tests across all 26 letters (builds without error; point count = section
      count).
- [ ] 4.3 Guide markers: L2 a dot at each stroke start; L3 dots + a static arrowed line
      through the anchors (CatmullRomSpline, built-in); L4 numbered dots ①②… in stroke
      order. Hidden when the eye toggle hides the model. Also a tagged test that renders
      all 26 letters with L3 markers to build/guide_markers/<letter>.png plus a contact
      sheet — Andrew reviews the sheet before this PR merges.

## Phase 5 — validation (Andrew)
- [ ] 5.1 On-device a–z sweep at level 3 on the Guide screen. Any zone that scores
      wrongly becomes a GitHub issue; fixes go through the normal zone routine.

## Later (not in this plan)
- Games mode (see `claude/game_mechanics_decisions.md`).
- Animated model trace and learner playback (plan on hold).
- Full plain-English feedback catalogue (roadmap Stream A).
