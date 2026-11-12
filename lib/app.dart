import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/session_lock.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ReLearnApp extends ConsumerWidget {
  const ReLearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ReLearn — Recycle to Learn',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      builder: (context, child) =>
          SessionLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
