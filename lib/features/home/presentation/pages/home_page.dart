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
import '../widgets/app_tab_header.dart';
import '../../../hadith/presentation/pages/hadith_page.dart';
import '../../../prayer/data/models/prayer_summary.dart';
import '../../../prayer/presentation/pages/prayer_page.dart';
import '../../../duas/presentation/pages/duas_page.dart';
import '../../../prayer/presentation/widgets/prayer_notification_sheets.dart' show prayerLabel, showHomePrayerNotifSheet;
import 'settings_page.dart';
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
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          const _HomeTab(),
          const QuranPage(),
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final prayer = state is HomeLoaded ? state.data.prayer : null;
              final calendar =
                  state is HomeLoaded ? state.data.calendar : null;
              return PrayerPage(prayer: prayer, calendar: calendar);
            },
          ),
          const HadithPage(),
          const SettingsPage(),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
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
      case 'Hadith':
        shell?.goToTab(3);
      case 'Prière':
        shell?.goToTab(2);
      case 'Douas':
        DuasPage.open(context);
    }
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
        const Expanded(child: AppTabHeader(title: 'Noor Al Iman')),
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

    showHomePrayerNotifSheet(
      context,
      enabled: enabled,
      prayer: prayer,
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
      (Icons.access_time_rounded, 'Prière'),
      (Icons.volunteer_activism_outlined, 'Douas'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6D0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verse.reference,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B6914),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Partager',
                visualDensity: VisualDensity.compact,
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
          const SizedBox(height: 8),
          Text(
            verse.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'ScheherazadeNew',
              color: AppColors.primary,
              fontSize: 24,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4A35A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '« ${verse.french} »',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: verse.audioUrl == null
                        ? null
                        : () => context.read<HomeCubit>().playVerse(
                              verse.audioUrl,
                            ),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPlaying
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPlaying ? 'Arrêter' : 'Écouter',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeCubit>(),
                            child: VerseDetailPage(verse: verse),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Lire la suite',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
