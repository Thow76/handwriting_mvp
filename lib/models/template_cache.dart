import 'guidelines.dart';
import 'template_rasterizer.dart';

/// Remembers rasterized template letters so each one is drawn offscreen once
/// per letter / canvas size, instead of after every Finish.
///
/// [prepare] can be called as soon as a letter loads; a later [prepare] with
/// the same settings returns the very same result.
class TemplateCache {
  final Map<String, Future<TemplateRasterResult>> _entries = {};

  /// The cache the Guide screen shares across letters and attempts.
  static final TemplateCache shared = TemplateCache();

  /// Number of distinct templates held.
  int get length => _entries.length;

  /// Forgets every cached template.
  void clear() => _entries.clear();

  Future<TemplateRasterResult> prepare({
    required String letter,
    required String fontFamily,
    required double fontSize,
    required Guidelines guidelines,
    required double canvasWidth,
  }) {
    final key = [
      letter,
      fontFamily,
      fontSize,
      canvasWidth,
      guidelines.ascenderLine,
      guidelines.midline,
      guidelines.baseline,
      guidelines.descenderLine,
    ].join('|');
    return _entries.putIfAbsent(
      key,
      () => TemplateRasterizer.rasterize(
        letter: letter,
        fontFamily: fontFamily,
        fontSize: fontSize,
        guidelines: guidelines,
        canvasWidth: canvasWidth,
      ),
    );
  }
}
