import 'dart:ui' show Offset, Rect;

import 'waypoint_section.dart';

/// The result of matching one expected [WaypointSection] against the observed
/// path.
///
/// [section] is the section that was checked.
/// [isHit] is `true` when an observed point fell inside the section's rectangle
/// AND occurred after the previous section's hit in the point stream.
/// [hitPointIndex] is the index into the observed-points list where the hit was
/// recorded, or `null` when [isHit] is `false` (a miss, or a section never
/// reached because scoring stopped at an earlier break).
class SectionHit {
  /// The section that was evaluated.
  final WaypointSection section;

  /// Whether the section was successfully matched.
  final bool isHit;

  /// Index of the matching observed point, or `null` on a miss.
  final int? hitPointIndex;

  const SectionHit({
    required this.section,
    required this.isHit,
    this.hitPointIndex,
  });
}

/// The complete result of [matchWaypointSections].
///
/// [hitCount] is the number of sections satisfied consecutively from the start
/// (the length of the in-order prefix the learner completed before the first
/// break).
/// [hits] contains one [SectionHit] per expected section, in ascending
/// [WaypointSection.number] order, providing per-section hit/miss detail for
/// learner feedback. Sections at and after the first break are reported as
/// misses.
class SectionMatchResult {
  /// Number of sections satisfied consecutively from the start.
  final int hitCount;

  /// Per-section breakdown, one entry per section, in number order.
  final List<SectionHit> hits;

  const SectionMatchResult({
    required this.hitCount,
    required this.hits,
  });
}

/// Matches an ordered set of numbered [WaypointSection]s against a list of
/// observed stroke points, using strict sequential scoring.
///
/// ## Algorithm
///
/// Sections are processed in ascending [WaypointSection.number] order. Starting
/// from the beginning of [observedPoints]:
/// - Scan forward from the index after the previous section's hit (or from the
///   beginning for the first section) for the first observed point that lies
///   inside the section's rectangle (per [WaypointSection.contains], evaluated
///   against [tightBounds]).
/// - If such a point is found, the section is a hit, that point's index becomes
///   the new cursor, and matching continues with the next section.
/// - If no such point is found, the section is a miss and **scoring stops**: no
///   further sections are evaluated, and they are all reported as misses.
///
/// ## Strict sequential scoring
///
/// Scoring stops at the first section that is not hit in order. There is no
/// partial credit for sections visited out of order and no credit for sections
/// reached only after a break. [hitCount] is therefore the length of the
/// in-order prefix the learner completed.
///
/// ## Parameters
///
/// - [observedPoints]: the raw point stream of a single observed stroke.
/// - [sections]: the numbered sections the stroke must pass through, in order.
///   Processed in ascending [WaypointSection.number] regardless of list order.
/// - [tightBounds]: the tight bounding box of the letter template, used to map
///   each section's fractional rectangle into absolute coordinates.
///
/// Returns a [SectionMatchResult] with the consecutive hit count and
/// per-section detail.
SectionMatchResult matchWaypointSections(
  List<Offset> observedPoints,
  List<WaypointSection> sections,
  Rect tightBounds,
) {
  // Process sections in ascending number order; the section number is
  // authoritative, not the list order.
  final ordered = [...sections]..sort((a, b) => a.number.compareTo(b.number));

  final hits = <SectionHit>[];
  var lastMatchedIndex = -1;
  var hitCount = 0;
  var broken = false;

  for (final section in ordered) {
    // Once scoring has stopped at a break, every remaining section is a miss
    // and is not evaluated against the points.
    if (broken) {
      hits.add(SectionHit(section: section, isHit: false));
      continue;
    }

    // Scan forward from just after the previous hit for the first point that
    // lies inside this section's rectangle.
    var matchIndex = -1;
    for (var i = lastMatchedIndex + 1; i < observedPoints.length; i++) {
      if (section.contains(observedPoints[i], tightBounds)) {
        matchIndex = i;
        break;
      }
    }

    if (matchIndex != -1) {
      hits.add(
        SectionHit(section: section, isHit: true, hitPointIndex: matchIndex),
      );
      lastMatchedIndex = matchIndex;
      hitCount++;
    } else {
      // First break: record the miss and stop crediting further sections.
      hits.add(SectionHit(section: section, isHit: false));
      broken = true;
    }
  }

  return SectionMatchResult(hitCount: hitCount, hits: hits);
}
