import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/app_tab_header.dart';
import '../../data/models/dua_main_categories.dart';
import '../../data/models/dua_models.dart';
import '../../data/repositories/duas_repository.dart';
import 'dua_detail_page.dart';
import 'duas_category_page.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DuasPage()),
    );
  }

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final _repo = DuasRepository();

  List<DuaCategory> _categories = const [];
  List<Dua> _duas = const [];
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
    try {
      final hub = await _repo.getHub();
      if (!mounted) return;
      setState(() {
        _categories = hub.categories;
        _duas = hub.duas;
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

  Dua? get _dailyDua {
    if (_duas.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _duas[dayOfYear % _duas.length];
  }

  List<DuaCategory> get _mainCategories =>
      DuaMainCategories.resolve(_categories, totalDuas: _duas.length);

  List<Dua> get _featured {
    const preferred = [
      'sleep',
      'gratitude',
      'distress',
      'protection',
      'forgiveness',
      'food',
    ];
    final out = <Dua>[];
    final dailyId = _dailyDua?.id;
    for (final cat in preferred) {
      final match = _duas.where(
        (d) => d.category == cat && d.id != dailyId,
      );
      if (match.isNotEmpty) out.add(match.first);
      if (out.length >= 3) break;
    }
    if (out.length < 3) {
      for (final d in _duas) {
        if (out.length >= 3) break;
        if (d.id == dailyId) continue;
        if (!out.any((x) => x.id == d.id)) out.add(d);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      sliver: SliverList.list(
                        children: [
                          const AppTabHeader(title: 'Douas'),
                          const SizedBox(height: 14),
                          if (_dailyDua != null)
                            _DailyDuaCard(
                              dua: _dailyDua!,
                              onTap: () =>
                                  DuaDetailPage.open(context, _dailyDua!),
                              onShare: () async {
                                final dua = _dailyDua!;
                                final text =
                                    '${dua.title}\n${dua.arabic}\n« ${dua.translation} »';
                                await Clipboard.setData(
                                  ClipboardData(text: text),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Doua copiée')),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Catégories',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.35,
                            children: [
                              for (final cat in _mainCategories)
                                _CategoryCard(
                                  category: cat,
                                  onTap: () =>
                                      DuasCategoryPage.open(context, cat),
                                ),
                            ],
                          ),
                          if (_featured.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Text(
                              'Douas en vedette',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < _featured.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FeaturedDuaCard(
                                  index: i + 1,
                                  dua: _featured[i],
                                  onTap: () =>
                                      DuaDetailPage.open(context, _featured[i]),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

IconData categoryIcon(String id) => DuaMainCategories.icon(id);

class _DailyDuaCard extends StatelessWidget {
  const _DailyDuaCard({
    required this.dua,
    required this.onTap,
    required this.onShare,
  });

  final Dua dua;
  final VoidCallback onTap;
  final VoidCallback onShare;

  String get _arabicPreview {
    final t = dua.arabic.trim();
    if (t.length <= 120) return t;
    return '${t.substring(0, 120).trimRight()}…';
  }

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
                  Icons.volunteer_activism,
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
                        'DOUA DU JOUR',
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
                    _arabicPreview,
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
                          dua.title,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final DuaCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.id),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.frenchLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (category.count > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${category.count} douas',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedDuaCard extends StatelessWidget {
  const _FeaturedDuaCard({
    required this.index,
    required this.dua,
    required this.onTap,
  });

  final int index;
  final Dua dua;
  final VoidCallback onTap;

  String get _arabicPreview {
    final t = dua.arabic.trim();
    if (t.length <= 100) return t;
    return '${t.substring(0, 100).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                      dua.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    categoryIcon(dua.category),
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _arabicPreview,
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
              if (dua.translation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  dua.translation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
