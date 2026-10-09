import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Handwriting MVP',
      theme: buildAppTheme(),
      initialRoute: AppRoutes.mode,
      routes: AppRoutes.table,
    );
  }
}
