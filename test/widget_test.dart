import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwriting_mvp/app_state.dart';
import 'package:handwriting_mvp/screens/home_screen.dart';

// Minimal MaterialApp wrapper for tests (avoids SystemChrome portrait lock).
class MaterialAppWrapper extends StatelessWidget {
  const MaterialAppWrapper({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomeScreen());
}

void main() {
  testWidgets('Home screen shows mode buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialAppWrapper(),
      ),
    );

    expect(find.text('Trace'), findsOneWidget);
    expect(find.text('Recall'), findsOneWidget);
  });
}
