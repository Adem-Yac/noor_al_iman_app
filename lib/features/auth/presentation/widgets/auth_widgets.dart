import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBrandHeader = true,
  });

  final Widget child;
  final bool showBrandHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBrandHeader) ...[
                    const _BrandHeader(),
                    const SizedBox(height: 28),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 36,
              height: 36,
              color: AppColors.primary,
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Noor Al-Iman',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryOf(context),
          ),
        ),
      ],
    );
  }
}

class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textOf(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedOf(context),
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: TextStyle(color: AppColors.textOf(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.softOf(context)),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.softOf(context), size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.cardOf(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primaryOf(context),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimaryOf(context),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.cardOf(context),
        side: BorderSide(color: AppColors.borderOf(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Google',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOf(context),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scaffoldOf(context),
      child: CustomPaint(
        painter: _AuthDecorPainter(
          strokeColor: AppColors.borderOf(context).withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _AuthDecorPainter extends CustomPainter {
  _AuthDecorPainter({required this.strokeColor});

  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 90, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 130, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.75), 70, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthDecorPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor;
}
