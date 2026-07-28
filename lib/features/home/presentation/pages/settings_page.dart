import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../app/theme/app_colors.dart';

String _avatarLetter(User user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    return name[0].toUpperCase();
  }
  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email[0].toUpperCase();
  }
  return '?';
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paramètres',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compte, langue et notifications',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    if (user != null) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.chipMint,
                          child: Text(
                            _avatarLetter(user),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          user.displayName ?? 'Mon compte',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.email ?? ''),
                      ),
                      const SizedBox(height: 24),
                    ],
                    FilledButton.icon(
                      onPressed: () => context.read<AuthCubit>().signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
