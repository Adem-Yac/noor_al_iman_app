import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onOpenRegister});

  final VoidCallback? onOpenRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthCubit>().signInWithEmail(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<AuthCubit>().clearTransientMessage();
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return AuthScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHero(
                title: 'Se connecter',
                subtitle: 'Ravis de vous revoir sur votre compagnon spirituel',
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Adresse e-mail',
                controller: _email,
                hint: 'nom@exemple.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mot de passe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOf(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          ),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AuthTextField(
                label: '',
                controller: _password,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.softOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Connexion',
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
                      'ou continuer avec',
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
                          final open = widget.onOpenRegister;
                          if (open != null) {
                            open();
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          }
                        },
                  child: Text.rich(
                    TextSpan(
                      text: 'Pas encore de compte ? ',
                      style: TextStyle(color: AppColors.mutedOf(context)),
                      children: [
                        TextSpan(
                          text: 'S’inscrire',
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
