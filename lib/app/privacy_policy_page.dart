import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'theme/app_colors.dart';

/// Politique de confidentialité (affichage in-app).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (S.privacyIntroTitle, S.privacyIntroBody),
      (S.privacyDataTitle, S.privacyDataBody),
      (S.privacyLocationTitle, S.privacyLocationBody),
      (S.privacyNotifTitle, S.privacyNotifBody),
      (S.privacyRightsTitle, S.privacyRightsBody),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(S.privacyPolicy),
        backgroundColor: AppColors.scaffoldOf(context),
        foregroundColor: AppColors.textOf(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final (title, body) in sections) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.mutedOf(context),
              ),
            ),
            const SizedBox(height: 22),
          ],
          Text(
            S.privacyUpdated,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.softOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
