/// The seven scores a learner can be shown.
enum ScoreKind {
  coverage,
  precision,
  placement,
  efficiency,
  start,
  path,
  strokes,
}

/// How much of the scoring a practice session reveals, from easiest to full.
enum ScoringLevel {
  /// Level 1: the four bitmap scores only.
  shapeOnly,

  /// Level 2: bitmap scores plus stroke start.
  shapeAndStart,

  /// Level 3: adds path.
  shapeStartAndPath,

  /// Level 4: adds stroke breaks.
  full,
}

/// The scores visible at [level].
Set<ScoreKind> visibleScores(ScoringLevel level) {
  const bitmap = {
    ScoreKind.coverage,
    ScoreKind.precision,
    ScoreKind.placement,
    ScoreKind.efficiency,
  };
  switch (level) {
    case ScoringLevel.shapeOnly:
      return bitmap;
    case ScoringLevel.shapeAndStart:
      return {...bitmap, ScoreKind.start};
    case ScoringLevel.shapeStartAndPath:
      return {...bitmap, ScoreKind.start, ScoreKind.path};
    case ScoringLevel.full:
      return {...bitmap, ScoreKind.start, ScoreKind.path, ScoreKind.strokes};
  }
}

/// Whether [kind] is visible at [level].
bool isScoreVisible(ScoringLevel level, ScoreKind kind) =>
    visibleScores(level).contains(kind);
