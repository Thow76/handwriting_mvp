import 'package:flutter/material.dart';

import 'drawing_canvas.dart';
import 'screens/breakdown_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/mode_screen.dart';
import 'screens/session_complete_screen.dart';

/// Named routes for the Practice flow.
class AppRoutes {
  AppRoutes._();

  static const mode = '/mode';
  static const home = '/';
  static const levelSelect = '/levelSelect';
  static const guide = '/guide';
  static const feedback = '/feedback';
  static const sessionComplete = '/sessionComplete';
  static const breakdown = '/breakdown';
  static const dev = '/dev';

  static Map<String, WidgetBuilder> get table => {
    mode: (_) => const ModeScreen(),
    home: (_) => const HomeScreen(),
    levelSelect: (_) => const LevelSelectScreen(),
    guide: (_) => const GuideScreen(),
    feedback: (_) => const FeedbackScreen(),
    sessionComplete: (_) => const SessionCompleteScreen(),
    breakdown: (_) => const BreakdownScreen(),
    dev: (_) => const DrawingCanvas(),
  };
}
