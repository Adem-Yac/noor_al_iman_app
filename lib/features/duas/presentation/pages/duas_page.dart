import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../../../app/l10n/lang_builder.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/app_tab_header.dart';
import '../../data/models/dua_main_categories.dart';
import '../../data/models/dua_models.dart';
import '../../data/repositories/duas_repository.dart';
import 'dua_detail_page.dart';
import 'duas_category_page.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

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

  List<DuaCategory> get _mainCategories => DuaMainCategories.resolve(
        _categories,
        totalDuas: _duas.length,
        duas: _duas,
      );

  List<Dua> get _featured {
    const preferred = [
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
    return LangBuilder(
      builder: (context, _) {
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
                              label: Text(S.retry),
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
                              AppTabHeader(title: S.duas),
                              const SizedBox(height: 14),
                              if (_dailyDua != null)
                                _DailyDuaCard(
                                  dua: _dailyDua!,
                                  onTap: () => DuaDetailPage.open(
                                    context,
                                    _dailyDua!,
                                    list: _duas,
                                  ),
                                  onShare: () async {
                                    final dua = _dailyDua!;
                                    final tr = ContentLang.duaTranslation(dua);
                                    final title = ContentLang.duaTitle(dua);
                                    final text = tr != null
                                        ? '$title\n${dua.arabic}\n« $tr »'
                                        : '$title\n${dua.arabic}';
                                    await Clipboard.setData(
                                      ClipboardData(text: text),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(S.duaCopied)),
                                    );
                                  },
                                ),
                              const SizedBox(height: 20),
                              Text(
                                S.categories,
                                style: TextStyle(
                                  color: AppColors.primaryOf(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  final cols = w >= 700 ? 3 : 2;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _mainCategories.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      // Plus haut que le contenu (icône + 2 lignes).
                                      mainAxisExtent: 128,
                                    ),
                                    itemBuilder: (context, i) {
                                      final cat = _mainCategories[i];
                                      return _CategoryCard(
                                        category: cat,
                                        onTap: () => DuasCategoryPage.open(
                                          context,
                                          cat,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              if (_featured.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text(
                                  S.duasFeatured,
                                  style: TextStyle(
                                    color: AppColors.primaryOf(context),
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
                                      onTap: () => DuaDetailPage.open(
                                        context,
                                        _featured[i],
                                        list: _featured,
                                      ),
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
      },
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
                        S.duaOfDay.toUpperCase(),
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
                          ContentLang.duaTitle(dua),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final DuaCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.subtleOf(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.id),
                  color: AppColors.primaryOf(context),
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ContentLang.categoryLabel(category),
                textAlign: TextAlign.center,
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
              if (category.count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${category.count} ${S.duas.toLowerCase()}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedOf(context),
                    fontSize: 10,
                    height: 1.2,
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
      color: AppColors.cardOf(context),
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
                      ContentLang.duaTitle(dua),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOf(context),
                      ),
                    ),
                  ),
                  Icon(
                    categoryIcon(dua.category),
                    size: 18,
                    color: AppColors.softOf(context),
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
                style: TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 18,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOf(context),
                ),
              ),
              if (ContentLang.duaTranslation(dua) case final tr?) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
