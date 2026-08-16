import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onBackToLogin});

  final VoidCallback? onBackToLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
      );
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères.'),
        ),
      );
      return;
    }

    context.read<AuthCubit>().signUp(
      email: _email.text,
      password: _password.text,
      displayName: _name.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthUnauthenticated && curr.message != null,
      listener: (context, state) {
        if (state is! AuthUnauthenticated || state.message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
        context.read<AuthCubit>().clearTransientMessage();
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return AuthScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHero(
                title: 'Créer un compte',
                subtitle: 'Commencez votre voyage spirituel dès aujourd’hui',
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Nom complet',
                controller: _name,
                hint: 'Abdoulaye Diallo',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Email',
                controller: _email,
                hint: 'votre@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Mot de passe',
                controller: _password,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.softOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Confirmer le mot de passe',
                controller: _confirm,
                hint: '••••••••',
                icon: Icons.verified_user_outlined,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.softOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'S’inscrire',
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderOf(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softOf(context),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.borderOf(context))),
                ],
              ),
              const SizedBox(height: 16),
              GoogleSignInButton(
                loading: loading,
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          final back = widget.onBackToLogin;
                          if (back != null) {
                            back();
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          }
                        },
                  child: Text.rich(
                    TextSpan(
                      text: 'Déjà un compte ? ',
                      style: TextStyle(color: AppColors.mutedOf(context)),
                      children: [
                        TextSpan(
                          text: 'Se connecter',
                          style: TextStyle(
                            color: AppColors.primaryOf(context),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
