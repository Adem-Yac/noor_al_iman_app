import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/surahs.dart';
import '../../data/repositories/quran_repository.dart';
import '../cubit/quran_reader_cubit.dart';


class _ReaderMetrics {
  _ReaderMetrics(BoxConstraints constraints)
      : width = constraints.maxWidth,
        height = constraints.maxHeight,
        isTablet = constraints.maxWidth >= 500,
        isLarge = constraints.maxWidth >= 900;

  final double width;
  final double height;
  final bool isTablet;
  final bool isLarge;

  double get hPadding {
    if (isLarge) return width * 0.1;
    if (isTablet) return width * 0.07;
    return width * 0.04;
  }

  double get defaultFontSize {
    if (isLarge) return 28;
    if (isTablet) return 25;
    return 22;
  }

  double get minFontSize => isTablet ? 20 : 18;
  double get maxFontSize {
    if (isLarge) return 38;
    if (isTablet) return 34;
    return 30;
  }

  double get titleSize => isTablet ? 26 : 22;
  double get subtitleSize => isTablet ? 12 : 11;
  double get bannerHeight => isTablet ? 64 : 52;
  double get bannerFontSize => isTablet ? 24 : 20;
  double get headerIcon => isTablet ? 40 : 36;
  double get audioAvatarSize => isTablet ? 34 : 30;
  double get playButtonSize => isTablet ? 42 : 36;
  double get audioIconSize => isTablet ? 22 : 18;
  double get audioTitleSize => isTablet ? 14 : 12;
  double get audioSubtitleSize => isTablet ? 12 : 10;
  double get vPadding => isTablet ? 16 : 10;
}

TextStyle _quranStyle({
  double fontSize = 22,
  double height = 2.05,
  Color? backgroundColor,
}) {
  return TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: fontSize,
    color: const Color(0xFF000000),
    height: height,
    backgroundColor: backgroundColor,
  );
}

class QuranReaderPage extends StatelessWidget {
  const QuranReaderPage({super.key, required this.target});

  final ReaderTarget target;

  static Future<void> open(BuildContext context, ReaderTarget target) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderPage(target: target),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranReaderCubit(QuranRepository())..load(target),
      child: const _MushafView(),
    );
  }
}

class _MushafView extends StatefulWidget {
  const _MushafView();

  @override
  State<_MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<_MushafView> {
  double? _fontSize;
  _ReaderMetrics? _metrics;

  void _initMetrics(_ReaderMetrics metrics) {
    if (_metrics?.width == metrics.width) return;
    _metrics = metrics;
    _fontSize ??= metrics.defaultFontSize;
  }

  void _changeFontSize(double change) {
    final m = _metrics;
    if (m == null) return;
    setState(
      () => _fontSize = (_fontSize! + change).clamp(m.minFontSize, m.maxFontSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _ReaderMetrics(constraints);
          _initMetrics(metrics);
          final fontSize = _fontSize ?? metrics.defaultFontSize;

          return SafeArea(
            child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
              builder: (context, state) {
                return switch (state) {
                  QuranReaderLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  QuranReaderError(:final message) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(metrics.hPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(message, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Retour'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  QuranReaderReady() => Column(
                    children: [
                      _SurahHeader(
                        state: state,
                        metrics: metrics,
                        fontSize: fontSize,
                        onDecreaseFont: () => _changeFontSize(-2),
                        onIncreaseFont: () => _changeFontSize(2),
                      ),
                      Expanded(
                        child: _MushafCard(
                          state: state,
                          metrics: metrics,
                          fontSize: fontSize,
                        ),
                      ),
                      _AudioPlayerBar(state: state, metrics: metrics),
                    ],
                  ),
                };
              },
            ),
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.state,
    required this.metrics,
    required this.fontSize,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
  });

  final QuranReaderReady state;
  final _ReaderMetrics metrics;
  final double fontSize;
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;

  @override
  Widget build(BuildContext context) {
    final name = state.mode == ReaderMode.juz
        ? state.current.surahName
        : state.title;

    return Padding(
      padding: EdgeInsets.fromLTRB(metrics.hPadding, 4, metrics.hPadding * 0.75, 8),
      child: Row(
        children: [
          Container(
            width: metrics.headerIcon,
            height: metrics.headerIcon,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(metrics.isTablet ? 14 : 12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: metrics.isTablet ? 26 : 22,
            ),
          ),
          SizedBox(width: metrics.isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOURATE ${state.current.surahNumber}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: metrics.subtitleSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: metrics.titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Favori',
            onPressed: () =>
                context.read<QuranReaderCubit>().toggleAyahFavorite(),
            icon: Icon(
              state.isCurrentFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: state.isCurrentFavorite
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: metrics.isTablet ? 28 : 24,
            ),
          ),
          _FontButton(
            label: '−',
            size: metrics.isTablet ? 42 : 36,
            onPressed: fontSize <= metrics.minFontSize ? null : onDecreaseFont,
          ),
          const SizedBox(width: 4),
          _FontButton(
            label: '+',
            size: metrics.isTablet ? 42 : 36,
            onPressed: fontSize >= metrics.maxFontSize ? null : onIncreaseFont,
          ),
        ],
      ),
    );
  }
}

class _FontButton extends StatelessWidget {
  const _FontButton({
    required this.label,
    required this.onPressed,
    this.size = 36,
  });

  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label == '+' ? 'Agrandir le texte' : 'Réduire le texte',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size - 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD8D8D2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: onPressed == null
                  ? AppColors.textMuted
                  : AppColors.primary,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MushafCard extends StatefulWidget {
  const _MushafCard({
    required this.state,
    required this.metrics,
    required this.fontSize,
  });

  final QuranReaderReady state;
  final _ReaderMetrics metrics;
  final double fontSize;

  @override
  State<_MushafCard> createState() => _MushafCardState();
}

class _MushafCardState extends State<_MushafCard> {
  List<TapGestureRecognizer> _taps = [];
  Object? _ayahsIdentity;

  void _ensureTaps(QuranReaderReady state) {
    if (identical(_ayahsIdentity, state.ayahs) &&
        _taps.length == state.ayahs.length) {
      return;
    }
    for (final t in _taps) {
      t.dispose();
    }
    _ayahsIdentity = state.ayahs;
    _taps = List.generate(state.ayahs.length, (i) {
      return TapGestureRecognizer()
        ..onTap = () async {
          if (!mounted) return;
          final cubit = context.read<QuranReaderCubit>();
          await cubit.selectAyah(i);
          await cubit.playCurrent(continuePlaylist: true);
        };
    });
  }

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final fontSize = widget.fontSize;
    _ensureTaps(state);

    final surahName = state.mode == ReaderMode.surah
        ? _surahArabicName(state.surahNumber)
        : state.subtitle;

    final spans = <InlineSpan>[];
    for (var i = 0; i < state.ayahs.length; i++) {
      final ayah = state.ayahs[i];
      final highlighted = state.playerVisible && i == state.currentIndex;

      spans.add(
        TextSpan(
          text: ayah.arabic,
          recognizer: _taps[i],
          style: _quranStyle(
            fontSize: fontSize,
            backgroundColor:
                highlighted ? const Color(0xFFD4EDE4) : null,
          ),
        ),
      );
      spans.add(const TextSpan(text: '\u00A0'));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AyahMarker(number: ayah.ayah, size: fontSize * 0.62),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            widget.metrics.hPadding,
            widget.metrics.vPadding,
            widget.metrics.hPadding,
            widget.metrics.vPadding + 8,
          ),
          children: [
            _SurahBanner(
              name: surahName,
              metrics: widget.metrics,
            ),
            SizedBox(height: widget.metrics.isTablet ? 20 : 14),
            Text.rich(
              TextSpan(children: spans),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}

String _surahArabicName(int number) {
  final match = kSurahs.where((s) => s.number == number);
  if (match.isEmpty) return '';
  return 'سُورَةُ ${match.first.arabic}';
}

class _SurahBanner extends StatelessWidget {
  const _SurahBanner({required this.name, required this.metrics});

  final String name;
  final _ReaderMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.bannerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(metrics.isTablet ? 10 : 8),
        border: Border.all(color: const Color(0xFFC9A227), width: 1.6),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(metrics.isTablet ? 7 : 5),
          border: Border.all(color: const Color(0xFFC9A227)),
        ),
        child: Text(
          name,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontSize: metrics.bannerFontSize,
            height: 1.3,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AyahMarker extends StatelessWidget {
  const _AyahMarker({required this.number, this.size = 20});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dim = size.clamp(13.0, 22.0);
    return Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF8F4EE),
        border: Border.all(color: const Color(0xFFC9A227), width: 1.1),
      ),
      child: Text(
        _toArabicDigits(number),
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: dim * 0.45,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF000000),
          height: 1,
        ),
      ),
    );
  }
}

class _AudioPlayerBar extends StatelessWidget {
  const _AudioPlayerBar({required this.state, required this.metrics});

  final QuranReaderReady state;
  final _ReaderMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    final playing =
        state.isPlaying && state.playingKey == state.current.key;
    final progress = state.ayahs.isEmpty
        ? 0.0
        : (state.currentIndex + 1) / state.ayahs.length;
    final playSize = metrics.playButtonSize;

    return Material(
      elevation: 10,
      color: Colors.white,
      shadowColor: Colors.black26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: metrics.isTablet ? 3 : 2,
            backgroundColor: const Color(0xFFE8E8E4),
            color: AppColors.primary,
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.hPadding * 0.6,
                metrics.isTablet ? 8 : 6,
                metrics.hPadding * 0.6,
                metrics.isTablet ? 8 : 6,
              ),
              child: Row(
                children: [
                  Container(
                    width: metrics.audioAvatarSize,
                    height: metrics.audioAvatarSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        metrics.isTablet ? 10 : 8,
                      ),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                      size: metrics.audioIconSize,
                    ),
                  ),
                  SizedBox(width: metrics.isTablet ? 10 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mishary Rashid',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: metrics.audioTitleSize,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Verset ${state.current.ayah}',
                          style: TextStyle(
                            fontSize: metrics.audioSubtitleSize,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: cubit.playPrevious,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: metrics.audioIconSize,
                    ),
                    color: AppColors.textSecondary,
                  ),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: cubit.togglePlayPause,
                      child: SizedBox(
                        width: playSize,
                        height: playSize,
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: playSize * 0.5,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: cubit.playNext,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: metrics.audioIconSize,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _toArabicDigits(int value) {
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.toString().split('').map((c) => eastern[int.parse(c)]).join();
}
