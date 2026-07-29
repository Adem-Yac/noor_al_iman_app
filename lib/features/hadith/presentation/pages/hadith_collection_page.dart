import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/hadith_models.dart';
import '../../data/repositories/hadith_repository.dart';
import 'hadith_detail_page.dart';

class HadithCollectionPage extends StatefulWidget {
  const HadithCollectionPage({super.key, required this.collection});

  final HadithCollection collection;

  static Future<void> open(BuildContext context, HadithCollection collection) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HadithCollectionPage(collection: collection),
      ),
    );
  }

  @override
  State<HadithCollectionPage> createState() => _HadithCollectionPageState();
}

class _HadithCollectionPageState extends State<HadithCollectionPage> {
  final _repo = HadithRepository();
  final _search = TextEditingController();
  final _scroll = ScrollController();

  List<Hadith> _items = [];
  Set<String> _favorites = {};
  int _page = 1;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _favorites = await _repo.loadFavorites();
    await _load(reset: true);
  }

  void _onScroll() {
    if (_loadingMore || _page >= _totalPages) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final result = await _repo.getCollectionPage(
        collection: widget.collection.key,
        page: 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _items = result.hadiths;
        _page = result.page;
        _totalPages = result.totalPages;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = await _repo.getCollectionPage(
        collection: widget.collection.key,
        page: next,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.hadiths];
        _page = result.page;
        _totalPages = result.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleFav(String id) async {
    final next = await _repo.toggleFavorite(id);
    if (mounted) setState(() => _favorites = next);
  }

  List<Hadith> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((h) {
      return h.english.toLowerCase().contains(q) ||
          h.arabic.contains(_query.trim()) ||
          '${h.number}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Hadiths',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un hadith ou un mot-clé…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVRE · ${c.key.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.name,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.author.isEmpty
                          ? c.countLabel
                          : '${c.author} · ${c.countLabel}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _visible.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _visible.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final h = _visible[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HadithListCard(
                            hadith: h,
                            favorited: _favorites.contains(h.id),
                            onOpen: () async {
                              await HadithDetailPage.open(context, h);
                              final favs = await _repo.loadFavorites();
                              if (mounted) setState(() => _favorites = favs);
                            },
                            onToggleFav: () => _toggleFav(h.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithListCard extends StatelessWidget {
  const _HadithListCard({
    required this.hadith,
    required this.favorited,
    required this.onOpen,
    required this.onToggleFav,
  });

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
                    radius: 16,
                    backgroundColor: const Color(0xFFD4EDE4),
                    child: Text(
                      '${hadith.number}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'HADITH N° ${hadith.number}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 12,
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
                hadith.arabicShort,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Lire la suite'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
