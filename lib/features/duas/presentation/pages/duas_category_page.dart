import 'package:flutter/material.dart';

import '../../../../app/l10n/app_lang.dart';
import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/dua_main_categories.dart';
import '../../data/models/dua_models.dart';
import '../../data/repositories/duas_repository.dart';
import 'dua_detail_page.dart';
import 'duas_page.dart' show categoryIcon;

class DuasCategoryPage extends StatefulWidget {
  const DuasCategoryPage({super.key, required this.category});

  final DuaCategory category;

  static Future<void> open(BuildContext context, DuaCategory category) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuasCategoryPage(category: category),
      ),
    );
  }

  @override
  State<DuasCategoryPage> createState() => _DuasCategoryPageState();
}

class _DuasCategoryPageState extends State<DuasCategoryPage> {
  final _repo = DuasRepository();
  final _search = TextEditingController();

  List<Dua> _duas = const [];
  List<Dua> _filtered = const [];
  bool _loading = true;
  String? _error;

  bool get _isOther => DuaMainCategories.isOther(widget.category.id);

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
      final List<Dua> list;
      if (_isOther) {
        list = (await _repo.getHub()).duas;
      } else {
        list = await _repo.getByCategory(widget.category.id);
      }
      final limit = DuaMainCategories.displayLimit(widget.category.id);
      final capped = limit == null || list.length <= limit
          ? list
          : list.take(limit).toList();
      if (!mounted) return;
      setState(() {
        _duas = capped;
        _filtered = capped;
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

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _duas);
      return;
    }
    setState(() {
      _filtered = _duas.where((d) {
        final title = ContentLang.duaTitle(d).toLowerCase();
        return title.contains(q) ||
            d.title.toLowerCase().contains(q) ||
            d.arabic.contains(query.trim()) ||
            d.transliteration.toLowerCase().contains(q) ||
            d.translation.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldOf(context),
        elevation: 0,
        foregroundColor: AppColors.textOf(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ContentLang.categoryLabel(widget.category),
              style: TextStyle(
                color: AppColors.primaryOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            if (!AppLang.isArabic)
              Text(
                widget.category.arabicLabel,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: AppColors.mutedOf(context),
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
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
            : Column(
                children: [
                  if (_isOther)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _SearchField(
                        controller: _search,
                        onChanged: _onSearch,
                      ),
                    ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune doua trouvée',
                              style: TextStyle(color: AppColors.mutedOf(context)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final dua = _filtered[i];
                              return _DuaTile(dua: dua, list: _filtered);
                            },
                          ),
                  ),
                ],
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
      style: TextStyle(fontSize: 14, color: AppColors.textOf(context)),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.cardOf(context),
        hintText: S.searchDua,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primaryOf(context),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DuaTile extends StatelessWidget {
  const _DuaTile({required this.dua, required this.list});

  final Dua dua;
  final List<Dua> list;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => DuaDetailPage.open(
          context,
          dua,
          list: list,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.subtleOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon(dua.category),
                  color: AppColors.primaryOf(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ContentLang.duaTitle(dua),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    if (ContentLang.showTransliteration &&
                        dua.transliteration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dua.transliteration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mutedOf(context),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (ContentLang.duaTranslation(dua)
                        case final tr?) ...[
                      const SizedBox(height: 4),
                      Text(
                        tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mutedOf(context),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.subtleOf(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x${dua.repeat}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
