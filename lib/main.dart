import 'package:flutter/material.dart';
import 'app/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_screen.dart';

void main() {
  runApp(const MoneyFlowApp());
}

class MoneyFlowApp extends StatelessWidget {
  const MoneyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyFlow',
      debugShowCheckedModeBanner: false,
      theme: moneyFlowTheme,
      home: const SplashScreen(),
    );
  }
}
