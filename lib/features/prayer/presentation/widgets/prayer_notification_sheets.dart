import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/prayer_notif_prefs.dart';
import '../../data/services/prayer_notification_service.dart';

/// Prière — type d’alerte (barre horizontale blanche, style maquette).
Future<PrayerNotifMode?> showPrayerAlertTypeSheet(
  BuildContext context, {
  required String prayerKey,
  required PrayerNotifMode current,
  String? countdown,
}) {
  return showDialog<PrayerNotifMode>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _NotificationDialogShell(
            child: _AlertTypePicker(
              prayerKey: prayerKey,
              initial: current,
              countdown: countdown,
              onSelected: (mode) => Navigator.pop(dialogContext, mode),
            ),
          ),
        ),
      );
    },
  );
}

class _AlertTypePicker extends StatefulWidget {
  const _AlertTypePicker({
    required this.prayerKey,
    required this.initial,
    required this.onSelected,
    this.countdown,
  });

  final String prayerKey;
  final PrayerNotifMode initial;
  final String? countdown;
  final ValueChanged<PrayerNotifMode> onSelected;

  @override
  State<_AlertTypePicker> createState() => _AlertTypePickerState();
}

class _AlertTypePickerState extends State<_AlertTypePicker> {
  late PrayerNotifMode _selected = widget.initial;

  static const _order = [
    PrayerNotifMode.adhan,
    PrayerNotifMode.takbir,
    PrayerNotifMode.vibration,
    PrayerNotifMode.off,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Notification · ${prayerLabel(widget.prayerKey)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.countdown != null && widget.countdown!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.countdown!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              for (final mode in _order)
                Expanded(
                  child: _ModeChip(
                    mode: mode,
                    selected: _selected == mode,
                    onTap: () => setState(() => _selected = mode),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_selected != PrayerNotifMode.off)
          TextButton.icon(
            onPressed: () async {
              await PrayerNotificationService.instance.showTest(_selected);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Test ${_selected.label} envoyé'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
            label: Text('Tester ${_selected.label}'),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onSelected(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PrayerNotifMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(notifModeIcon(mode), size: 22, color: fg),
                const SizedBox(height: 6),
                Text(
                  mode.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: child,
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
    PrayerNotifMode.off => Icons.volume_off_rounded,
    PrayerNotifMode.vibration => Icons.vibration_rounded,
    PrayerNotifMode.takbir => Icons.notifications_none_rounded,
    PrayerNotifMode.adhan => Icons.volume_up_rounded,
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
