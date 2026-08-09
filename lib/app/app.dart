import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'app_settings.dart';
import 'auth_gate.dart';
import 'l10n/app_lang.dart';
import 'theme/app_theme.dart';

class NoorAlImanApp extends StatelessWidget {
  const NoorAlImanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(AuthRepository()),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppSettings.themeMode,
        builder: (context, mode, _) {
          return ValueListenableBuilder<String>(
            valueListenable: AppSettings.lang,
            builder: (context, lang, _) {
              return MaterialApp(
                title: 'Noor Al-Iman',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: mode,
                locale: AppLang.materialLocale,
                supportedLocales: AppLang.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  return Directionality(
                    textDirection: TextDirection.ltr,
                    // Clé langue : rebuild strings sans remonter AuthGate/HomeCubit.
                    child: KeyedSubtree(
                      key: ValueKey('locale-$lang'),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}
