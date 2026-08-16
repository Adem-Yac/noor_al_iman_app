import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
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
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return AuthScaffold(
          showBrandHeader: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const AuthHero(
                title: 'Mot de passe oublié',
                subtitle:
                    'Entrez votre e-mail pour recevoir un lien de réinitialisation',
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Adresse e-mail',
                controller: _email,
                hint: 'nom@exemple.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Envoyer le lien',
                loading: loading,
                onPressed: () => context.read<AuthCubit>().sendPasswordReset(
                  _email.text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
