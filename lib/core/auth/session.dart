import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/app_store.dart';
import '../config/app_config.dart';

/// Signs out of Supabase (when live) and returns to the login screen.
Future<void> signOutAndGo(BuildContext context, WidgetRef ref) async {
  if (!AppConfig.demoMode) {
    await Supabase.instance.client.auth.signOut();
  }
  ref.invalidate(appStoreProvider);
  if (context.mounted) context.go('/login');
}
