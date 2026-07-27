import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_al_iman_app/features/welcome/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('Welcome page shows greeting and CTA', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    await tester.pump();

    expect(find.textContaining('As-Salamu'), findsOneWidget);
    expect(find.text('Bienvenue sur Noor Al-Iman'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('LA LUMIÈRE DE LA FOI'), findsOneWidget);
  });
}
