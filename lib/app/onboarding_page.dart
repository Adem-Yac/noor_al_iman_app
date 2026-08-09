import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'app_settings.dart';
import 'l10n/app_strings.dart';
import 'theme/app_colors.dart';
import '../features/prayer/data/services/prayer_notification_service.dart';

/// Première ouverture : bienvenue + localisation + notifications.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppSettings.setOnboardingDone(true);
    widget.onFinished();
  }

  Future<void> _next() async {
    if (_index >= 2) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _enableLocation() async {
    setState(() => _busy = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _next();
  }

  Future<void> _enableNotifications() async {
    setState(() => _busy = true);
    try {
      final ok =
          await PrayerNotificationService.instance.requestPermissions();
      await AppSettings.setNotificationsEnabled(ok);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardSlide(
        icon: Icons.mosque_rounded,
        title: S.onboardWelcomeTitle,
        body: S.onboardWelcomeBody,
        primaryLabel: S.next,
        onPrimary: _busy ? null : _next,
        secondaryLabel: null,
        onSecondary: null,
      ),
      _OnboardSlide(
        icon: Icons.location_on_outlined,
        title: S.onboardLocationTitle,
        body: S.onboardLocationBody,
        primaryLabel: S.onboardEnableLocation,
        onPrimary: _busy ? null : _enableLocation,
        secondaryLabel: S.onboardSkip,
        onSecondary: _busy ? null : _next,
      ),
      _OnboardSlide(
        icon: Icons.notifications_active_outlined,
        title: S.onboardNotifTitle,
        body: S.onboardNotifBody,
        primaryLabel: S.onboardEnableNotifs,
        onPrimary: _busy ? null : _enableNotifications,
        secondaryLabel: S.onboardSkip,
        onSecondary: _busy ? null : _finish,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _finish,
                child: Text(S.onboardSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 22 : 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryOf(context)
                          : AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? AppColors.darkPrimaryContainer
                  : AppColors.chipMint.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 44,
              color: AppColors.primaryOf(context),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textOf(context),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.mutedOf(context),
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOf(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
