import 'dart:math';
import 'dart:ui';

import '../app_state.dart';
import '../models/guideline_metrics.dart';
import '../models/letter_template.dart';
import '../models/scoring_result.dart';
import '../models/stroke_data.dart';
import '../utils/constants.dart';
import 'point_resampling.dart';
import 'stroke_matching_service.dart';

/// Number of equidistant points each path is resampled to before comparison.
const int _kResampleN = 64;

/// Minimum coverage ratio (user arc-length / template arc-length, scale-
/// corrected) below which the combined score is penalised.  Drawings with
/// a ratio above this threshold are considered "complete enough".
const double _kCoverageThreshold = 0.55;

/// Maximum rotation angle (radians) that Procrustes may apply without
/// penalising the shape score.  ~20° allows for natural handwriting slant
/// while penalising clearly rotated or upside-down letters.
const double _kMaxFreeRotation = 20.0 * pi / 180.0; // ~0.349 rad

/// Maximum additive penalty for rotation (added to shape error).
/// At 180° rotation the full penalty is applied; at the threshold, zero.
/// 0.50 maps to a shape score of about 1 on beginner difficulty.
const double _kRotationPenaltyMax = 0.50;

/// Scores a user's drawing against a letter template.
///
/// All geometric comparison happens in **template coordinate space**
/// (x ∈ [0,1], y ∈ [0,1]).  Canvas-pixel user strokes are converted via
/// [GuidelineMetrics.canvasToTemplate] before any analysis.
class ScoringService {
  const ScoringService._();

  /// Entry point — returns a fully-populated [ScoringResult].
  static ScoringResult score({
    required List<StrokeData> userStrokes,
    required LetterTemplate template,
    required Size canvasSize,
    required GuidelineMode guidelineMode,
    required Difficulty difficulty,
  }) {
    final metrics = GuidelineMetrics(canvasSize);

    // 1. Convert user strokes to template space.
    final userStrokesTemplate = userStrokes
        .map((s) => s.points
            .map((p) => metrics.canvasToTemplate(Offset(p.x, p.y)))
            .toList())
        .toList();

    // 2. Match & concatenate for shape comparison.
    final (templatePath, userPath) = StrokeMatchingService.alignAndConcatenate(
      template.strokes,
      userStrokesTemplate,
    );

    // 3. All user points flat (for bounding-box analyses).
    final allUserPts = [for (final s in userStrokesTemplate) ...s];
    final allTemplatePts = [for (final s in template.strokes) ...s];

    // Guard: if user drew nothing, return minimum scores.
    if (allUserPts.isEmpty) {
      return _emptyResult(guidelineMode, difficulty);
    }

    // 4. Resample both paths to _kResampleN equidistant points.
    final tResampled = resampleEquidistant(templatePath, _kResampleN);
    final uResampled = resampleEquidistant(userPath, _kResampleN);

    // 5. Procrustes analysis.
    final procResult = _procrustes(tResampled, uResampled);

    // 6. Discrete Frechet on Procrustes-aligned points.
    final frechetDist =
        _discreteFrechet(procResult.alignedTemplate, procResult.alignedUser);

    // 7. Shape error (combined), with rotation penalty.
    //    If Procrustes needed to rotate the user path significantly to
    //    match, add a penalty to the shape error — letters should not
    //    need large rotations to look correct.  Additive so that even a
    //    perfect geometric match at 180° still gets penalised.
    final rawShapeError = 0.6 * procResult.distance + 0.4 * frechetDist;
    final absRotation = procResult.rotationAngle.abs();
    final rotationExcess = (absRotation - _kMaxFreeRotation)
        .clamp(0.0, pi - _kMaxFreeRotation);
    final rotationPenalty =
        _kRotationPenaltyMax * (rotationExcess / (pi - _kMaxFreeRotation));
    final shapeError = rawShapeError + rotationPenalty;

    // 8. Placement error.
    final placementError =
        _placementError(allUserPts, allTemplatePts);

    // 9. Third metric — proportion or size.
    final double thirdError;
    final String thirdLabel;
    if (guidelineMode == GuidelineMode.full) {
      thirdLabel = 'Proportion';
      thirdError = _proportionError(allUserPts, allTemplatePts);
    } else {
      thirdLabel = 'Size';
      thirdError = _sizeError(procResult.scaleFactor);
    }

    // 10. Map errors → scores via difficulty thresholds.
    final shapeScore = _errorToScore(shapeError, difficulty);
    final placementScore = _errorToScore(placementError, difficulty);
    final thirdScore = _errorToScore(thirdError, difficulty);

    // 11. Coverage penalty — penalise incomplete drawings.
    //     Compare user arc-length to template arc-length, corrected for
    //     the Procrustes scale factor so that small-but-complete drawings
    //     are not penalised (size is already handled by proportion/size).
    final templateArcLen = _arcLength(templatePath);
    final userArcLen = _arcLength(userPath);
    final scaleFactor = procResult.scaleFactor;
    final coverageRatio = (templateArcLen > 1e-10 && scaleFactor > 1e-10)
        ? ((userArcLen / templateArcLen) / scaleFactor).clamp(0.0, 1.5)
        : 0.0;

    final coveragePenalty = coverageRatio >= _kCoverageThreshold
        ? 1.0
        : (coverageRatio / _kCoverageThreshold) *
          (coverageRatio / _kCoverageThreshold); // quadratic ramp

    final rawCombined = (shapeScore + placementScore + thirdScore) / 3.0;
    final combined =
        (rawCombined * coveragePenalty).round().clamp(1, 10);

    return ScoringResult(
      shapeScore: shapeScore,
      placementScore: placementScore,
      thirdScore: thirdScore,
      thirdScoreLabel: thirdLabel,
      combinedScore: combined,
      feedbackMessage: ScoringResult.messageForScore(combined),
      rawErrors: {
        'shape': shapeError,
        'placement': placementError,
        thirdLabel.toLowerCase(): thirdError,
        'procrustes': procResult.distance,
        'frechet': frechetDist,
        'scaleFactor': procResult.scaleFactor,
        'coverageRatio': coverageRatio,
        'rotationDeg': procResult.rotationAngle * 180.0 / pi,
      },
    );
  }

  // ===========================================================================
  // Procrustes analysis
  // ===========================================================================

  /// Full ordinary Procrustes analysis: translate → scale → rotate.
  ///
  /// Returns the distance (residual), the scale factor ratio (user/template),
  /// and the aligned point sets.
  static _ProcrustesResult _procrustes(
    List<Offset> template,
    List<Offset> user,
  ) {
    assert(template.length == user.length);
    final n = template.length;

    // Centre both at origin.
    final tCentroid = _centroid(template);
    final uCentroid = _centroid(user);
    var t = template.map((p) => p - tCentroid).toList();
    var u = user.map((p) => p - uCentroid).toList();

    // Compute norms (RMS distance from centroid).
    final tNorm = _norm(t);
    final uNorm = _norm(u);

    // Scale factor: how much larger/smaller the user drew relative to template.
    // 1.0 = same size,  >1 = user drew bigger,  <1 = user drew smaller.
    final scaleFactor = tNorm > 1e-10 ? uNorm / tNorm : 1.0;

    // Scale both to unit norm.
    if (tNorm > 1e-10) {
      t = t.map((p) => Offset(p.dx / tNorm, p.dy / tNorm)).toList();
    }
    if (uNorm > 1e-10) {
      u = u.map((p) => Offset(p.dx / uNorm, p.dy / uNorm)).toList();
    }

    // Optimal rotation: θ = atan2(Σ(u×t), Σ(u·t))
    // where × is 2D cross product and · is dot product.
    var crossSum = 0.0, dotSum = 0.0;
    for (var i = 0; i < n; i++) {
      crossSum += u[i].dx * t[i].dy - u[i].dy * t[i].dx;
      dotSum += u[i].dx * t[i].dx + u[i].dy * t[i].dy;
    }
    final theta = atan2(crossSum, dotSum);

    // Rotate user points.
    final cosT = cos(theta), sinT = sin(theta);
    final uRotated = u
        .map((p) => Offset(
              p.dx * cosT - p.dy * sinT,
              p.dx * sinT + p.dy * cosT,
            ))
        .toList();

    // Try reversed user path and pick the better alignment.
    final uReversed = user.reversed.toList();
    var uRev = uReversed.map((p) => p - uCentroid).toList();
    if (uNorm > 1e-10) {
      uRev = uRev.map((p) => Offset(p.dx / uNorm, p.dy / uNorm)).toList();
    }
    var crossRev = 0.0, dotRev = 0.0;
    for (var i = 0; i < n; i++) {
      crossRev += uRev[i].dx * t[i].dy - uRev[i].dy * t[i].dx;
      dotRev += uRev[i].dx * t[i].dx + uRev[i].dy * t[i].dy;
    }
    final thetaRev = atan2(crossRev, dotRev);
    final cosR = cos(thetaRev), sinR = sin(thetaRev);
    final uRevRotated = uRev
        .map((p) => Offset(
              p.dx * cosR - p.dy * sinR,
              p.dx * sinR + p.dy * cosR,
            ))
        .toList();

    final distForward = _avgDistance(t, uRotated);
    final distReversed = _avgDistance(t, uRevRotated);

    if (distReversed < distForward) {
      return _ProcrustesResult(
        distance: distReversed,
        scaleFactor: scaleFactor,
        rotationAngle: thetaRev,
        alignedTemplate: t,
        alignedUser: uRevRotated,
      );
    }

    return _ProcrustesResult(
      distance: distForward,
      scaleFactor: scaleFactor,
      rotationAngle: theta,
      alignedTemplate: t,
      alignedUser: uRotated,
    );
  }

  // ===========================================================================
  // Discrete Fréchet distance
  // ===========================================================================

  /// Discrete Fréchet distance between two same-length point sequences.
  ///
  /// Uses a standard O(m×n) DP table.  With m = n = 64 this is 4096 cells —
  /// trivially fast.
  static double _discreteFrechet(List<Offset> p, List<Offset> q) {
    final m = p.length, n = q.length;
    // DP table.  dp[i][j] = Fréchet distance up to (p[i], q[j]).
    final dp = List.generate(m, (_) => List.filled(n, 0.0));

    dp[0][0] = (p[0] - q[0]).distance;
    for (var i = 1; i < m; i++) {
      dp[i][0] = max(dp[i - 1][0], (p[i] - q[0]).distance);
    }
    for (var j = 1; j < n; j++) {
      dp[0][j] = max(dp[0][j - 1], (p[0] - q[j]).distance);
    }

    for (var i = 1; i < m; i++) {
      for (var j = 1; j < n; j++) {
        final prev = min(dp[i - 1][j], min(dp[i][j - 1], dp[i - 1][j - 1]));
        dp[i][j] = max(prev, (p[i] - q[j]).distance);
      }
    }

    return dp[m - 1][n - 1];
  }

  // ===========================================================================
  // Category-specific error computations
  // ===========================================================================

  /// Baseline placement error: average of top and bottom bounding-box
  /// deviation in template space.
  static double _placementError(
    List<Offset> userPts,
    List<Offset> templatePts,
  ) {
    final uBox = _boundingBox(userPts);
    final tBox = _boundingBox(templatePts);

    final topErr = (uBox.maxY - tBox.maxY).abs();
    final bottomErr = (uBox.minY - tBox.minY).abs();
    return (topErr + bottomErr) / 2.0;
  }

  /// Proportion error (full-guidelines mode):
  ///   0.5 × aspect-ratio error  +  0.5 × vertical-zone-distribution error.
  static double _proportionError(
    List<Offset> userPts,
    List<Offset> templatePts,
  ) {
    final uBox = _boundingBox(userPts);
    final tBox = _boundingBox(templatePts);

    // Aspect ratio error.
    final tAspect = tBox.width > 1e-10 ? tBox.width / tBox.height : 1.0;
    final uAspect = uBox.width > 1e-10 ? uBox.width / uBox.height : 1.0;
    final aspectErr = tAspect > 1e-10 ? (uAspect - tAspect).abs() / tAspect : 0.0;

    // Zone distribution: fraction of points above x-height.
    final tAbove = templatePts.where((p) => p.dy > kTemplateXHeight).length /
        templatePts.length;
    final uAbove =
        userPts.where((p) => p.dy > kTemplateXHeight).length / userPts.length;
    final zoneErr = (uAbove - tAbove).abs();

    return 0.5 * aspectErr + 0.5 * zoneErr;
  }

  /// Size consistency error (baseline-only mode):
  ///   |1.0 − scaleFactor|
  static double _sizeError(double scaleFactor) =>
      (1.0 - scaleFactor).abs();

  // ===========================================================================
  // Error → score mapping
  // ===========================================================================

  static int _errorToScore(double error, Difficulty difficulty) {
    final thresholds = kDifficultyThresholds[difficulty.name]!;
    for (final (maxError, score) in thresholds) {
      if (error < maxError) return score;
    }
    return 1;
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Total arc length (sum of segment distances) of a polyline.
  static double _arcLength(List<Offset> pts) {
    var len = 0.0;
    for (var i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    return len;
  }

  static Offset _centroid(List<Offset> pts) {
    var sx = 0.0, sy = 0.0;
    for (final p in pts) {
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / pts.length, sy / pts.length);
  }

  /// Frobenius norm = sqrt(Σ(x² + y²)) for centred points.
  static double _norm(List<Offset> pts) {
    var sum = 0.0;
    for (final p in pts) {
      sum += p.dx * p.dx + p.dy * p.dy;
    }
    return sqrt(sum);
  }

  /// Average Euclidean distance between corresponding points.
  static double _avgDistance(List<Offset> a, List<Offset> b) {
    assert(a.length == b.length);
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).distance;
    }
    return sum / a.length;
  }

  static _BBox _boundingBox(List<Offset> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return _BBox(minX, minY, maxX, maxY);
  }

  static ScoringResult _emptyResult(
    GuidelineMode guidelineMode,
    Difficulty difficulty,
  ) {
    final label =
        guidelineMode == GuidelineMode.full ? 'Proportion' : 'Size';
    return ScoringResult(
      shapeScore: 1,
      placementScore: 1,
      thirdScore: 1,
      thirdScoreLabel: label,
      combinedScore: 1,
      feedbackMessage: ScoringResult.messageForScore(1),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data classes
// ---------------------------------------------------------------------------

class _ProcrustesResult {
  const _ProcrustesResult({
    required this.distance,
    required this.scaleFactor,
    required this.rotationAngle,
    required this.alignedTemplate,
    required this.alignedUser,
  });

  /// Residual average distance after optimal alignment.
  final double distance;

  /// User norm / template norm before unit scaling.
  /// 1.0 = same size, >1 = user drew bigger, <1 = user drew smaller.
  final double scaleFactor;

  /// Optimal rotation angle (radians) applied to align user to template.
  /// 0 = no rotation needed, π = upside-down.
  final double rotationAngle;

  /// Centred, unit-scaled, rotation-aligned template points.
  final List<Offset> alignedTemplate;

  /// Centred, unit-scaled, rotation-aligned user points.
  final List<Offset> alignedUser;
}

class _BBox {
  const _BBox(this.minX, this.minY, this.maxX, this.maxY);
  final double minX, minY, maxX, maxY;

  double get width => (maxX - minX).abs();
  double get height => (maxY - minY).abs();
}
