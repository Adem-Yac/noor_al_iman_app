import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/dua_models.dart';
import '../../data/repositories/duas_repository.dart';

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
      final list = await _repo.getByCategory(widget.category.id);
      if (!mounted) return;
      setState(() {
        _duas = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.category.frenchLabel,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
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
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _duas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _DuaCard(dua: _duas[i]),
              ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final Dua dua;

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
            Text(
              dua.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dua.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 24,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (dua.transliteration.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                dua.transliteration,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              dua.translation,
              style: const TextStyle(height: 1.5),
            ),
            if (dua.source.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                dua.source,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            if (dua.repeat > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Répéter ${dua.repeat} fois',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
