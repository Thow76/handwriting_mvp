import 'letter_formation_data.dart';
import 'stroke_formation_enums.dart';

/// Formation data for every single-stroke lowercase letter.
///
/// Category: **Single stroke** — `c, e, l, o, s, v, w, z`.
/// Every entry has `minRequiredStrokes = 1` and exactly one
/// [ExpectedStroke].  Direction assignments follow the Universal Core
/// table in `stroke_formation_scope.md`:
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
/// Returns `null` for any letter not yet authored.
const Map<String, LetterFormationData> letterFormationRegistry = {
  'c': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
  'e': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
  'l': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
  'o': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.anticlockwise,
        startRegion: StrokeStartRegion.top,
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
      ),
    ],
  ),
  'v': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
  'w': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
  'z': LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
      ),
    ],
  ),
};
