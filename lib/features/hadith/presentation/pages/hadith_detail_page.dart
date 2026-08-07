import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/l10n/app_lang.dart';
import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
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
    final next = await _repo.toggleFavorite(widget.hadith);
    if (mounted) {
      setState(() => _favorited = next.contains(widget.hadith.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hadith;
    final numberPart = switch (AppLang.current) {
      AppLanguage.ar => 'رقم ${h.number}',
      AppLanguage.en => 'No. ${h.number}',
      AppLanguage.fr => 'n° ${h.number}',
    };
    final chip = h.grade == null || h.grade!.isEmpty
        ? ContentLang.hadithRefLabel(h)
        : '${h.grade} · $numberPart';

    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldOf(context),
        elevation: 0,
        foregroundColor: AppColors.textOf(context),
        title: Text(
          S.hadithDetail,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryOf(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
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
                          color: AppColors.chipOf(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          chip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: S.favorites,
                      visualDensity: VisualDensity.compact,
                      onPressed: _toggleFav,
                      icon: Icon(
                        _favorited
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                        color: AppColors.primaryOf(context),
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
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      color: AppColors.textOf(context),
                      fontSize: 24,
                      height: 1.85,
                    ),
                  ),
                if (ContentLang.hadithTranslation(h) case final tr?) ...[
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOf(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '« $tr »',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.mutedOf(context),
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
                    '${S.narratedBy} ${h.narrator}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softOf(context),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Material(
                  color: _favorited
                      ? AppColors.primaryOf(context)
                      : AppColors.subtleOf(context),
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
                                ? AppColors.onPrimaryOf(context)
                                : AppColors.primaryOf(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _favorited ? S.favorites : S.addFavorite,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _favorited
                                  ? AppColors.onPrimaryOf(context)
                                  : AppColors.primaryOf(context),
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
