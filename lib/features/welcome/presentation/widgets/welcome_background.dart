import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Fond maquette : grille de points + arcs circulaires.
class WelcomeBackground extends StatelessWidget {
  const WelcomeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        CustomPaint(painter: _WelcomeDecorPainter()),
        child,
      ],
    );
  }
}

class _WelcomeDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = AppColors.deco.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    final arcPaint = Paint()
      ..color = AppColors.deco.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void arc(Offset c, double r) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        0,
        math.pi * 2,
        false,
        arcPaint,
      );
    }

    arc(Offset(size.width * 0.15, size.height * 0.22), size.width * 0.55);
    arc(Offset(size.width * 0.85, size.height * 0.18), size.width * 0.48);
    arc(Offset(size.width * 0.5, size.height * 0.95), size.width * 0.7);
    arc(Offset(size.width * -0.05, size.height * 0.7), size.width * 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
