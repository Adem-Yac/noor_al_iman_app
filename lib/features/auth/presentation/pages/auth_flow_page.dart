import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Login + Register au démarrage (sans pile Navigator fragile).
class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  bool _showRegister = false;

  void _openRegister() => setState(() => _showRegister = true);

  void _openLogin() => setState(() => _showRegister = false);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthUnauthenticated && curr.message != null,
      listener: (context, state) {
        if (state is AuthUnauthenticated && state.message != null) {
          setState(() => _showRegister = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<AuthCubit>().clearTransientMessage();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _showRegister
            ? RegisterPage(
                key: const ValueKey('register'),
                onBackToLogin: _openLogin,
              )
            : LoginPage(
                key: const ValueKey('login'),
                onOpenRegister: _openRegister,
              ),
      ),
    );
  }
}
