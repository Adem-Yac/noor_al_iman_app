import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _search = TextEditingController();

  List<HadithCollection> _collections = const [];
  Hadith? _ofTheDay;
  List<Hadith> _featured = const [];
  List<Hadith>? _searchResults;
  Set<String> _favorites = {};
  bool _loading = true;
  String? _error;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getCollections(),
        _repo.getRandom(),
        _repo.getFeatured(),
        _repo.loadFavorites(),
      ]);
      if (!mounted) return;
      setState(() {
        _collections = results[0] as List<HadithCollection>;
        _ofTheDay = results[1] as Hadith;
        _featured = results[2] as List<Hadith>;
        _favorites = results[3] as Set<String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await _repo.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = list;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
    }
  }

  Future<void> _toggleFav(String id) async {
    final next = await _repo.toggleFavorite(id);
    if (mounted) setState(() => _favorites = next);
  }

  Future<void> _share(Hadith h) async {
    final text = '${h.arabic}\n\n${h.english}\n\n— ${h.refLabel}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hadith copié')),
    );
  }

  Future<void> _openDetail(Hadith h) async {
    await HadithDetailPage.open(context, h);
    final favs = await _repo.loadFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
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
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      children: [
                        const AppTabHeader(title: 'Hadith'),
                        const SizedBox(height: 14),
                        _SearchField(
                          controller: _search,
                          onChanged: _onSearch,
                        ),
                        if (_searching) ...[
                          const SizedBox(height: 24),
                          const Center(child: CircularProgressIndicator()),
                        ] else if (_searchResults != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            _searchResults!.isEmpty
                                ? 'Aucun résultat'
                                : '${_searchResults!.length} résultat(s)',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < _searchResults!.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FeaturedCard(
                                index: i + 1,
                                hadith: _searchResults![i],
                                favorited: _favorites.contains(
                                  _searchResults![i].id,
                                ),
                                onOpen: () => _openDetail(_searchResults![i]),
                                onToggleFav: () =>
                                    _toggleFav(_searchResults![i].id),
                              ),
                            ),
                        ] else ...[
                          const SizedBox(height: 18),
                          if (_ofTheDay != null)
                            _HadithOfDayCard(
                              hadith: _ofTheDay!,
                              onShare: () => _share(_ofTheDay!),
                              onTap: () => _openDetail(_ofTheDay!),
                            ),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: 'Catégories',
                            action: 'Voir tout',
                            onAction: () {
                              if (_collections.isEmpty) return;
                              HadithCollectionPage.open(
                                context,
                                _collections.first,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _CategoriesGrid(
                            collections: _collections.take(4).toList(),
                            onOpen: (c) => HadithCollectionPage.open(context, c),
                          ),
                          const SizedBox(height: 22),
                          const _SectionHeader(title: 'Hadiths en vedette'),
                          const SizedBox(height: 12),
                          for (var i = 0; i < _featured.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FeaturedCard(
                                index: i + 1,
                                hadith: _featured[i],
                                favorited: _favorites.contains(_featured[i].id),
                                onOpen: () => _openDetail(_featured[i]),
                                onToggleFav: () =>
                                    _toggleFav(_featured[i].id),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
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
      decoration: InputDecoration(
        hintText: 'Rechercher un hadith ou un mot-clé…',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFE8D5A3), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'HADITH DU JOUR',
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
                      hadith.refLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onShare,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    label: const Text('Partager'),
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
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.collections, required this.onOpen});

  final List<HadithCollection> collections;
  final ValueChanged<HadithCollection> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: collections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, i) {
        final c = collections[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onOpen(c),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.countLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
      color: Colors.white,
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
                    backgroundColor: const Color(0xFFD4EDE4),
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hadith.collectionName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primarySoft,
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
                      color: AppColors.primary,
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
                style: const TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 18,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hadith.narrator == null
                          ? 'Hadith n° ${hadith.number}'
                          : 'Rapporté par : ${hadith.narrator}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    hadith.grade ?? hadith.collectionName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
