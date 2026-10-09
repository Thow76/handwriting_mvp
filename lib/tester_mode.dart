import 'package:flutter/foundation.dart';

/// Tester mode: when on, every finished attempt shows the Breakdown screen.
/// Held in memory only; off by default. Works in release builds.
class TesterMode {
  TesterMode._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
}
