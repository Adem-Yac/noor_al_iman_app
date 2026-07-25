import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/home_data.dart';
import '../cubit/home_cubit.dart';

class VerseDetailPage extends StatefulWidget {
  const VerseDetailPage({super.key, required this.verse});

  final DailyVerse verse;

  @override
  State<VerseDetailPage> createState() => _VerseDetailPageState();
}

class _VerseDetailPageState extends State<VerseDetailPage> {
  late DailyVerse _verse = widget.verse;
  bool _loadingNext = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_verse.reference),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _verse.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  height: 1.9,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '« ${_verse.french} »',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const Spacer(),
              BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  final playing =
                      state is HomeLoaded &&
                      state.isPlaying &&
                      state.playingUrl == _verse.audioUrl;
                  return OutlinedButton.icon(
                    onPressed: _verse.audioUrl == null
                        ? null
                        : () => context.read<HomeCubit>().playVerse(
                            _verse.audioUrl,
                          ),
                    icon: Icon(
                      playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                    ),
                    label: Text(playing ? 'Arrêter' : 'Écouter'),
                  );
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loadingNext ? null : _loadNext,
                icon: _loadingNext
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(_loadingNext ? 'Chargement…' : 'Ayah suivant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadNext() async {
    setState(() {
      _loadingNext = true;
      _error = null;
    });
    try {
      final next = await context.read<HomeCubit>().loadNextAyah(_verse);
      if (!mounted) return;
      setState(() => _verse = next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Fin de sourate ou erreur API.');
    } finally {
      if (mounted) setState(() => _loadingNext = false);
    }
  }
}
