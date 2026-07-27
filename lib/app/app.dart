import 'package:flutter/material.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/welcome/presentation/pages/welcome_page.dart';
import 'theme/app_theme.dart';

class NoorAlImanApp extends StatelessWidget {
  const NoorAlImanApp({super.key, required this.onboarded});

  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor Al-Iman',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: onboarded ? const HomePage() : const WelcomePage(),
    );
  }
}
