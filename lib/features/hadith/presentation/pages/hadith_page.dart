import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../../../app/l10n/lang_builder.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/app_tab_header.dart';
import '../../data/models/hadith_models.dart';
import '../../data/repositories/hadith_repository.dart';
import 'hadith_collection_page.dart';
import 'hadith_detail_page.dart';

class HadithPage extends StatefulWidget {
  const HadithPage({super.key});

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  final _repo = HadithRepository();

  List<HadithCollection> _collections = const [];
  Hadith? _ofTheDay;
  List<Hadith> _featured = const [];
  Set<String> _favorites = {};
  List<Hadith> _favoriteHadiths = [];
  int _tab = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    List<HadithCollection> collections = const [];
    Hadith? ofTheDay;
    Set<String> favorites = {};
    List<Hadith> favoriteHadiths = const [];

    final collectionsFuture = () async {
      try {
        return await _repo.getCollections();
      } catch (_) {
        return <HadithCollection>[];
      }
    }();
    final Future<Hadith?> randomFuture = () async {
      try {
        return await _repo.getRandom();
      } catch (_) {
        return null;
      }
    }();
    final Future<Set<String>> favsFuture = () async {
      try {
        return await _repo.loadFavorites();
      } catch (_) {
        return <String>{};
      }
    }();
    final Future<List<Hadith>> favHadithsFuture = () async {
      try {
        return await _repo.loadFavoriteHadiths();
      } catch (_) {
        return <Hadith>[];
      }
    }();

    collections = await collectionsFuture;
    ofTheDay = await randomFuture;
    favorites = await favsFuture;
    favoriteHadiths = await favHadithsFuture;

    if (!mounted) return;
    setState(() {
      _collections = collections;
      _ofTheDay = ofTheDay;
      _favorites = favorites;
      _favoriteHadiths = favoriteHadiths;
      _error = collections.isEmpty
          ? 'Impossible de charger les hadiths.'
          : null;
      _loading = false;
    });

    try {
      final featured = await _repo.getFeatured();
      if (!mounted) return;
      setState(() => _featured = featured);
    } catch (_) {}
  }

  Future<void> _toggleFav(Hadith hadith) async {
    final next = await _repo.toggleFavorite(hadith);
    final favHadiths = await _repo.loadFavoriteHadiths();
    if (mounted) {
      setState(() {
        _favorites = next;
        _favoriteHadiths = favHadiths;
      });
    }
  }

  Future<void> _share(Hadith h) async {
    final tr = ContentLang.hadithTranslation(h);
    final text = tr != null
        ? '${h.arabic}\n\n$tr\n\n— ${ContentLang.hadithRefLabel(h)}'
        : '${h.arabic}\n\n— ${ContentLang.hadithRefLabel(h)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.hadithCopied)),
    );
  }

  Future<void> _openDetail(Hadith h) async {
    await HadithDetailPage.open(context, h);
    final favs = await _repo.loadFavorites();
    final favHadiths = await _repo.loadFavoriteHadiths();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _favoriteHadiths = favHadiths;
      });
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (_ofTheDay != null)
            _HadithOfDayCard(
              hadith: _ofTheDay!,
              onShare: () => _share(_ofTheDay!),
              onTap: () => _openDetail(_ofTheDay!),
            ),
          const SizedBox(height: 22),
          _SectionHeader(title: S.categories),
          const SizedBox(height: 12),
          _CategoriesGrid(
            collections: _collections.take(4).toList(),
            onOpen: (c) => HadithCollectionPage.open(context, c),
          ),
          const SizedBox(height: 22),
          _SectionHeader(title: S.hadithFeatured),
          const SizedBox(height: 12),
          for (var i = 0; i < _featured.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FeaturedCard(
                index: i + 1,
                hadith: _featured[i],
                favorited: _favorites.contains(_featured[i].id),
                onOpen: () => _openDetail(_featured[i]),
                onToggleFav: () => _toggleFav(_featured[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteHadiths.isEmpty) {
      return const _EmptyFavoritesTab();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: _favoriteHadiths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final h = _favoriteHadiths[i];
        return _FavoriteCard(
          hadith: h,
          onOpen: () => _openDetail(h),
          onToggleFav: () => _toggleFav(h),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, _) {
        return ColoredBox(
          color: AppColors.scaffoldOf(context),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _load,
                                child: Text(S.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              children: [
                                AppTabHeader(title: S.hadith),
                                const SizedBox(height: 12),
                                _SegmentTabs(
                              index: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _tab == 0 ? _buildHomeTab() : _buildFavoritesTab(),
                      ),
                    ],
                  ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HadithOfDayCard extends StatelessWidget {
  const _HadithOfDayCard({
    required this.hadith,
    required this.onShare,
    required this.onTap,
  });

  final Hadith hadith;
  final VoidCallback onShare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -6,
                top: -16,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        S.hadithOfDay,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hadith.arabicPreview,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ContentLang.hadithRefLabel(hadith),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onShare,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.cardOf(context),
                          foregroundColor: AppColors.primaryOf(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: Text(S.share),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textOf(context),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.collections, required this.onOpen});

  final List<HadithCollection> collections;
  final ValueChanged<HadithCollection> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: collections.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 108,
          ),
          itemBuilder: (context, i) {
            final c = collections[i];
            return Material(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onOpen(c),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primaryOf(context),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ContentLang.hadithCollectionName(c),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.2,
                          color: AppColors.textOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ContentLang.hadithCountLabel(c.totalHadiths),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          color: AppColors.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.index,
    required this.hadith,
    required this.favorited,
    required this.onOpen,
    required this.onToggleFav,
  });

  final int index;
  final Hadith hadith;
  final bool favorited;
  final VoidCallback onOpen;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.chipOf(context),
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ContentLang.hadithCollectionNameByKey(
                        hadith.collection,
                        fallback: hadith.collectionName,
                      ).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOf(context),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleFav,
                    icon: Icon(
                      favorited
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ],
              ),
              Text(
                hadith.arabicPreview,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 18,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOf(context),
                ),
              ),
              if (ContentLang.hadithTranslation(hadith) case final tr?) ...[
                const SizedBox(height: 8),
                Text(
                  tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.mutedOf(context),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hadith.narrator == null
                          ? ContentLang.hadithRefLabel(hadith)
                          : '${S.narratedBy} ${hadith.narrator}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedOf(context),
                      ),
                    ),
                  ),
                  Text(
                    hadith.grade ??
                        ContentLang.hadithCollectionNameByKey(
                          hadith.collection,
                          fallback: hadith.collectionName,
                        ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final labels = [S.home, S.favorites];
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

class _EmptyFavoritesTab extends StatelessWidget {
  const _EmptyFavoritesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 44,
              color: AppColors.primaryOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              S.favorites,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.emptyFavorites,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.hadith,
    required this.onOpen,
    required this.onToggleFav,
  });

  final Hadith hadith;
  final VoidCallback onOpen;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ContentLang.hadithRefLabel(hadith),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hadith.arabicPreview,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 18,
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    if (ContentLang.hadithTranslation(hadith)
                        case final tr?) ...[
                      const SizedBox(height: 6),
                      Text(
                        tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.mutedOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleFav,
                icon: Icon(
                  Icons.bookmark_rounded,
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
