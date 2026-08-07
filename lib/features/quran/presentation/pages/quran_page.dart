import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/app_tab_header.dart';
import '../../data/models/quran_models.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/surahs.dart';
import '../cubit/quran_hub_cubit.dart';
import '../cubit/quran_reader_cubit.dart';
import 'quran_reader_page.dart';
import 'quran_tafsir_surah_page.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranHubCubit(QuranRepository()),
      child: const _QuranView(),
    );
  }
}

class _QuranView extends StatefulWidget {
  const _QuranView();

  @override
  State<_QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<_QuranView> {
  final _search = TextEditingController();
  int _tab = 0;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Surah> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kSurahs;
    return kSurahs.where((s) {
      return s.latin.toLowerCase().contains(q) ||
          s.french.toLowerCase().contains(q) ||
          s.arabic.contains(_query.trim()) ||
          '${s.number}'.contains(q);
    }).toList();
  }

  Future<void> _openSurah(Surah surah, {int ayah = 1}) async {
    await QuranReaderPage.open(
      context,
      SurahTarget(surah.number, initialAyah: ayah),
    );
    if (mounted) context.read<QuranHubCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: BlocBuilder<QuranHubCubit, QuranHubState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // En-tête scrollable avec le reste de la page.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          AppTabHeader(title: S.quran),
                          if (_tab != 2) ...[
                            const SizedBox(height: 10),
                            _SearchField(
                              controller: _search,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _LastReadingCard(
                            reading: state.lastReading,
                            onPlay: () {
                              final r = state.lastReading;
                              if (r == null) {
                                _openSurah(kSurahs[1], ayah: 255);
                                return;
                              }
                              _openSurah(
                                kSurahs.firstWhere(
                                  (s) => s.number == r.surah,
                                  orElse: () => kSurahs.first,
                                ),
                                ayah: r.ayah,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _SegmentTabs(
                            index: _tab,
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  ..._bodySlivers(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _bodySlivers(QuranHubState state) {
    if (_tab == 2) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          sliver: SliverList.separated(
            itemCount: kSurahs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final surah = kSurahs[i];
              return _TafsirSurahListTile(
                surah: surah,
                onTap: () => QuranTafsirSurahPage.open(context, surah),
              );
            },
          ),
        ),
      ];
    }

    if (_tab == 1) {
      if (state.loading) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      if (state.favorites.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyTab(
              icon: Icons.bookmark_border_rounded,
              title: S.favorites,
              subtitle: 'Ajoute des sourates ou versets depuis la lecture',
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          sliver: SliverList.separated(
            itemCount: state.favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final fav = state.favorites[i];
              return Material(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final surah = kSurahs.firstWhere(
                      (s) => s.number == fav.surah,
                      orElse: () => kSurahs.first,
                    );
                    _openSurah(surah, ayah: fav.ayah ?? 1);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          fav.type == 'ayah'
                              ? Icons.menu_book_outlined
                              : Icons.bookmark_rounded,
                          color: AppColors.primaryOf(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fav.type == 'ayah'
                                    ? '${ContentLang.surahTitleByNumber(fav.surah, fallbackLatin: fav.surahLatin)} ${fav.ayah}'
                                    : ContentLang.surahTitleByNumber(
                                        fav.surah,
                                        fallbackLatin: fav.surahLatin,
                                      ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOf(context),
                                ),
                              ),
                              if (fav.arabicPreview != null)
                                Text(
                                  fav.arabicPreview!,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textOf(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          fav.surahArabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: AppColors.primaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ];
    }

    final list = _filtered;
    if (list.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              S.noSurahFound,
              style: TextStyle(color: AppColors.mutedOf(context)),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final surah = list[i];
            final favId = FavoriteItem.surahId(surah.number);
            final isFav = state.favorites.any((f) => f.id == favId);
            return _SurahTile(
              surah: surah,
              isFavorite: isFav,
              onTap: () => _openSurah(surah),
              onFavorite: () => context.read<QuranHubCubit>().toggleSurahFavorite(
                    surah: surah.number,
                    latin: surah.latin,
                    arabic: surah.arabic,
                  ),
            );
          },
        ),
      ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 13, color: AppColors.textOf(context)),
      decoration: InputDecoration(
        isDense: true,
        hintText: S.searchSurah,
        hintStyle: TextStyle(color: AppColors.softOf(context), fontSize: 13),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.softOf(context),
          size: 20,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 36,
        ),
        filled: true,
        fillColor: AppColors.cardOf(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryOf(context),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _LastReadingCard extends StatelessWidget {
  const _LastReadingCard({required this.reading, required this.onPlay});

  final LastReading? reading;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final title = ContentLang.lastReadingTitle(reading);
    final subtitle = ContentLang.lastReadingSubtitle(reading);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22003D33),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 48,
            bottom: -8,
            child: Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.lastReading,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.bookmark_outline_rounded,
                          size: 15,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
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

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [S.surahs, S.favorites, S.tafsir];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: index == i
                      ? AppColors.primaryOf(context)
                      : AppColors.subtleOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: index == i
                        ? AppColors.onPrimaryOf(context)
                        : AppColors.textOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
  });

  final Surah surah;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _HexBadge(number: surah.number),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ContentLang.surahTitle(surah),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ContentLang.surahSubtitle(surah)}  •  ${surah.ayahCount} ${S.verses}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: S.favorites,
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFavorite
                      ? AppColors.primaryOf(context)
                      : AppColors.softOf(context),
                  size: 20,
                ),
              ),
              Text(
                surah.arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TafsirSurahListTile extends StatelessWidget {
  const _TafsirSurahListTile({required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _HexBadge(number: surah.number),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ContentLang.surahTitle(surah),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ContentLang.surahSubtitle(surah)}  •  ${surah.ayahCount} ${S.verses}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                surah.arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexBadge extends StatelessWidget {
  const _HexBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 46,
      child: CustomPaint(
        painter: _HexPainter(color: AppColors.chipOf(context)),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: AppColors.primaryOf(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primaryOf(context)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
