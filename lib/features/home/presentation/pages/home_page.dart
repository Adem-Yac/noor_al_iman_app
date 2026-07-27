import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../../data/models/home_data.dart';
import '../../data/repositories/home_repository.dart';
import '../cubit/home_cubit.dart';
import '../widgets/app_bottom_nav.dart';
import 'verse_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(HomeRepository())..load(),
      child: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;

  void goToTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const _HomeTab(),
          const QuranPage(),
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final prayer = state is HomeLoaded ? state.data.prayer : null;
              return _PrayerTimesTab(prayer: prayer);
            },
          ),
          const _ComingSoon(
            title: 'Qibla',
            subtitle: 'Direction de la Kaaba',
            icon: Icons.explore_rounded,
          ),
          const _ComingSoon(
            title: 'Paramètres',
            subtitle: 'Langue, thème et notifications',
            icon: Icons.settings_rounded,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _tab,
        onSelect: goToTab,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().load(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      sliver: SliverList.list(
                        children: [
                          _Header(state: state),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _DateAndNotifRow(state: state),
                          const SizedBox(height: 18),
                          _PrayerSection(state: state),
                          const SizedBox(height: 24),
                          const _SectionTitle(title: 'Accès Rapide'),
                          const SizedBox(height: 12),
                          _QuickAccess(
                            onOpen: (label) => _openQuickAccess(context, label),
                          ),
                          const SizedBox(height: 26),
                          _VerseSection(state: state),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openQuickAccess(BuildContext context, String label) {
    final shell = context.findAncestorStateOfType<_HomeShellState>();
    switch (label) {
      case 'Quran':
        shell?.goToTab(1);
      case 'Qibla':
        shell?.goToTab(3);
      case 'Hadith':
        _pushComingSoon(
          context,
          title: 'Hadith',
          subtitle: 'Collections via UmmahAPI',
          icon: Icons.format_quote_rounded,
        );
      case 'Duas':
        _pushComingSoon(
          context,
          title: 'Duas',
          subtitle: 'Invocations via UmmahAPI',
          icon: Icons.volunteer_activism_outlined,
        );
    }
  }

  void _pushComingSoon(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: _ComingSoon(title: title, subtitle: subtitle, icon: icon),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is HomeLoaded ? state as HomeLoaded : null;
    final city = loaded?.data.location.label ?? '…';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Noor Al Iman',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.read<HomeCubit>().requestUserLocation(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  size: 18,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    city,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateAndNotifRow extends StatelessWidget {
  const _DateAndNotifRow({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is HomeLoaded ? state as HomeLoaded : null;
    final notifOn = loaded?.notificationsEnabled ?? true;
    final gregorian = loaded?.data.calendar.gregorianLabel ?? '…';
    final hijri = loaded?.data.calendar.hijriLabel ?? '…';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gregorian, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                hijri,
                style: const TextStyle(
                  color: Color(0xFFB08968),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: 'Notifications',
          button: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.filledTonal(
                onPressed: () => _onNotifTap(context, state),
                icon: Icon(
                  notifOn
                      ? Icons.notifications_none
                      : Icons.notifications_off_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              if (notifOn)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onNotifTap(BuildContext context, HomeState state) {
    final cubit = context.read<HomeCubit>();
    cubit.toggleNotifications();
    final enabled = state is HomeLoaded ? !state.notificationsEnabled : true;
    final prayer = state is HomeLoaded ? state.data.prayer : null;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled
                      ? 'Notifications activées'
                      : 'Notifications désactivées',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enabled
                      ? 'Tu seras alerté avant chaque prière.'
                      : 'Tu ne recevras plus d’alertes de prière.',
                ),
                if (prayer != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Prochaine : ${prayerLabel(prayer.nextPrayer)} à ${prayer.nextTime}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('Dans ${prayer.timeUntilNext}'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrayerSection extends StatelessWidget {
  const _PrayerSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      HomeLoaded(:final data) => _PrayerCard(prayer: data.prayer),
      HomeError(:final message) => _ErrorCard(message: message),
      _ => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _PrayerCard extends StatefulWidget {
  const _PrayerCard({required this.prayer});

  final PrayerSummary prayer;

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  late Duration _remaining;
  Timer? _timer;

  PrayerSummary get prayer => widget.prayer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayer.nextPrayer != prayer.nextPrayer ||
        oldWidget.prayer.minutesUntilNext != prayer.minutesUntilNext) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _remaining = Duration(minutes: prayer.minutesUntilNext);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        _timer?.cancel();
        setState(() => _remaining = Duration.zero);
        context.read<HomeCubit>().load();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  String get _countdown {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22003D33),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROCHAINE SALAT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prayerLabel(prayer.nextPrayer),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      prayerLabel(prayer.nextPrayer),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      prayer.nextTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prayer.progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              color: const Color(0xFFFFC66B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Il reste $_countdown',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                prayer.nextTime,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final entry in prayer.displayTimes)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        prayerLabel(entry.key),
                        style: TextStyle(
                          color:
                              entry.key == prayer.currentPrayer ||
                                  entry.key == prayer.nextPrayer
                              ? const Color(0xFFFFC66B)
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SelectableText(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.read<HomeCubit>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.menu_book_outlined, 'Quran'),
      (Icons.format_quote_rounded, 'Hadith'),
      (Icons.explore_outlined, 'Qibla'),
      (Icons.volunteer_activism_outlined, 'Duas'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final item in items)
          Semantics(
            label: 'Ouvrir ${item.$2}',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onOpen(item.$2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(item.$1, color: AppColors.primary),
                    ),
                    const SizedBox(height: 7),
                    Text(item.$2, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VerseSection extends StatelessWidget {
  const _VerseSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(title: 'Verset du jour'),
        const SizedBox(height: 10),
        if (state case HomeLoaded(
          :final data,
          :final isPlaying,
          :final playingUrl,
        ))
          _VerseCard(
            verse: data.verse,
            isPlaying: isPlaying && playingUrl == data.verse.audioUrl,
          )
        else if (state is HomeError)
          const SizedBox.shrink()
        else
          const Card(
            child: SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.verse, required this.isPlaying});

  final DailyVerse verse;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(verse.reference),
                  backgroundColor: const Color(0xFFFFE6D0),
                  side: BorderSide.none,
                  labelStyle: const TextStyle(fontSize: 11),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Partager',
                  onPressed: () async {
                    final text =
                        '${verse.reference}\n${verse.arabic}\n« ${verse.french} »';
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verset copié')),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              verse.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '« ${verse.french} »',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: verse.audioUrl == null
                        ? null
                        : () => context.read<HomeCubit>().playVerse(
                            verse.audioUrl,
                          ),
                    icon: Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 18,
                    ),
                    label: Text(isPlaying ? 'Arrêter' : 'Écouter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeCubit>(),
                            child: VerseDetailPage(verse: verse),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Lire la suite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesTab extends StatelessWidget {
  const _PrayerTimesTab({required this.prayer});

  final PrayerSummary? prayer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Horaires de prière',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (prayer == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text('En cours : ${prayerLabel(prayer!.currentPrayer)}'),
            Text(
              'Prochain : ${prayerLabel(prayer!.nextPrayer)} (${prayer!.nextTime})',
            ),
            const SizedBox(height: 16),
            for (final entry in prayer!.displayTimes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(prayerLabel(entry.key)),
                trailing: Text(
                  entry.value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Bientôt disponible',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String prayerLabel(String value) {
  const names = {
    'fajr': 'Fajr',
    'sunrise': 'Lever',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };
  return names[value] ?? value;
}
