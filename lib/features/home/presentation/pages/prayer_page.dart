import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/home_data.dart';
import '../../data/services/prayer_notif_prefs.dart';
import '../../data/services/prayer_notification_service.dart';

const _gold = Color(0xFFB08968);
const _goldSoft = Color(0xFFF5E6D8);
const _cardBorder = Color(0xFFE8E4DE);

class PrayerPage extends StatefulWidget {
  const PrayerPage({
    super.key,
    required this.prayer,
    required this.calendar,
  });

  final PrayerSummary? prayer;
  final IslamicCalendar? calendar;

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  late DateTime _selectedDay;
  late DateTime _weekStart;
  Map<String, PrayerNotifMode> _modes = {
    for (final k in PrayerNotifPrefs.prayerKeys)
      k: k == 'sunrise' ? PrayerNotifMode.off : PrayerNotifMode.adhan,
  };
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _weekStart = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    _syncCountdown();
    _loadModes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_tickCountdown);
    });
  }

  Future<void> _loadModes() async {
    final modes = await PrayerNotifPrefs.getAllModes();
    if (!mounted) return;
    setState(() => _modes = modes);
  }

  @override
  void didUpdateWidget(covariant PrayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayer?.nextPrayer != widget.prayer?.nextPrayer ||
        oldWidget.prayer?.minutesUntilNext !=
            widget.prayer?.minutesUntilNext) {
      _syncCountdown();
    }
  }

  void _syncCountdown() {
    final prayer = widget.prayer;
    _remaining = prayer == null
        ? Duration.zero
        : Duration(minutes: prayer.minutesUntilNext);
  }

  void _tickCountdown() {
    if (_remaining.inSeconds <= 0) {
      _remaining = Duration.zero;
      return;
    }
    _remaining -= const Duration(seconds: 1);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  String get _countdownLabel {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onBellTap(String prayerKey) async {
    final prayer = widget.prayer;
    if (prayer == null) return;

    final chosen = await showModalBottomSheet<PrayerNotifMode>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final current = _modes[prayerKey] ?? PrayerNotifMode.off;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notification · ${_prayerLabel(prayerKey)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisis le type d’alerte à l’heure de la prière (horaires API).',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final mode in PrayerNotifMode.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      switch (mode) {
                        PrayerNotifMode.off => Icons.notifications_off_outlined,
                        PrayerNotifMode.vibration => Icons.vibration_rounded,
                        PrayerNotifMode.takbir => Icons.campaign_outlined,
                        PrayerNotifMode.adhan => Icons.mosque_outlined,
                      },
                      color: current == mode
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      mode.label,
                      style: TextStyle(
                        fontWeight: current == mode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: current == mode
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, mode),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;

    if (chosen != PrayerNotifMode.off) {
      final ok = await PrayerNotificationService.instance.requestPermissions();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorise les notifications pour recevoir l’adhan.'),
          ),
        );
      }
    }

    await PrayerNotifPrefs.setMode(prayerKey, chosen);
    setState(() => _modes[prayerKey] = chosen);
    await PrayerNotificationService.instance.rescheduleFromApi(prayer);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          chosen == PrayerNotifMode.off
              ? 'Notification ${_prayerLabel(prayerKey)} désactivée'
              : '${chosen.label} planifié pour ${_prayerLabel(prayerKey)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    final calendar = widget.calendar;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: prayer == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _Header(
                    selectedDay: _selectedDay,
                    hijriLabel: calendar?.hijriLabel ?? '—',
                  ),
                  const SizedBox(height: 16),
                  _WeekSelector(
                    weekStart: _weekStart,
                    selectedDay: _selectedDay,
                    onSelect: (day) => setState(() => _selectedDay = day),
                  ),
                  const SizedBox(height: 18),
                  _NextPrayerCard(
                    prayerName: _prayerLabel(prayer.nextPrayer),
                    time: _formatTime(prayer.nextTime),
                    countdown: _isToday ? _countdownLabel : '--:--:--',
                  ),
                  const SizedBox(height: 18),
                  for (final entry in _rowsFor(prayer)) ...[
                    _PrayerRow(
                      entry: entry,
                      mode: _modes[entry.key] ?? PrayerNotifMode.off,
                      onBellTap: () => _onBellTap(entry.key),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }

  List<_PrayerEntry> _rowsFor(PrayerSummary prayer) {
    const order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final next = prayer.nextPrayer.toLowerCase();

    return [
      for (final key in order)
        if (prayer.prayerTimes.containsKey(key))
          _PrayerEntry(
            key: key,
            name: _prayerLabel(key),
            time: _formatTime(prayer.prayerTimes[key]!),
            isNow: _isToday && key == next,
            icon: _iconFor(key),
          ),
    ];
  }
}

class _PrayerEntry {
  const _PrayerEntry({
    required this.key,
    required this.name,
    required this.time,
    required this.isNow,
    required this.icon,
  });

  final String key;
  final String name;
  final String time;
  final bool isNow;
  final IconData icon;
}

class _Header extends StatelessWidget {
  const _Header({required this.selectedDay, required this.hijriLabel});

  final DateTime selectedDay;
  final String hijriLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _monthYear(selectedDay),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          hijriLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _gold,
          ),
        ),
      ],
    );
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.weekStart,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
              child: _DayChip(
                day: weekStart.add(Duration(days: i)),
                selected:
                    _sameDay(weekStart.add(Duration(days: i)), selectedDay),
                onTap: () => onSelect(weekStart.add(Duration(days: i))),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? null : Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              Text(
                _weekdayShort(day.weekday),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: selected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                day.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.prayerName,
    required this.time,
    required this.countdown,
  });

  final String prayerName;
  final String time;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33003D33),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: Icon(
              Icons.star_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROCHAINE PRIÈRE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prayerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dans $countdown',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.entry,
    required this.mode,
    required this.onBellTap,
  });

  final _PrayerEntry entry;
  final PrayerNotifMode mode;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final off = mode == PrayerNotifMode.off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isNow ? _gold : _cardBorder,
          width: entry.isNow ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Opacity(
        opacity: off && !entry.isNow ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: entry.isNow ? _goldSoft : const Color(0xFFF3F1EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                entry.icon,
                color: entry.isNow ? _gold : AppColors.primarySoft,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: entry.time,
                          style: TextStyle(
                            fontSize: 13,
                            color: entry.isNow
                                ? _gold
                                : AppColors.textSecondary,
                            fontWeight: entry.isNow
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (entry.isNow)
                          const TextSpan(
                            text: '  •  Maintenant',
                            style: TextStyle(
                              fontSize: 13,
                              color: _gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onBellTap,
              tooltip: mode.label,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                switch (mode) {
                  PrayerNotifMode.off => Icons.notifications_off_outlined,
                  PrayerNotifMode.vibration => Icons.vibration_rounded,
                  PrayerNotifMode.takbir => Icons.campaign_outlined,
                  PrayerNotifMode.adhan => Icons.notifications_active_rounded,
                },
                color: entry.isNow
                    ? _gold
                    : (off ? AppColors.textMuted : AppColors.primary),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _prayerLabel(String value) {
  const names = {
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };
  return names[value.toLowerCase()] ?? value;
}

IconData _iconFor(String key) {
  switch (key.toLowerCase()) {
    case 'fajr':
      return Icons.wb_twilight_rounded;
    case 'sunrise':
      return Icons.wb_sunny_outlined;
    case 'dhuhr':
      return Icons.wb_sunny_rounded;
    case 'asr':
      return Icons.sunny_snowing;
    case 'maghrib':
      return Icons.nights_stay_outlined;
    case 'isha':
      return Icons.nightlight_round;
    default:
      return Icons.access_time_rounded;
  }
}

String _formatTime(String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1].padLeft(2, '0');
  final isPm = hour >= 12;
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${h12.toString().padLeft(2, '0')}:$minute ${isPm ? 'PM' : 'AM'}';
}

String _monthYear(DateTime day) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[day.month - 1]} ${day.year}';
}

String _weekdayShort(int weekday) {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return days[weekday - 1];
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
