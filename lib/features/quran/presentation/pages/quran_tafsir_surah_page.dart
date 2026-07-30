import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/quran_models.dart';
import '../../data/repositories/tafsir_repository.dart';
import '../../data/surahs.dart';

class QuranTafsirSurahPage extends StatefulWidget {
  const QuranTafsirSurahPage({super.key, required this.surah});

  final Surah surah;

  static Future<void> open(BuildContext context, Surah surah) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranTafsirSurahPage(surah: surah),
      ),
    );
  }

  @override
  State<QuranTafsirSurahPage> createState() => _QuranTafsirSurahPageState();
}

class _QuranTafsirSurahPageState extends State<QuranTafsirSurahPage> {
  final _repo = TafsirRepository();

  TafsirLanguage _language = TafsirLanguage.french;
  SurahContent? _content;
  final _tafsirCache = <String, TafsirEntry>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    setState(() {
      _loading = true;
      _error = null;
      _content = null;
      _tafsirCache.clear();
    });
    try {
      final content = await _repo.loadSurah(widget.surah.number);
      if (!mounted) return;
      setState(() {
        _content = content;
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

  Future<TafsirEntry?> _loadTafsir(int ayah) async {
    final key =
        '${widget.surah.number}:$ayah:${_language.name}';
    if (_tafsirCache.containsKey(key)) {
      return _tafsirCache[key];
    }
    try {
      final entry = await _repo.loadTafsir(
        surah: widget.surah.number,
        ayah: ayah,
        language: _language,
      );
      _tafsirCache[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  void _setLanguage(TafsirLanguage language) {
    if (_language == language) return;
    setState(() {
      _language = language;
      _tafsirCache.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.surah.latin,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            Text(
              widget.surah.french,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              widget.surah.arabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: _loading
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
                      onPressed: _loadSurah,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _LangChip(
                            label: 'Français',
                            selected: _language == TafsirLanguage.french,
                            onTap: () => _setLanguage(TafsirLanguage.french),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LangChip(
                            label: 'English',
                            selected: _language == TafsirLanguage.english,
                            onTap: () => _setLanguage(TafsirLanguage.english),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LangChip(
                            label: 'عربي',
                            selected: _language == TafsirLanguage.arabic,
                            onTap: () => _setLanguage(TafsirLanguage.arabic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: _content!.ayahs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final ayah = _content!.ayahs[i];
                      return _TafsirAyahCard(
                        key: ValueKey('${_language.name}-${ayah.ayah}'),
                        ayah: ayah,
                        translation: _repo.verseTranslation(ayah, _language),
                        language: _language,
                        loadTafsir: () => _loadTafsir(ayah.ayah),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.tabInactive,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TafsirAyahCard extends StatefulWidget {
  const _TafsirAyahCard({
    super.key,
    required this.ayah,
    required this.translation,
    required this.language,
    required this.loadTafsir,
  });

  final QuranAyah ayah;
  final String translation;
  final TafsirLanguage language;
  final Future<TafsirEntry?> Function() loadTafsir;

  @override
  State<_TafsirAyahCard> createState() => _TafsirAyahCardState();
}

class _TafsirAyahCardState extends State<_TafsirAyahCard> {
  TafsirEntry? _tafsir;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TafsirAyahCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language ||
        oldWidget.ayah.ayah != widget.ayah.ayah) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _tafsir = null;
    });
    final entry = await widget.loadTafsir();
    if (!mounted) return;
    setState(() {
      _tafsir = entry;
      _loading = false;
      if (entry == null || entry.text.isEmpty) {
        _error = 'Tafsir indisponible pour ce verset.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.ayah.ayah}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.ayah.reference,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.ayah.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 22,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.translation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.translation,
                textDirection: widget.language == TafsirLanguage.arabic
                    ? TextDirection.ltr
                    : TextDirection.ltr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontStyle: widget.language == TafsirLanguage.arabic
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.language == TafsirLanguage.arabic
                      ? 'تفسير${_tafsir != null ? ' · ${_tafsir!.sourceName}' : ''}'
                      : 'Tafsir${_tafsir != null ? ' · ${_tafsir!.sourceName}' : ''}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppColors.textMuted),
              )
            else
              Text(
                _tafsir!.text,
                textDirection: widget.language == TafsirLanguage.arabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                textAlign: widget.language == TafsirLanguage.arabic
                    ? TextAlign.right
                    : TextAlign.start,
                style: TextStyle(
                  height: 1.6,
                  fontFamily: widget.language == TafsirLanguage.arabic
                      ? 'ScheherazadeNew'
                      : null,
                  fontSize: widget.language == TafsirLanguage.arabic ? 18 : 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
