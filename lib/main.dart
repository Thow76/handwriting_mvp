import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/letter_picker_screen.dart';
import 'screens/trace_screen.dart';
import 'screens/recall_screen.dart';
import 'screens/score_screen.dart';
import 'screens/template_capture_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const HandwritingApp(),
    ),
  );
}

class HandwritingApp extends StatelessWidget {
  const HandwritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Handwriting Practice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A86FF)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/letter-picker': (_) => const LetterPickerScreen(),
        '/trace': (_) => const TraceScreen(),
        '/recall': (_) => const RecallScreen(),
        '/score': (_) => const ScoreScreen(),
        '/capture': (_) => const TemplateCaptureScreen(),
      },
    );
  }
}
