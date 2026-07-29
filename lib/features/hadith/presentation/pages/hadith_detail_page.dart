import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/hadith_models.dart';
import '../../data/repositories/hadith_repository.dart';

class HadithDetailPage extends StatefulWidget {
  const HadithDetailPage({super.key, required this.hadith});

  final Hadith hadith;

  static Future<void> open(BuildContext context, Hadith hadith) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HadithDetailPage(hadith: hadith),
      ),
    );
  }

  @override
  State<HadithDetailPage> createState() => _HadithDetailPageState();
}

class _HadithDetailPageState extends State<HadithDetailPage> {
  final _repo = HadithRepository();
  bool _favorited = false;

  @override
  void initState() {
    super.initState();
    _repo.loadFavorites().then((favs) {
      if (mounted) {
        setState(() => _favorited = favs.contains(widget.hadith.id));
      }
    });
  }

  Future<void> _toggleFav() async {
    final next = await _repo.toggleFavorite(widget.hadith.id);
    if (mounted) {
      setState(() => _favorited = next.contains(widget.hadith.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hadith;
    final chip = h.grade == null || h.grade!.isEmpty
        ? '${h.collectionName} · n° ${h.number}'
        : '${h.grade} · n° ${h.number}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Détail Hadith',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6D0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          chip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B6914),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Favoris',
                      visualDensity: VisualDensity.compact,
                      onPressed: _toggleFav,
                      icon: Icon(
                        _favorited
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (h.arabic.isNotEmpty)
                  Text(
                    h.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      color: AppColors.primary,
                      fontSize: 24,
                      height: 1.85,
                    ),
                  ),
                if (h.english.isNotEmpty) ...[
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
                            '« ${h.english} »',
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
                ],
                if (h.narrator != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Rapporté par : ${h.narrator}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Material(
                  color: _favorited
                      ? AppColors.primary
                      : const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _toggleFav,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _favorited
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: _favorited
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _favorited ? 'Dans les favoris' : 'Ajouter aux favoris',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _favorited
                                  ? Colors.white
                                  : AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
