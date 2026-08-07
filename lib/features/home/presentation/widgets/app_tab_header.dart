import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// En-tête d’onglet : logo + nom de la page.
class AppTabHeader extends StatelessWidget {
  const AppTabHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.primaryOf(context),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
