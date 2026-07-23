import 'package:flutter/material.dart';

import '../widgets/welcome_background.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 128,
                    height: 128,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'As-Salamu\nAlaykum',
                  textAlign: TextAlign.center,
                  style: textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenue sur Noor Al-Iman',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  'Votre compagnon spirituel quotidien\n'
                  'pour nourrir votre foi et illuminer\n'
                  'votre chemin vers l\'excellence.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () {
                    // Prochaine étape : auth / onboarding
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Commencer'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'LA LUMIÈRE DE LA FOI',
                  style: textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
