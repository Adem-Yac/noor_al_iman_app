import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/dua_models.dart';

class DuaDetailPage extends StatefulWidget {
  const DuaDetailPage({
    super.key,
    required this.duas,
    required this.initialIndex,
  });

  final List<Dua> duas;
  final int initialIndex;

  static Future<void> open(
    BuildContext context,
    Dua dua, {
    List<Dua>? list,
  }) {
    final duas = (list == null || list.isEmpty) ? [dua] : list;
    var index = duas.indexWhere((d) => d.id == dua.id);
    if (index < 0) index = 0;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuaDetailPage(duas: duas, initialIndex: index),
      ),
    );
  }

  @override
  State<DuaDetailPage> createState() => _DuaDetailPageState();
}

class _DuaDetailPageState extends State<DuaDetailPage> {
  late int _index;
  int _count = 0;

  Dua get dua => widget.duas[_index];
  bool get _hasNext => _index < widget.duas.length - 1;
  bool get _hasPrev => _index > 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.duas.length - 1);
  }

  void _tap() {
    final target = dua.repeat < 1 ? 1 : dua.repeat;
    setState(() => _count++);
    HapticFeedback.selectionClick();

    // Une seule fois, à la fin des répétitions demandées.
    if (_count == target && _hasNext) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _goNext();
      });
    }
  }

  void _reset() => setState(() => _count = 0);

  void _goNext() {
    if (!_hasNext) return;
    setState(() {
      _index++;
      _count = 0;
    });
  }

  void _goPrev() {
    if (!_hasPrev) return;
    setState(() {
      _index--;
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = dua;
    final target = d.repeat < 1 ? 1 : d.repeat;
    final done = _count >= target;

    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldOf(context),
        elevation: 0,
        foregroundColor: AppColors.textOf(context),
          title: Text(
          S.duas,
          style: TextStyle(
            color: AppColors.primaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (widget.duas.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  '${_index + 1} / ${widget.duas.length}',
                  style: TextStyle(
                    color: AppColors.mutedOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.chipOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d.category.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: AppColors.primaryOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ContentLang.duaTitle(d),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryOf(context),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.reciteHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedOf(context), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  d.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'ScheherazadeNew',
                    fontSize: 28,
                    height: 1.85,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOf(context),
                  ),
                ),
                if (ContentLang.showTransliteration &&
                    d.transliteration.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.subtleOf(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      d.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedOf(context),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                if (ContentLang.duaTranslation(d) case final tr?) ...[
                  const SizedBox(height: 14),
                  Text(
                    tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  if (ContentLang.duaTranslationSourceNote(d) case final note?) ...[
                    const SizedBox(height: 6),
                    Text(
                      note,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.softOf(context),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: AppColors.subtleOf(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${S.goal} : $target',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textOf(context),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(S.reset),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryOf(context),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _tap,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.cardOf(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? AppColors.primaryOf(context)
                            : AppColors.borderOf(context),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_count',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                        Text(
                          done ? S.done : S.tap,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: done
                                ? AppColors.primaryOf(context)
                                : AppColors.softOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  done && _hasNext
                      ? S.goingNextDua
                      : done
                          ? S.lastDua
                          : S.nextDuaHint,
                  style: TextStyle(
                    color: AppColors.mutedOf(context),
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                if (widget.duas.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _hasPrev ? _goPrev : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(S.previous),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryOf(context),
                            side: BorderSide(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _hasNext ? () => _goNext() : null,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(S.next),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (d.source.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppColors.primaryOf(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        S.source,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontSize: 12,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.source,
                    style: TextStyle(
                      color: AppColors.mutedOf(context),
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
