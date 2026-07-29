import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/prayer_summary.dart';
import '../../data/services/prayer_notif_prefs.dart';

/// Accueil — notifications activées / désactivées (dialogue centré).
Future<void> showHomePrayerNotifSheet(
  BuildContext context, {
  required bool enabled,
  PrayerSummary? prayer,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _NotificationDialogShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusIcon(enabled: enabled),
                const SizedBox(height: 18),
                Text(
                  enabled
                      ? 'Notifications activées'
                      : 'Notifications désactivées',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  enabled
                      ? 'Tu seras alerté à l’heure de chaque prière.'
                      : 'Tu ne recevras plus d’alertes de prière.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (prayer != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chipMint.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Prochaine : ${prayerLabel(prayer.nextPrayer)} à ${prayer.nextTime}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dans ${prayer.timeUntilNext}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Prière — type d’alerte (dialogue centré).
Future<PrayerNotifMode?> showPrayerAlertTypeSheet(
  BuildContext context, {
  required String prayerKey,
  required PrayerNotifMode current,
}) {
  return showDialog<PrayerNotifMode>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _NotificationDialogShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Notification · ${prayerLabel(prayerKey)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisis le type d’alerte à l’heure de la prière (horaires API).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                for (final mode in PrayerNotifMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AlertTypeOption(
                      mode: mode,
                      selected: current == mode,
                      onTap: () => Navigator.pop(dialogContext, mode),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _NotificationDialogShell extends StatelessWidget {
  const _NotificationDialogShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: child,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: enabled ? AppColors.chipMint : AppColors.tabInactive,
        shape: BoxShape.circle,
      ),
      child: Icon(
        enabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class _AlertTypeOption extends StatelessWidget {
  const _AlertTypeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PrayerNotifMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.chipMint
          : AppColors.tabInactive.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                notifModeIcon(mode),
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  mode.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icône cloche / alerte sur chaque ligne de prière.
Widget prayerNotifBellIcon(
  PrayerNotifMode mode, {
  Color? color,
  double size = 22,
}) {
  return Icon(
    notifModeIcon(mode),
    size: size,
    color: color ?? AppColors.primary,
  );
}

IconData notifModeIcon(PrayerNotifMode mode) {
  return switch (mode) {
    PrayerNotifMode.off => Icons.notifications_off_outlined,
    PrayerNotifMode.vibration => Icons.phone_android_outlined,
    PrayerNotifMode.takbir => Icons.campaign_outlined,
    PrayerNotifMode.adhan => Icons.mosque_outlined,
  };
}

String prayerLabel(String key) {
  const names = {
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };
  return names[key] ?? key;
}
