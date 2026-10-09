import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'letter_formation_data.dart';
import 'stroke.dart';
import 'waypoint_section.dart';

/// Whether the learner put ink in every numbered section of a letter.
class CompletionResult {
  /// True when every section of the letter was entered by some ink.
  final bool complete;

  /// The numbers of the sections no ink entered, in ascending order. Empty
  /// when [complete].
  final List<int> missingSections;

  const CompletionResult({
    required this.complete,
    required this.missingSections,
  });
}

/// Checks that ink reached every [WaypointSection] of a letter.
///
/// This is separate from path scoring: order, direction and which stroke made
/// the ink do not matter, and nothing here feeds the Path score. It answers one
/// question only — is any part of the letter missing?
///
/// Ink is tested as line segments, not only recorded points. Each segment
/// between consecutive points of the same stroke is walked in steps of at most
/// [stepSize] pixels, so a fast stroke cannot jump over a small section.
class CompletionChecker {
  /// The longest gap, in pixels, left untested along a segment.
  static const double stepSize = 1.0;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box used to map each section's fractional rectangle.
  final Rect bounds;

  const CompletionChecker({required this.data, required this.bounds});

  /// Reports which sections of the letter [observed] strokes entered.
  /// A letter with no sections is complete.
  CompletionResult check(List<Stroke> observed) {
    final sections = data.strokes.expand((s) => s.sections).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final missing = <int>[
      for (final section in sections)
        if (!_entered(section, observed)) section.number,
    ];
    return CompletionResult(
      complete: missing.isEmpty,
      missingSections: missing,
    );
  }

  bool _entered(WaypointSection section, List<Stroke> observed) {
    for (final stroke in observed) {
      final points = stroke.points;
      if (points.isEmpty) continue;
      if (section.contains(points.first, bounds)) return true;
      for (var i = 1; i < points.length; i++) {
        if (_segmentEnters(section, points[i - 1], points[i])) return true;
      }
    }
    return false;
  }

  bool _segmentEnters(WaypointSection section, Offset a, Offset b) {
    final steps = math.max(1, ((b - a).distance / stepSize).ceil());
    for (var i = 1; i <= steps; i++) {
      if (section.contains(Offset.lerp(a, b, i / steps)!, bounds)) return true;
    }
    return false;
  }
}
