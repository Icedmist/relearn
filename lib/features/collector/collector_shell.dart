import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';

class CollectorShell extends ConsumerWidget {
  const CollectorShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/collector/search')) return 1;
    if (location.startsWith('/collector/history')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final live = state.isLive;
    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(height: 30),
        actions: [
          if (narrow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                live ? Icons.cloud_done_outlined : Icons.science_outlined,
                size: 20,
                color: live ? AppColors.leaf : AppColors.sky,
              ),
            )
          else
            StatusPill(
              label: live
                  ? 'LIVE · v${AppConfig.version}'
                  : 'DEMO · v${AppConfig.version}',
              color: live ? AppColors.leaf : AppColors.sky,
              icon: live ? Icons.cloud_done_outlined : Icons.science_outlined,
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Admin dashboard',
            onPressed: () => context.go('/admin/dashboard'),
            icon: const Icon(Icons.dashboard_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => signOutAndGo(context, ref),
            icon: const Icon(Icons.logout, size: 19),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          context.go(switch (index) {
            1 => '/collector/search',
            2 => '/collector/history',
            _ => '/collector/home',
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
