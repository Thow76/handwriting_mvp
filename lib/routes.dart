import 'package:flutter/material.dart';

import 'drawing_canvas.dart';
import 'screens/placeholder_screens.dart';

/// Named routes for the Practice flow.
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const levelSelect = '/levelSelect';
  static const guide = '/guide';
  static const feedback = '/feedback';
  static const sessionComplete = '/sessionComplete';
  static const dev = '/dev';

  static Map<String, WidgetBuilder> get table => {
    home: (_) => const HomeScreen(),
    levelSelect: (_) => const LevelSelectScreen(),
    guide: (_) => const GuideScreen(),
    feedback: (_) => const FeedbackScreen(),
    sessionComplete: (_) => const SessionCompleteScreen(),
    dev: (_) => const DrawingCanvas(),
  };
}
