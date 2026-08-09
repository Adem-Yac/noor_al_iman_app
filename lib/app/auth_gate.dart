import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/pages/auth_flow_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'app_settings.dart';
import 'onboarding_page.dart';
import 'splash_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.onboardingDone,
      builder: (context, onboarded, _) {
        if (!onboarded) {
          return OnboardingPage(
            onFinished: () => AppSettings.setOnboardingDone(true),
          );
        }

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const HomePage();
            }

            // Splash seulement au tout premier démarrage (pas pendant login).
            if (state is AuthInitial) {
              return const SplashView();
            }

            // AuthLoading / Failure / Unauthenticated → garder le formulaire.
            return const AuthFlowPage();
          },
        );
      },
    );
  }
}
