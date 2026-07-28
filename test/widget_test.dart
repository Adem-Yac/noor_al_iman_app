import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_al_iman_app/features/auth/data/repositories/auth_repository.dart';
import 'package:noor_al_iman_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:noor_al_iman_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page shows sign-in form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthCubit(AuthRepository()),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('S’inscrire'), findsOneWidget);
  });
}
