import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relearn/app.dart';
import 'package:relearn/core/router/app_router.dart';

void main() {
  testWidgets('login screen renders brand and the how-to entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ReLearnApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('How ReLearn works'), findsOneWidget);
    expect(find.text('Sign in as admin'), findsOneWidget);
  });

  testWidgets('onboarding guide can be completed', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(const ProviderScope(child: ReLearnApp()));
    appRouter.go('/onboarding');
    await tester.pumpAndSettle();

    expect(find.text('Recycle to Learn.'), findsOneWidget);
    for (var page = 0; page < 3; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
