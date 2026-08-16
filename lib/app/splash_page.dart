import 'package:flutter/material.dart';

/// Écran de chargement — design Stitch « Emerald Nocturne ».
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF064E3B);
  static const _primary = Color(0xFF95D3BA);
  static const _onPrimaryContainer = Color(0xFF80BEA6);

  late final AnimationController _pulse;
  bool _showLogo = false;
  bool _showText = false;
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showLogo = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showText = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showLoader = true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _bg),
          CustomPaint(painter: _IslamicPatternPainter()),
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _showLogo ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: _showLogo ? 1 : 0.8,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _showText ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: _showText ? Offset.zero : const Offset(0, 0.15),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: Column(
                      children: [
                        Text(
                          'Noor Al-Iman',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            letterSpacing: 0.6,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ILLUMINATING FAITH',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _onPrimaryContainer.withValues(alpha: 0.85),
                            letterSpacing: 3.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedOpacity(
                  opacity: _showLoader ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              final t = (_pulse.value - i * 0.15) % 1.0;
                              final scale = (t < 0.4)
                                  ? (t / 0.4)
                                  : (1 - (t - 0.4) / 0.6).clamp(0.0, 1.0);
                              final s = 0.35 + scale * 0.65;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Transform.scale(
                                  scale: s,
                                  child: Opacity(
                                    opacity: 0.35 + scale * 0.65,
                                    child: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(width: 8, height: 8),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preparing your experience'.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primary.withValues(alpha: 0.55),
                          letterSpacing: 2.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF95D3BA).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final fill = Paint()
      ..color = const Color(0xFF95D3BA).withValues(alpha: 0.06);

    const step = 48.0;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        final cx = x;
        final cy = y;
        final path = Path()
          ..moveTo(cx, cy - 10)
          ..lineTo(cx + 4, cy - 4)
          ..lineTo(cx + 10, cy)
          ..lineTo(cx + 4, cy + 4)
          ..lineTo(cx, cy + 10)
          ..lineTo(cx - 4, cy + 4)
          ..lineTo(cx - 10, cy)
          ..lineTo(cx - 4, cy - 4)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(cx, cy), 2.2, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
