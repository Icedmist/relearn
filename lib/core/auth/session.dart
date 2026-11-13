import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/app_store.dart';
import '../config/app_config.dart';
import 'session_lock.dart';

/// The landing route for a signed-in staff role.
///
/// Admins see the whole programme; teachers are read-only and land on their
/// school overview; collectors land on the collection desk.
String homeForRole(String role) => switch (role) {
  'admin' => '/admin/dashboard',
  'teacher' => '/teacher/home',
  _ => '/collector/home',
};

/// Signs out of Supabase (when live), clears the lock state, and returns to
/// the login screen.
Future<void> signOutAndGo(BuildContext context, WidgetRef ref) async {
  await ref.read(sessionLockProvider.notifier).reset();
  if (!AppConfig.demoMode) {
    await Supabase.instance.client.auth.signOut();
  }
  ref.invalidate(appStoreProvider);
  if (context.mounted) context.go('/login');
}
