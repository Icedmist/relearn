import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relearn/app.dart';
import 'package:relearn/core/router/app_router.dart';

const _routes = <String>[
  '/login',
  '/onboarding',
  '/account',
  '/admin/dashboard',
  '/admin/schools',
  '/admin/beneficiaries',
  '/admin/beneficiaries/new',
  '/admin/beneficiaries/ben-1',
  '/admin/print',
  '/admin/materials',
  '/admin/rewards',
  '/admin/reports',
  '/admin/users',
  '/collector/home',
  '/collector/search',
  '/collector/scan',
  '/collector/beneficiary/ben-1',
  '/collector/beneficiary/ben-1/collect',
  '/collector/beneficiary/ben-1/redeem',
  '/collector/success?action=collect&points=20&balance=250&beneficiary=ben-1',
  '/collector/history',
];

Future<void> _pumpAt(WidgetTester tester, Size size, String route) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(const ProviderScope(child: ReLearnApp()));
  appRouter.go(route);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    appRouter.go('/login');
  });

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    for (final route in _routes) {
      testWidgets('renders $route at $label', (tester) async {
        await _pumpAt(tester, size, route);
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow or build error on $route',
        );
      });
    }
  }

  testWidgets('collector app bar fits a 360 px phone', (tester) async {
    await _pumpAt(tester, const Size(360, 800), '/collector/home');
    expect(tester.takeException(), isNull);
    expect(find.text('Ready to collect'), findsOneWidget);
  });
}
