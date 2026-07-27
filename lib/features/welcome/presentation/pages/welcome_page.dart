import 'package:flutter/material.dart';

import '../../../../app/app_prefs.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../home/data/services/location_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/welcome_background.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _busy = false;
  String? _error;

  Future<void> _onStart() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Première fois uniquement : demande localisation GPS.
      await LocationService().requestAndSave(force: true);
    } on LocationException catch (e) {
      // On continue quand même vers l'accueil (fallback Paris).
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Localisation indisponible. On continue.');
      }
    }

    await AppPrefs.setOnboarded();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

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
                const SizedBox(height: 10),
                Text(
                  'Votre compagnon spirituel quotidien\n'
                  'pour nourrir votre foi et illuminer\n'
                  'votre chemin vers l\'excellence.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB08968),
                      fontSize: 13,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: _busy ? null : _onStart,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Commencer'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La localisation est demandée une seule fois\npour les horaires de prière.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 28),
                Text('LA LUMIÈRE DE LA FOI', style: textTheme.labelSmall),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
