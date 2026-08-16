import 'package:flutter/material.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/services/prayer_notif_prefs.dart';

/// Prière — type d’alerte (adhan / takbir / vibration / off).
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
          '${S.notification} · ${prayerLabel(widget.prayerKey)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textOf(context),
          ),
        ),
        if (widget.countdown != null && widget.countdown!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.subtleOf(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.primaryOf(context),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.countdown!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOf(context),
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
            color: AppColors.subtleOf(context),
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onSelected(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentOf(context),
              foregroundColor: AppColors.onPrimaryOf(context),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              S.save,
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
    final fg = selected
        ? AppColors.onPrimaryOf(context)
        : AppColors.primaryOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? AppColors.accentOf(context) : Colors.transparent,
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
          color: AppColors.cardOf(context),
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

Widget prayerNotifBellIcon(
  PrayerNotifMode mode, {
  Color? color,
  double size = 22,
}) {
  return Builder(
    builder: (context) => Icon(
      notifModeIcon(mode),
      size: size,
      color: color ?? AppColors.primaryOf(context),
    ),
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

String prayerLabel(String key) => PrayerNotifPrefs.labelFr(key);
