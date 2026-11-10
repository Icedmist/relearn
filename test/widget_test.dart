import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relearn/app.dart';

void main() {
  testWidgets('login screen renders brand and demo entry points', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ReLearnApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Admin demo'), findsOneWidget);
    expect(find.text('Collector demo'), findsOneWidget);
  });
}
