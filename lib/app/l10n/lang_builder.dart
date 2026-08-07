import 'package:flutter/material.dart';

import '../app_settings.dart';

/// Rebuilds when the app language changes (IndexedStack tabs need this).
class LangBuilder extends StatelessWidget {
  const LangBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, String lang) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.lang,
      builder: (context, lang, _) => builder(context, lang),
    );
  }
}
