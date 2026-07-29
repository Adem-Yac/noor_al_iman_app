import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/quran_models.dart';
import '../../data/repositories/tafsir_repository.dart';
import '../../data/surahs.dart';

class QuranTafsirTab extends StatefulWidget {
  const QuranTafsirTab({super.key});

  @override
  State<QuranTafsirTab> createState() => _QuranTafsirTabState();
}

class _QuranTafsirTabState extends State<QuranTafsirTab> {
  final _repo = TafsirRepository();

  Surah _surah = kSurahs.first;
  TafsirLanguage _language = TafsirLanguage.french;
  SurahContent? _content;
  final _tafsirCache = <String, TafsirEntry>{};
  bool _loadingSurah = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    setState(() {
      _loadingSurah = true;
      _error = null;
      _content = null;
      _tafsirCache.clear();
    });
    try {
      final content = await _repo.loadSurah(_surah.number);
      if (!mounted) return;
      setState(() {
        _content = content;
        _loadingSurah = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSurah = false;
      });
    }
  }

  Future<TafsirEntry?> _loadTafsir(int ayah) async {
    final key = '${_surah.number}:$ayah:${_language.name}';
    if (_tafsirCache.containsKey(key)) {
      return _tafsirCache[key];
    }
    try {
      final entry = await _repo.loadTafsir(
        surah: _surah.number,
        ayah: ayah,
        language: _language,
      );
      _tafsirCache[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickSurah() async {
    final picked = await showModalBottomSheet<Surah>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scroll) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choisir une sourate',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: kSurahs.length,
                    itemBuilder: (context, i) {
                      final s = kSurahs[i];
                      final selected = s.number == _surah.number;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? AppColors.primary
                              : const Color(0xFFE8F1F2),
                          foregroundColor: selected
                              ? Colors.white
                              : AppColors.primary,
                          child: Text('${s.number}'),
                        ),
                        title: Text(s.latin),
                        subtitle: Text(s.french),
                        trailing: Text(
                          s.arabic,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        onTap: () => Navigator.pop(context, s),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && picked.number != _surah.number) {
      setState(() => _surah = picked);
      await _loadSurah();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _pickSurah,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _surah.latin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _surah.french,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _surah.arabic,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.expand_more,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LangChip(
                      label: 'Français',
                      selected: _language == TafsirLanguage.french,
                      onTap: () {
                        if (_language == TafsirLanguage.french) return;
                        setState(() {
                          _language = TafsirLanguage.french;
                          _tafsirCache.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LangChip(
                      label: 'English',
                      selected: _language == TafsirLanguage.english,
                      onTap: () {
                        if (_language == TafsirLanguage.english) return;
                        setState(() {
                          _language = TafsirLanguage.english;
                          _tafsirCache.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingSurah
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _content!.ayahs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ayah = _content!.ayahs[i];
                    return _TafsirAyahCard(
                      ayah: ayah,
                      translation: _repo.verseTranslation(ayah, _language),
                      language: _language,
                      loadTafsir: () => _loadTafsir(ayah.ayah),
                    );
                  },
                ),
        ),
      ],
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
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
                  'Tafsir${_tafsir != null ? ' · ${_tafsir!.sourceName}' : ''}',
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
                style: const TextStyle(height: 1.6),
              ),
          ],
        ),
      ),
    );
  }
}
